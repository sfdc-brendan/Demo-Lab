@IsTest
private class IntakeBuilderControllerTest {

    @IsTest
    static void createAndListTemplates() {
        Test.startTest();
        Id newId = IntakeBuilderController.createTemplate('Test Template A');
        List<IntakeBuilderController.TemplateSummary> all = IntakeBuilderController.listTemplates(null);
        List<IntakeBuilderController.TemplateSummary> drafts = IntakeBuilderController.listTemplates('Draft');
        Test.stopTest();

        System.assertNotEquals(null, newId);
        System.assert(all.size() >= 1);
        Boolean foundDraft = false;
        for (IntakeBuilderController.TemplateSummary s : drafts) {
            if (s.id == newId) {
                foundDraft = true;
                System.assertEquals('Draft', s.status);
            }
        }
        System.assert(foundDraft);
    }

    @IsTest
    static void saveTemplate_persistsTemplateAndChildren() {
        Id tplId = IntakeBuilderController.createTemplate('Save Test');

        IntakeBuilderController.SavePayload payload = new IntakeBuilderController.SavePayload();
        IntakeBuilderController.TemplatePayload tp = new IntakeBuilderController.TemplatePayload();
        tp.id = tplId;
        tp.name = 'Save Test Updated';
        tp.status = 'Draft';
        tp.targetObject = 'Case';
        tp.personaDescription = 'You are an assistant.';
        tp.defaultLocale = 'en_US';
        tp.version = 1;
        payload.template = tp;

        IntakeBuilderController.QuestionPayload qp = new IntakeBuilderController.QuestionPayload();
        qp.developerName = 'Customer_Name';
        qp.questionText = 'Name?';
        qp.answerType = 'text';
        qp.targetField = 'Customer_Name__c';
        qp.orderNum = 1;
        qp.isRequired = true;
        payload.questions = new List<IntakeBuilderController.QuestionPayload>{ qp };

        IntakeBuilderController.PicklistValuePayload pvp = new IntakeBuilderController.PicklistValuePayload();
        pvp.questionDeveloperName = 'Customer_Name';
        pvp.label = 'foo';
        pvp.value = 'foo';
        pvp.orderNum = 1;
        payload.picklistValues = new List<IntakeBuilderController.PicklistValuePayload>{ pvp };

        IntakeBuilderController.VisibilityRulePayload vrp = new IntakeBuilderController.VisibilityRulePayload();
        vrp.questionDeveloperName = 'Customer_Name';
        vrp.sourceQuestionDeveloperName = 'Customer_Name';
        vrp.operator = 'is_not_blank';
        vrp.value = '';
        vrp.logicGroup = 'default';
        payload.visibilityRules = new List<IntakeBuilderController.VisibilityRulePayload>{ vrp };

        IntakeBuilderController.TranslationPayload tpp = new IntakeBuilderController.TranslationPayload();
        tpp.questionDeveloperName = 'Customer_Name';
        tpp.locale = 'es_MX';
        tpp.questionText = '¿Nombre?';
        tpp.helpText = '';
        payload.translations = new List<IntakeBuilderController.TranslationPayload>{ tpp };

        Test.startTest();
        IntakeBuilderController.SaveResult result =
            IntakeBuilderController.saveTemplate(JSON.serialize(payload));
        Test.stopTest();

        System.assertEquals(true, result.success);
        Intake_Template__c saved = [
            SELECT Name, Persona_Description__c FROM Intake_Template__c WHERE Id = :tplId
        ];
        System.assertEquals('Save Test Updated', saved.Name);

        List<Intake_Question__c> qs = [
            SELECT DeveloperName__c FROM Intake_Question__c WHERE Intake_Template__c = :tplId
        ];
        System.assertEquals(1, qs.size());

        List<Intake_Picklist_Value__c> pvs = [
            SELECT Label__c FROM Intake_Picklist_Value__c WHERE Intake_Question__c = :qs[0].Id
        ];
        System.assertEquals(1, pvs.size());

        List<Intake_Visibility_Rule__c> rules = [
            SELECT Operator__c FROM Intake_Visibility_Rule__c WHERE Intake_Question__c = :qs[0].Id
        ];
        System.assertEquals(1, rules.size());

        List<Intake_Translation__c> trs = [
            SELECT Locale__c FROM Intake_Translation__c WHERE Intake_Question__c = :qs[0].Id
        ];
        System.assertEquals(1, trs.size());
    }

    @IsTest
    static void cloneTemplate_copiesChildren() {
        Id source = IntakeBuilderController.createTemplate('Clone Source');
        Intake_Question__c q = new Intake_Question__c(
            Intake_Template__c = source,
            DeveloperName__c = 'Q1',
            Question_Text__c = 'Q1?',
            Answer_Type__c = 'text',
            Order__c = 1
        );
        insert q;

        Test.startTest();
        Id cloneId = IntakeBuilderController.cloneTemplate(source);
        Test.stopTest();

        System.assertNotEquals(source, cloneId);
        Integer count = [SELECT COUNT() FROM Intake_Question__c WHERE Intake_Template__c = :cloneId];
        System.assertEquals(1, count);
    }

