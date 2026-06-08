public with sharing class IntakeBuilderController {
    private static final String MODEL_NAME = 'sfdc_ai__DefaultGPT4Omni';
    private static final Set<String> SUPPORTED_ANSWER_TYPES = new Set<String>{
        'text', 'textarea', 'number', 'date',
        'email', 'phone', 'picklist', 'multipicklist', 'boolean', 'lookup'
    };

    @TestVisible
    private static String mockQuestionGenerationResponse;

    @AuraEnabled(cacheable=true)
    public static List<TemplateSummary> listTemplates(String statusFilter) {
        String status = String.isBlank(statusFilter) ? null : statusFilter;
        List<Intake_Template__c> records;
        if (status == null) {
            records = [
                SELECT Id, Name, Status__c, Target_Object_API_Name__c, Version__c, LastModifiedDate
                FROM Intake_Template__c
                ORDER BY Name ASC, Version__c DESC
            ];
        } else {
            records = [
                SELECT Id, Name, Status__c, Target_Object_API_Name__c, Version__c, LastModifiedDate
                FROM Intake_Template__c
                WHERE Status__c = :status
                ORDER BY Name ASC, Version__c DESC
            ];
        }
        List<TemplateSummary> results = new List<TemplateSummary>();
        for (Intake_Template__c rec : records) {
            results.add(new TemplateSummary(rec));
        }
        return results;
    }

    @AuraEnabled
    public static IntakeRuntimeController.TemplateBundle getTemplate(Id templateId) {
        return IntakeRuntimeController.getTemplate(templateId);
    }

    @AuraEnabled
    public static Id createTemplate(String name) {
        Intake_Template__c tpl = new Intake_Template__c(
            Name = String.isBlank(name) ? 'New Intake Template' : name,
            Status__c = 'Draft',
            Version__c = 1,
            Default_Locale__c = 'en_US'
        );
        insert tpl;
        return tpl.Id;
    }

    @AuraEnabled
    public static Id cloneTemplate(Id sourceId) {
        if (sourceId == null) {
            throw new AuraHandledException('Source template Id is required.');
        }

        Intake_Template__c source = [
            SELECT Id, Name, Status__c, Description__c, Target_Object_API_Name__c,
                   Persona_Description__c, PDF_Header__c, PDF_Footer__c,
                   Brand_Color__c, Brand_Logo_File_Id__c, Brand_Logo_Static_Resource__c,
                   Default_Locale__c, Version__c, Parent_Template__c
            FROM Intake_Template__c
            WHERE Id = :sourceId
            LIMIT 1
        ];

        Intake_Template__c clone = source.clone(false, true, false, false);
        clone.Name = source.Name + ' (Copy)';
        clone.Status__c = 'Draft';
        clone.Version__c = 1;
        clone.Parent_Template__c = null;
        insert clone;

        copyChildren(source.Id, clone.Id);
        return clone.Id;
    }

    @AuraEnabled
    public static Id newVersion(Id sourceId) {
        if (sourceId == null) {
            throw new AuraHandledException('Source template Id is required.');
        }

        Intake_Template__c source = [
            SELECT Id, Name, Status__c, Description__c, Target_Object_API_Name__c,
                   Persona_Description__c, PDF_Header__c, PDF_Footer__c,
                   Brand_Color__c, Brand_Logo_File_Id__c, Brand_Logo_Static_Resource__c,
                   Default_Locale__c, Version__c
            FROM Intake_Template__c
            WHERE Id = :sourceId
            LIMIT 1
        ];

        Intake_Template__c clone = source.clone(false, true, false, false);
        clone.Status__c = 'Draft';
        clone.Version__c = (source.Version__c != null ? source.Version__c : 1) + 1;
        clone.Parent_Template__c = source.Id;
        insert clone;

        copyChildren(source.Id, clone.Id);
        return clone.Id;
    }

    private static void copyChildren(Id sourceId, Id cloneId) {
        Map<Id, Id> oldQuestionToNew = new Map<Id, Id>();

        List<Intake_Question__c> sourceQuestions = [
            SELECT Id, DeveloperName__c, Question_Text__c, Help_Text__c, Category__c,
                   Order__c, Required__c, Answer_Type__c, Target_Field_API_Name__c,
                   Picklist_Source__c, Picklist_Source_Object__c, Picklist_Source_Field__c,
                   Lookup_Object__c, Validation_Regex__c, Validation_Error_Message__c,
                   AI_Extraction_Hint__c
            FROM Intake_Question__c
            WHERE Intake_Template__c = :sourceId
        ];

        List<Intake_Question__c> newQuestions = new List<Intake_Question__c>();
        for (Intake_Question__c q : sourceQuestions) {
            Intake_Question__c qClone = q.clone(false, true, false, false);
            qClone.Intake_Template__c = cloneId;
            newQuestions.add(qClone);
        }
        insert newQuestions;

        for (Integer i = 0; i < sourceQuestions.size(); i++) {
            oldQuestionToNew.put(sourceQuestions[i].Id, newQuestions[i].Id);
        }

        Set<Id> oldQuestionIds = oldQuestionToNew.keySet();

        List<Intake_Picklist_Value__c> newPicklist = new List<Intake_Picklist_Value__c>();
        for (Intake_Picklist_Value__c pv : [
            SELECT Id, Intake_Question__c, Label__c, Value__c, Order__c
            FROM Intake_Picklist_Value__c
            WHERE Intake_Question__c IN :oldQuestionIds
        ]) {
            Intake_Picklist_Value__c c = pv.clone(false, true, false, false);
            c.Intake_Question__c = oldQuestionToNew.get(pv.Intake_Question__c);
            newPicklist.add(c);
        }
        if (!newPicklist.isEmpty()) insert newPicklist;

        List<Intake_Visibility_Rule__c> newRules = new List<Intake_Visibility_Rule__c>();
        for (Intake_Visibility_Rule__c r : [
            SELECT Id, Intake_Question__c, Source_Question_Developer_Name__c,
                   Operator__c, Value__c, Logic_Group__c
            FROM Intake_Visibility_Rule__c
            WHERE Intake_Question__c IN :oldQuestionIds
        ]) {
            Intake_Visibility_Rule__c c = r.clone(false, true, false, false);
            c.Intake_Question__c = oldQuestionToNew.get(r.Intake_Question__c);
            newRules.add(c);
        }
        if (!newRules.isEmpty()) insert newRules;

        List<Intake_Translation__c> newTranslations = new List<Intake_Translation__c>();
        for (Intake_Translation__c t : [
            SELECT Id, Intake_Question__c, Locale__c,
                   Question_Text_Translated__c, Help_Text_Translated__c
            FROM Intake_Translation__c
            WHERE Intake_Question__c IN :oldQuestionIds
        ]) {
            Intake_Translation__c c = t.clone(false, true, false, false);
            c.Intake_Question__c = oldQuestionToNew.get(t.Intake_Question__c);
            newTranslations.add(c);
        }
        if (!newTranslations.isEmpty()) insert newTranslations;
    }

    @AuraEnabled
    public static void archiveTemplate(Id templateId) {
        if (templateId == null) return;
        Intake_Template__c tpl = new Intake_Template__c(Id = templateId, Status__c = 'Archived');
        update tpl;
    }

    @AuraEnabled
    public static void deleteTemplate(Id templateId) {
        if (templateId == null) return;

        List<Intake_Question__c> questions = [
            SELECT Id
            FROM Intake_Question__c
            WHERE Intake_Template__c = :templateId
        ];
        Set<Id> questionIds = new Set<Id>();
        for (Intake_Question__c q : questions) {
            questionIds.add(q.Id);
        }

        if (!questionIds.isEmpty()) {
            delete [
                SELECT Id
                FROM Intake_Picklist_Value__c
                WHERE Intake_Question__c IN :questionIds
            ];
            delete [
                SELECT Id
                FROM Intake_Visibility_Rule__c
                WHERE Intake_Question__c IN :questionIds
            ];
            delete [
                SELECT Id
                FROM Intake_Translation__c
                WHERE Intake_Question__c IN :questionIds
            ];
            delete questions;
        }

        delete new Intake_Template__c(Id = templateId);
    }

    @AuraEnabled
    public static void activateTemplate(Id templateId) {
        if (templateId == null) return;
        ValidationResult vr = validateTemplate(templateId);
        if (!vr.isValid) {
            throw new AuraHandledException('Template has errors: ' + String.join(vr.errors, '; '));
        }
        Intake_Template__c tpl = new Intake_Template__c(Id = templateId, Status__c = 'Active');
        update tpl;
    }

    @AuraEnabled
    public static SaveResult saveTemplate(String payloadJson) {
        if (String.isBlank(payloadJson)) {
            throw new AuraHandledException('Payload is required.');
        }
        SavePayload payload = (SavePayload) JSON.deserialize(payloadJson, SavePayload.class);
        if (payload == null || payload.template == null) {
            throw new AuraHandledException('Template is required in payload.');
        }

        Savepoint sp = Database.setSavepoint();
        try {
            Intake_Template__c tpl;
            if (payload.template.id != null) {
                tpl = new Intake_Template__c(Id = payload.template.id);
            } else {
                tpl = new Intake_Template__c();
            }
            tpl.Name = payload.template.name;
            tpl.Status__c = payload.template.status;
            tpl.Description__c = payload.template.description;
            tpl.Target_Object_API_Name__c = payload.template.targetObject;
            tpl.Persona_Description__c = payload.template.personaDescription;
            tpl.PDF_Header__c = payload.template.pdfHeader;
            tpl.PDF_Footer__c = payload.template.pdfFooter;
            tpl.Brand_Color__c = normalizeBrandColor(payload.template.brandColor);
            tpl.Brand_Logo_File_Id__c = payload.template.brandLogoFileId;
            tpl.Brand_Logo_Static_Resource__c = payload.template.brandLogoStaticResource;
            tpl.Default_Locale__c = String.isBlank(payload.template.defaultLocale)
                ? 'en_US'
                : payload.template.defaultLocale;
            if (payload.template.version != null) {
                tpl.Version__c = payload.template.version;
            }
            upsert tpl;

            Map<String, Id> devNameToQuestionId = new Map<String, Id>();
            List<Intake_Question__c> existingQuestions = [
                SELECT Id, DeveloperName__c FROM Intake_Question__c
                WHERE Intake_Template__c = :tpl.Id
            ];
            for (Intake_Question__c q : existingQuestions) {
                devNameToQuestionId.put(q.DeveloperName__c, q.Id);
            }

            Set<Id> retainedQuestionIds = new Set<Id>();
            List<Intake_Question__c> upsertQs = new List<Intake_Question__c>();

            if (payload.questions != null) {
                for (QuestionPayload qp : payload.questions) {
                    Intake_Question__c q = new Intake_Question__c();
                    if (String.isNotBlank(qp.id)) {
                        q.Id = qp.id;
                        retainedQuestionIds.add(qp.id);
                    } else if (devNameToQuestionId.containsKey(qp.developerName)) {
                        q.Id = devNameToQuestionId.get(qp.developerName);
                        retainedQuestionIds.add(q.Id);
                    }
                    // Parent relationship can be non-reparentable in some orgs.
                    // Only set it for inserts; for updates, keep existing parent.
                    if (q.Id == null) {
                        q.Intake_Template__c = tpl.Id;
                    }
                    q.DeveloperName__c = qp.developerName;
                    q.Question_Text__c = qp.questionText;
                    q.Help_Text__c = qp.helpText;
                    q.Category__c = qp.category;
                    q.Order__c = qp.orderNum;
                    q.Required__c = qp.isRequired == true;
                    q.Answer_Type__c = normalizeAnswerType(qp.answerType);
                    q.Target_Field_API_Name__c = qp.targetField;
                    q.Picklist_Source__c = qp.picklistSource;
                    q.Picklist_Source_Object__c = qp.picklistSourceObject;
                    q.Picklist_Source_Field__c = qp.picklistSourceField;
                    q.Lookup_Object__c = qp.lookupObject;
                    q.Validation_Regex__c = qp.validationRegex;
                    q.Validation_Error_Message__c = qp.validationErrorMessage;
                    q.AI_Extraction_Hint__c = qp.aiExtractionHint;
                    upsertQs.add(q);
                }
            }
            upsert upsertQs;

            // Track question Ids by developerName for child reattachment
            Map<String, Id> qIdByDevName = new Map<String, Id>();
            for (Intake_Question__c q : upsertQs) {
                if (String.isNotBlank(q.DeveloperName__c)) {
                    qIdByDevName.put(q.DeveloperName__c, q.Id);
                    retainedQuestionIds.add(q.Id);
                }
            }

            // Delete questions that were removed from the payload
            List<Intake_Question__c> toDelete = new List<Intake_Question__c>();
            for (Intake_Question__c q : existingQuestions) {
                if (!retainedQuestionIds.contains(q.Id)) {
                    toDelete.add(new Intake_Question__c(Id = q.Id));
                }
            }
            if (!toDelete.isEmpty()) delete toDelete;

            // Wipe and reinsert children for retained questions
            if (!retainedQuestionIds.isEmpty()) {
                delete [
                    SELECT Id FROM Intake_Picklist_Value__c
                    WHERE Intake_Question__c IN :retainedQuestionIds
                ];
                delete [
                    SELECT Id FROM Intake_Visibility_Rule__c
                    WHERE Intake_Question__c IN :retainedQuestionIds
                ];
                delete [
                    SELECT Id FROM Intake_Translation__c
                    WHERE Intake_Question__c IN :retainedQuestionIds
                ];
            }

            List<Intake_Picklist_Value__c> insertPv = new List<Intake_Picklist_Value__c>();
            if (payload.picklistValues != null) {
                for (PicklistValuePayload pv : payload.picklistValues) {
                    Id qId = qIdByDevName.get(pv.questionDeveloperName);
                    if (qId == null) continue;
                    insertPv.add(new Intake_Picklist_Value__c(
                        Intake_Question__c = qId,
                        Label__c = pv.label,
                        Value__c = pv.value,
                        Order__c = pv.orderNum
                    ));
                }
            }
            if (!insertPv.isEmpty()) insert insertPv;

            List<Intake_Visibility_Rule__c> insertRules = new List<Intake_Visibility_Rule__c>();
            if (payload.visibilityRules != null) {
                for (VisibilityRulePayload r : payload.visibilityRules) {
                    Id qId = qIdByDevName.get(r.questionDeveloperName);
                    if (qId == null) continue;
                    insertRules.add(new Intake_Visibility_Rule__c(
                        Intake_Question__c = qId,
                        Source_Question_Developer_Name__c = r.sourceQuestionDeveloperName,
                        Operator__c = r.operator,
                        Value__c = r.value,
                        Logic_Group__c = String.isBlank(r.logicGroup) ? 'default' : r.logicGroup
                    ));
                }
            }
            if (!insertRules.isEmpty()) insert insertRules;

            List<Intake_Translation__c> insertTrans = new List<Intake_Translation__c>();
            if (payload.translations != null) {
                for (TranslationPayload t : payload.translations) {
                    Id qId = qIdByDevName.get(t.questionDeveloperName);
                    if (qId == null) continue;
                    insertTrans.add(new Intake_Translation__c(
                        Intake_Question__c = qId,
                        Locale__c = t.locale,
                        Question_Text_Translated__c = t.questionText,
                        Help_Text_Translated__c = t.helpText
                    ));
                }
            }
            if (!insertTrans.isEmpty()) insert insertTrans;

            return new SaveResult(tpl.Id, true, null);
        } catch (Exception e) {
            Database.rollback(sp);
            throw new AuraHandledException('Save failed: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static ValidationResult validateTemplate(Id templateId) {
        ValidationResult vr = new ValidationResult();
        vr.errors = new List<String>();
        vr.warnings = new List<String>();
        vr.isValid = true;

        if (templateId == null) {
            vr.errors.add('Template Id is required.');
            vr.isValid = false;
            return vr;
        }

        List<Intake_Template__c> tpls = [
            SELECT Id, Name, Target_Object_API_Name__c
            FROM Intake_Template__c
            WHERE Id = :templateId LIMIT 1
        ];
        if (tpls.isEmpty()) {
            vr.errors.add('Template not found.');
            vr.isValid = false;
            return vr;
        }
        Intake_Template__c tpl = tpls[0];

        Set<String> validFields = null;
        if (String.isNotBlank(tpl.Target_Object_API_Name__c)) {
            Schema.SObjectType sot = Schema.getGlobalDescribe().get(tpl.Target_Object_API_Name__c);
            if (sot == null) {
                vr.errors.add('Target Object "' + tpl.Target_Object_API_Name__c + '" does not exist.');
                vr.isValid = false;
            } else {
                validFields = new Set<String>();
                for (String f : sot.getDescribe().fields.getMap().keySet()) {
                    validFields.add(f.toLowerCase());
                }
            }
        }

        Set<String> seenDevNames = new Set<String>();
        for (Intake_Question__c q : [
            SELECT Id, DeveloperName__c, Question_Text__c, Answer_Type__c,
                   Target_Field_API_Name__c, Required__c
            FROM Intake_Question__c
            WHERE Intake_Template__c = :templateId
        ]) {
            if (String.isBlank(q.DeveloperName__c)) {
                vr.errors.add('Question "' + q.Question_Text__c + '" is missing a developer name.');
                vr.isValid = false;
            } else if (seenDevNames.contains(q.DeveloperName__c)) {
                vr.errors.add('Duplicate developer name: ' + q.DeveloperName__c);
                vr.isValid = false;
            } else {
                seenDevNames.add(q.DeveloperName__c);
            }
            if (validFields != null
                    && String.isNotBlank(q.Target_Field_API_Name__c)
                    && !validFields.contains(q.Target_Field_API_Name__c.toLowerCase())) {
                vr.warnings.add('Question "' + q.DeveloperName__c
                    + '": target field "' + q.Target_Field_API_Name__c
                    + '" not found on ' + tpl.Target_Object_API_Name__c);
            }
        }

        return vr;
    }

    @AuraEnabled
    public static Map<String, String> testAnalyze(
        String personaDescription,
        String questionsJson,
        String transcriptText
    ) {
        return IntakeTranscriptAnalyzer.analyzeTranscript(
            personaDescription, questionsJson, transcriptText
        );
    }

    @AuraEnabled
    public static TestPdfResult createTestRecordAndPdf(Id templateId) {
        if (templateId == null) {
            throw new AuraHandledException('Template Id is required.');
        }

        List<Intake_Question__c> questions = [
            SELECT Id, DeveloperName__c, Question_Text__c, Answer_Type__c
            FROM Intake_Question__c
            WHERE Intake_Template__c = :templateId
            ORDER BY Order__c ASC NULLS LAST, CreatedDate ASC
        ];
        if (questions.isEmpty()) {
            throw new AuraHandledException('Add at least one question before running a test.');
        }

        Set<Id> questionIds = new Set<Id>();
        for (Intake_Question__c q : questions) {
            questionIds.add(q.Id);
        }

        Map<Id, List<Intake_Picklist_Value__c>> staticPicklistByQuestion = new Map<Id, List<Intake_Picklist_Value__c>>();
        for (Intake_Picklist_Value__c pv : [
            SELECT Intake_Question__c, Label__c, Value__c
            FROM Intake_Picklist_Value__c
            WHERE Intake_Question__c IN :questionIds
            ORDER BY Order__c ASC NULLS LAST, CreatedDate ASC
        ]) {
            if (!staticPicklistByQuestion.containsKey(pv.Intake_Question__c)) {
                staticPicklistByQuestion.put(pv.Intake_Question__c, new List<Intake_Picklist_Value__c>());
            }
            staticPicklistByQuestion.get(pv.Intake_Question__c).add(pv);
        }

        Map<String, Object> answers = new Map<String, Object>();
        Integer numberSeed = 1;
        for (Intake_Question__c q : questions) {
            if (String.isBlank(q.DeveloperName__c)) {
                continue;
            }
            answers.put(
                q.DeveloperName__c,
                buildSampleAnswer(q, staticPicklistByQuestion.get(q.Id), numberSeed)
            );
            numberSeed++;
        }

        Id intakeId = IntakeRuntimeController.submitIntake(
            templateId,
            null,
            JSON.serialize(answers)
        );
        IntakeRuntimeController.attachIntakePDF(intakeId);
        return new TestPdfResult(
            intakeId,
            '/apex/IntakePDF?id=' + EncodingUtil.urlEncode(String.valueOf(intakeId), 'UTF-8')
        );
    }

    @AuraEnabled
    public static String generateTestCallScript(Id templateId, String scenarioHint) {
        if (templateId == null) {
            throw new AuraHandledException('Template Id is required.');
        }
        Intake_Template__c tpl = loadTemplateForTesting(templateId);
        if (tpl == null) {
            throw new AuraHandledException('Template not found.');
        }
        List<IntakeTranscriptAnalyzer.QuestionInput> qInputs = buildQuestionInputsFromTemplate(templateId);
        if (qInputs.isEmpty()) {
            throw new AuraHandledException('Add at least one question before generating a test script.');
        }

        String questionsBulleted = '';
        for (IntakeTranscriptAnalyzer.QuestionInput q : qInputs) {
            questionsBulleted += '- ' + q.developerName + ': ' + q.questionText;
            if (String.isNotBlank(q.picklistValuesStr)) {
                questionsBulleted += ' [options: ' + q.picklistValuesStr.replace(';', ', ') + ']';
            }
            questionsBulleted += '\n';
        }

        String prompt =
            'Create a realistic customer service call transcript for testing AI extraction.\n'
            + 'Use a natural conversation with alternating lines that start with "Agent:" and "Customer:".\n'
            + 'Keep it to 12-20 lines and include enough information to answer most of these intake questions:\n'
            + questionsBulleted + '\n'
            + (String.isNotBlank(scenarioHint)
                ? ('Scenario hint from admin: ' + scenarioHint + '\n')
                : '')
            + (String.isNotBlank(tpl.Persona_Description__c)
                ? ('Persona context: ' + tpl.Persona_Description__c + '\n')
                : '')
            + 'Output only plain transcript text. No JSON, no markdown, no code fences.';

        String generated = callQuestionGenerationModel(prompt);
        if (String.isBlank(generated)) {
            return buildFallbackTestCallScript(qInputs, scenarioHint);
        }
        return cleanupModelText(generated);
    }

    @AuraEnabled
    public static ExtractionPdfResult runTestExtractionAndCreatePdf(Id templateId, String transcriptText) {
        if (templateId == null) {
            throw new AuraHandledException('Template Id is required.');
        }
        if (String.isBlank(transcriptText)) {
            throw new AuraHandledException('Transcript text is required.');
        }
        Intake_Template__c tpl = loadTemplateForTesting(templateId);
        if (tpl == null) {
            throw new AuraHandledException('Template not found.');
        }

        List<IntakeTranscriptAnalyzer.QuestionInput> qInputs = buildQuestionInputsFromTemplate(templateId);
        if (qInputs.isEmpty()) {
            throw new AuraHandledException('Add at least one question before running extraction.');
        }

        Map<String, String> extracted = IntakeTranscriptAnalyzer.analyzeTranscript(
            tpl.Persona_Description__c,
            JSON.serialize(qInputs),
            transcriptText
        );
        if (extracted == null || extracted.isEmpty()) {
            throw new AuraHandledException('AI extraction returned no answers. Try a richer transcript.');
        }

        Id intakeId = IntakeRuntimeController.submitIntake(templateId, null, JSON.serialize(extracted));
        IntakeRuntimeController.attachIntakePDF(intakeId);
        return new ExtractionPdfResult(
            intakeId,
            '/apex/IntakePDF?id=' + EncodingUtil.urlEncode(String.valueOf(intakeId), 'UTF-8'),
            JSON.serialize(extracted)
        );
    }

    private static Intake_Template__c loadTemplateForTesting(Id templateId) {
        List<Intake_Template__c> rows = [
            SELECT Id, Persona_Description__c
            FROM Intake_Template__c
            WHERE Id = :templateId
            LIMIT 1
        ];
        return rows.isEmpty() ? null : rows[0];
    }

    private static List<IntakeTranscriptAnalyzer.QuestionInput> buildQuestionInputsFromTemplate(Id templateId) {
        List<Intake_Question__c> questions = [
            SELECT Id, DeveloperName__c, Question_Text__c, Answer_Type__c, AI_Extraction_Hint__c
            FROM Intake_Question__c
            WHERE Intake_Template__c = :templateId
            ORDER BY Order__c ASC NULLS LAST, CreatedDate ASC
        ];
        if (questions.isEmpty()) return new List<IntakeTranscriptAnalyzer.QuestionInput>();

        Set<Id> qIds = new Set<Id>();
        for (Intake_Question__c q : questions) qIds.add(q.Id);
        Map<Id, List<String>> pickValsByQ = new Map<Id, List<String>>();
        for (Intake_Picklist_Value__c pv : [
            SELECT Intake_Question__c, Value__c
            FROM Intake_Picklist_Value__c
            WHERE Intake_Question__c IN :qIds
            ORDER BY Order__c ASC NULLS LAST, CreatedDate ASC
        ]) {
            if (!pickValsByQ.containsKey(pv.Intake_Question__c)) {
                pickValsByQ.put(pv.Intake_Question__c, new List<String>());
            }
            pickValsByQ.get(pv.Intake_Question__c).add(pv.Value__c);
        }

        List<IntakeTranscriptAnalyzer.QuestionInput> result = new List<IntakeTranscriptAnalyzer.QuestionInput>();
        for (Intake_Question__c q : questions) {
            IntakeTranscriptAnalyzer.QuestionInput qi = new IntakeTranscriptAnalyzer.QuestionInput();
            qi.developerName = q.DeveloperName__c;
            qi.questionText = q.Question_Text__c;
            qi.answerType = q.Answer_Type__c;
            qi.aiHint = q.AI_Extraction_Hint__c;
            List<String> values = pickValsByQ.get(q.Id);
            qi.picklistValuesStr = (values == null || values.isEmpty()) ? '' : String.join(values, ';');
            result.add(qi);
        }
        return result;
    }

    private static String cleanupModelText(String raw) {
        if (String.isBlank(raw)) return raw;
        String cleaned = raw.trim();
        if (cleaned.startsWith('```')) {
            cleaned = cleaned.replaceAll('```[a-zA-Z]*\\n?', '').replaceAll('```', '').trim();
        }
        return cleaned;
    }

    private static String buildFallbackTestCallScript(
        List<IntakeTranscriptAnalyzer.QuestionInput> qInputs,
        String scenarioHint
    ) {
        String scenario = String.isNotBlank(scenarioHint)
            ? scenarioHint.trim()
            : 'general service request';
        List<String> lines = new List<String>{
            'Agent: Thanks for calling support. How can I help you today?',
            'Customer: Hi, I am calling about ' + scenario + '.'
        };
        Integer maxQuestions = Math.min(qInputs.size(), 6);
        for (Integer i = 0; i < maxQuestions; i++) {
            IntakeTranscriptAnalyzer.QuestionInput q = qInputs[i];
            String questionText = String.isBlank(q.questionText)
                ? 'Can you share more details?'
                : q.questionText.trim();
            String answerType = String.isBlank(q.answerType) ? 'text' : q.answerType.toLowerCase();
            lines.add('Agent: ' + questionText);
            lines.add('Customer: ' + buildFallbackCustomerAnswer(answerType, q.picklistValuesStr));
        }
        lines.add('Agent: Thank you. I have what I need to continue.');
        return String.join(lines, '\n');
    }

    private static String buildFallbackCustomerAnswer(String answerType, String picklistValuesStr) {
        if (answerType == 'boolean') return 'Yes, that is correct.';
        if (answerType == 'number') return 'The amount is 1200.';
        if (answerType == 'date') return Date.today().addDays(2).format();
        if (answerType == 'email') return 'customer@example.com';
        if (answerType == 'phone') return '555-867-5309';
        if (answerType == 'picklist' || answerType == 'multipicklist') {
            if (String.isNotBlank(picklistValuesStr)) {
                List<String> options = picklistValuesStr.split(';');
                if (!options.isEmpty()) {
                    return options[0];
                }
            }
            return 'Sample Option';
        }
        if (answerType == 'textarea') return 'Here are the details and context you requested.';
        return 'Sample response.';
    }

    private static Object buildSampleAnswer(
        Intake_Question__c question,
        List<Intake_Picklist_Value__c> staticPicklistValues,
        Integer seed
    ) {
        String answerType = String.isBlank(question.Answer_Type__c)
            ? 'text'
            : question.Answer_Type__c.toLowerCase();
        if (answerType == 'boolean') return true;
        if (answerType == 'date') return Date.today().format();
        if (answerType == 'email') return 'test' + seed + '@example.com';
        if (answerType == 'phone') return '555-010' + String.valueOf(Math.mod(seed, 10));
        if (answerType == 'number') return String.valueOf(1000 + seed);
        if (answerType == 'picklist' || answerType == 'multipicklist') {
            if (staticPicklistValues != null && !staticPicklistValues.isEmpty()) {
                String firstValue = String.isNotBlank(staticPicklistValues[0].Value__c)
                    ? staticPicklistValues[0].Value__c
                    : staticPicklistValues[0].Label__c;
                if (answerType == 'multipicklist') {
                    return firstValue;
                }
                return firstValue;
            }
            return 'Sample Option';
        }
        if (answerType == 'textarea') {
            return 'Sample response for: ' + (String.isBlank(question.Question_Text__c)
                ? question.DeveloperName__c
                : question.Question_Text__c);
        }
        return 'Sample ' + seed;
    }

    @AuraEnabled
    public static List<QuestionPayload> generateQuestionsFromDescription(
        String formDescription,
        String targetObjectApiName
    ) {
        if (String.isBlank(formDescription)) {
            throw new AuraHandledException('Please describe the intake form first.');
        }

        String prompt = buildQuestionGenerationPrompt(formDescription, targetObjectApiName);
        String aiResponse = callQuestionGenerationModel(prompt);
        List<QuestionPayload> generated = parseGeneratedQuestions(aiResponse);
        if (!generated.isEmpty() && isTooGeneric(generated)) {
            String retryPrompt = buildQuestionGenerationRetryPrompt(formDescription, targetObjectApiName);
            String retryResponse = callQuestionGenerationModel(retryPrompt);
            generated = parseGeneratedQuestions(retryResponse);
        }
        if (generated.isEmpty() || isTooGeneric(generated)) {
            generated = buildFallbackQuestions(formDescription);
        }

        if (generated.isEmpty()) {
            throw new AuraHandledException('AI could not generate questions from that description. Try adding more detail.');
        }
        return generated;
    }

    private static String buildQuestionGenerationPrompt(String formDescription, String targetObjectApiName) {
        String targetObjectLine = String.isNotBlank(targetObjectApiName)
            ? 'Target object API name: ' + targetObjectApiName + '.\n'
            : '';

        return 'You are helping an admin design a Salesforce intake form.\n'
            + targetObjectLine
            + 'Form description:\n' + formDescription + '\n\n'
            + 'Generate 6-10 practical intake questions.\n'
            + 'Return ONLY valid JSON in this exact shape:\n'
            + '{"questions":[{"developerName":"Customer_Name","questionText":"What is the customer name?","helpText":"",'
            + '"answerType":"text","isRequired":true,"targetField":"Customer_Name__c","aiExtractionHint":"Use legal full name.","category":"Customer"}]}\n'
            + 'Rules:\n'
            + '- questionText is required and user-friendly.\n'
            + '- Every question must be specific to the described business process/domain.\n'
            + '- Do not output placeholders like "New Question", "Question 1", or generic boilerplate.\n'
            + '- If the description is vague, infer a likely domain and still produce useful starter intake questions.\n'
            + '- developerName must be API-safe (letters, numbers, underscore).\n'
            + '- answerType must be one of: text, textarea, number, date, email, phone, picklist, multipicklist, boolean, lookup.\n'
            + '- Keep targetField blank if uncertain.\n'
            + '- Respond with JSON only. No markdown, no explanation.';
    }

    private static String buildQuestionGenerationRetryPrompt(String formDescription, String targetObjectApiName) {
        String targetObjectLine = String.isNotBlank(targetObjectApiName)
            ? 'Target object API name: ' + targetObjectApiName + '.\n'
            : '';
        return 'Your prior output was too generic.\n'
            + 'Return only domain-specific intake questions for this exact scenario.\n'
            + targetObjectLine
            + 'Scenario description:\n' + formDescription + '\n\n'
            + 'Return ONLY valid JSON with this shape:'
            + '{"questions":[{"developerName":"Example_Name","questionText":"Specific question here","helpText":"","answerType":"text","isRequired":true,"targetField":"","aiExtractionHint":"","category":"General"}]}'
            + '\nHard constraints:\n'
            + '- Never use "New Question", "Question 1", or similar placeholders.\n'
            + '- Each question must reference concrete details implied by the scenario.\n'
            + '- If details are sparse, provide strong starter questions commonly used for this type of intake.\n'
            + '- JSON only. No prose.';
    }

    private static String callQuestionGenerationModel(String prompt) {
        if (Test.isRunningTest() && mockQuestionGenerationResponse != null) {
            return mockQuestionGenerationResponse;
        }
        return null;
    }

    private static List<QuestionPayload> parseGeneratedQuestions(String rawResponse) {
        if (String.isBlank(rawResponse)) {
            return new List<QuestionPayload>();
        }

        String cleaned = rawResponse.trim();
        if (cleaned.startsWith('```')) {
            cleaned = cleaned.replaceAll('```[a-zA-Z]*\\n?', '').replaceAll('```', '').trim();
        }

        List<QuestionPayload> results = new List<QuestionPayload>();
        Set<String> usedDevNames = new Set<String>();
        try {
            Object untyped = JSON.deserializeUntyped(cleaned);
            List<Object> questions;
            if (untyped instanceof Map<String, Object>) {
                Map<String, Object> parsed = (Map<String, Object>) untyped;
                questions = (List<Object>) parsed.get('questions');
                if (questions == null && parsed.containsKey('items')) {
                    questions = (List<Object>) parsed.get('items');
                }
            } else if (untyped instanceof List<Object>) {
                questions = (List<Object>) untyped;
            }
            if (questions == null) {
                return results;
            }
            Integer orderCounter = 1;
            for (Object qObj : questions) {
                Map<String, Object> qMap = (Map<String, Object>) qObj;
                String questionText = extractQuestionText(qMap);
                if (String.isBlank(questionText)) {
                    continue;
                }

                QuestionPayload q = new QuestionPayload();
                q.questionText = questionText.trim();
                q.helpText = valueAsString(qMap.get('helpText'));
                q.category = valueAsString(qMap.get('category'));
                q.answerType = normalizeAnswerType(valueAsString(qMap.get('answerType')));
                q.targetField = valueAsString(qMap.get('targetField'));
                q.aiExtractionHint = valueAsString(qMap.get('aiExtractionHint'));
                q.isRequired = valueAsBoolean(qMap.get('isRequired'));
                q.orderNum = orderCounter++;
                q.picklistSource = 'Static';
                q.developerName = ensureUniqueDeveloperName(
                    valueAsString(qMap.get('developerName')),
                    q.questionText,
                    usedDevNames
                );
                results.add(q);
            }
        } catch (Exception ex) {
            throw new AuraHandledException('Could not parse AI output. Please try again.');
        }
        return results;
    }

    private static List<QuestionPayload> buildFallbackQuestions(String formDescription) {
        String d = String.isBlank(formDescription) ? '' : formDescription.toLowerCase();
        List<QuestionPayload> fallback = new List<QuestionPayload>();

        if (d.contains('mortgage') || d.contains('home loan') || d.contains('loan application')) {
            fallback.add(buildFallbackQuestion('Applicant_Full_Name', 'What is the applicant\'s full legal name?', 'text', true, 'Applicant'));
            fallback.add(buildFallbackQuestion('Applicant_Email', 'What is the applicant\'s email address?', 'email', true, 'Applicant'));
            fallback.add(buildFallbackQuestion('Employment_Status', 'What is the applicant\'s current employment status?', 'picklist', true, 'Financial'));
            fallback.add(buildFallbackQuestion('Annual_Income', 'What is the applicant\'s annual gross income?', 'currency', true, 'Financial'));
            fallback.add(buildFallbackQuestion('Requested_Loan_Amount', 'What loan amount is being requested?', 'currency', true, 'Loan'));
            fallback.add(buildFallbackQuestion('Property_Address', 'What is the property address?', 'textarea', true, 'Property'));
            fallback.add(buildFallbackQuestion('Down_Payment_Source', 'What is the source of the down payment?', 'picklist', false, 'Financial'));
            fallback.add(buildFallbackQuestion('Co_Borrower_Name', 'Is there a co-borrower? If yes, provide full legal name.', 'text', false, 'Applicant'));
            return fallback;
        }

        fallback.add(buildFallbackQuestion('Requester_Full_Name', 'What is the requester\'s full name?', 'text', true, 'General'));
        fallback.add(buildFallbackQuestion('Requester_Contact', 'What is the best contact phone number or email?', 'text', true, 'General'));
        fallback.add(buildFallbackQuestion('Request_Summary', 'Briefly describe the request or issue.', 'textarea', true, 'General'));
        fallback.add(buildFallbackQuestion('Request_Category', 'What category best describes this request?', 'picklist', true, 'General'));
        fallback.add(buildFallbackQuestion('Needed_By_Date', 'When is this needed by?', 'date', false, 'General'));
        fallback.add(buildFallbackQuestion('Priority', 'What is the priority level?', 'picklist', false, 'General'));
        return fallback;
    }

    private static QuestionPayload buildFallbackQuestion(
        String developerName,
        String questionText,
        String answerType,
        Boolean isRequired,
        String category
    ) {
        QuestionPayload q = new QuestionPayload();
        q.developerName = developerName;
        q.questionText = questionText;
        q.answerType = normalizeAnswerType(answerType);
        q.isRequired = isRequired;
        q.category = category;
        q.orderNum = 0;
        q.picklistSource = 'Static';
        q.helpText = '';
        q.targetField = '';
        q.aiExtractionHint = '';
        return q;
    }

    private static String extractQuestionText(Map<String, Object> qMap) {
        List<String> keys = new List<String>{ 'questionText', 'question', 'prompt', 'label', 'text' };
        for (String key : keys) {
            String value = valueAsString(qMap.get(key));
            if (String.isNotBlank(value)) {
                return value;
            }
        }
        return null;
    }

    private static Boolean isTooGeneric(List<QuestionPayload> questions) {
        if (questions == null || questions.isEmpty()) return false;
        Integer genericCount = 0;
        for (QuestionPayload q : questions) {
            String text = String.isBlank(q.questionText) ? '' : q.questionText.trim().toLowerCase();
            if (text == ''
                || text == 'new question'
                || text.startsWith('question ')
                || text.startsWith('sample question')
                || text.contains('placeholder')) {
                genericCount++;
            }
        }
        return genericCount == questions.size();
    }

    private static String valueAsString(Object value) {
        return value == null ? null : String.valueOf(value).trim();
    }

    private static Boolean valueAsBoolean(Object value) {
        if (value == null) return false;
        String normalized = String.valueOf(value).trim().toLowerCase();
        return normalized == 'true' || normalized == '1' || normalized == 'yes';
    }

    private static String normalizeAnswerType(String answerType) {
        String normalized = String.isBlank(answerType) ? 'text' : answerType.trim().toLowerCase();
        if (normalized == 'currency') {
            normalized = 'number';
        } else if (normalized == 'datetime') {
            normalized = 'date';
        }
        return SUPPORTED_ANSWER_TYPES.contains(normalized) ? normalized : 'text';
    }

    private static String ensureUniqueDeveloperName(String proposed, String questionText, Set<String> usedDevNames) {
        String base = sanitizeDeveloperName(proposed);
        if (String.isBlank(base)) {
            base = sanitizeDeveloperName(questionText);
        }
        if (String.isBlank(base)) {
            base = 'Question';
        }

        String candidate = base;
        Integer suffix = 2;
        while (usedDevNames.contains(candidate)) {
            candidate = (base + '_' + suffix).left(80);
            suffix++;
        }
        usedDevNames.add(candidate);
        return candidate;
    }

    private static String sanitizeDeveloperName(String input) {
        if (String.isBlank(input)) return null;
        String value = input.trim().replaceAll('[^A-Za-z0-9_]', '_');
        value = value.replaceAll('_+', '_');
        value = value.replaceAll('^_+', '');
        value = value.replaceAll('_+$', '');
        if (String.isBlank(value)) return null;
        if (value.length() > 80) {
            value = value.substring(0, 80);
        }
        return value;
    }

    public class TemplateSummary {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public String status;
        @AuraEnabled public String targetObject;
        @AuraEnabled public Decimal version;
        @AuraEnabled public Datetime lastModifiedDate;
        public TemplateSummary(Intake_Template__c rec) {
            this.id = rec.Id;
            this.name = rec.Name;
            this.status = rec.Status__c;
            this.targetObject = rec.Target_Object_API_Name__c;
            this.version = rec.Version__c;
            this.lastModifiedDate = rec.LastModifiedDate;
        }
    }

    public class SaveResult {
        @AuraEnabled public Id templateId;
        @AuraEnabled public Boolean success;
        @AuraEnabled public String errorMessage;
        public SaveResult(Id templateId, Boolean success, String errorMessage) {
            this.templateId = templateId;
            this.success = success;
            this.errorMessage = errorMessage;
        }
    }

    public class TestPdfResult {
        @AuraEnabled public Id intakeId;
        @AuraEnabled public String pdfUrl;
        public TestPdfResult(Id intakeId, String pdfUrl) {
            this.intakeId = intakeId;
            this.pdfUrl = pdfUrl;
        }
    }

    public class ExtractionPdfResult {
        @AuraEnabled public Id intakeId;
        @AuraEnabled public String pdfUrl;
        @AuraEnabled public String extractedAnswersJson;
        public ExtractionPdfResult(Id intakeId, String pdfUrl, String extractedAnswersJson) {
            this.intakeId = intakeId;
            this.pdfUrl = pdfUrl;
            this.extractedAnswersJson = extractedAnswersJson;
        }
    }

    public class ValidationResult {
        @AuraEnabled public Boolean isValid;
        @AuraEnabled public List<String> errors;
        @AuraEnabled public List<String> warnings;
    }

    public class SavePayload {
        public TemplatePayload template;
        public List<QuestionPayload> questions;
        public List<PicklistValuePayload> picklistValues;
        public List<VisibilityRulePayload> visibilityRules;
        public List<TranslationPayload> translations;
    }

    public class TemplatePayload {
        public Id id;
        public String name;
        public String status;
        public String description;
        public String targetObject;
        public String personaDescription;
        public String pdfHeader;
        public String pdfFooter;
        public String brandColor;
        public String brandLogoFileId;
        public String brandLogoStaticResource;
        public String defaultLocale;
        public Decimal version;
    }

    private static String normalizeBrandColor(String raw) {
        if (String.isBlank(raw)) return null;
        String trimmed = raw.trim();
        if (!trimmed.startsWith('#')) trimmed = '#' + trimmed;
        // Validation rule enforces format, but normalize casing for consistency.
        return trimmed.toUpperCase();
    }

    public class QuestionPayload {
        @AuraEnabled public String id;
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
    }

    public class PicklistValuePayload {
        public String questionDeveloperName;
        public String label;
        public String value;
        public Decimal orderNum;
    }

    public class VisibilityRulePayload {
        public String questionDeveloperName;
        public String sourceQuestionDeveloperName;
        public String operator;
        public String value;
        public String logicGroup;
    }

    public class TranslationPayload {
        public String questionDeveloperName;
        public String locale;
        public String questionText;
        public String helpText;
    }
}
