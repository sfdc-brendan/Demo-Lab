/**
 * @description Invocable entry point for Case Tagging: run analysis for one or more Cases, or enqueue historical batch.
 */
public with sharing class CaseTaggingInvocable {

    @InvocableMethod(
        label='Run Case Tagging Analysis'
        description='Runs AI case tagging for the given Case IDs, or enqueues historical batch when scope months is set.'
        category='Case Tagging'
    )
    public static List<InvocableResult> runAnalysis(List<InvocableRequest> requests) {
        List<InvocableResult> results = new List<InvocableResult>();
        for (InvocableRequest req : requests) {
            InvocableResult res = new InvocableResult();
            try {
                if (req.scopeMonths != null && req.scopeMonths > 0) {
                    CaseTaggingBatch.enqueue(req.scopeMonths);
                    res.success = true;
                    res.message = 'Historical case tagging batch enqueued for the last ' + req.scopeMonths + ' month(s).';
                } else if (req.caseIds != null && !req.caseIds.isEmpty()) {
                    CaseTaggingService.runAnalysis(new Set<Id>(req.caseIds));
                    res.success = true;
                    res.message = 'Case tagging analysis completed for ' + req.caseIds.size() + ' case(s).';
                } else {
                    res.success = false;
                    res.message = 'Provide either Case IDs or scope months for historical run.';
                }
            } catch (Exception e) {
                res.success = false;
                res.message = e.getMessage();
            }
            results.add(res);
        }
        return results;
    }

    public class InvocableRequest {
        @InvocableVariable(label='Case IDs' description='Case record IDs to analyze (leave blank for historical run).')
        public List<Id> caseIds;
        @InvocableVariable(label='Historical Scope (Months)' description='If set, enqueues batch for cases in the last N months instead of running for Case IDs.')
        public Integer scopeMonths;
    }

    public class InvocableResult {
        @InvocableVariable(label='Success')
        public Boolean success;
        @InvocableVariable(label='Message')
        public String message;
    }
}
