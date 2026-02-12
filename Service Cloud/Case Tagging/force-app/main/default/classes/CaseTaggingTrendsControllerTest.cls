/**
 * @description Unit tests for Case Tag Trends controller.
 */
@IsTest
private class CaseTaggingTrendsControllerTest {

    @TestSetup
    static void setup() {
        List<Case> cases = new List<Case>();
        cases.add(new Case(Subject = 'A', Case_Tags__c = 'Billing, Refund', Status = 'New', Origin = 'Web'));
        cases.add(new Case(Subject = 'B', Case_Tags__c = 'Billing', Status = 'New', Origin = 'Web'));
        cases.add(new Case(Subject = 'C', Case_Tags__c = 'Refund, Billing', Status = 'New', Origin = 'Web'));
        insert cases;
    }

    @IsTest
    static void testGetTagSummary() {
        Test.startTest();
        List<CaseTaggingTrendsController.TagSummaryItem> summary = CaseTaggingTrendsController.getTagSummary(2);
        Test.stopTest();
        System.assertNotEquals(null, summary);
        System.assert(summary.size() >= 2, 'Should have at least Billing and Refund');
        Integer billingCount = 0;
        for (CaseTaggingTrendsController.TagSummaryItem item : summary) {
            if (item.tag == 'Billing') billingCount = item.count;
        }
        System.assertEquals(3, billingCount, 'Billing should appear on 3 cases');
    }

    @IsTest
    static void testGetCasesByTag() {
        Test.startTest();
        List<CaseTaggingTrendsController.CaseSummaryItem> cases = CaseTaggingTrendsController.getCasesByTag('Billing', 2);
        Test.stopTest();
        System.assertNotEquals(null, cases);
        System.assertEquals(3, cases.size(), 'Should return 3 cases tagged Billing');
    }

    @IsTest
    static void testGetCasesByTagEmpty() {
        List<CaseTaggingTrendsController.CaseSummaryItem> cases = CaseTaggingTrendsController.getCasesByTag('', 2);
        System.assert(cases.isEmpty());
    }
}
