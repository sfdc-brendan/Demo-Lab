public with sharing class IntakePDFController {

    private static final String DEFAULT_BRAND_COLOR = '#032D60';
    private static final String DEFAULT_FOOTER_HTML =
        'Generated automatically by the Intake Builder.';

    public Id intakeId { get; set; }

    public IntakePDFController() {
        if (ApexPages.currentPage() != null) {
            this.intakeId = ApexPages.currentPage().getParameters().get('id');
        }
    }

    private PageData cachedData;
    public PageData getData() {
        if (cachedData == null) {
            cachedData = buildData(this.intakeId);
        }
        return cachedData;
    }

    public List<Section> getSections() { return getData().sections; }
    public String getTemplateName() { return getData().templateName; }
    public Decimal getTemplateVersion() { return getData().templateVersion; }
    public String getPdfHeader() { return getData().pdfHeader; }
    public String getPdfFooter() { return getData().pdfFooter; }
    public String getBrandColor() { return getData().brandColor; }
    public String getBrandTextColor() { return getData().brandTextColor; }
    public String getLogoSrc() { return getData().logoSrc; }
    public Boolean getHasLogo() { return String.isNotBlank(getData().logoSrc); }
    public String getRecordName() { return getData().recordName; }
    public String getErrorMessage() { return getData().errorMessage; }
    public String getTodayString() {
        return Datetime.now().format('MMMM d, yyyy h:mm a');
    }

    @TestVisible
    private static PageData buildData(Id intakeId) {
        PageData data = new PageData();
        if (intakeId == null) {
            data.errorMessage = 'No record id supplied.';
            applyDefaults(data, null);
            return data;
        }

        Schema.SObjectType sot = intakeId.getSObjectType();
        String objApi = sot.getDescribe().getName();

        Intake_Template__c tpl = resolveTemplate(intakeId, objApi);
        if (tpl == null) {
            data.errorMessage = 'No Intake Template linked to this record.';
            applyDefaults(data, null);
            return data;
        }

        data.templateName = tpl.Name;
        data.templateVersion = tpl.Version__c;
        data.pdfHeader = tpl.PDF_Header__c;
        data.targetObject = tpl.Target_Object_API_Name__c;
        data.recordName = readRecordName(intakeId, objApi);

        applyDefaults(data, tpl);

        List<Intake_Question__c> questions = [
            SELECT Id, DeveloperName__c, Question_Text__c, Category__c, Order__c,
                   Target_Field_API_Name__c
            FROM Intake_Question__c
            WHERE Intake_Template__c = :tpl.Id
            ORDER BY Order__c ASC NULLS LAST, CreatedDate ASC
        ];

        Map<String, Object> answersMap = readAnswers(intakeId, objApi, questions, tpl);

        Map<String, List<QAItem>> grouped = new Map<String, List<QAItem>>();
        List<String> categoryOrder = new List<String>();

        for (Intake_Question__c q : questions) {
            String category = String.isBlank(q.Category__c) ? 'General' : q.Category__c;
            if (!grouped.containsKey(category)) {
                grouped.put(category, new List<QAItem>());
                categoryOrder.add(category);
            }
            QAItem item = new QAItem();
            item.questionText = q.Question_Text__c;
            Object val = answersMap.get(q.DeveloperName__c);
            item.answer = (val == null) ? '' : String.valueOf(val);
            grouped.get(category).add(item);
        }

        data.sections = new List<Section>();
        for (String cat : categoryOrder) {
            Section sec = new Section();
            sec.category = cat;
            sec.items = grouped.get(cat);
            data.sections.add(sec);
        }

        return data;
    }

    private static void applyDefaults(PageData data, Intake_Template__c tpl) {
        // Brand color: template override → default Salesforce blue.
        String color = (tpl == null) ? null : tpl.Brand_Color__c;
        data.brandColor = String.isNotBlank(color) ? color : DEFAULT_BRAND_COLOR;
        data.brandTextColor = computeTextColor(data.brandColor);

        // Footer: template override → default platform footer.
        String footer = (tpl == null) ? null : tpl.PDF_Footer__c;
        data.pdfFooter = String.isNotBlank(footer) ? footer : DEFAULT_FOOTER_HTML;

        // Logo: file id (preferred) → static resource → blank.
        if (tpl == null) {
            data.logoSrc = null;
            return;
        }
        if (String.isNotBlank(tpl.Brand_Logo_File_Id__c)) {
            String dataUri = resolveLogoFromFile(tpl.Brand_Logo_File_Id__c);
            if (String.isNotBlank(dataUri)) {
                data.logoSrc = dataUri;
                return;
            }
        }
        if (String.isNotBlank(tpl.Brand_Logo_Static_Resource__c)) {
            data.logoSrc = '/resource/' + tpl.Brand_Logo_Static_Resource__c;
        }
    }

    /**
     * Compute readable text color (white or near-black) for a given background hex
     * using the WCAG-style relative luminance formula.
     */
    @TestVisible
    private static String computeTextColor(String backgroundHex) {
        if (String.isBlank(backgroundHex)) return '#181818';
        String hex = backgroundHex.startsWith('#') ? backgroundHex.substring(1) : backgroundHex;
        if (hex.length() != 6) return '#181818';
        try {
            Integer r = parseHexByte(hex.substring(0, 2));
            Integer g = parseHexByte(hex.substring(2, 4));
            Integer b = parseHexByte(hex.substring(4, 6));
            // Perceived luminance (BT.601 weighting — fast and good enough for headers).
            Decimal luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255.0;
            return luminance > 0.6 ? '#181818' : '#FFFFFF';
        } catch (Exception e) {
            return '#FFFFFF';
        }
    }

    private static final String HEX_CHARS = '0123456789ABCDEF';

    private static Integer parseHexByte(String twoChars) {
        String hi = twoChars.substring(0, 1).toUpperCase();
        String lo = twoChars.substring(1, 2).toUpperCase();
        Integer hiVal = HEX_CHARS.indexOf(hi);
        Integer loVal = HEX_CHARS.indexOf(lo);
        if (hiVal < 0 || loVal < 0) {
            throw new IllegalArgumentException('Invalid hex byte: ' + twoChars);
        }
        return hiVal * 16 + loVal;
    }

    /**
     * Look up a Salesforce File by ContentDocumentId, base64-encode its latest version,
     * and return an inline data URI suitable for an HTML img src attribute.
     * Returns null on any miss.
     */
    @TestVisible
    private static String resolveLogoFromFile(String contentDocumentId) {
        if (String.isBlank(contentDocumentId)) return null;
        try {
            List<ContentVersion> vers = [
                SELECT VersionData, FileType
                FROM ContentVersion
                WHERE ContentDocumentId = :contentDocumentId
                  AND IsLatest = true
                LIMIT 1
            ];
            if (vers.isEmpty() || vers[0].VersionData == null) return null;
            String mime = mimeForFileType(vers[0].FileType);
            String base64 = EncodingUtil.base64Encode(vers[0].VersionData);
            return 'data:' + mime + ';base64,' + base64;
        } catch (Exception e) {
            return null;
        }
    }

    private static String mimeForFileType(String fileType) {
        if (String.isBlank(fileType)) return 'image/png';
        String t = fileType.toUpperCase();
        if (t == 'PNG') return 'image/png';
        if (t == 'JPG' || t == 'JPEG') return 'image/jpeg';
        if (t == 'GIF') return 'image/gif';
        if (t == 'SVG') return 'image/svg+xml';
        if (t == 'WEBP') return 'image/webp';
        return 'image/png';
    }

    private static Intake_Template__c resolveTemplate(Id intakeId, String objApi) {
        // Case 1: this is an Intake_Submission__c
        if (objApi == 'Intake_Submission__c') {
            List<Intake_Submission__c> subs = [
                SELECT Intake_Template__c FROM Intake_Submission__c
                WHERE Id = :intakeId LIMIT 1
            ];
            if (!subs.isEmpty() && subs[0].Intake_Template__c != null) {
                return loadTemplate(subs[0].Intake_Template__c);
            }
        }

        // Case 2: target object has an Intake_Template__c lookup field
        Schema.SObjectType sot = Schema.getGlobalDescribe().get(objApi);
        if (sot != null) {
            Map<String, Schema.SObjectField> fieldMap = sot.getDescribe().fields.getMap();
            if (fieldMap.containsKey('intake_template__c')) {
                String soql = 'SELECT Intake_Template__c FROM '
                    + objApi.replaceAll('[^A-Za-z0-9_]', '')
                    + ' WHERE Id = :intakeId LIMIT 1';
                List<SObject> recs = Database.query(soql);
                if (!recs.isEmpty()) {
                    Id tplId = (Id) recs[0].get('Intake_Template__c');
                    if (tplId != null) return loadTemplate(tplId);
                }
            }
        }

        // Case 3: fallback — look up any Active template by Target_Object_API_Name__c
        List<Intake_Template__c> matches = [
            SELECT Id, Name, Version__c, PDF_Header__c, PDF_Footer__c,
                   Brand_Color__c, Brand_Logo_File_Id__c, Brand_Logo_Static_Resource__c,
                   Target_Object_API_Name__c
            FROM Intake_Template__c
            WHERE Target_Object_API_Name__c = :objApi
              AND Status__c = 'Active'
            ORDER BY Version__c DESC
            LIMIT 1
        ];
        return matches.isEmpty() ? null : matches[0];
    }

    private static Intake_Template__c loadTemplate(Id tplId) {
        List<Intake_Template__c> tpls = [
            SELECT Id, Name, Version__c, PDF_Header__c, PDF_Footer__c,
                   Brand_Color__c, Brand_Logo_File_Id__c, Brand_Logo_Static_Resource__c,
                   Target_Object_API_Name__c
            FROM Intake_Template__c
            WHERE Id = :tplId LIMIT 1
        ];
        return tpls.isEmpty() ? null : tpls[0];
    }

    private static String readRecordName(Id recordId, String objApi) {
        try {
            String safeObj = objApi.replaceAll('[^A-Za-z0-9_]', '');
            List<SObject> recs = Database.query(
                'SELECT Id, Name FROM ' + safeObj + ' WHERE Id = :recordId LIMIT 1'
            );
            if (!recs.isEmpty()) return (String) recs[0].get('Name');
        } catch (Exception e) {
            // Some objects don't have a Name field; ignore
        }
        return String.valueOf(recordId);
    }

    private static Map<String, Object> readAnswers(
        Id recordId,
        String objApi,
        List<Intake_Question__c> questions,
        Intake_Template__c tpl
    ) {
        Map<String, Object> result = new Map<String, Object>();

        if (objApi == 'Intake_Submission__c') {
            List<Intake_Submission__c> subs = [
                SELECT Answers_JSON__c FROM Intake_Submission__c
                WHERE Id = :recordId LIMIT 1
            ];
            if (!subs.isEmpty() && String.isNotBlank(subs[0].Answers_JSON__c)) {
                Map<String, Object> parsed =
                    (Map<String, Object>) JSON.deserializeUntyped(subs[0].Answers_JSON__c);
                result.putAll(parsed);
            }
            return result;
        }

        Schema.SObjectType sot = Schema.getGlobalDescribe().get(objApi);
        if (sot == null) return result;
        Map<String, Schema.SObjectField> fieldMap = sot.getDescribe().fields.getMap();

        Set<String> wantFields = new Set<String>{ 'id' };
        for (Intake_Question__c q : questions) {
            if (String.isNotBlank(q.Target_Field_API_Name__c)
                    && fieldMap.containsKey(q.Target_Field_API_Name__c.toLowerCase())) {
                wantFields.add(q.Target_Field_API_Name__c);
            }
        }
        if (fieldMap.containsKey('raw_responses_json__c')) {
            wantFields.add('Raw_Responses_JSON__c');
        }

        String safeObj = objApi.replaceAll('[^A-Za-z0-9_]', '');
        String soql = 'SELECT ' + String.join(new List<String>(wantFields), ', ')
            + ' FROM ' + safeObj + ' WHERE Id = :recordId LIMIT 1';
        List<SObject> recs = Database.query(soql);
        if (recs.isEmpty()) return result;
        SObject rec = recs[0];

        for (Intake_Question__c q : questions) {
            if (String.isNotBlank(q.Target_Field_API_Name__c)
                    && fieldMap.containsKey(q.Target_Field_API_Name__c.toLowerCase())) {
                Object val = rec.get(q.Target_Field_API_Name__c);
                if (val != null) result.put(q.DeveloperName__c, val);
            }
        }
        // Fallback: pull from Raw_Responses_JSON__c if a question has no resolved field
        if (fieldMap.containsKey('raw_responses_json__c')) {
            String raw = (String) rec.get('Raw_Responses_JSON__c');
            if (String.isNotBlank(raw)) {
                try {
                    Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(raw);
                    for (Intake_Question__c q : questions) {
                        if (!result.containsKey(q.DeveloperName__c)
                                && parsed.containsKey(q.DeveloperName__c)) {
                            result.put(q.DeveloperName__c, parsed.get(q.DeveloperName__c));
                        }
                    }
                } catch (Exception e) {
                    // Bad JSON, skip
                }
            }
        }
        return result;
    }

    public class PageData {
        public String templateName { get; set; }
        public Decimal templateVersion { get; set; }
        public String pdfHeader { get; set; }
        public String pdfFooter { get; set; }
        public String brandColor { get; set; }
        public String brandTextColor { get; set; }
        public String logoSrc { get; set; }
        public String targetObject { get; set; }
        public String recordName { get; set; }
        public List<Section> sections { get; set; }
        public String errorMessage { get; set; }
    }

    public class Section {
        public String category { get; set; }
        public List<QAItem> items { get; set; }
    }

    public class QAItem {
        public String questionText { get; set; }
        public String answer { get; set; }
    }
}
