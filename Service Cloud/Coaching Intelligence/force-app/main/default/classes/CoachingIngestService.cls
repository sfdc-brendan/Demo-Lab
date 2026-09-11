/**
 * @description Coaching Intelligence v2 engine. Invoked from the channel coaching flows after the
 *              prompt template returns its JSON response. Parses the JSON once (CoachingResult),
 *              persists a unified Coaching_Insight__c record, mirrors the latest result back onto
 *              the source channel record (Voice/Chat) for backward compatibility, and publishes a
 *              Coaching_Insight_Ready__e platform event for real-time UI updates.
 *
 *              Replaces TextExtractor / ChatExtractor / ChatCoachingExtractor and their brittle
 *              indexOf() parsing with a single, testable, bulk-safe, fault-tolerant service.
 */
public with sharing class CoachingIngestService {
    private static final Set<String> VALID_SENTIMENTS = new Set<String>{ 'Positive', 'Neutral', 'Negative' };

    public class Request {
        @InvocableVariable(label='Raw Prompt Response (JSON)' required=true)
        public String rawJson;

        @InvocableVariable(label='Channel (Voice/Chat/Case)' required=true)
        public String channel;

        @InvocableVariable(label='Source Record Id' required=true)
        public String recordId;

        @InvocableVariable(label='Agent User Id')
        public String agentId;

        @InvocableVariable(label='Model')
        public String model;

        @InvocableVariable(label='Prompt Version')
        public String promptVersion;

        @InvocableVariable(label='Analysis Type (Real-time/Historical)')
        public String analysisType;

        @InvocableVariable(label='Latency (ms)')
        public Decimal latencyMs;
    }

    public class Response {
        @InvocableVariable(label='Coaching Insight Id')
        public String insightId;

        @InvocableVariable(label='Status')
        public String status;
    }

    @InvocableMethod(label='Ingest Coaching Result' description='Parses a coaching/sentiment JSON response, persists a Coaching Insight, mirrors channel fields, and fires a real-time event.')
    public static List<Response> ingest(List<Request> requests) {
        List<Coaching_Insight__c> insights = new List<Coaching_Insight__c>();
        // Map each insight (by list index) back to its request for mirroring + events.
        for (Request req : requests) {
            insights.add(buildInsight(req));
        }

        insert insights;

        // Group mirror records by SObjectType; a single DML call cannot mix object types.
        Map<SObjectType, List<SObject>> mirrorsByType = new Map<SObjectType, List<SObject>>();
        List<Coaching_Insight_Ready__e> events = new List<Coaching_Insight_Ready__e>();
        List<Response> responses = new List<Response>();

        for (Integer i = 0; i < requests.size(); i++) {
            Request req = requests[i];
            Coaching_Insight__c insight = insights[i];

            SObject mirror = buildMirror(req, insight);
            if (mirror != null) {
                SObjectType t = mirror.getSObjectType();
                if (!mirrorsByType.containsKey(t)) {
                    mirrorsByType.put(t, new List<SObject>());
                }
                mirrorsByType.get(t).add(mirror);
            }

            events.add(new Coaching_Insight_Ready__e(
                Record_Id__c = req.recordId,
                Channel__c = req.channel,
                Insight_Id__c = insight.Id,
                Performance_Rating__c = insight.Performance_Rating__c,
                Sentiment_Rating__c = insight.Sentiment_Rating__c,
                Status__c = insight.Status__c
            ));

            Response res = new Response();
            res.insightId = insight.Id;
            res.status = insight.Status__c;
            responses.add(res);
        }

        // Mirror is best-effort; a bad picklist value should never lose the persisted insight.
        for (List<SObject> mirrorList : mirrorsByType.values()) {
            Database.update(mirrorList, false);
        }
        if (!events.isEmpty()) {
            EventBus.publish(events);
        }

        notifyAgents(requests, insights);

        return responses;
    }

    private static Coaching_Insight__c buildInsight(Request req) {
        Coaching_Insight__c insight = new Coaching_Insight__c();
        insight.Channel__c = req.channel;
        insight.Analysis_Type__c = String.isBlank(req.analysisType) ? 'Real-time' : req.analysisType;
        insight.Model__c = req.model;
        insight.Prompt_Version__c = req.promptVersion;
        insight.Latency_Ms__c = req.latencyMs;
        if (String.isNotBlank(req.agentId)) {
            insight.Agent__c = (Id) req.agentId;
        }
        setRelatedRecord(insight, req);

        CoachingResult result = CoachingResult.parse(req.rawJson);
        if (result == null) {
            insight.Status__c = 'Failed';
            insight.Error__c = 'Unable to parse JSON from prompt response. Raw: '
                + (req.rawJson == null ? '' : req.rawJson.abbreviate(30000));
            return insight;
        }

        insight.Performance_Rating__c = clampRating(result.performanceRating);
        insight.Performance_Evaluation__c = result.toEvaluationText();
        insight.Sentiment_Rating__c = normalizeSentiment(result.sentimentRating);
        insight.Sentiment_Narrative__c = result.sentimentNarrative;
        if (result.categories != null) {
            insight.Category_Scores__c = JSON.serialize(result.categories);
        }
        insight.Status__c = 'Success';
        return insight;
    }

    @TestVisible
    private static void setRelatedRecord(Coaching_Insight__c insight, Request req) {
        if (String.isBlank(req.recordId)) {
            return;
        }
        Id rid = (Id) req.recordId;
        // Channel-agnostic reference so the object installs in any org (no typed Voice/Chat lookups).
        insight.Related_Record_Id__c = rid;
        insight.Related_Record_Type__c = rid.getSObjectType().getDescribe().getName();
        if ((req.channel == null ? '' : req.channel.toLowerCase()) == 'case') {
            insight.Related_Case__c = rid;
        }
    }

    /**
     * @description Mirror the latest result onto the source channel record so the v1 LWCs and any
     *              existing reports continue to work. Case has no v1 mirror fields, so it is skipped.
     */
    @TestVisible
    private static SObject buildMirror(Request req, Coaching_Insight__c insight) {
        if (insight.Status__c != 'Success' || String.isBlank(req.recordId)) {
            return null;
        }
        Id rid = (Id) req.recordId;
        String channel = req.channel == null ? '' : req.channel.toLowerCase();
        if (channel == 'voice') {
            return buildDynamicMirror('VoiceCall', rid, insight,
                'Agent_Performance_Rating__c', 'Agent_Performance_Evaluation__c',
                'Call_Sentiment__c', 'Sentiment_Rating__c');
        } else if (channel == 'chat') {
            return buildDynamicMirror('MessagingSession', rid, insight,
                'AgentPerformanceRating__c', 'AgentPerformanceEvaluation__c',
                'ChatSentiment__c', 'SentimentRating__c');
        }
        return null;
    }

    /**
     * @description Build a mirror update for a channel object only if that object and its coaching
     *              fields exist in the org. Fully dynamic, so the engine compiles and runs in any org,
     *              including those without Service Cloud Voice or Enhanced Messaging installed.
     */
    private static SObject buildDynamicMirror(
        String objectName, Id rid, Coaching_Insight__c insight,
        String ratingField, String evalField, String narrativeField, String sentimentField
    ) {
        SObjectType sot = Schema.getGlobalDescribe().get(objectName);
        if (sot == null) {
            return null;
        }
        Map<String, Schema.SObjectField> fieldMap = sot.getDescribe().fields.getMap();
        SObject record = sot.newSObject(rid);
        Boolean anySet = false;
        if (fieldMap.containsKey(ratingField.toLowerCase())) {
            record.put(ratingField, insight.Performance_Rating__c);
            anySet = true;
        }
        if (fieldMap.containsKey(evalField.toLowerCase())) {
            record.put(evalField, insight.Performance_Evaluation__c);
            anySet = true;
        }
        if (fieldMap.containsKey(narrativeField.toLowerCase())) {
            record.put(narrativeField, insight.Sentiment_Narrative__c);
            anySet = true;
        }
        if (insight.Sentiment_Rating__c != null && fieldMap.containsKey(sentimentField.toLowerCase())) {
            record.put(sentimentField, insight.Sentiment_Rating__c);
            anySet = true;
        }
        return anySet ? record : null;
    }

    /**
     * @description Best-effort Custom Notification fallback so the agent is alerted even if they
     *              navigated away from the record. Never throws into the main flow.
     */
    private static void notifyAgents(List<Request> requests, List<Coaching_Insight__c> insights) {
        try {
            List<CustomNotificationType> types = [
                SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'Coaching_Insight_Ready' LIMIT 1
            ];
            if (types.isEmpty()) {
                return;
            }
            Id typeId = types[0].Id;
            for (Integer i = 0; i < requests.size(); i++) {
                Request req = requests[i];
                Coaching_Insight__c insight = insights[i];
                if (insight.Status__c != 'Success' || String.isBlank(req.agentId)) {
                    continue;
                }
                Messaging.CustomNotification n = new Messaging.CustomNotification();
                n.setTitle('Coaching insight ready');
                String rating = insight.Performance_Rating__c == null ? 'n/a' : String.valueOf(insight.Performance_Rating__c);
                n.setBody(req.channel + ' evaluation complete. Performance ' + rating + '/10, sentiment '
                    + (insight.Sentiment_Rating__c == null ? 'n/a' : insight.Sentiment_Rating__c) + '.');
                n.setNotificationTypeId(typeId);
                n.setTargetId(String.isNotBlank(req.recordId) ? req.recordId : insight.Id);
                n.send(new Set<String>{ req.agentId });
            }
        } catch (Exception e) {
            // Notifications are a fallback; swallow errors so they never block persistence.
        }
    }

    private static Decimal clampRating(Integer rating) {
        if (rating == null) {
            return null;
        }
        if (rating < 0) {
            return 0;
        }
        if (rating > 10) {
            return 10;
        }
        return rating;
    }

    /**
     * @description Map free-text sentiment to a restricted picklist value. Returns null if it can't
     *              be confidently mapped (so a bad value never blocks the DML).
     */
    @TestVisible
    private static String normalizeSentiment(String raw) {
        if (String.isBlank(raw)) {
            return null;
        }
        String cleaned = raw.trim();
        // Take the first word and strip punctuation, e.g. "Positive." or "Positive - because...".
        cleaned = cleaned.replaceAll('[^A-Za-z].*$', '').trim();
        if (cleaned.length() == 0) {
            return null;
        }
        String titled = cleaned.substring(0, 1).toUpperCase() + cleaned.substring(1).toLowerCase();
        return VALID_SENTIMENTS.contains(titled) ? titled : null;
    }
}
