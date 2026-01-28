public with sharing class CaseIncidentHandler {
    
    public class IncidentResponse {
        public Boolean isMatch;
        public String matchedCaseId;
        public String incidentTitle;
        public String reasoning;
    }

    @InvocableMethod(label='Evaluate Case for Incident' description='Checks if the new case is part of an incident using GenAI')
    public static void evaluateCaseForIncident(List<Id> caseIds) {
        // Since we are running in a flow, we handle one at a time, but bulkify for best practice
        if (caseIds.isEmpty()) return;
        Id targetCaseId = caseIds[0];

        // 1. Get Target Case Details
        Case targetCase = [SELECT Id, Subject, Description, Priority, Origin, AI_Summary__c FROM Case WHERE Id = :targetCaseId LIMIT 1];
        
        // Use AI Summary if available, otherwise fall back to Subject/Description
        String targetCaseInput;
        if (String.isNotBlank(targetCase.AI_Summary__c)) {
            targetCaseInput = 'ID: ' + targetCase.Id + '\nSummary: ' + targetCase.AI_Summary__c;
        } else {
             targetCaseInput = 'ID: ' + targetCase.Id + '\nSubject: ' + targetCase.Subject + '\nDescription: ' + targetCase.Description;
        }

        // 2. Get Recent Cases (Last 24 hours, open, excluding target)
        // We limit to 5 to fit in context window and keep it relevant
        List<Case> recentCases = [
            SELECT Id, Subject, Description, AI_Summary__c 
            FROM Case 
            WHERE Id != :targetCaseId 
            AND CreatedDate = LAST_N_DAYS:1 
            AND Status != 'Closed'
            ORDER BY CreatedDate DESC 
            LIMIT 5
        ];

        if (recentCases.isEmpty()) return;

        // Format Recent Cases for AI
        String recentCasesInput = '';
        for (Case c : recentCases) {
            String summary = String.isNotBlank(c.AI_Summary__c) ? c.AI_Summary__c : (c.Description != null ? c.Description.abbreviate(50) : 'N/A');
            recentCasesInput += 'ID: ' + c.Id + ' | Subject: ' + c.Subject + ' | Summary: ' + summary + '\n';
        }

        // 3. Call Einstein Prompt Template
        try {
            // Define Inputs
            Map<String, ConnectApi.WrappedValue> inputs = new Map<String, ConnectApi.WrappedValue>();
            
            ConnectApi.WrappedValue targetCaseValue = new ConnectApi.WrappedValue();
            targetCaseValue.value = targetCaseInput;
            inputs.put('Input:targetCase', targetCaseValue);
            
            ConnectApi.WrappedValue recentCasesValue = new ConnectApi.WrappedValue();
            recentCasesValue.value = recentCasesInput;
            inputs.put('Input:recentCases', recentCasesValue);

            // Execute Template
            ConnectApi.EinsteinPromptTemplateGenerationsInput promptInput = new ConnectApi.EinsteinPromptTemplateGenerationsInput();
            // Removed additionalConfig
            promptInput.inputParams = inputs;
            promptInput.isPreview = false;

            // Call the API
            ConnectApi.EinsteinPromptTemplateGenerationsRepresentation output = ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate('Case_RealTime_Similarity', promptInput);
            String aiResponse = output.generations[0].text;

            // 4. Parse Response
            // Clean JSON if AI adds backticks
            aiResponse = aiResponse.replace('```json', '').replace('```', '').trim();
            IncidentResponse response = (IncidentResponse) JSON.deserialize(aiResponse, IncidentResponse.class);

            // Post to Chatter for visibility
            postToChatter(targetCase.Id, 'AI Analysis: ' + (response.isMatch ? 'Match Found with Case ' + response.matchedCaseId : 'No Match Found') + '\nReasoning: ' + response.reasoning);

            if (response.isMatch == true && String.isNotBlank(response.matchedCaseId)) {
                handleMatch(targetCase, response);
            }

        } catch (Exception e) {
            System.debug('Error in AI Incident Detection: ' + e.getMessage());
            postToChatter(targetCase.Id, 'AI Analysis Failed: ' + e.getMessage() + '. Attempting Fallback Logic.');
            
            runFallbackAnalysis(targetCase);
        }
    }

    private static void runFallbackAnalysis(Case targetCase) {
        // Helper to detect issue type from text
        String issueType = detectIssueType(targetCase.Subject + ' ' + targetCase.Description + ' ' + targetCase.AI_Summary__c);
        
        if (issueType == null) {
            postToChatter(targetCase.Id, 'Fallback Analysis: No recognizable pattern found in this case.');
            return;
        }

        // Scan Recent Cases (last 4 hours) for the SAME issue type
        List<Case> recentCases = [
            SELECT Id, Subject, Description, AI_Summary__c 
            FROM Case 
            WHERE Id != :targetCase.Id 
            AND CreatedDate >= :System.now().addHours(-4)
            AND Status != 'Closed'
        ];
        
        List<Case> matchingRecentCases = new List<Case>();
        for (Case c : recentCases) {
            if (detectIssueType(c.Subject + ' ' + c.Description + ' ' + c.AI_Summary__c) == issueType) {
                matchingRecentCases.add(c);
            }
        }
        
        // DECISION: Only create incident if there is a PATTERN (at least 1 other case)
        if (!matchingRecentCases.isEmpty()) {
             // Pattern Confirmed!
             String incidentTitle = issueType + ' Incident';
             
             // Find existing active incident
             List<Incident> existingIncidents = [SELECT Id FROM Incident WHERE Subject = :incidentTitle AND Status != 'Closed' LIMIT 1];
             Id incidentId;
             
             if (!existingIncidents.isEmpty()) {
                 incidentId = existingIncidents[0].Id;
             } else {
                 Incident newInc = new Incident(
                     Subject = incidentTitle, 
                     Description = 'Auto-detected pattern. \nIssue Type: ' + issueType + '\nAffected Cases: ' + (matchingRecentCases.size() + 1),
                     Status = 'New', 
                     Priority = 'High'
                 );
                 insert newInc;
                 incidentId = newInc.Id;
             }
             
             // Link Target Case
             linkCaseToIncident(targetCase.Id, incidentId);
             
             // Link Matching Recent Cases (Retroactive Grouping)
             for (Case c : matchingRecentCases) {
                 linkCaseToIncident(c.Id, incidentId);
             }
             
             postToChatter(targetCase.Id, 'Fallback Analysis: Pattern Detected (' + matchingRecentCases.size() + ' recent cases). Linked to Incident: ' + incidentTitle);
        } else {
             // Isolated Incident (so far)
             postToChatter(targetCase.Id, 'Fallback Analysis: Issue Type identified (' + issueType + '), but no recent matching cases found. Monitoring for pattern.');
        }
    }
    
    private static String detectIssueType(String text) {
        if (text == null) return null;
        text = text.toLowerCase();
        if (text.contains('checkout') || text.contains('payment')) return 'Checkout Service';
        if (text.contains('login') || text.contains('sso') || text.contains('auth')) return 'Identity Service';
        if (text.contains('slow') || text.contains('timeout') || text.contains('performance')) return 'Performance';
        if (text.contains('database') || text.contains('connection')) return 'Database Connectivity';
        if (text.contains('vpn') || text.contains('network')) return 'Network Infrastructure';
        return null;
    }
    
    private static void linkCaseToIncident(Id caseId, Id incidentId) {
        List<CaseRelatedIssue> existing = [SELECT Id FROM CaseRelatedIssue WHERE CaseId = :caseId AND RelatedIssueId = :incidentId LIMIT 1];
        if (existing.isEmpty()) {
            insert new CaseRelatedIssue(CaseId = caseId, RelatedIssueId = incidentId, RelationshipType = 'Similar');
        }
    }

    private static void postToChatter(Id caseId, String message) {
        ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();
        ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();
        ConnectApi.TextSegmentInput textSegmentInput = new ConnectApi.TextSegmentInput();
        
        textSegmentInput.text = message;
        messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
        messageBodyInput.messageSegments.add(textSegmentInput);
        
        feedItemInput.body = messageBodyInput;
        feedItemInput.subjectId = caseId;
        
        try {
            ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), feedItemInput);
        } catch(Exception e) {
            System.debug('Failed to post to chatter: ' + e.getMessage());
        }
    }

    private static void handleMatch(Case targetCase, IncidentResponse response) {
        Id matchedCaseId = (Id) response.matchedCaseId;
        
        // Check if the matched case is already part of an Incident using standard CaseRelatedIssue object
        List<CaseRelatedIssue> existingIssues = [
            SELECT RelatedIssueId 
            FROM CaseRelatedIssue 
            WHERE CaseId = :matchedCaseId 
            AND RelatedEntityType = 'Incident'
            LIMIT 1
        ];

        Id incidentId;

        if (!existingIssues.isEmpty()) {
            // Scenario A: Matched case is already in an Incident -> Add target case to it
            incidentId = existingIssues[0].RelatedIssueId;
        } else {
            // Scenario B: Matched case is NOT in an Incident -> Create new Incident
            Incident newIncident = new Incident(
                Subject = response.incidentTitle,
                Description = 'Auto-detected via AI. \nReasoning: ' + response.reasoning,
                Priority = 'High',
                Status = 'New'
            );
            insert newIncident;
            incidentId = newIncident.Id;

            // Link the matched case to this new incident
            CaseRelatedIssue linkMatched = new CaseRelatedIssue(
                CaseId = matchedCaseId,
                RelatedIssueId = incidentId,
                RelationshipType = 'Similar'
            );
            insert linkMatched;
        }

        // Link the Target Case to the Incident
        // Check if already linked to avoid duplicates
        List<CaseRelatedIssue> targetIssues = [SELECT Id FROM CaseRelatedIssue WHERE CaseId = :targetCase.Id AND RelatedIssueId = :incidentId LIMIT 1];
        if (targetIssues.isEmpty()) {
            CaseRelatedIssue linkTarget = new CaseRelatedIssue(
                CaseId = targetCase.Id,
                RelatedIssueId = incidentId,
                RelationshipType = 'Similar'
            );
            insert linkTarget;
        }
    }
}
