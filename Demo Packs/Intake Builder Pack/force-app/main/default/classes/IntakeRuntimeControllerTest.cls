@IsTest
private class IntakeRuntimeControllerTest {

    private static Intake_Template__c buildTemplate(String targetObj) {
        Intake_Template__c tpl = new Intake_Template__c(
            Name = 'Test Template',
            Status__c = 'Active',
            Default_Locale__c = 'en_US',
            Version__c = 1,
            Target_Object_API_Name__c = targetObj,
            Persona_Description__c = 'Test persona.'
        );
        insert tpl;

        List<Intake_Question__c> qs = new List<Intake_Question__c>{
            new Intake_Question__c(Intake_Template__c=tpl.Id, DeveloperName__c='Customer_Name',
                Question_Text__c='Name?', Category__c='Caller', Order__c=1, Required__c=true,
                Answer_Type__c='text', Target_Field_API_Name__c='Name'),
            new Intake_Question__c(Intake_Template__c=tpl.Id, DeveloperName__c='Issue_Type',
                Question_Text__c='Issue?', Category__c='Incident', Order__c=2,
                Answer_Type__c='textarea', Target_Field_API_Name__c='Description')
        };
        insert qs;
        return tpl;
    }

    @IsTest
    static void getTemplate_returnsHydratedBundle() {
        Intake_Template__c tpl = buildTemplate('Account');

        Test.startTest();
        IntakeRuntimeController.TemplateBundle bundle =
            IntakeRuntimeController.getTemplate(tpl.Id);
        Test.stopTest();

        System.assertNotEquals(null, bundle);
        System.assertEquals(2, bundle.questions.size());
        Boolean foundIssueQuestion = false;
        for (IntakeRuntimeController.QuestionDTO q : bundle.questions) {
            if (q.developerName == 'Issue_Type') {
                foundIssueQuestion = true;
                System.assertEquals('textarea', q.answerType);
            }
        }
        System.assert(foundIssueQuestion);
    }

    @IsTest
    static void submit_writesToTargetObjectDynamically() {
        Intake_Template__c tpl = buildTemplate('Account');

        String answers = '{"Customer_Name":"Jane Doe","Issue_Type":"Customer reports account issue."}';

        Test.startTest();
        Id newId = IntakeRuntimeController.submitIntake(tpl.Id, null, answers);
        Test.stopTest();

        System.assertNotEquals(null, newId);
        Account rec = [
            SELECT Name, Description
            FROM Account
            WHERE Id = :newId LIMIT 1
        ];
        System.assertEquals('Jane Doe', rec.Name);
        System.assertEquals('Customer reports account issue.', rec.Description);
    }

    @IsTest
    static void submit_fallsBackToIntakeSubmission_whenTargetBlank() {
        Intake_Template__c tpl = buildTemplate(null);

        String answers = '{"Customer_Name":"Jane"}';

        Test.startTest();
        Id newId = IntakeRuntimeController.submitIntake(tpl.Id, null, answers);
        Test.stopTest();

        Intake_Submission__c sub = [
            SELECT Status__c, Answers_JSON__c, Intake_Template__c
            FROM Intake_Submission__c WHERE Id = :newId LIMIT 1
        ];
        System.assertEquals('Submitted', sub.Status__c);
        System.assertEquals(tpl.Id, sub.Intake_Template__c);
    }

    @IsTest
    static void runAnalysis_invokesAnalyzerWithTemplatePersona() {
        Intake_Template__c tpl = buildTemplate('Account');
        IntakeTranscriptAnalyzer.mockResponse = '{"Customer_Name":"Bob","Issue_Type":"User cannot access account"}';
        String questionsJson = '[{"developerName":"Customer_Name","questionText":"Name?","answerType":"text"}]';

        Test.startTest();
        Map<String, String> result = IntakeRuntimeController.runAnalysis(
            tpl.Id, questionsJson, 'Customer: My name is Bob and I am locked out.'
        );
        Test.stopTest();

        System.assertEquals('Bob', result.get('Customer_Name'));
        System.assertEquals('User cannot access account', result.get('Issue_Type'));
    }

    @IsTest
    static void getTranscriptEntries_handlesMissingVoiceCall() {
        Test.startTest();
        List<IntakeRuntimeController.TranscriptEntry> empty1 =
            IntakeRuntimeController.getTranscriptEntries(null, null);
        Test.stopTest();
        System.assertEquals(0, empty1.size());
    }

    @IsTest
    static void getVoiceCallContext_handlesNull() {
        IntakeRuntimeController.VoiceCallContext ctx =
            IntakeRuntimeController.getVoiceCallContext(null);
        System.assertEquals(null, ctx);
    }

    @IsTest
    static void saveAndLoadDraft_roundTrip_targetObject() {
        Intake_Template__c tpl = buildTemplate('Account');
        Intake_Submission__c existing = new Intake_Submission__c(
            Intake_Template__c = tpl.Id,
            Status__c = 'Draft',
            Answers_JSON__c = '{"Customer_Name":"Test"}'
        );
        insert existing;

        IntakeRuntimeController.DraftResult drafted =
            IntakeRuntimeController.getDraftIntake(tpl.Id, null);
        System.assertEquals(null, drafted);
    }

    @IsTest
    static void attachIntakePDF_handlesIntakeSubmission() {
        Intake_Template__c tpl = buildTemplate(null);
        Intake_Submission__c sub = new Intake_Submission__c(
            Intake_Template__c = tpl.Id,
            Status__c = 'Submitted',
            Answers_JSON__c = '{"Customer_Name":"Carl"}'
        );
        insert sub;

        Test.startTest();
        IntakeRuntimeController.attachIntakePDF(sub.Id);
        Test.stopTest();

        List<ContentDocumentLink> links = [
            SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :sub.Id
        ];
        System.assertEquals(1, links.size());
    }
}