    @IsTest
    static void newVersion_setsParentAndIncrementsVersion() {
        Id source = IntakeBuilderController.createTemplate('Versioned');

        Test.startTest();
        Id v2 = IntakeBuilderController.newVersion(source);
        Test.stopTest();

        Intake_Template__c v2Rec = [
            SELECT Version__c, Parent_Template__c FROM Intake_Template__c WHERE Id = :v2
        ];
        System.assertEquals(2, v2Rec.Version__c);
        System.assertEquals(source, v2Rec.Parent_Template__c);
    }

    @IsTest
    static void archiveAndActivate_updateStatus() {
        Id tplId = IntakeBuilderController.createTemplate('Archive Test');
        Intake_Question__c q = new Intake_Question__c(
            Intake_Template__c = tplId,
            DeveloperName__c = 'Q1',
            Answer_Type__c = 'text'
        );
        insert q;

        Test.startTest();
        IntakeBuilderController.activateTemplate(tplId);
        Intake_Template__c afterActivate = [SELECT Status__c FROM Intake_Template__c WHERE Id = :tplId];
        IntakeBuilderController.archiveTemplate(tplId);
        Intake_Template__c afterArchive = [SELECT Status__c FROM Intake_Template__c WHERE Id = :tplId];
        Test.stopTest();

        System.assertEquals('Active', afterActivate.Status__c);
        System.assertEquals('Archived', afterArchive.Status__c);
    }

