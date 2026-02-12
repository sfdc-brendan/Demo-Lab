/**
 * @description Apex controller for Case Tagging LWC: add tag, run analysis, run historical.
 */
public with sharing class CaseTaggingController {

    @AuraEnabled(cacheable=false)
    public static void addTag(Id caseId, String newTag) {
        if (caseId == null || String.isBlank(newTag)) {
            return;
        }
        List<Case> cases = [SELECT Id, Case_Tags__c FROM Case WHERE Id = :caseId WITH SECURITY_ENFORCED LIMIT 1];
        if (cases.isEmpty()) {
            throw new AuraHandledException('Case not found.');
        }
        Case c = cases[0];
        String current = c.Case_Tags__c != null ? c.Case_Tags__c : '';
        String trimmed = newTag.trim();
        if (String.isBlank(trimmed)) {
            return;
        }
        List<String> existing = new List<String>();
        if (String.isNotBlank(current)) {
            for (String s : current.split(',')) {
                String t = s.trim();
                if (String.isNotBlank(t)) {
                    existing.add(t);
                }
            }
        }
        Set<String> seen = new Set<String>();
        for (String s : existing) {
            seen.add(s.toLowerCase());
        }
        if (seen.contains(trimmed.toLowerCase())) {
            return;
        }
        existing.add(trimmed);
        c.Case_Tags__c = String.join(existing, ', ');
        update as user c;
    }

    @AuraEnabled(cacheable=false)
    public static void removeTag(Id caseId, String tagToRemove) {
        if (caseId == null || String.isBlank(tagToRemove)) {
            return;
        }
        List<Case> cases = [SELECT Id, Case_Tags__c FROM Case WHERE Id = :caseId WITH SECURITY_ENFORCED LIMIT 1];
        if (cases.isEmpty()) {
            throw new AuraHandledException('Case not found.');
        }
        Case c = cases[0];
        String current = c.Case_Tags__c != null ? c.Case_Tags__c : '';
        String toRemove = tagToRemove.trim();
        if (String.isBlank(toRemove)) {
            return;
        }
        List<String> existing = new List<String>();
        if (String.isNotBlank(current)) {
            for (String s : current.split(',')) {
                String t = s.trim();
                if (String.isNotBlank(t) && !t.equalsIgnoreCase(toRemove)) {
                    existing.add(t);
                }
            }
        }
        c.Case_Tags__c = existing.isEmpty() ? null : String.join(existing, ', ');
        update as user c;
    }

    @AuraEnabled(cacheable=false)
    public static String runAnalysis(Id caseId) {
        if (caseId == null) {
            throw new AuraHandledException('Case ID is required.');
        }
        try {
            CaseTaggingService.runAnalysis(new Set<Id>{ caseId });
            return 'Analysis completed.';
        } catch (CaseTaggingService.CaseTaggingServiceException e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=false)
    public static String runHistorical(Integer scopeMonths) {
        Id jobId = CaseTaggingBatch.enqueue(scopeMonths != null ? scopeMonths : CaseTaggingService.getDefaultHistoricalScopeMonths());
        return 'Historical analysis started. Job ID: ' + String.valueOf(jobId);
    }

    @AuraEnabled(cacheable=true)
    public static Integer getDefaultScopeMonths() {
        return CaseTaggingService.getDefaultHistoricalScopeMonths();
    }
}
