public with sharing class IncidentDashboardController {

    @AuraEnabled(cacheable=true)
    public static List<IncidentWithCasesWrapper> getActiveIncidentsWithCases() {
        List<IncidentWithCasesWrapper> result = new List<IncidentWithCasesWrapper>();

        List<Incident> incidents = [
            SELECT Id, Subject, Description, Status, Priority, CreatedDate, OwnerId, Owner.Name
            FROM Incident
            WHERE Status != 'Closed'
            ORDER BY CreatedDate DESC
            LIMIT 50
        ];

        if (incidents.isEmpty()) {
            return result;
        }

        Set<Id> incidentIds = new Set<Id>();
        for (Incident inc : incidents) {
            incidentIds.add(inc.Id);
        }

        List<CaseRelatedIssue> links = [
            SELECT Id, CaseId, RelatedIssueId
            FROM CaseRelatedIssue
            WHERE RelatedIssueId IN :incidentIds
        ];

        Map<Id, List<Id>> incidentToCaseIds = new Map<Id, List<Id>>();
        for (CaseRelatedIssue link : links) {
            if (!incidentToCaseIds.containsKey(link.RelatedIssueId)) {
                incidentToCaseIds.put(link.RelatedIssueId, new List<Id>());
            }
            incidentToCaseIds.get(link.RelatedIssueId).add(link.CaseId);
        }

        Set<Id> allCaseIds = new Set<Id>();
        for (List<Id> caseIds : incidentToCaseIds.values()) {
            allCaseIds.addAll(caseIds);
        }

        Map<Id, Case> casesById = new Map<Id, Case>();
        if (!allCaseIds.isEmpty()) {
            for (Case c : [
                SELECT Id, CaseNumber, Subject, Status, Priority
                FROM Case
                WHERE Id IN :allCaseIds
            ]) {
                casesById.put(c.Id, c);
            }
        }

        for (Incident inc : incidents) {
            List<CaseSummaryWrapper> relatedCases = new List<CaseSummaryWrapper>();
            List<Id> caseIds = incidentToCaseIds.get(inc.Id);
            if (caseIds != null) {
                for (Id caseId : caseIds) {
                    Case c = casesById.get(caseId);
                    if (c != null) {
                        relatedCases.add(new CaseSummaryWrapper(
                            c.Id,
                            c.CaseNumber,
                            c.Subject,
                            c.Status,
                            c.Priority != null ? c.Priority : ''
                        ));
                    }
                }
            }

            result.add(new IncidentWithCasesWrapper(
                inc.Id,
                inc.Subject,
                inc.Description != null ? inc.Description : '',
                inc.Status,
                inc.Priority != null ? inc.Priority : '',
                inc.CreatedDate,
                inc.OwnerId,
                inc.Owner != null ? inc.Owner.Name : '',
                relatedCases
            ));
        }

        return result;
    }

    public class IncidentWithCasesWrapper {
        @AuraEnabled public String id;
        @AuraEnabled public String subject;
        @AuraEnabled public String description;
        @AuraEnabled public String status;
        @AuraEnabled public String priority;
        @AuraEnabled public Datetime createdDate;
        @AuraEnabled public String ownerId;
        @AuraEnabled public String ownerName;
        @AuraEnabled public List<CaseSummaryWrapper> relatedCases;

        public IncidentWithCasesWrapper(String id, String subject, String description, String status, String priority,
                Datetime createdDate, String ownerId, String ownerName, List<CaseSummaryWrapper> relatedCases) {
            this.id = id;
            this.subject = subject;
            this.description = description;
            this.status = status;
            this.priority = priority;
            this.createdDate = createdDate;
            this.ownerId = ownerId;
            this.ownerName = ownerName;
            this.relatedCases = relatedCases;
        }
    }

    public class CaseSummaryWrapper {
        @AuraEnabled public String id;
        @AuraEnabled public String caseNumber;
        @AuraEnabled public String subject;
        @AuraEnabled public String status;
        @AuraEnabled public String priority;

        public CaseSummaryWrapper(String id, String caseNumber, String subject, String status, String priority) {
            this.id = id;
            this.caseNumber = caseNumber;
            this.subject = subject;
            this.status = status;
            this.priority = priority;
        }
    }
}
