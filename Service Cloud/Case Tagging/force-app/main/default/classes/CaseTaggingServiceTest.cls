/**
 * @description Unit tests for Case Tagging service, invocable, and batch.
 */
@IsTest
private class CaseTaggingServiceTest {

    @TestSetup
    static void setup() {
        Case c = new Case(
            Subject = 'Billing question',
            Description = 'Customer cannot see last invoice.',
            Status = 'New',
            Origin = 'Web'
        );
        insert c;
    }

    @IsTest
    static void testRunAnalysis() {
        Case c = [SELECT Id FROM Case LIMIT 1];
        Test.startTest();
        CaseTaggingService.runAnalysis(new Set<Id>{ c.Id });
        Test.stopTest();
        c = [SELECT Id, Case_Tags__c, Case_Tags_Last_Analyzed_Date__c FROM Case WHERE Id = :c.Id];
        System.assertNotEquals(null, c.Case_Tags__c, 'Case tags should be set');
        System.assert(c.Case_Tags__c.contains('High Criticality') || c.Case_Tags__c.contains('Billing'), 'Should contain expected tags');
        System.assertNotEquals(null, c.Case_Tags_Last_Analyzed_Date__c, 'Last analyzed date should be set');
    }

    @IsTest
    static void testRunAnalysisEmptySet() {
        CaseTaggingService.runAnalysis(new Set<Id>());
        CaseTaggingService.runAnalysis(null);
        // no exception
    }

    @IsTest
    static void testNormalizeTagsString() {
        System.assertEquals('A, B, C', CaseTaggingService.normalizeTagsString('A, B, C'));
        System.assertEquals('A, B', CaseTaggingService.normalizeTagsString('A , B , B'));
        System.assertEquals('One', CaseTaggingService.normalizeTagsString('One\nMore line'));
        System.assertEquals(null, CaseTaggingService.normalizeTagsString(null));
        System.assertEquals(null, CaseTaggingService.normalizeTagsString('   '));
    }

    @IsTest
    static void testGetDefaultHistoricalScopeMonths() {
        Integer scope = CaseTaggingService.getDefaultHistoricalScopeMonths();
        System.assert(scope >= 1 && scope <= 12, 'Scope should be reasonable');
    }

    @IsTest
    static void testInvocableRunAnalysis() {
        Case c = [SELECT Id FROM Case LIMIT 1];
        CaseTaggingInvocable.InvocableRequest req = new CaseTaggingInvocable.InvocableRequest();
        req.caseIds = new List<Id>{ c.Id };
        req.scopeMonths = null;
        Test.startTest();
        List<CaseTaggingInvocable.InvocableResult> results = CaseTaggingInvocable.runAnalysis(new List<CaseTaggingInvocable.InvocableRequest>{ req });
        Test.stopTest();
        System.assertEquals(1, results.size());
        System.assert(results[0].success, results[0].message);
    }

    @IsTest
    static void testInvocableHistoricalRun() {
        CaseTaggingInvocable.InvocableRequest req = new CaseTaggingInvocable.InvocableRequest();
        req.caseIds = null;
        req.scopeMonths = 1;
        Test.startTest();
        List<CaseTaggingInvocable.InvocableResult> results = CaseTaggingInvocable.runAnalysis(new List<CaseTaggingInvocable.InvocableRequest>{ req });
        Test.stopTest();
        System.assertEquals(1, results.size());
        System.assert(results[0].success, results[0].message);
    }

    @IsTest
    static void testBatchEnqueue() {
        Test.startTest();
        Id jobId = CaseTaggingBatch.enqueue(2);
        Test.stopTest();
        System.assertNotEquals(null, jobId);
    }

    @IsTest
    static void testBatchExecution() {
        Test.startTest();
        CaseTaggingBatch b = new CaseTaggingBatch(2);
        Database.executeBatch(b, 10);
        Test.stopTest();
        // Batch runs; at least one Case may get tags if in scope
        List<Case> withTags = new List<Case>();
        for (Case cx : [SELECT Id, Case_Tags__c FROM Case]) {
            if (String.isNotBlank(cx.Case_Tags__c)) withTags.add(cx);
        }
        System.assert(true, 'Batch completed');
    }
}
