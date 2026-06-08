/**
 * Drives a "virtual customer" against the Messaging for In-App and Web (MIAW)
 * inbound REST API so that REAL inbound messages land in a live Messaging
 * Session. Because the messages are genuine inbound conversation entries, the
 * org's Real-Time Conversation Translation engages automatically when the
 * customer's language differs from the agent's.
 *
 * Flow:
 *   1. startConversation  -> get an unauthenticated access token + create a conversation
 *   2. sendMessage        -> post a (foreign-language) customer message
 *   3. locateSession      -> find the resulting MessagingSession / Conversation
 *   4. getNewAgentEntries -> detect the agent's reply so the customer can respond back
 *
 * Requires an API (Custom Client) Messaging deployment that is PUBLISHED, and a
 * Remote Site Setting for the org's *.my.salesforce-scrt.com host.
 */
public with sharing class sdo_VirtualCustomerCtrl {
    private static final String DEFAULT_ES_DEVELOPER_NAME = 'RTT_New';
    private static final String DEFAULT_CHANNEL_DEV_NAME = 'RTT';
    private static final String API_BASE = '/iamessage/api/v2';
    private static final String MODEL_NAME = 'sfdc_ai__DefaultGPT4Omni';

    // ---------------------------------------------------------------------
    // Public (LWC) entry points
    // ---------------------------------------------------------------------

    /**
     * Curated conversation routes the demo can switch between. Each maps to an
     * API (Custom Client) Messaging deployment (esDeveloperName) and the
     * MessagingChannel its sessions land on. The "Human Agent" route lands in an
     * Omni-Channel queue (so Real-Time Translation engages); the "Agentforce"
     * route points at a deployment whose channel is answered by an Agentforce
     * Service Agent, so the conversation rolls through Agentforce first.
     */
    @AuraEnabled(cacheable=true)
    public static List<Route> getRoutes() {
        List<Route> routes = new List<Route>();
        routes.add(new Route('Human Agent (Real-Time Translation)', DEFAULT_ES_DEVELOPER_NAME, DEFAULT_CHANNEL_DEV_NAME, false));
        routes.add(new Route('Agentforce Service Agent', 'SDO_Messaging_API', 'Messaging_for_In_App_Web', true));
        return routes;
    }

    @AuraEnabled
    public static StartResult startConversation(Id contactId, String esDeveloperName) {
        String esName = String.isBlank(esDeveloperName) ? DEFAULT_ES_DEVELOPER_NAME : esDeveloperName;
        Contact c = resolveDemoContact(contactId);
        String token = requestAccessToken(esName);
        String conversationId = newUuid();
        createConversation(token, conversationId, c.FirstName, c.LastName, c.Email, esName);
        return new StartResult(token, conversationId, c.Id, c.Name);
    }

    /**
     * Returns the Contact (with a phone number) that the messaging session will
     * be linked to, so the LWC can show who the "customer" is before starting.
     */
    @AuraEnabled(cacheable=true)
    public static ContactInfo getDemoContact() {
        Contact c = resolveDemoContact(null);
        return new ContactInfo(c.Id, c.Name, c.Email, c.Phone);
    }

    /**
     * Links the live Messaging Session to a Contact. MessagingSession.EndUserContactId
     * is read-only, so we set ContactId on the related MessagingEndUser, which the
     * session reflects. Returns false if the session/identity is not ready yet.
     */
    @AuraEnabled
    public static Boolean assignContactToSession(Id messagingSessionId, Id contactId) {
        if (messagingSessionId == null || contactId == null) {
            return false;
        }
        List<MessagingSession> sessions = [
            SELECT Id, MessagingEndUserId FROM MessagingSession WHERE Id = :messagingSessionId LIMIT 1
        ];
        if (sessions.isEmpty() || sessions[0].MessagingEndUserId == null) {
            return false;
        }
        Contact c = [SELECT Id, Name, AccountId FROM Contact WHERE Id = :contactId LIMIT 1];
        // Setting Name (the messaging end user's display name) drives the session's
        // friendly subject formula: "Message from {Contact Full Name}".
        update new MessagingEndUser(
            Id = sessions[0].MessagingEndUserId,
            ContactId = c.Id,
            AccountId = c.AccountId,
            Name = c.Name
        );
        return true;
    }

    // Friendly demo contacts to link the messaging session to, in priority order.
    private static final List<String> PREFERRED_CONTACT_NAMES = new List<String>{
        'David Adelson', 'Melanie Lexington', 'Oscar Tran', 'Carol Tezak', 'Stewart Clink',
        'Tony Piazza', 'Scott Smith', 'Dan Fitzgerald', 'Zach Acme', 'Ed Flachbarth',
        'Kathy Fitzpatrick', 'Stephanie Curran', 'Jeff Kane', 'Sean Murphy', 'Al Miller'
    };

    private static Contact resolveDemoContact(Id contactId) {
        if (contactId != null) {
            return [SELECT Id, FirstName, LastName, Name, Email, Phone, AccountId FROM Contact WHERE Id = :contactId LIMIT 1];
        }

        // Rotate across the known, friendly demo contacts (with a phone): pick one at random.
        Map<String, Contact> byName = new Map<String, Contact>();
        for (Contact c : [
            SELECT Id, FirstName, LastName, Name, Email, Phone, AccountId
            FROM Contact
            WHERE Name IN :PREFERRED_CONTACT_NAMES AND Phone != null
        ]) {
            if (!byName.containsKey(c.Name)) {
                byName.put(c.Name, c);
            }
        }
        List<Contact> pool = new List<Contact>();
        for (String nm : PREFERRED_CONTACT_NAMES) {
            if (byName.containsKey(nm)) {
                pool.add(byName.get(nm));
            }
        }
        if (!pool.isEmpty()) {
            Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), pool.size());
            return pool[idx];
        }

        // Fallback: any contact with a phone (never the generic dispatcher placeholder).
        List<Contact> matches = [
            SELECT Id, FirstName, LastName, Name, Email, Phone, AccountId
            FROM Contact
            WHERE Phone != null AND (NOT Name LIKE '%Dispatcher%')
            ORDER BY Name ASC
            LIMIT 1
        ];
        if (matches.isEmpty()) {
            throw new AuraHandledException('No Contact with a phone number was found to link to the messaging session.');
        }
        return matches[0];
    }

    @AuraEnabled
    public static void sendMessage(String accessToken, String conversationId, String text, String languageCode, Boolean isFirst, String esDeveloperName) {
        String esName = String.isBlank(esDeveloperName) ? DEFAULT_ES_DEVELOPER_NAME : esDeveloperName;
        Map<String, Object> staticContent = new Map<String, Object>{
            'formatType' => 'Text',
            'text' => text
        };
        Map<String, Object> message = new Map<String, Object>{
            'inReplyToMessageId' => '',
            'id' => newUuid(),
            'messageType' => 'StaticContentMessage',
            'staticContent' => staticContent
        };
        Map<String, Object> body = new Map<String, Object>{
            'message' => message,
            'esDeveloperName' => esName,
            'isNewMessagingSession' => (isFirst == true),
            'routingAttributes' => new Map<String, Object>(),
            'language' => String.isBlank(languageCode) ? 'en' : languageCode
        };

        HttpResponse res = doCallout(
            'POST',
            API_BASE + '/conversation/' + conversationId + '/message',
            accessToken,
            JSON.serialize(body)
        );
        if (res.getStatusCode() < 200 || res.getStatusCode() >= 300) {
            throw new AuraHandledException('Send message failed (' + res.getStatusCode() + '): ' + res.getBody());
        }
    }

    /**
     * Finds the Messaging Session created for this MIAW channel. Returns the
     * session Id and the underlying Conversation Id used to read entries.
     */
    @AuraEnabled
    public static SessionRef locateSession(Datetime startedAfter, String channelDevName) {
        Datetime cutoff = startedAfter == null ? Datetime.now().addMinutes(-10) : startedAfter.addSeconds(-30);
        String chName = String.isBlank(channelDevName) ? DEFAULT_CHANNEL_DEV_NAME : channelDevName;

        List<MessagingChannel> channels = [
            SELECT Id FROM MessagingChannel WHERE DeveloperName = :chName LIMIT 1
        ];
        Id channelId = channels.isEmpty() ? null : channels[0].Id;

        List<MessagingSession> sessions = [
            SELECT Id, Status, ConversationId, StartTime
            FROM MessagingSession
            WHERE MessagingChannelId = :channelId
            AND CreatedDate >= :cutoff
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        if (sessions.isEmpty()) {
            return null;
        }
        MessagingSession ms = sessions[0];
        return new SessionRef(ms.Id, ms.ConversationId, ms.Status);
    }

    /**
     * Reads the live conversation transcript from the MIAW API (as the customer)
     * and returns the text messages authored by anyone other than the end user
     * (i.e. the human agent or a bot). The LWC dedupes by identifier so it can
     * detect a fresh agent reply and trigger the customer's next line.
     *
     * This uses the messaging API rather than the ConversationEntry sObject
     * because, in this org, ConversationEntry is not populated/queryable.
     */
    @AuraEnabled
    public static List<AgentEntry> getAgentEntries(String accessToken, String conversationId) {
        List<AgentEntry> out = new List<AgentEntry>();
        if (String.isBlank(accessToken) || String.isBlank(conversationId)) {
            return out;
        }

        HttpResponse res = doCallout('GET', API_BASE + '/conversation/' + conversationId + '/entries', accessToken, null);
        if (res.getStatusCode() < 200 || res.getStatusCode() >= 300) {
            return out; // swallow transient errors during polling
        }

        Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        List<Object> entries = (List<Object>) body.get('conversationEntries');
        if (entries == null) {
            return out;
        }

        for (Object o : entries) {
            Map<String, Object> entry = (Map<String, Object>) o;
            if (!'Message'.equals((String) entry.get('entryType'))) {
                continue;
            }
            Map<String, Object> sender = (Map<String, Object>) entry.get('sender');
            String role = sender == null ? null : (String) sender.get('role');
            if (String.isBlank(role) || role == 'EndUser') {
                continue;
            }
            String text = extractMessageText(entry);
            if (String.isBlank(text)) {
                continue;
            }
            AgentEntry ae = new AgentEntry();
            ae.identifier = (String) entry.get('identifier');
            ae.actorName = (String) entry.get('senderDisplayName');
            ae.role = role;
            ae.text = text;
            Object ts = entry.get('transcriptedTimestamp');
            ae.timestamp = ts == null ? 0 : Long.valueOf(String.valueOf(ts));
            out.add(ae);
        }
        return out;
    }

    private static String extractMessageText(Map<String, Object> entry) {
        Map<String, Object> payload = (Map<String, Object>) entry.get('entryPayload');
        if (payload == null) {
            return null;
        }
        Map<String, Object> msg = (Map<String, Object>) payload.get('abstractMessage');
        if (msg == null) {
            return null;
        }
        Map<String, Object> staticContent = (Map<String, Object>) msg.get('staticContent');
        if (staticContent == null) {
            return null;
        }
        return (String) staticContent.get('text');
    }

    /**
     * Generates the virtual customer's next message with the Models API (LLM
     * Gateway), in the scenario's language, reacting to the conversation so far.
     * The model plays the customer, so prior customer turns map to 'assistant'
     * and agent turns map to 'user'.
     *
     * @param languageCode ISO language code the customer must speak (e.g. 'es')
     * @param persona      the customer's situation/goal for this scenario
     * @param historyJson  JSON array of {"sender":"customer|agent","text":"..."}
     */
    @AuraEnabled
    public static String generateCustomerMessage(String languageCode, String persona, String historyJson) {
        List<aiplatform.ModelsAPI_ChatMessageRequest> messages = buildChatMessages(languageCode, persona, historyJson);

        aiplatform.ModelsAPI modelsAPI = new aiplatform.ModelsAPI();
        aiplatform.ModelsAPI.createChatGenerations_Request request = new aiplatform.ModelsAPI.createChatGenerations_Request();
        request.modelName = MODEL_NAME;
        aiplatform.ModelsAPI_ChatGenerationsRequest reqBody = new aiplatform.ModelsAPI_ChatGenerationsRequest();
        reqBody.messages = messages;
        request.body = reqBody;

        try {
            aiplatform.ModelsAPI.createChatGenerations_Response resp = modelsAPI.createChatGenerations(request);
            String content = resp.Code200.generationDetails.generations[0].content;
            return content == null ? '' : content.trim();
        } catch (Exception e) {
            throw new AuraHandledException('AI generation failed: ' + e.getMessage());
        }
    }

    @TestVisible
    private static List<aiplatform.ModelsAPI_ChatMessageRequest> buildChatMessages(String languageCode, String persona, String historyJson) {
        String lang = languageName(languageCode);
        String systemPrompt =
            'You are role-playing as a customer messaging a company\'s support agent in a live chat.\n' +
            'Your situation: ' + (String.isBlank(persona) ? 'You have a general support question.' : persona) + '\n' +
            'Rules:\n' +
            '- Reply ONLY as the customer. Do not include quotes, labels, your name, or any translation.\n' +
            '- Write every message in ' + lang + ' only. Never use any other language.\n' +
            '- Keep each message short and natural (1 to 2 sentences), like a real chat.\n' +
            '- React directly to what the agent just said, and give details when asked.\n' +
            '- When your issue is resolved, thank the agent and say goodbye.';

        List<aiplatform.ModelsAPI_ChatMessageRequest> messages = new List<aiplatform.ModelsAPI_ChatMessageRequest>();
        messages.add(buildChatMessage('system', systemPrompt));

        List<Object> history = String.isBlank(historyJson)
            ? new List<Object>()
            : (List<Object>) JSON.deserializeUntyped(historyJson);

        for (Object o : history) {
            Map<String, Object> turn = (Map<String, Object>) o;
            String sender = (String) turn.get('sender');
            String text = (String) turn.get('text');
            if (String.isBlank(text)) {
                continue;
            }
            messages.add(buildChatMessage(sender == 'customer' ? 'assistant' : 'user', text));
        }

        if (history.isEmpty()) {
            messages.add(buildChatMessage('user', 'Start the conversation by sending your opening message describing your issue.'));
        }
        return messages;
    }

    private static aiplatform.ModelsAPI_ChatMessageRequest buildChatMessage(String role, String content) {
        aiplatform.ModelsAPI_ChatMessageRequest m = new aiplatform.ModelsAPI_ChatMessageRequest();
        m.role = role;
        m.content = content;
        return m;
    }

    private static String languageName(String code) {
        if (String.isBlank(code)) {
            return 'English';
        }
        Map<String, String> names = new Map<String, String>{
            'es' => 'Spanish', 'fr' => 'French', 'ja' => 'Japanese', 'de' => 'German',
            'pt' => 'Portuguese', 'it' => 'Italian', 'zh' => 'Chinese', 'en' => 'English'
        };
        String key = code.toLowerCase();
        return names.containsKey(key) ? names.get(key) : code;
    }

    @AuraEnabled(cacheable=true)
    public static List<Scenario> getScenarios() {
        List<Scenario> scenarios = new List<Scenario>();

        Scenario es1 = new Scenario('Spanish - Disputed Card Charge', 'es', 'Mateo', 'Garcia', 'mateo.garcia@example.com');
        es1.persona = 'Your credit card was charged $480 at a store you have never shopped at. You want the charge reversed, the card blocked, and a new card issued. You are worried but polite.';
        es1.lines = new List<String>{
            'Hola, no reconozco un cargo en mi tarjeta de crédito y necesito ayuda urgente.',
            'Son 480 dólares de una tienda en la que nunca he comprado.',
            'Sí, por favor bloquee la tarjeta y envíeme una nueva.',
            'Muchas gracias por su ayuda, ha sido muy amable.'
        };
        scenarios.add(es1);

        Scenario es2 = new Scenario('Spanish - Locked Out of Account', 'es', 'Lucía', 'Fernández', 'lucia.fernandez@example.com');
        es2.persona = 'You cannot log in to your online account and you have a payment due today. The password reset email never arrives. You are a bit frustrated but cooperative.';
        es2.lines = new List<String>{
            'Buenas tardes, no puedo iniciar sesión en mi cuenta y tengo un pago pendiente.',
            'Ya intenté restablecer la contraseña pero no me llega el correo.',
            'Mi nombre de usuario es lucia.fernandez y el correo termina en example.com.',
            'Perfecto, ya puedo entrar. ¡Gracias!'
        };
        scenarios.add(es2);

        Scenario fr1 = new Scenario('French - Late Delivery', 'fr', 'Camille', 'Dubois', 'camille.dubois@example.com');
        fr1.persona = 'Your order number 100245 was supposed to arrive yesterday and still has not. You want a status update and a firm new delivery date. Polite but you want a resolution.';
        fr1.lines = new List<String>{
            'Bonjour, ma commande devait arriver hier et je n\'ai toujours rien reçu.',
            'Le numéro de commande est le 100245.',
            'D\'accord, pouvez-vous me confirmer la nouvelle date de livraison ?',
            'Merci beaucoup pour votre aide.'
        };
        scenarios.add(fr1);

        Scenario en1 = new Scenario('English - Service Outage', 'en', 'James', 'Whitaker', 'james.whitaker@example.com');
        en1.persona = 'Your internet has been completely down for two days. You work from home and need it restored urgently, and you want a credit for the downtime. You are frustrated but willing to work with the agent.';
        en1.lines = new List<String>{
            'Hi, my internet has been down for two days and I work from home, so this is a real problem.',
            'I\'ve already restarted the modem twice and checked all the cables.',
            'Okay, when can a technician come out, and can I get a credit for the lost days?',
            'Thanks, I appreciate you getting this sorted out.'
        };
        scenarios.add(en1);

        Scenario en2 = new Scenario('English - Upgrade Plan', 'en', 'Priya', 'Sharma', 'priya.sharma@example.com');
        en2.persona = 'You want to upgrade your current plan and add a new line for a family member. You are happy and just need to understand pricing and next steps.';
        en2.lines = new List<String>{
            'Hello, I\'d like to upgrade my plan and add a line for my daughter.',
            'She mostly needs data for streaming, so something with a larger allowance.',
            'That sounds good — how much would my monthly bill be after the change?',
            'Great, let\'s go ahead and set that up. Thank you!'
        };
        scenarios.add(en2);

        Scenario en3 = new Scenario('English - Damaged Item Return', 'en', 'Marcus', 'Bell', 'marcus.bell@example.com');
        en3.persona = 'A product you received arrived damaged. You want a replacement shipped quickly and a prepaid label to return the damaged one. Polite but you expect a fast resolution.';
        en3.lines = new List<String>{
            'Hi there, the item I received yesterday arrived cracked and unusable.',
            'The order number is 558210 and it was the wireless speaker.',
            'Can you ship a replacement and send me a prepaid return label for the damaged one?',
            'Perfect, thanks so much for the quick help.'
        };
        scenarios.add(en3);

        return scenarios;
    }

    // ---------------------------------------------------------------------
    // MIAW callouts
    // ---------------------------------------------------------------------

    private static String requestAccessToken(String esDeveloperName) {
        Map<String, Object> body = new Map<String, Object>{
            'orgId' => UserInfo.getOrganizationId(),
            'esDeveloperName' => esDeveloperName,
            'capabilitiesVersion' => '1',
            'platform' => 'Web'
        };
        HttpResponse res = doCallout(
            'POST',
            API_BASE + '/authorization/unauthenticated/access-token',
            null,
            JSON.serialize(body)
        );
        if (res.getStatusCode() < 200 || res.getStatusCode() >= 300) {
            throw new AuraHandledException('Could not start the virtual customer (' + res.getStatusCode() + '): ' + res.getBody());
        }
        Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        String token = (String) parsed.get('accessToken');
        if (String.isBlank(token)) {
            throw new AuraHandledException('No access token returned by the messaging service.');
        }
        return token;
    }

    private static void createConversation(String token, String conversationId, String firstName, String lastName, String email, String esDeveloperName) {
        Map<String, Object> routingAttributes = new Map<String, Object>{
            '_firstName' => String.isBlank(firstName) ? 'Demo' : firstName,
            '_lastName' => String.isBlank(lastName) ? 'Customer' : lastName,
            '_email' => String.isBlank(email) ? 'demo.customer@example.com' : email
        };
        Map<String, Object> body = new Map<String, Object>{
            'conversationId' => conversationId,
            'esDeveloperName' => esDeveloperName,
            'routingAttributes' => routingAttributes
        };
        HttpResponse res = doCallout('POST', API_BASE + '/conversation', token, JSON.serialize(body));
        if (res.getStatusCode() < 200 || res.getStatusCode() >= 300) {
            throw new AuraHandledException('Create conversation failed (' + res.getStatusCode() + '): ' + res.getBody());
        }
    }

    private static HttpResponse doCallout(String method, String path, String bearerToken, String body) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(scrt2BaseUrl() + path);
        req.setMethod(method);
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(120000);
        if (String.isNotBlank(bearerToken)) {
            req.setHeader('Authorization', 'Bearer ' + bearerToken);
        }
        if (String.isNotBlank(body)) {
            req.setBody(body);
        }
        return new Http().send(req);
    }

    // ---------------------------------------------------------------------
    // Helpers
    // ---------------------------------------------------------------------

    private static String scrt2BaseUrl() {
        String host = URL.getOrgDomainUrl().getHost();
        host = host.replace('.my.salesforce.com', '.my.salesforce-scrt.com');
        return 'https://' + host;
    }

    /** Generates a lowercase RFC-4122 version-4 style UUID. */
    private static String newUuid() {
        String hex = EncodingUtil.convertToHex(Crypto.generateAesKey(128));
        return hex.substring(0, 8) + '-' +
            hex.substring(8, 12) + '-' +
            '4' + hex.substring(13, 16) + '-' +
            'a' + hex.substring(17, 20) + '-' +
            hex.substring(20, 32);
    }

    // ---------------------------------------------------------------------
    // DTOs
    // ---------------------------------------------------------------------

    public class StartResult {
        @AuraEnabled public String accessToken { get; set; }
        @AuraEnabled public String conversationId { get; set; }
        @AuraEnabled public Id contactId { get; set; }
        @AuraEnabled public String contactName { get; set; }
        public StartResult(String accessToken, String conversationId, Id contactId, String contactName) {
            this.accessToken = accessToken;
            this.conversationId = conversationId;
            this.contactId = contactId;
            this.contactName = contactName;
        }
    }

    public class ContactInfo {
        @AuraEnabled public Id id { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String email { get; set; }
        @AuraEnabled public String phone { get; set; }
        public ContactInfo(Id id, String name, String email, String phone) {
            this.id = id;
            this.name = name;
            this.email = email;
            this.phone = phone;
        }
    }

    public class SessionRef {
        @AuraEnabled public Id messagingSessionId { get; set; }
        @AuraEnabled public Id conversationId { get; set; }
        @AuraEnabled public String status { get; set; }
        public SessionRef(Id messagingSessionId, Id conversationId, String status) {
            this.messagingSessionId = messagingSessionId;
            this.conversationId = conversationId;
            this.status = status;
        }
    }

    public class AgentEntry {
        @AuraEnabled public String identifier { get; set; }
        @AuraEnabled public String actorName { get; set; }
        @AuraEnabled public String role { get; set; }
        @AuraEnabled public String text { get; set; }
        @AuraEnabled public Long timestamp { get; set; }
    }

    public class Scenario {
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String language { get; set; }
        @AuraEnabled public String firstName { get; set; }
        @AuraEnabled public String lastName { get; set; }
        @AuraEnabled public String email { get; set; }
        @AuraEnabled public String persona { get; set; }
        @AuraEnabled public List<String> lines { get; set; }
        // Localized "please transfer me to a human" line the LWC sends on the
        // Agentforce route to trigger the agent's escalation/transfer action.
        @AuraEnabled public String escalationLine { get; set; }
        public Scenario(String label, String language, String firstName, String lastName, String email) {
            this.label = label;
            this.language = language;
            this.firstName = firstName;
            this.lastName = lastName;
            this.email = email;
            this.lines = new List<String>();
            this.escalationLine = escalationPhrase(language);
        }
    }

    private static String escalationPhrase(String code) {
        String key = String.isBlank(code) ? 'en' : code.toLowerCase();
        Map<String, String> phrases = new Map<String, String>{
            'en' => 'Actually, I\'d really like to speak with a human representative, please.',
            'es' => 'En realidad, me gustaría hablar con un representante humano, por favor.',
            'fr' => 'En fait, j\'aimerais parler à un représentant humain, s\'il vous plaît.',
            'de' => 'Ich möchte eigentlich mit einem menschlichen Mitarbeiter sprechen, bitte.',
            'pt' => 'Na verdade, eu gostaria de falar com um atendente humano, por favor.',
            'it' => 'In realtà, vorrei parlare con un operatore umano, per favore.',
            'ja' => '実は、人間の担当者と話したいのですが、お願いします。',
            'zh' => '其实，我想和人工客服通话，谢谢。'
        };
        return phrases.containsKey(key) ? phrases.get(key) : phrases.get('en');
    }

    public class Route {
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String esDeveloperName { get; set; }
        @AuraEnabled public String channelDevName { get; set; }
        @AuraEnabled public Boolean agentforce { get; set; }
        public Route(String label, String esDeveloperName, String channelDevName, Boolean agentforce) {
            this.label = label;
            this.esDeveloperName = esDeveloperName;
            this.channelDevName = channelDevName;
            this.agentforce = agentforce;
        }
    }
}