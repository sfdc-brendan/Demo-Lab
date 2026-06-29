@isTest
private class CoachingInsightControllerTest {
    @isTest
    static void returnsNullAndEmptyWhenNoInsights() {
        // A fabricated, correctly-prefixed Case id that matches no insight.
        Id fakeCaseId = Id.valueOf(Case.SObjectType.getDescribe().getKeyPrefix() + '000000000000');
        System.Assert.isNull(CoachingInsightController.getLatestInsight(fakeCaseId));
        System.Assert.areEqual(0, CoachingInsightController.getHistory(fakeCaseId, 5).size());
    }

    @isTest
    static void getHistoryDefaultsLimitWhenInvalid() {
        Id fakeCaseId = Id.valueOf(Case.SObjectType.getDescribe().getKeyPrefix() + '000000000000');
        // Exercise the default-limit branch (null/0) without requiring related parent records.
        System.Assert.areEqual(0, CoachingInsightController.getHistory(fakeCaseId, null).size());
        System.Assert.areEqual(0, CoachingInsightController.getHistory(fakeCaseId, 0).size());
    }
}
