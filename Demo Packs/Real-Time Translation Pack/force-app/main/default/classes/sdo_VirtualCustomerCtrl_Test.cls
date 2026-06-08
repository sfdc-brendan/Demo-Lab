@isTest
private class sdo_VirtualCustomerCtrl_Test {
    @testSetup
    static void setup() {
        Account a = new Account(Name = 'Virtual Customer Test Acct');
        insert a;
        insert new Contact(
            FirstName = 'Phone',
            LastName = 'Customer',
            Email = 'phone.customer@example.com',
            Phone = '(555) 555-0100',
            AccountId = a.Id
        );
    }

    private class MiawMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            if (req.getEndpoint().contains('access-token')) {
                res.setBody('{"accessToken":"eyJTEST.token.value","lastEventId":"0"}');
            } else {
                res.setBody('{"conversationId":"abc"}');
            }
            return res;
        }
    }

    private class EntriesMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody(
                '{"conversationEntries":[' +
                '{"entryType":"Message","identifier":"e1","senderDisplayName":"Guest",' +
                '"transcriptedTimestamp":1780103430346,"sender":{"role":"EndUser"},' +
                '"entryPayload":{"abstractMessage":{"staticContent":{"formatType":"Text","text":"Hola"}}}},' +
                '{"entryType":"RoutingResult","identifier":"r1","sender":{"role":"System"},"entryPayload":{}},' +
                '{"entryType":"Message","identifier":"e2","senderDisplayName":"Alex Agent",' +
                '"transcriptedTimestamp":1780103440346,"sender":{"role":"Agent"},' +
                '"entryPayload":{"abstractMessage":{"staticContent":{"formatType":"Text","text":"Hello, how can I help?"}}}}' +
                ']}'
            );
            return res;
        }
    }

    private class MiawErrorMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(400);
            res.setBody('{"errorCode":"BAD_REQUEST","message":"boom"}');
            return res;
        }
    }

    @isTest
    static void startAndSend_happyPath() {
        Test.setMock(HttpCalloutMock.class, new MiawMock());
        Test.startTest();
        sdo_VirtualCustomerCtrl.StartResult start = sdo_VirtualCustomerCtrl.startConversation(null, null);
        sdo_VirtualCustomerCtrl.sendMessage(start.accessToken, start.conversationId, 'Hola', 'es', true, null);
        sdo_VirtualCustomerCtrl.sendMessage(start.accessToken, start.conversationId, 'Gracias', 'es', false, 'SDO_Messaging_API');
        Test.stopTest();

        System.assertEquals('eyJTEST.token.value', start.accessToken, 'Access token should be parsed from response');
        System.assertNotEquals(null, start.conversationId, 'Conversation id should be generated');
        System.assertNotEquals(null, start.contactId, 'A phone Contact should be resolved and returned');
    }

    @isTest
    static void startConversation_handlesError() {
        Test.setMock(HttpCalloutMock.class, new MiawErrorMock());
        Test.startTest();
        Boolean threw = false;
        try {
            sdo_VirtualCustomerCtrl.startConversation(null, null);
        } catch (Exception e) {
            threw = true;
        }
        Test.stopTest();
        System.assert(threw, 'An error response should surface as an exception');
    }

    @isTest
    static void getDemoContact_returnsPhoneContact() {
        sdo_VirtualCustomerCtrl.ContactInfo info = sdo_VirtualCustomerCtrl.getDemoContact();
        System.assertNotEquals(null, info, 'A demo contact should be returned');
        System.assertNotEquals(null, info.id, 'Contact id should be populated');
    }

    @isTest
    static void assignContactToSession_guardsMissingArgs() {
        System.assertEquals(false, sdo_VirtualCustomerCtrl.assignContactToSession(null, null), 'Missing args should return false');
    }

    @isTest
    static void buildChatMessages_mapsRolesFromHistory() {
        String history = '[{"sender":"customer","text":"Hola"},{"sender":"agent","text":"How can I help?"}]';
        List<aiplatform.ModelsAPI_ChatMessageRequest> msgs =
            sdo_VirtualCustomerCtrl.buildChatMessages('es', 'Disputed charge', history);
        System.assertEquals(3, msgs.size(), 'system + 2 history turns');
        System.assertEquals('system', msgs[0].role, 'First message is the system prompt');
        System.assertEquals('assistant', msgs[1].role, 'Customer turn maps to assistant');
        System.assertEquals('user', msgs[2].role, 'Agent turn maps to user');
    }

    @isTest
    static void buildChatMessages_emptyHistoryAddsStarter() {
        List<aiplatform.ModelsAPI_ChatMessageRequest> msgs =
            sdo_VirtualCustomerCtrl.buildChatMessages('fr', 'Late delivery', null);
        System.assertEquals(2, msgs.size(), 'system + starter user prompt');
        System.assertEquals('user', msgs[1].role, 'Starter prompt is a user turn');
    }

    @isTest
    static void scenarios_areReturned() {
        List<sdo_VirtualCustomerCtrl.Scenario> scenarios = sdo_VirtualCustomerCtrl.getScenarios();
        System.assert(!scenarios.isEmpty(), 'Built-in scenarios should be returned');
        System.assert(!scenarios[0].lines.isEmpty(), 'Scenario should include customer lines');
        System.assert(String.isNotBlank(scenarios[0].escalationLine), 'Scenario should include a localized escalation line');
    }

    @isTest
    static void routes_includeHumanAndAgentforce() {
        List<sdo_VirtualCustomerCtrl.Route> routes = sdo_VirtualCustomerCtrl.getRoutes();
        System.assertEquals(2, routes.size(), 'Two curated routes are expected');
        Boolean hasAgentforce = false;
        for (sdo_VirtualCustomerCtrl.Route r : routes) {
            System.assert(String.isNotBlank(r.esDeveloperName), 'Each route needs a deployment name');
            System.assert(String.isNotBlank(r.channelDevName), 'Each route needs a channel name');
            if (r.agentforce == true) {
                hasAgentforce = true;
            }
        }
        System.assert(hasAgentforce, 'An Agentforce route should be available');
    }

    @isTest
    static void locateAndEntries_returnSafelyWhenEmpty() {
        Test.startTest();
        sdo_VirtualCustomerCtrl.SessionRef ref = sdo_VirtualCustomerCtrl.locateSession(Datetime.now(), null);
        List<sdo_VirtualCustomerCtrl.AgentEntry> entries = sdo_VirtualCustomerCtrl.getAgentEntries(null, null);
        Test.stopTest();
        System.assertEquals(null, ref, 'No session expected in test context');
        System.assert(entries.isEmpty(), 'No agent entries expected when token/conversation missing');
    }

    @isTest
    static void getAgentEntries_parsesAgentMessages() {
        Test.setMock(HttpCalloutMock.class, new EntriesMock());
        Test.startTest();
        List<sdo_VirtualCustomerCtrl.AgentEntry> entries = sdo_VirtualCustomerCtrl.getAgentEntries('token', 'conv-id');
        Test.stopTest();
        System.assertEquals(1, entries.size(), 'Only the agent message should be returned');
        System.assertEquals('Hello, how can I help?', entries[0].text, 'Agent text should be extracted');
        System.assertEquals('Agent', entries[0].role, 'Role should be Agent');
    }
}