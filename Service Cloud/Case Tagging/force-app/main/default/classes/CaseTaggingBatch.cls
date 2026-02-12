/**
 * @description Batch job to run case tagging analysis for Cases created in the last N months.
 */
public class CaseTaggingBatch implements Database.Batchable<sObject> {
    private Integer scopeMonths;

    public CaseTaggingBatch(Integer scopeMonths) {
        this.scopeMonths = scopeMonths != null && scopeMonths > 0 ? scopeMonths : CaseTaggingService.getDefaultHistoricalScopeMonths();
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        Integer months = this.scopeMonths;
        Date startDate = Date.today().addMonths(-months);
        return Database.getQueryLocator([
            SELECT Id
            FROM Case
            WHERE CreatedDate >= :startDate
            WITH SECURITY_ENFORCED
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Case> scope) {
        Set<Id> caseIds = new Set<Id>();
        for (Case c : scope) {
            caseIds.add(c.Id);
        }
        CaseTaggingService.runAnalysis(caseIds);
    }

    public void finish(Database.BatchableContext bc) {
        // Optional: notify or log completion
    }

    /**
     * @description Enqueue the historical case tagging batch. Uses default scope from config if scopeMonths is null.
     */
    public static Id enqueue(Integer scopeMonths) {
        Integer months = scopeMonths != null && scopeMonths > 0
            ? scopeMonths
            : CaseTaggingService.getDefaultHistoricalScopeMonths();
        return Database.executeBatch(new CaseTaggingBatch(months), 10);
    }
}
