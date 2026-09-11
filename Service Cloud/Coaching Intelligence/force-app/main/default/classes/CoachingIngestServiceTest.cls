@isTest
private class CoachingIngestServiceTest {
    private static String buildJson(Integer rating, String sentiment) {
        Map<String, Object> cats = new Map<String, Object>{
            'agentProcess' => 'Greeted the customer.',
            'customerFocus' => 'Focused on resolution.',
            'softSkills' => 'Empathetic.',
            'toneLanguageClarity' => 'Clear.',
            'professionalConduct' => 'Professional.'
        };
        Map<String, Object> root = new Map<String, Object>{
            'performanceRating' => rating,
            'categories' => cats,
            'summary' => 'Solid interaction.',
            'sentimentRating' => sentiment,
            'sentimentNarrative' => 'Customer was satisfied.'
        };
        return JSON.serialize(root);
    }

    // Generic request with no related record, so the insert path does not trigger org
    // channel-object create automation (which is unrelated to this engine).
    private static CoachingIngestService.Request genericRequest(String channel, String rawJson) {
        CoachingIngestService.Request req = new CoachingIngestService.Request();
        req.rawJson = rawJson;
        req.channel = channel;
        req.recordId = null;
        req.agentId = UserInfo.getUserId();
        req.model = 'sfdc_ai__DefaultGPT41';
        req.promptVersion = 'Coaching_' + channel + '_v2';
        req.analysisType = 'Real-time';
        req.latencyMs = 1234;
        return req;
    }

    @isTest
    static void successCreatesInsightAndPublishesEvent() {
        Test.startTest();
        List<CoachingIngestService.Response> res = CoachingIngestService.ingest(
            new List<CoachingIngestService.Request>{ genericRequest('Case', buildJson(7, 'Positive')) }
        );
        Test.stopTest();

        System.Assert.areEqual('Success', res[0].status);
        Coaching_Insight__c ins = [
            SELECT Channel__c, Status__c, Performance_Rating__c, Sentiment_Rating__c, Agent__c,
                   Category_Scores__c, Performance_Evaluation__c, Model__c, Prompt_Version__c,
                   Analysis_Type__c, Latency_Ms__c, Sentiment_Narrative__c
            FROM Coaching_Insight__c
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        System.Assert.areEqual('Case', ins.Channel__c);
        System.Assert.areEqual('Success', ins.Status__c);
        System.Assert.areEqual(7, ins.Performance_Rating__c);
        System.Assert.areEqual('Positive', ins.Sentiment_Rating__c);
        System.Assert.areEqual(UserInfo.getUserId(), ins.Agent__c);
        System.Assert.isNotNull(ins.Category_Scores__c);
        System.Assert.isTrue(ins.Performance_Evaluation__c.contains('Rating Score: 7'));
        System.Assert.areEqual('Real-time', ins.Analysis_Type__c);
        System.Assert.areEqual(1234, ins.Latency_Ms__c);
    }

    @isTest
    static void parseFailureCreatesFailedInsight() {
        Test.startTest();
        CoachingIngestService.ingest(
            new List<CoachingIngestService.Request>{ genericRequest('Voice', 'this is not json at all') }
        );
        Test.stopTest();

        Coaching_Insight__c ins = [
            SELECT Status__c, Error__c, Performance_Rating__c
            FROM Coaching_Insight__c
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        System.Assert.areEqual('Failed', ins.Status__c);
        System.Assert.isNotNull(ins.Error__c);
        System.Assert.isNull(ins.Performance_Rating__c);
    }

    @isTest
    static void ratingIsClamped() {
        Test.startTest();
        CoachingIngestService.ingest(
            new List<CoachingIngestService.Request>{ genericRequest('Chat', buildJson(15, 'Neutral')) }
        );
        Test.stopTest();

        Coaching_Insight__c ins = [
            SELECT Performance_Rating__c FROM Coaching_Insight__c ORDER BY CreatedDate DESC LIMIT 1
        ];
        System.Assert.areEqual(10, ins.Performance_Rating__c, 'Rating above 10 should clamp to 10');
    }

    @isTest
    static void sentimentNormalizationHandlesMessyValues() {
        System.Assert.areEqual('Positive', CoachingIngestService.normalizeSentiment('Positive.'));
        System.Assert.areEqual('Negative', CoachingIngestService.normalizeSentiment('negative - customer upset'));
        System.Assert.areEqual('Neutral', CoachingIngestService.normalizeSentiment('  NEUTRAL  '));
        System.Assert.isNull(CoachingIngestService.normalizeSentiment('mildly annoyed'));
        System.Assert.isNull(CoachingIngestService.normalizeSentiment(''));
        System.Assert.isNull(CoachingIngestService.normalizeSentiment(null));
    }

    // Channel routing uses a channel-agnostic Related Record Id (+ native Case lookup), so this is
    // portable to any org. Uses fabricated, correctly-prefixed Ids (no DML, no org automation).
    @isTest
    static void channelRoutingSetsGenericReference() {
        Id caseId = fakeId(Case.SObjectType);
        Coaching_Insight__c caseIns = new Coaching_Insight__c();
        CoachingIngestService.setRelatedRecord(caseIns, reqFor('Case', caseId));
        System.Assert.areEqual(caseId, Id.valueOf(caseIns.Related_Record_Id__c));
        System.Assert.areEqual(caseId, caseIns.Related_Case__c);
        System.Assert.areEqual('Case', caseIns.Related_Record_Type__c);

        // A non-Case channel (Account stands in for Voice/Chat record ids) sets the generic
        // reference but not the Case lookup.
        Id otherId = fakeId(Account.SObjectType);
        Coaching_Insight__c otherIns = new Coaching_Insight__c();
        CoachingIngestService.setRelatedRecord(otherIns, reqFor('Voice', otherId));
        System.Assert.areEqual(otherId, Id.valueOf(otherIns.Related_Record_Id__c));
        System.Assert.isNull(otherIns.Related_Case__c);
    }

    @isTest
    static void buildMirrorIsDynamicAndChannelAware() {
        Coaching_Insight__c ins = new Coaching_Insight__c(
            Status__c = 'Success',
            Performance_Rating__c = 6,
            Performance_Evaluation__c = 'Eval text',
            Sentiment_Narrative__c = 'Narrative',
            Sentiment_Rating__c = 'Negative'
        );

        // Case channel never mirrors.
        System.Assert.isNull(CoachingIngestService.buildMirror(reqFor('Case', fakeId(Case.SObjectType)), ins));

        // Voice mirror only happens when the org actually has the VoiceCall object; otherwise null.
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        if (gd.containsKey('voicecall')) {
            Id vId = fakeId(gd.get('VoiceCall'));
            SObject vc = CoachingIngestService.buildMirror(reqFor('Voice', vId), ins);
            if (vc != null) {
                System.Assert.areEqual('VoiceCall', vc.getSObjectType().getDescribe().getName());
            }
        } else {
            System.Assert.isNull(CoachingIngestService.buildMirror(reqFor('Voice', fakeId(Account.SObjectType)), ins));
        }
    }

    private static CoachingIngestService.Request reqFor(String channel, Id recordId) {
        CoachingIngestService.Request req = new CoachingIngestService.Request();
        req.channel = channel;
        req.recordId = recordId;
        return req;
    }

    private static Id fakeId(Schema.SObjectType sot) {
        String prefix = sot.getDescribe().getKeyPrefix();
        return Id.valueOf(prefix + '000000000000');
    }
}
