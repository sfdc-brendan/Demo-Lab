/**
 * @description Service for running AI-powered case tagging.
 * In production, invokes an autolaunched Flow (configured in Case Tagging Config) that runs the Prompt Template and updates the Case.
 * In tests, uses mock tags and updates Case records directly.
 */
public with sharing class CaseTaggingService {
    private static final String CONFIG_DEVELOPER_NAME = 'Case_Tagging_Default';
    private static final String DEFAULT_FLOW_API_NAME = 'Case_Tagging_Analysis_Flow';
    private static final Integer MAX_TAGS_LENGTH = 32768;

    /**
     * @description Run case tagging analysis for the given Case IDs.
     * @param caseIds Set of Case Ids to analyze.
     */
    public static void runAnalysis(Set<Id> caseIds) {
        if (caseIds == null || caseIds.isEmpty()) {
            return;
        }

        if (Test.isRunningTest()) {
            runAnalysisMock(caseIds);
            return;
        }

        String flowApiName = getFlowApiName();
        for (Id caseId : caseIds) {
            try {
                Flow.Interview flow = Flow.Interview.createInterview(flowApiName, new Map<String, Object>{ 'CaseId' => caseId });
                flow.start();
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'CaseTaggingService.runAnalysis flow error for ' + caseId + ': ' + e.getMessage());
                String msg = e.getMessage();
                if (msg != null && msg.contains('Invalid type:')) {
                    throw new CaseTaggingServiceException(
                        'Flow "' + flowApiName + '" was not found or is not active. Create an Autolaunched Flow with that API Name and an input variable "CaseId" (see SETUP.md).'
                    );
                }
                throw new CaseTaggingServiceException('Case tagging flow error: ' + msg);
            }
        }
    }

    public class CaseTaggingServiceException extends Exception {}

    /**
     * @description Test-only path: update cases with mock tags.
     */
    @TestVisible
    private static void runAnalysisMock(Set<Id> caseIds) {
        List<Case> cases = [
            SELECT Id
            FROM Case
            WHERE Id IN :caseIds
            WITH SECURITY_ENFORCED
        ];
        String mockTags = normalizeTagsString('High Criticality, Billing, Test Tag');
        Datetime analyzedAt = Datetime.now();
        List<Case> toUpdate = new List<Case>();
        for (Case c : cases) {
            toUpdate.add(new Case(
                Id = c.Id,
                Case_Tags__c = mockTags,
                Case_Tags_Last_Analyzed_Date__c = analyzedAt
            ));
        }
        if (!toUpdate.isEmpty()) {
            update as user toUpdate;
        }
    }

    /**
     * @description Normalize prompt output to a single comma-delimited string (trim, dedupe, no empty).
     */
    @TestVisible
    private static String normalizeTagsString(String raw) {
        if (String.isBlank(raw)) {
            return null;
        }
        String s = raw.trim();
        String newline = '\n';
        if (s.contains(newline)) {
            s = s.substring(0, s.indexOf(newline)).trim();
        }
        List<String> parts = s.split(',');
        Set<String> seen = new Set<String>();
        List<String> out = new List<String>();
        for (String p : parts) {
            String t = p.trim();
            if (String.isNotBlank(t) && !seen.contains(t.toLowerCase())) {
                seen.add(t.toLowerCase());
                out.add(t);
            }
        }
        return String.join(out, ', ');
    }

    private static String getFlowApiName() {
        List<Case_Tagging_Config__mdt> configs = [
            SELECT Flow_Api_Name__c
            FROM Case_Tagging_Config__mdt
            WHERE DeveloperName = :CONFIG_DEVELOPER_NAME
            LIMIT 1
        ];
        if (!configs.isEmpty() && String.isNotBlank(configs[0].Flow_Api_Name__c)) {
            return configs[0].Flow_Api_Name__c;
        }
        return DEFAULT_FLOW_API_NAME;
    }

    /**
     * @description Get default historical scope in months from config.
     */
    public static Integer getDefaultHistoricalScopeMonths() {
        List<Case_Tagging_Config__mdt> configs = [
            SELECT Default_Historical_Scope_Months__c
            FROM Case_Tagging_Config__mdt
            WHERE DeveloperName = :CONFIG_DEVELOPER_NAME
            LIMIT 1
        ];
        if (!configs.isEmpty() && configs[0].Default_Historical_Scope_Months__c != null) {
            return configs[0].Default_Historical_Scope_Months__c.intValue();
        }
        return 2;
    }
}
