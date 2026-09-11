/**
 * @description Read API for the coachingInsightPanel LWC. Returns the latest (and historical)
 *              Coaching_Insight__c records for a given Voice Call, Messaging Session, or Case.
 */
public with sharing class CoachingInsightController {
    private static final String FIELDS =
        'Id, Name, Channel__c, Performance_Rating__c, Performance_Evaluation__c, ' +
        'Sentiment_Rating__c, Sentiment_Narrative__c, Category_Scores__c, Model__c, ' +
        'Prompt_Version__c, Analysis_Type__c, Status__c, Error__c, CreatedDate, Agent__r.Name';

    @AuraEnabled(cacheable=true)
    public static Coaching_Insight__c getLatestInsight(Id recordId) {
        List<Coaching_Insight__c> rows = query(recordId, 1);
        return rows.isEmpty() ? null : rows[0];
    }

    @AuraEnabled(cacheable=true)
    public static List<Coaching_Insight__c> getHistory(Id recordId, Integer maxRows) {
        Integer lim = (maxRows == null || maxRows <= 0) ? 10 : maxRows;
        return query(recordId, lim);
    }

    private static List<Coaching_Insight__c> query(Id recordId, Integer lim) {
        String recordIdString = String.valueOf(recordId);
        String soql =
            'SELECT ' + FIELDS + ' FROM Coaching_Insight__c ' +
            'WHERE Related_Record_Id__c = :recordIdString ' +
            'OR Related_Case__c = :recordId ' +
            'ORDER BY CreatedDate DESC LIMIT :lim';
        return Database.query(soql);
    }
}
