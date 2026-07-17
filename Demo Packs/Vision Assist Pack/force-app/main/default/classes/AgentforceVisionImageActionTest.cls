@IsTest
private class AgentforceVisionImageActionTest {
    private class StubRunner implements AgentforceVisionImageAction.PromptRunner {
        public String lastTemplate;
        public Id lastDoc;
        public String lastDesc;
        public String returnValue;
        public String run(String templateApiName, Id contentDocumentId, String userDescription) {
            this.lastTemplate = templateApiName;
            this.lastDoc = contentDocumentId;
            this.lastDesc = userDescription;
            return returnValue;
        }
    }

    // Inserting a ContentVersion auto-creates a ContentDocumentLink to the owner
    // (the running user), so no explicit link is needed for the resolve test.
    private static Id insertImage() {
        ContentVersion cv = new ContentVersion(
            Title = 'test-image',
            PathOnClient = 'test-image.png',
            VersionData = Blob.valueOf('fake-image-bytes')
        );
        insert cv;
        return [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
    }

    @IsTest
    static void analyzesExplicitDocumentAndParsesResponse() {
        Id docId = insertImage();
        StubRunner stub = new StubRunner();
        stub.returnValue = 'DIAGNOSIS: The thermostat shows an E5 error.\nKEYWORDS: thermostat, E5 error, in-room climate';
        AgentforceVisionImageAction.runner = stub;

        AgentforceVisionImageAction.Request req = new AgentforceVisionImageAction.Request();
        req.contentDocumentId = docId;
        req.userDescription = 'the AC is not working';

        Test.startTest();
        List<AgentforceVisionImageAction.Response> results =
            AgentforceVisionImageAction.analyze(new List<AgentforceVisionImageAction.Request>{ req });
        Test.stopTest();

        AgentforceVisionImageAction.Response res = results[0];
        System.assertEquals(true, res.success, 'Expected success');
        System.assertEquals('The thermostat shows an E5 error.', res.diagnosis);
        System.assertEquals('thermostat, E5 error, in-room climate', res.searchKeywords);
        System.assertEquals(docId, res.contentDocumentId);
        System.assertEquals(docId, stub.lastDoc, 'Runner should receive the resolved document id');
        System.assertEquals('the AC is not working', stub.lastDesc);
    }

    @IsTest
    static void resolvesLatestImageFromLinkedRecord() {
        // The image auto-links to its owner (running user); resolve by that id.
        Id linkId = UserInfo.getUserId();
        Id docId = insertImage();

        StubRunner stub = new StubRunner();
        stub.returnValue = 'DIAGNOSIS: Something is visible.\nKEYWORDS: test';
        AgentforceVisionImageAction.runner = stub;

        AgentforceVisionImageAction.Request req = new AgentforceVisionImageAction.Request();
        req.recordId = linkId;

        Test.startTest();
        List<AgentforceVisionImageAction.Response> results =
            AgentforceVisionImageAction.analyze(new List<AgentforceVisionImageAction.Request>{ req });
        Test.stopTest();

        System.assertEquals(true, results[0].success);
        System.assertEquals(docId, results[0].contentDocumentId, 'Should resolve the linked image');
    }

    @IsTest
    static void returnsFailureWhenNoImageFound() {
        AgentforceVisionImageAction.Request req = new AgentforceVisionImageAction.Request();
        // A valid record id with no image linked in this transaction.
        req.recordId = UserInfo.getUserId();

        Test.startTest();
        List<AgentforceVisionImageAction.Response> results =
            AgentforceVisionImageAction.analyze(new List<AgentforceVisionImageAction.Request>{ req });
        Test.stopTest();

        System.assertEquals(false, results[0].success);
        System.assertNotEquals(null, results[0].message);
    }

    @IsTest
    static void parseFallsBackToRawWhenUnformatted() {
        AgentforceVisionImageAction.Response res = new AgentforceVisionImageAction.Response();
        AgentforceVisionImageAction.parseInto('just some unstructured text', res);
        System.assertEquals('just some unstructured text', res.diagnosis);
        System.assertEquals('', res.searchKeywords);
    }
}