    @IsTest
    static void deleteTemplate_removesTemplateAndChildren() {
        Id tplId = IntakeBuilderController.createTemplate('Delete Test');
        Intake_Question__c q = new Intake_Question__c(
            Intake_Template__c = tplId,
            DeveloperName__c = 'Delete_Q1',
            Question_Text__c = 'Delete me?',
            Answer_Type__c = 'text',
            Order__c = 1
        );
        insert q;
        insert new Intake_Picklist_Value__c(
            Intake_Question__c = q.Id,
            Label__c = 'Option',
            Value__c = 'Option',
            Order__c = 1
        );
        insert new Intake_Visibility_Rule__c(
            Intake_Question__c = q.Id,
            Source_Question_Developer_Name__c = 'Delete_Q1',
            Operator__c = 'is_not_blank',
            Value__c = '',
            Logic_Group__c = 'default'
        );
        insert new Intake_Translation__c(
            Intake_Question__c = q.Id,
            Locale__c = 'es_MX',
            Question_Text_Translated__c = 'Eliminar',
            Help_Text_Translated__c = ''
        );

        Test.startTest();
        IntakeBuilderController.deleteTemplate(tplId);
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM Intake_Template__c WHERE Id = :tplId]);
        System.assertEquals(0, [SELECT COUNT() FROM Intake_Question__c WHERE Intake_Template__c = :tplId]);
    }

    @IsTest
    static void validate_flagsDuplicateDeveloperNames() {
        Id tplId = IntakeBuilderController.createTemplate('Dup Test');
        insert new List<Intake_Question__c>{
            new Intake_Question__c(Intake_Template__c=tplId, DeveloperName__c='SameName',
                Question_Text__c='A', Answer_Type__c='text'),
            new Intake_Question__c(Intake_Template__c=tplId, DeveloperName__c='SameName',
                Question_Text__c='B', Answer_Type__c='text')
        };

        Test.startTest();
        IntakeBuilderController.ValidationResult vr =
            IntakeBuilderController.validateTemplate(tplId);
        Test.stopTest();

        System.assertEquals(false, vr.isValid);
        System.assert(vr.errors.size() > 0);
    }

    @IsTest
    static void testAnalyze_passesThroughAnalyzer() {
        IntakeTranscriptAnalyzer.mockResponse = '{"Customer_Name":"Sue"}';
        String qJson = '[{"developerName":"Customer_Name","questionText":"Name?","answerType":"text"}]';

        Test.startTest();
        Map<String, String> result = IntakeBuilderController.testAnalyze(
            'You are a test assistant.', qJson, 'Customer: Sue here.'
        );
        Test.stopTest();

        System.assertEquals('Sue', result.get('Customer_Name'));
    }

    @IsTest
    static void generateQuestionsFromDescription_returnsNormalizedQuestions() {
        IntakeBuilderController.mockQuestionGenerationResponse =
            '{"questions":[{"developerName":"Customer Name","questionText":"What is the customer full name?",'
            + '"answerType":"Text","isRequired":"true","targetField":"Customer_Name__c","aiExtractionHint":"Use legal name."},'
            + '{"developerName":"Customer Name","questionText":"Describe the issue in detail.","answerType":"textarea"}]}';

        Test.startTest();
        List<IntakeBuilderController.QuestionPayload> generated =
            IntakeBuilderController.generateQuestionsFromDescription(
                'Vehicle support intake form.',
                'Case'
            );
        Test.stopTest();

        System.assertEquals(2, generated.size());
        System.assertEquals('Customer_Name', generated[0].developerName);
        System.assertEquals('text', generated[0].answerType);
        System.assertEquals(true, generated[0].isRequired);
        System.assertEquals('Customer_Name_2', generated[1].developerName);
        System.assertEquals('textarea', generated[1].answerType);
        System.assertEquals(1, generated[0].orderNum);
        System.assertEquals(2, generated[1].orderNum);
    }

    @IsTest
    static void generateQuestionsFromDescription_supportsAlternateQuestionKey() {
        IntakeBuilderController.mockQuestionGenerationResponse =
            '{"questions":[{"developerName":"Loan_Amount","question":"What mortgage amount is requested?","answerType":"currency"}]}';

        Test.startTest();
        List<IntakeBuilderController.QuestionPayload> generated =
            IntakeBuilderController.generateQuestionsFromDescription(
                'Mortgage application intake form.',
                'Application__c'
            );
        Test.stopTest();

        System.assertEquals(1, generated.size());
        System.assertEquals('What mortgage amount is requested?', generated[0].questionText);
        System.assertEquals('number', generated[0].answerType);
    }

    @IsTest
    static void generateQuestionsFromDescription_fallsBackForVagueDescription() {
        IntakeBuilderController.mockQuestionGenerationResponse = '{"questions":[{"questionText":"New Question"}]}';

        Test.startTest();
        List<IntakeBuilderController.QuestionPayload> generated =
            IntakeBuilderController.generateQuestionsFromDescription(
                'Mortgage intake',
                null
            );
        Test.stopTest();

        System.assert(generated.size() >= 6);
        Boolean foundLoanAmount = false;
        for (IntakeBuilderController.QuestionPayload q : generated) {
            if (q.developerName == 'Requested_Loan_Amount') {
                foundLoanAmount = true;
                System.assertEquals('number', q.answerType);
            }
        }
        System.assertEquals(true, foundLoanAmount);
    }

    @IsTest
    static void createTestRecordAndPdf_createsSubmissionAndPdfLink() {
        Intake_Template__c tpl = new Intake_Template__c(
            Name = 'PDF Preview Test',
            Status__c = 'Draft',
            Version__c = 1,
            Default_Locale__c = 'en_US'
        );
        insert tpl;

        insert new Intake_Question__c(
            Intake_Template__c = tpl.Id,
            DeveloperName__c = 'Applicant_Name',
            Question_Text__c = 'Applicant name?',
            Answer_Type__c = 'text',
            Order__c = 1
        );

        Test.startTest();
        IntakeBuilderController.TestPdfResult result =
            IntakeBuilderController.createTestRecordAndPdf(tpl.Id);
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertNotEquals(null, result.intakeId);
        System.assert(result.pdfUrl != null && result.pdfUrl.contains('/apex/IntakePDF?id='));

        Integer links = [
            SELECT COUNT()
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :result.intakeId
        ];
        System.assertEquals(1, links, 'Expected one generated PDF link on test intake record.');
    }

    @IsTest
    static void generateTestCallScript_returnsTranscriptText() {
        Intake_Template__c tpl = new Intake_Template__c(
            Name = 'Script Gen Test',
            Status__c = 'Draft',
            Version__c = 1,
            Default_Locale__c = 'en_US'
        );
        insert tpl;
        insert new Intake_Question__c(
            Intake_Template__c = tpl.Id,
            DeveloperName__c = 'Issue_Summary',
            Question_Text__c = 'What is the issue?',
            Answer_Type__c = 'textarea',
            Order__c = 1
        );

        IntakeBuilderController.mockQuestionGenerationResponse =
            'Agent: Thanks for calling.' + '\n' + 'Customer: I need help with my mortgage application.';

        Test.startTest();
        String transcript = IntakeBuilderController.generateTestCallScript(tpl.Id, 'Mortgage call');
        Test.stopTest();

        System.assert(String.isNotBlank(transcript));
        System.assert(transcript.contains('Agent:'));
        System.assert(transcript.contains('Customer:'));
    }

    @IsTest
    static void runTestExtractionAndCreatePdf_createsPdfFromExtractedAnswers() {
        Intake_Template__c tpl = new Intake_Template__c(
            Name = 'Extraction to PDF Test',
            Status__c = 'Draft',
            Version__c = 1,
            Default_Locale__c = 'en_US'
        );
        insert tpl;
        insert new Intake_Question__c(
            Intake_Template__c = tpl.Id,
            DeveloperName__c = 'Applicant_Name',
            Question_Text__c = 'Applicant name?',
            Answer_Type__c = 'text',
            Order__c = 1
        );
        IntakeTranscriptAnalyzer.mockResponse = '{"Applicant_Name":"Taylor Brooks"}';

        Test.startTest();
        IntakeBuilderController.ExtractionPdfResult result =
            IntakeBuilderController.runTestExtractionAndCreatePdf(
                tpl.Id,
                'Agent: What is your name?\nCustomer: Taylor Brooks.'
            );
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertNotEquals(null, result.intakeId);
        System.assert(result.pdfUrl != null && result.pdfUrl.contains('/apex/IntakePDF?id='));
        System.assert(result.extractedAnswersJson.contains('Taylor Brooks'));
    }
}
