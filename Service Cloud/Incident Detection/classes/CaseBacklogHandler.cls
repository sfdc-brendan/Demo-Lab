/**
 * Inner class used by CaseBacklogBatch for GenAI prompt response.
 * Must match JSON from Case_RealTime_Similarity: isMatch, matchedCaseId, incidentTitle, reasoning.
 */
public with sharing class CaseBacklogHandler {

    public class IncidentResponse {
        public Boolean isMatch;
        public String matchedCaseId;
        public String incidentTitle;
        public String reasoning;
    }
}
