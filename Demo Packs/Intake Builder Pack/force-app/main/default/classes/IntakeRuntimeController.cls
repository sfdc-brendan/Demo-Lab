public with sharing class IntakeRuntimeController {

    @AuraEnabled(cacheable=true)
    public static List<TemplateOption> getAvailableTemplates() {
        List<TemplateOption> result = new List<TemplateOption>();
        for (Intake_Template__c t : [
            SELECT Id, Name, Description__c, Target_Object_API_Name__c, Version__c
            FROM Intake_Template__c
            WHERE Status__c = 'Active'
            ORDER BY Name ASC
            LIMIT 200
        ]) {
            result.add(new TemplateOption(t));
        }
        return result;
    }

    @AuraEnabled(cacheable=true)
    public static TemplateBundle getTemplate(Id templateId) {
        if (templateId == null) {
            return null;
        }

        List<Intake_Template__c> templates = [
            SELECT Id, Name, Status__c, Description__c, Target_Object_API_Name__c,
                   Persona_Description__c, PDF_Header__c, PDF_Footer__c,
                   Brand_Color__c, Brand_Logo_File_Id__c, Brand_Logo_Static_Resource__c,
                   Default_Locale__c, Version__c, Parent_Template__c
            FROM Intake_Template__c
            WHERE Id = :templateId
            LIMIT 1
        ];
        if (templates.isEmpty()) {
            return null;
        }

        List<Intake_Question__c> questions = [
            SELECT Id, Name, DeveloperName__c, Question_Text__c, Help_Text__c, Category__c,
                   Order__c, Required__c, Answer_Type__c, Target_Field_API_Name__c,
                   Picklist_Source__c, Picklist_Source_Object__c, Picklist_Source_Field__c,
                   Lookup_Object__c, Validation_Regex__c, Validation_Error_Message__c,
                   AI_Extraction_Hint__c
            FROM Intake_Question__c
            WHERE Intake_Template__c = :templateId
            ORDER BY Order__c ASC NULLS LAST, CreatedDate ASC
        ];

        Set<Id> questionIds = new Set<Id>();
        for (Intake_Question__c q : questions) {
            questionIds.add(q.Id);
        }

        Map<Id, List<Intake_Picklist_Value__c>> picklistByQ = new Map<Id, List<Intake_Picklist_Value__c>>();
        for (Intake_Picklist_Value__c pv : [
            SELECT Id, Intake_Question__c, Label__c, Value__c, Order__c
            FROM Intake_Picklist_Value__c
            WHERE Intake_Question__c IN :questionIds
            ORDER BY Order__c ASC NULLS LAST, CreatedDate ASC
        ]) {
            if (!picklistByQ.containsKey(pv.Intake_Question__c)) {
                picklistByQ.put(pv.Intake_Question__c, new List<Intake_Picklist_Value__c>());
            }
            picklistByQ.get(pv.Intake_Question__c).add(pv);
        }

        Map<Id, List<Intake_Visibility_Rule__c>> rulesByQ = new Map<Id, List<Intake_Visibility_Rule__c>>();
        for (Intake_Visibility_Rule__c r : [
            SELECT Id, Intake_Question__c, Source_Question_Developer_Name__c,
                   Operator__c, Value__c, Logic_Group__c
            FROM Intake_Visibility_Rule__c
            WHERE Intake_Question__c IN :questionIds
        ]) {
            if (!rulesByQ.containsKey(r.Intake_Question__c)) {
                rulesByQ.put(r.Intake_Question__c, new List<Intake_Visibility_Rule__c>());
            }
            rulesByQ.get(r.Intake_Question__c).add(r);
        }

        Map<Id, List<Intake_Translation__c>> translationsByQ = new Map<Id, List<Intake_Translation__c>>();
        for (Intake_Translation__c t : [
            SELECT Id, Intake_Question__c, Locale__c,
                   Question_Text_Translated__c, Help_Text_Translated__c
            FROM Intake_Translation__c
            WHERE Intake_Question__c IN :questionIds
        ]) {
            if (!translationsByQ.containsKey(t.Intake_Question__c)) {
                translationsByQ.put(t.Intake_Question__c, new List<Intake_Translation__c>());
            }
            translationsByQ.get(t.Intake_Question__c).add(t);
        }

        TemplateBundle bundle = new TemplateBundle(templates[0]);
        for (Intake_Question__c q : questions) {
            QuestionDTO dto = new QuestionDTO(q);
            dto.picklistOptions = buildPicklistOptions(q, picklistByQ.get(q.Id));
            dto.visibilityRules = buildVisibilityRules(rulesByQ.get(q.Id));
            dto.translations = buildTranslations(translationsByQ.get(q.Id));
            bundle.questions.add(dto);
        }

        return bundle;
    }

    private static List<PicklistOption> buildPicklistOptions(
        Intake_Question__c q,
        List<Intake_Picklist_Value__c> staticValues
    ) {
        List<PicklistOption> result = new List<PicklistOption>();
        if (q.Answer_Type__c != 'picklist' && q.Answer_Type__c != 'multipicklist') {
            return result;
        }

        if (q.Picklist_Source__c == 'From_Field'
                && String.isNotBlank(q.Picklist_Source_Object__c)
                && String.isNotBlank(q.Picklist_Source_Field__c)) {
            result = describePicklistField(q.Picklist_Source_Object__c, q.Picklist_Source_Field__c);
        } else if (staticValues != null) {
            for (Intake_Picklist_Value__c pv : staticValues) {
                result.add(new PicklistOption(pv.Label__c, pv.Value__c));
            }
        }
        return result;
    }

    private static List<PicklistOption> describePicklistField(String objectApi, String fieldApi) {
        List<PicklistOption> options = new List<PicklistOption>();
        try {
            Schema.SObjectType sot = Schema.getGlobalDescribe().get(objectApi);
            if (sot == null) return options;
            Schema.DescribeFieldResult dfr = sot.getDescribe().fields.getMap().get(fieldApi).getDescribe();
            for (Schema.PicklistEntry pe : dfr.getPicklistValues()) {
                if (pe.isActive()) {
                    options.add(new PicklistOption(pe.getLabel(), pe.getValue()));
                }
            }
        } catch (Exception e) {
            // Field describe failed; return empty list and let UI surface a friendly error
        }
        return options;
    }

    private static List<VisibilityRuleDTO> buildVisibilityRules(List<Intake_Visibility_Rule__c> rules) {
        List<VisibilityRuleDTO> result = new List<VisibilityRuleDTO>();
        if (rules == null) return result;
        for (Intake_Visibility_Rule__c r : rules) {
            result.add(new VisibilityRuleDTO(r));
        }
        return result;
    }

    private static List<TranslationDTO> buildTranslations(List<Intake_Translation__c> translations) {
        List<TranslationDTO> result = new List<TranslationDTO>();
        if (translations == null) return result;
        for (Intake_Translation__c t : translations) {
            result.add(new TranslationDTO(t));
        }
        return result;
    }

    @AuraEnabled
    public static DraftResult getDraftIntake(Id templateId, Id voiceCallId) {
        if (templateId == null) {
            return null;
        }

        Intake_Template__c tpl = loadTemplate(templateId);
        if (tpl == null) {
            return null;
        }

        if (String.isNotBlank(tpl.Target_Object_API_Name__c)) {
            return loadDraftFromTargetObject(tpl, voiceCallId);
        }
        return loadDraftFromSubmission(tpl);
    }

    private static DraftResult loadDraftFromTargetObject(Intake_Template__c tpl, Id voiceCallId) {
        if (!hasField(tpl.Target_Object_API_Name__c, 'VoiceCall__c')
                || !hasField(tpl.Target_Object_API_Name__c, 'Status__c')) {
            return null;
        }
        String soql = 'SELECT Id, Name, Raw_Responses_JSON__c FROM '
            + escapeIdentifier(tpl.Target_Object_API_Name__c)
            + ' WHERE VoiceCall__c = :voiceCallId AND Status__c = \'Draft\''
            + ' ORDER BY LastModifiedDate DESC LIMIT 1';
        if (!hasField(tpl.Target_Object_API_Name__c, 'Raw_Responses_JSON__c')) {
            soql = 'SELECT Id, Name FROM ' + escapeIdentifier(tpl.Target_Object_API_Name__c)
                + ' WHERE VoiceCall__c = :voiceCallId AND Status__c = \'Draft\''
                + ' ORDER BY LastModifiedDate DESC LIMIT 1';
        }
        List<SObject> drafts = Database.query(soql);
        if (drafts.isEmpty()) {
            return null;
        }
        SObject draft = drafts[0];
        String answersJson = null;
        if (hasField(tpl.Target_Object_API_Name__c, 'Raw_Responses_JSON__c')) {
            answersJson = (String) draft.get('Raw_Responses_JSON__c');
        }
        return new DraftResult(draft.Id, (String) draft.get('Name'), answersJson);
    }

    private static DraftResult loadDraftFromSubmission(Intake_Template__c tpl) {
        List<Intake_Submission__c> drafts = [
            SELECT Id, Name, Answers_JSON__c
            FROM Intake_Submission__c
            WHERE Intake_Template__c = :tpl.Id
              AND Status__c = 'Draft'
            ORDER BY LastModifiedDate DESC
            LIMIT 1
        ];
        if (drafts.isEmpty()) {
            return null;
        }
        return new DraftResult(drafts[0].Id, drafts[0].Name, drafts[0].Answers_JSON__c);
    }

    @AuraEnabled
    public static DraftResult saveDraftIntake(Id templateId, Id voiceCallId, String answersJson) {
        if (templateId == null || String.isBlank(answersJson)) {
            return null;
        }

        Intake_Template__c tpl = loadTemplate(templateId);
        if (tpl == null) {
            return null;
        }

        Map<String, Object> answers = (Map<String, Object>) JSON.deserializeUntyped(answersJson);

        if (String.isNotBlank(tpl.Target_Object_API_Name__c)) {
            return saveDraftToTargetObject(tpl, voiceCallId, answers, answersJson);
        }
        return saveDraftToSubmission(tpl, answersJson);
    }

    private static DraftResult saveDraftToTargetObject(
        Intake_Template__c tpl,
        Id voiceCallId,
        Map<String, Object> answers,
        String answersJson
    ) {
        String objApi = tpl.Target_Object_API_Name__c;
        if (!hasField(objApi, 'VoiceCall__c') || !hasField(objApi, 'Status__c')) {
            return null;
        }

        SObject record;
        String soql = 'SELECT Id FROM ' + escapeIdentifier(objApi)
            + ' WHERE VoiceCall__c = :voiceCallId AND Status__c = \'Draft\''
            + ' ORDER BY LastModifiedDate DESC LIMIT 1';
        List<SObject> drafts = Database.query(soql);
        if (!drafts.isEmpty()) {
            record = drafts[0];
        } else {
            record = Schema.getGlobalDescribe().get(objApi).newSObject();
            record.put('VoiceCall__c', voiceCallId);
            record.put('Status__c', 'Draft');
        }

        applyAnswersToRecord(record, objApi, answers, getQuestionFieldMap(tpl.Id));

        if (hasField(objApi, 'Raw_Responses_JSON__c')) {
            record.put('Raw_Responses_JSON__c', answersJson);
        }

        upsert record;
        Id recordId = (Id) record.get('Id');
        SObject reloaded = Database.query(
            'SELECT Id, Name FROM ' + escapeIdentifier(objApi) + ' WHERE Id = :recordId LIMIT 1'
        )[0];
        return new DraftResult(reloaded.Id, (String) reloaded.get('Name'));
    }

    private static DraftResult saveDraftToSubmission(Intake_Template__c tpl, String answersJson) {
        List<Intake_Submission__c> drafts = [
            SELECT Id FROM Intake_Submission__c
            WHERE Intake_Template__c = :tpl.Id
              AND Status__c = 'Draft'
            ORDER BY LastModifiedDate DESC LIMIT 1
        ];

        Intake_Submission__c sub;
        if (!drafts.isEmpty()) {
            sub = drafts[0];
        } else {
            sub = new Intake_Submission__c(
                Intake_Template__c = tpl.Id,
                Status__c = 'Draft'
            );
        }
        sub.Answers_JSON__c = answersJson;
        sub.Template_Version__c = tpl.Version__c;
        upsert sub;

        Intake_Submission__c reloaded = [
            SELECT Id, Name FROM Intake_Submission__c WHERE Id = :sub.Id LIMIT 1
        ];
        return new DraftResult(reloaded.Id, reloaded.Name);
    }

    @AuraEnabled
    public static Id submitIntake(Id templateId, Id voiceCallId, String answersJson) {
        if (templateId == null) {
            throw new AuraHandledException('Template Id is required.');
        }
        if (String.isBlank(answersJson)) {
            throw new AuraHandledException('Answers JSON is required.');
        }

        Intake_Template__c tpl = loadTemplate(templateId);
        if (tpl == null) {
            throw new AuraHandledException('Template not found.');
        }

        Map<String, Object> answers = (Map<String, Object>) JSON.deserializeUntyped(answersJson);

        if (String.isNotBlank(tpl.Target_Object_API_Name__c)) {
            return submitToTargetObject(tpl, voiceCallId, answers, answersJson);
        }
        return submitToSubmission(tpl, voiceCallId, answersJson);
    }

    private static Id submitToTargetObject(
        Intake_Template__c tpl,
        Id voiceCallId,
        Map<String, Object> answers,
        String answersJson
    ) {
        String objApi = tpl.Target_Object_API_Name__c;
        SObject record;

        if (voiceCallId != null
                && hasField(objApi, 'VoiceCall__c')
                && hasField(objApi, 'Status__c')) {
            String soql = 'SELECT Id FROM ' + escapeIdentifier(objApi)
                + ' WHERE VoiceCall__c = :voiceCallId AND Status__c = \'Draft\''
                + ' ORDER BY LastModifiedDate DESC LIMIT 1';
            List<SObject> drafts = Database.query(soql);
            if (!drafts.isEmpty()) {
                record = drafts[0];
            }
        }

        if (record == null) {
            record = Schema.getGlobalDescribe().get(objApi).newSObject();
            if (voiceCallId != null && hasField(objApi, 'VoiceCall__c')) {
                record.put('VoiceCall__c', voiceCallId);
            }
        }

        applyAnswersToRecord(record, objApi, answers, getQuestionFieldMap(tpl.Id));

        if (hasField(objApi, 'Status__c')) {
            record.put('Status__c', 'Submitted');
        }
        if (hasField(objApi, 'Raw_Responses_JSON__c')) {
            record.put('Raw_Responses_JSON__c', answersJson);
        }
        if (hasField(objApi, 'Intake_Template__c')) {
            record.put('Intake_Template__c', tpl.Id);
        }

        upsert record;
        return (Id) record.get('Id');
    }

    private static Id submitToSubmission(Intake_Template__c tpl, Id voiceCallId, String answersJson) {
        Intake_Submission__c sub;
        List<Intake_Submission__c> drafts = [
            SELECT Id FROM Intake_Submission__c
            WHERE Intake_Template__c = :tpl.Id
              AND Status__c = 'Draft'
            ORDER BY LastModifiedDate DESC LIMIT 1
        ];
        if (!drafts.isEmpty()) {
            sub = drafts[0];
        }
        if (sub == null) {
            sub = new Intake_Submission__c(Intake_Template__c = tpl.Id);
        }
        sub.Status__c = 'Submitted';
        sub.Answers_JSON__c = answersJson;
        sub.Template_Version__c = tpl.Version__c;
        upsert sub;
        return sub.Id;
    }

    @AuraEnabled
    public static void attachIntakePDF(Id intakeId) {
        if (intakeId == null) return;

        Schema.SObjectType sot = intakeId.getSObjectType();
        String objApi = sot.getDescribe().getName();
        String displayName = readRecordName(intakeId, objApi);

        PageReference pdfPage = Page.IntakePDF;
        pdfPage.getParameters().put('id', intakeId);

        Blob pdfBlob;
        if (Test.isRunningTest()) {
            pdfBlob = Blob.valueOf('Test PDF Content');
        } else {
            pdfBlob = pdfPage.getContentAsPDF();
        }

        String fileLabel = String.isBlank(displayName) ? String.valueOf(intakeId) : displayName;
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Intake - ' + fileLabel;
        cv.PathOnClient = 'Intake_' + fileLabel.replaceAll('[^A-Za-z0-9_-]', '_') + '.pdf';
        cv.VersionData = pdfBlob;
        insert cv;

        cv = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];

        List<ContentDocumentLink> links = new List<ContentDocumentLink>();
        links.add(new ContentDocumentLink(
            ContentDocumentId = cv.ContentDocumentId,
            LinkedEntityId = intakeId,
            ShareType = 'V'
        ));

        insert links;
    }

    private static String readRecordName(Id recordId, String objApi) {
        try {
            String safeObj = objApi.replaceAll('[^A-Za-z0-9_]', '');
            List<SObject> recs = Database.query(
                'SELECT Id, Name FROM ' + safeObj + ' WHERE Id = :recordId LIMIT 1'
            );
            if (!recs.isEmpty()) return (String) recs[0].get('Name');
        } catch (Exception e) {
            // not all objects have a Name field
        }
        return String.valueOf(recordId);
    }

    private static Id readVoiceCallId(Id recordId, String objApi) {
        return null;
    }

    @AuraEnabled
    public static List<TranscriptEntry> getTranscriptEntries(Id voiceCallId, Integer lastSeenSeq) {
        return new List<TranscriptEntry>();
    }

    @AuraEnabled(cacheable=true)
    public static VoiceCallContext getVoiceCallContext(Id voiceCallId) {
        return null;
    }

    @AuraEnabled
    public static Map<String, String> runAnalysis(
        Id templateId,
        String questionsJson,
        String transcriptText
    ) {
        if (templateId == null) {
            return new Map<String, String>();
        }
        Intake_Template__c tpl = loadTemplate(templateId);
        String persona = tpl != null ? tpl.Persona_Description__c : null;
        return IntakeTranscriptAnalyzer.analyzeTranscript(persona, questionsJson, transcriptText);
    }

    private static Intake_Template__c loadTemplate(Id templateId) {
        List<Intake_Template__c> templates = [
            SELECT Id, Name, Status__c, Target_Object_API_Name__c,
                   Persona_Description__c, Default_Locale__c, Version__c
            FROM Intake_Template__c
            WHERE Id = :templateId
            LIMIT 1
        ];
        return templates.isEmpty() ? null : templates[0];
    }

    private static Map<String, String> getQuestionFieldMap(Id templateId) {
        Map<String, String> fieldByDeveloperName = new Map<String, String>();
        for (Intake_Question__c q : [
            SELECT DeveloperName__c, Target_Field_API_Name__c
            FROM Intake_Question__c
            WHERE Intake_Template__c = :templateId
        ]) {
            if (String.isNotBlank(q.DeveloperName__c) && String.isNotBlank(q.Target_Field_API_Name__c)) {
                fieldByDeveloperName.put(q.DeveloperName__c, q.Target_Field_API_Name__c);
            }
        }
        return fieldByDeveloperName;
    }

    private static void applyAnswersToRecord(
        SObject record,
        String objApi,
        Map<String, Object> answers,
        Map<String, String> fieldByDeveloperName
    ) {
        Schema.DescribeSObjectResult dsr = Schema.getGlobalDescribe().get(objApi).getDescribe();
        Map<String, Schema.SObjectField> fieldMap = dsr.fields.getMap();

        for (String developerName : answers.keySet()) {
            String fieldApi = fieldByDeveloperName.get(developerName);
            if (String.isBlank(fieldApi)) continue;
            Schema.SObjectField sf = fieldMap.get(fieldApi.toLowerCase());
            if (sf == null) continue;

            Object value = answers.get(developerName);
            if (value == null || String.isBlank(String.valueOf(value))) {
                record.put(fieldApi, null);
                continue;
            }

            Schema.DisplayType dt = sf.getDescribe().getType();
            try {
                if (dt == Schema.DisplayType.Boolean) {
                    record.put(fieldApi, Boolean.valueOf(String.valueOf(value)));
                } else if (dt == Schema.DisplayType.Double
                        || dt == Schema.DisplayType.Currency
                        || dt == Schema.DisplayType.Percent) {
                    record.put(fieldApi, Decimal.valueOf(String.valueOf(value)));
                } else if (dt == Schema.DisplayType.Integer) {
                    record.put(fieldApi, Integer.valueOf(String.valueOf(value)));
                } else if (dt == Schema.DisplayType.Date) {
                    record.put(fieldApi, Date.valueOf(String.valueOf(value)));
                } else if (dt == Schema.DisplayType.DateTime) {
                    record.put(fieldApi, Datetime.valueOf(String.valueOf(value)));
                } else {
                    record.put(fieldApi, String.valueOf(value));
                }
            } catch (Exception e) {
                record.put(fieldApi, String.valueOf(value));
            }
        }
    }

    private static Map<String, Set<String>> fieldCache = new Map<String, Set<String>>();
    private static Boolean hasField(String objApi, String fieldApi) {
        if (String.isBlank(objApi) || String.isBlank(fieldApi)) return false;
        if (!fieldCache.containsKey(objApi)) {
            Schema.SObjectType sot = Schema.getGlobalDescribe().get(objApi);
            if (sot == null) {
                fieldCache.put(objApi, new Set<String>());
            } else {
                Set<String> names = new Set<String>();
                for (String f : sot.getDescribe().fields.getMap().keySet()) {
                    names.add(f.toLowerCase());
                }
                fieldCache.put(objApi, names);
            }
        }
        return fieldCache.get(objApi).contains(fieldApi.toLowerCase());
    }

    private static String escapeIdentifier(String raw) {
        return raw.replaceAll('[^A-Za-z0-9_]', '');
    }

    public class TemplateOption {
        @AuraEnabled public Id templateId;
        @AuraEnabled public String name;
        @AuraEnabled public String description;
        @AuraEnabled public String targetObject;
        @AuraEnabled public Decimal version;

        public TemplateOption(Intake_Template__c rec) {
            this.templateId = rec.Id;
            this.name = rec.Name;
            this.description = rec.Description__c;
            this.targetObject = rec.Target_Object_API_Name__c;
            this.version = rec.Version__c;
        }
    }

    public class TemplateBundle {
        @AuraEnabled public Id templateId;
        @AuraEnabled public String name;
        @AuraEnabled public String status;
        @AuraEnabled public String description;
        @AuraEnabled public String targetObject;
        @AuraEnabled public String personaDescription;
        @AuraEnabled public String pdfHeader;
        @AuraEnabled public String pdfFooter;
        @AuraEnabled public String brandColor;
        @AuraEnabled public String brandLogoFileId;
        @AuraEnabled public String brandLogoStaticResource;
        @AuraEnabled public String defaultLocale;
        @AuraEnabled public Decimal version;
        @AuraEnabled public List<QuestionDTO> questions;

        public TemplateBundle(Intake_Template__c rec) {
            this.templateId = rec.Id;
            this.name = rec.Name;
            this.status = rec.Status__c;
            this.description = rec.Description__c;
            this.targetObject = rec.Target_Object_API_Name__c;
            this.personaDescription = rec.Persona_Description__c;
            this.pdfHeader = rec.PDF_Header__c;
            this.pdfFooter = rec.PDF_Footer__c;
            this.brandColor = rec.Brand_Color__c;
            this.brandLogoFileId = rec.Brand_Logo_File_Id__c;
            this.brandLogoStaticResource = rec.Brand_Logo_Static_Resource__c;
            this.defaultLocale = rec.Default_Locale__c;
            this.version = rec.Version__c;
            this.questions = new List<QuestionDTO>();
        }
    }

    public class QuestionDTO {
        @AuraEnabled public Id questionId;
        @AuraEnabled public String developerName;
        @AuraEnabled public String questionText;
        @AuraEnabled public String helpText;
        @AuraEnabled public String category;
        @AuraEnabled public Decimal orderNum;
        @AuraEnabled public Boolean isRequired;
        @AuraEnabled public String answerType;
        @AuraEnabled public String targetField;
        @AuraEnabled public String picklistSource;
        @AuraEnabled public String picklistSourceObject;
        @AuraEnabled public String picklistSourceField;
        @AuraEnabled public String lookupObject;
        @AuraEnabled public String validationRegex;
        @AuraEnabled public String validationErrorMessage;
        @AuraEnabled public String aiExtractionHint;
        @AuraEnabled public List<PicklistOption> picklistOptions;
        @AuraEnabled public List<VisibilityRuleDTO> visibilityRules;
        @AuraEnabled public List<TranslationDTO> translations;

        public QuestionDTO(Intake_Question__c q) {
            this.questionId = q.Id;
            this.developerName = q.DeveloperName__c;
            this.questionText = q.Question_Text__c;
            this.helpText = q.Help_Text__c;
            this.category = q.Category__c;
            this.orderNum = q.Order__c;
            this.isRequired = q.Required__c;
            this.answerType = q.Answer_Type__c;
            this.targetField = q.Target_Field_API_Name__c;
            this.picklistSource = q.Picklist_Source__c;
            this.picklistSourceObject = q.Picklist_Source_Object__c;
            this.picklistSourceField = q.Picklist_Source_Field__c;
            this.lookupObject = q.Lookup_Object__c;
            this.validationRegex = q.Validation_Regex__c;
            this.validationErrorMessage = q.Validation_Error_Message__c;
            this.aiExtractionHint = q.AI_Extraction_Hint__c;
            this.picklistOptions = new List<PicklistOption>();
            this.visibilityRules = new List<VisibilityRuleDTO>();
            this.translations = new List<TranslationDTO>();
        }
    }

    public class PicklistOption {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        public PicklistOption(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }

    public class VisibilityRuleDTO {
        @AuraEnabled public String sourceQuestionDeveloperName;
        @AuraEnabled public String operator;
        @AuraEnabled public String value;
        @AuraEnabled public String logicGroup;
        public VisibilityRuleDTO(Intake_Visibility_Rule__c r) {
            this.sourceQuestionDeveloperName = r.Source_Question_Developer_Name__c;
            this.operator = r.Operator__c;
            this.value = r.Value__c;
            this.logicGroup = String.isBlank(r.Logic_Group__c) ? 'default' : r.Logic_Group__c;
        }
    }

    public class TranslationDTO {
        @AuraEnabled public String locale;
        @AuraEnabled public String questionText;
        @AuraEnabled public String helpText;
        public TranslationDTO(Intake_Translation__c t) {
            this.locale = t.Locale__c;
            this.questionText = t.Question_Text_Translated__c;
            this.helpText = t.Help_Text_Translated__c;
        }
    }

    public class DraftResult {
        @AuraEnabled public Id intakeId;
        @AuraEnabled public String intakeName;
        @AuraEnabled public String answersJson;
        public DraftResult(Id intakeId, String intakeName) {
            this.intakeId = intakeId;
            this.intakeName = intakeName;
        }
        public DraftResult(Id intakeId, String intakeName, String answersJson) {
            this.intakeId = intakeId;
            this.intakeName = intakeName;
            this.answersJson = answersJson;
        }
    }

    public class TranscriptEntry {
        @AuraEnabled public String message;
        @AuraEnabled public String actorType;
        @AuraEnabled public String actorName;
        @AuraEnabled public Datetime entryTime;
        @AuraEnabled public Integer seq;
        @AuraEnabled public Boolean isCustomer;
        public TranscriptEntry(
            String message,
            String actorType,
            String actorName,
            Datetime entryTime,
            Integer seq
        ) {
            this.message = message;
            this.actorType = actorType;
            this.actorName = actorName;
            this.entryTime = entryTime;
            this.seq = seq;
            this.isCustomer = actorType == 'EndUser';
        }
    }

    public class VoiceCallContext {
        @AuraEnabled public Id contactId;
        @AuraEnabled public String contactName;
        @AuraEnabled public String callbackPhone;
        @AuraEnabled public Id conversationId;
        public VoiceCallContext(Id contactId, String contactName, String callbackPhone, Id conversationId) {
            this.contactId = contactId;
            this.contactName = contactName;
            this.callbackPhone = callbackPhone;
            this.conversationId = conversationId;
        }
    }
}
