@IsTest
private class VisionAgentAssistControllerTest {
    // Stubs the vision prompt-template call so no live model callout happens.
    private class StubRunner implements AgentforceVisionImageAction.PromptRunner {
        public String returnValue;
        public String run(String templateApiName, Id contentDocumentId, String userDescription) {
            return returnValue;
        }
    }

    // Returns deterministic Knowledge articles without publishing mechanics.
    private class StubSearcher implements VisionAgentAssistController.Searcher {
        public List<Knowledge__kav> toReturn = new List<Knowledge__kav>();
        public List<Knowledge__kav> search(String terms, Integer maxArticles) {
            return toReturn;
        }
    }

    // Inserting a ContentVersion auto-creates a ContentDocumentLink to the owner
    // (the running user), so it resolves by that id with no explicit link.
    private static Id insertImage() {
        ContentVersion cv = new ContentVersion(
            Title = 'customer-screenshot',
            PathOnClient = 'customer-screenshot.png',
            VersionData = Blob.valueOf('fake-image-bytes')
        );
        insert cv;
        return [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
    }

    // Builds a string of the requested byte length so ContentSize is deterministic.
    private static String bytesOfLength(Integer length) {
        String s = 'a';
        while (s.length() < length) {
            s += s;
        }
        return s.substring(0, length);
    }

    private static Id insertImageLinkedTo(Id linkedEntityId, String title, Integer sizeBytes) {
        ContentVersion cv = new ContentVersion(
            Title = title,
            PathOnClient = title + '.png',
            VersionData = Blob.valueOf(bytesOfLength(sizeBytes))
        );
        insert cv;
        Id docId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
        insert new ContentDocumentLink(
            ContentDocumentId = docId,
            LinkedEntityId = linkedEntityId,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        return docId;
    }

    private static Id insertInboundEmail(Id caseId) {
        EmailMessage em = new EmailMessage(
            ParentId = caseId,
            Subject = 'My streaming keeps failing - see attached',
            Incoming = true,
            FromAddress = 'customer@example.com',
            TextBody = 'I get an error every time I open the app.'
        );
        insert em;
        return em.Id;
    }

    @IsTest
    static void getLatestScreenshotResolvesLinkedImage() {
        Id docId = insertImage();

        Test.startTest();
        VisionAgentAssistController.ScreenshotInfo info =
            VisionAgentAssistController.getLatestScreenshot(UserInfo.getUserId());
        Test.stopTest();

        System.assertNotEquals(null, info, 'Expected a screenshot to be found');
        System.assertEquals(docId, info.contentDocumentId, 'Should resolve the linked image');
        System.assertEquals('PNG', info.fileType);
        System.assert(
            info.previewUrl != null && info.previewUrl.contains(info.contentVersionId),
            'Preview URL should reference the ContentVersion'
        );
    }

    // Uses an existing Case because inserting a Case in this SDO org triggers a
    // managed record-triggered flow that fails in test context. Existing demo
    // cases carry confirmation emails without image attachments, so the only
    // email-linked images are the ones these tests insert.
    @IsTest(SeeAllData=true)
    static void getLatestScreenshotResolvesCaseEmailAttachment() {
        List<Case> cases = [SELECT Id FROM Case LIMIT 1];
        if (cases.isEmpty()) {
            return;
        }
        Id caseId = cases[0].Id;
        Id emailId = insertInboundEmail(caseId);
        Id docId = insertImageLinkedTo(emailId, 'customer-error-screenshot', 40000);

        Test.startTest();
        VisionAgentAssistController.ScreenshotInfo info =
            VisionAgentAssistController.getLatestScreenshot(caseId);
        Test.stopTest();

        System.assertNotEquals(null, info, 'Should find the image attached to the inbound email');
        System.assertEquals(docId, info.contentDocumentId, 'Should resolve the email attachment');
    }

    @IsTest(SeeAllData=true)
    static void getLatestScreenshotSkipsSmallEmailSignatureImage() {
        List<Case> cases = [SELECT Id FROM Case LIMIT 1];
        if (cases.isEmpty()) {
            return;
        }
        Id caseId = cases[0].Id;
        Id emailId = insertInboundEmail(caseId);
        // A tiny signature/logo graphic plus the real (larger) screenshot.
        Id smallDocId = insertImageLinkedTo(emailId, 'company-logo-signature', 2000);
        Id realDocId = insertImageLinkedTo(emailId, 'customer-error-screenshot', 40000);

        Test.startTest();
        VisionAgentAssistController.ScreenshotInfo info =
            VisionAgentAssistController.getLatestScreenshot(caseId);
        Test.stopTest();

        System.assertNotEquals(null, info, 'Should still find the real screenshot');
        System.assertNotEquals(smallDocId, info.contentDocumentId, 'Should skip the tiny signature image');
        System.assertEquals(realDocId, info.contentDocumentId, 'Should return the real screenshot');
    }

    @IsTest
    static void getConversationScreenshotsReturnsAllLinkedImages() {
        Id docA = insertImage();
        Id docB = insertImage();

        Test.startTest();
        List<VisionAgentAssistController.ScreenshotInfo> shots =
            VisionAgentAssistController.getConversationScreenshots(UserInfo.getUserId(), 12);
        Test.stopTest();

        System.assertEquals(2, shots.size(), 'Both linked images should be returned');
        Set<String> docIds = new Set<String>();
        for (VisionAgentAssistController.ScreenshotInfo s : shots) {
            docIds.add(s.contentDocumentId);
        }
        System.assert(docIds.contains(docA) && docIds.contains(docB), 'Both docs should be present');
    }

    @IsTest(SeeAllData=true)
    static void getConversationScreenshotsFiltersSmallEmailImages() {
        List<Case> cases = [SELECT Id FROM Case LIMIT 1];
        if (cases.isEmpty()) {
            return;
        }
        Id caseId = cases[0].Id;
        Id emailId = insertInboundEmail(caseId);
        Id smallDocId = insertImageLinkedTo(emailId, 'company-logo-signature', 2000);
        Id realDocId = insertImageLinkedTo(emailId, 'customer-error-screenshot', 40000);

        Test.startTest();
        List<VisionAgentAssistController.ScreenshotInfo> shots =
            VisionAgentAssistController.getConversationScreenshots(caseId, 12);
        Test.stopTest();

        Set<String> docIds = new Set<String>();
        for (VisionAgentAssistController.ScreenshotInfo s : shots) {
            docIds.add(s.contentDocumentId);
        }
        System.assert(docIds.contains(realDocId), 'Real screenshot should be listed');
        System.assert(!docIds.contains(smallDocId), 'Tiny signature image should be filtered out');
    }

    @IsTest
    static void getLatestScreenshotReturnsNullWhenNoImage() {
        Test.startTest();
        VisionAgentAssistController.ScreenshotInfo info =
            VisionAgentAssistController.getLatestScreenshot(UserInfo.getUserId());
        Test.stopTest();

        System.assertEquals(null, info, 'No image exists so none should be returned');
    }

    @IsTest
    static void analyzeScreenshotDiagnosesAndGroundsSteps() {
        insertImage();

        StubRunner runner = new StubRunner();
        runner.returnValue = 'DIAGNOSIS: The router status light is blinking red.\n'
            + 'KEYWORDS: router, blinking, light';
        AgentforceVisionImageAction.runner = runner;

        StubSearcher searcher = new StubSearcher();
        searcher.toReturn = new List<Knowledge__kav>{
            new Knowledge__kav(
                Title = 'Router blinking light fix',
                Summary = 'How to fix a blinking router light',
                FAQ_Answer__c = '<ol><li>Unplug the router.</li>'
                    + '<li>Wait 30 seconds.</li><li>Plug it back in.</li></ol>'
            )
        };
        VisionAgentAssistController.searcher = searcher;

        Test.startTest();
        VisionAgentAssistController.AssistResult result =
            VisionAgentAssistController.analyzeScreenshot(
                UserInfo.getUserId(), null, 'my internet is down'
            );
        Test.stopTest();

        System.assertEquals(true, result.success, 'Expected a successful analysis');
        System.assertEquals('The router status light is blinking red.', result.diagnosis);
        System.assertEquals('router, blinking, light', result.keywords);
        System.assertEquals(true, result.grounded, 'Steps should be grounded in Knowledge');
        System.assertEquals('Router blinking light fix', result.stepsSource);
        System.assertEquals(3, result.steps.size(), 'FAQ list should yield 3 steps');
        System.assertEquals('Unplug the router.', result.steps[0]);
        System.assertEquals(1, result.articleCount);
    }

    @IsTest
    static void analyzeScreenshotReturnsFailureWhenNoImage() {
        StubRunner runner = new StubRunner();
        runner.returnValue = 'DIAGNOSIS: nothing\nKEYWORDS: none';
        AgentforceVisionImageAction.runner = runner;

        Test.startTest();
        VisionAgentAssistController.AssistResult result =
            VisionAgentAssistController.analyzeScreenshot(UserInfo.getUserId(), null, null);
        Test.stopTest();

        System.assertEquals(false, result.success, 'No image should produce a failure result');
        System.assertNotEquals(null, result.message);
    }

    @IsTest
    static void analyzeScreenshotWithoutMatchLeavesStepsEmpty() {
        insertImage();

        StubRunner runner = new StubRunner();
        runner.returnValue = 'DIAGNOSIS: A thermostat shows E5.\nKEYWORDS: thermostat, E5';
        AgentforceVisionImageAction.runner = runner;

        StubSearcher searcher = new StubSearcher();
        searcher.toReturn = new List<Knowledge__kav>(); // nothing matched
        VisionAgentAssistController.searcher = searcher;

        Test.startTest();
        VisionAgentAssistController.AssistResult result =
            VisionAgentAssistController.analyzeScreenshot(UserInfo.getUserId(), null, null);
        Test.stopTest();

        System.assertEquals(true, result.success, 'Diagnosis still succeeds without an article');
        System.assertEquals(false, result.grounded, 'No article means no grounded steps');
        System.assertEquals(0, result.steps.size());
        System.assertEquals(0, result.articleCount);
    }

    @IsTest
    static void toStepsParsesListAndDropsMarkers() {
        List<String> steps = VisionAgentAssistController.toSteps(
            '1. First step<br/>2) Second step<ul><li>Third step</li></ul>'
        );
        System.assertEquals(3, steps.size());
        System.assertEquals('First step', steps[0]);
        System.assertEquals('Second step', steps[1]);
        System.assertEquals('Third step', steps[2]);
    }

    @IsTest
    static void sanitizeStripsSoslReservedCharacters() {
        String cleaned = VisionAgentAssistController.sanitize('router+light? {test}');
        System.assert(!cleaned.contains('+'), 'Reserved chars should be removed');
        System.assert(!cleaned.contains('?'));
        System.assert(cleaned.contains('router'));
        System.assert(cleaned.contains('light'));
    }
}
