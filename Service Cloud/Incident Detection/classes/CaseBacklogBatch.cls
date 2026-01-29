/**
 * Batch job: evaluates open Cases for incident patterns using Models API (createGenerations),
 * same path as CaseIncidentHandler. Links cases to Incidents via CaseRelatedIssue.
 *
 * Run with batch size 1 to stay within callout limits:
 *   Database.executeBatch(new CaseBacklogBatch(), 1);
 *
 * Uses CaseId + RelatedIssueId only (no RelatedEntityType) for CaseRelatedIssue so it works
 * in all Service Cloud orgs.
 */
public with sharing class CaseBacklogBatch implements Database.Batchable<SObject>, Database.AllowsCallouts {

    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT Id, Subject, Description, Priority, Origin, AI_Summary__c
            FROM Case
            WHERE Status != 'Closed'
            ORDER BY CreatedDate DESC
        ]);
    }

    public void execute(Database.BatchableContext BC, List<Case> scope) {
        if (scope.isEmpty()) return;

        Set<Id> caseIds = new Map<Id, Case>(scope).keySet();
        List<CaseRelatedIssue> existingLinks = [
            SELECT CaseId
            FROM CaseRelatedIssue
            WHERE CaseId IN :caseIds
        ];
        Set<Id> caseIdsAlreadyLinked = new Set<Id>();
        for (CaseRelatedIssue link : existingLinks) {
            caseIdsAlreadyLinked.add(link.CaseId);
        }

        for (Case targetCase : scope) {
            if (caseIdsAlreadyLinked.contains(targetCase.Id)) continue;
            processCase(targetCase);
        }
    }

    private void processCase(Case targetCase) {
        try {
            String targetCaseInput;
            if (String.isNotBlank(targetCase.AI_Summary__c)) {
                targetCaseInput = 'ID: ' + targetCase.Id + '\nSummary: ' + targetCase.AI_Summary__c;
            } else {
                targetCaseInput = 'ID: ' + targetCase.Id + '\nSubject: ' + targetCase.Subject + '\nDescription: ' + targetCase.Description;
            }

            List<Case> recentCases = [
                SELECT Id, Subject, Description, AI_Summary__c
                FROM Case
                WHERE Id != :targetCase.Id
                AND CreatedDate = LAST_N_DAYS:30
                AND Status != 'Closed'
                ORDER BY CreatedDate DESC
                LIMIT 5
            ];

            if (recentCases.isEmpty()) return;

            String recentCasesInput = '';
            for (Case c : recentCases) {
                String summary = String.isNotBlank(c.AI_Summary__c) ? c.AI_Summary__c : (c.Description != null ? c.Description.abbreviate(50) : 'N/A');
                recentCasesInput += 'ID: ' + c.Id + ' | Subject: ' + c.Subject + ' | Summary: ' + summary + '\n';
            }

            String aiResponse = CaseIncidentHandler.generateSimilarityAnalysis(targetCaseInput, recentCasesInput);
            if (String.isBlank(aiResponse)) {
                postToChatter(targetCase.Id, 'AI Analysis Failed: No response from Models API. Attempting Fallback Logic.');
                runFallbackAnalysis(targetCase);
                return;
            }
            aiResponse = aiResponse.replace('```json', '').replace('```', '').trim();
            CaseBacklogHandler.IncidentResponse response = (CaseBacklogHandler.IncidentResponse) JSON.deserialize(aiResponse, CaseBacklogHandler.IncidentResponse.class);

            postToChatter(targetCase.Id, 'AI Analysis: ' + (response.isMatch ? 'Match Found with Case ' + response.matchedCaseId : 'No Match Found') + '\nReasoning: ' + response.reasoning);

            if (response.isMatch == true && String.isNotBlank(response.matchedCaseId)) {
                linkToIncident(targetCase, response);
            }
        } catch (Exception e) {
            System.debug('Error processing case ' + targetCase.Id + ': ' + e.getMessage());
            postToChatter(targetCase.Id, 'AI Analysis Failed: ' + e.getMessage() + '. Attempting Fallback Logic.');
            runFallbackAnalysis(targetCase);
        }
    }

    private void runFallbackAnalysis(Case targetCase) {
        String textToAnalyze = (targetCase.Subject + ' ' + targetCase.Description + ' ' + targetCase.AI_Summary__c).toLowerCase();
        String incidentTitle = null;

        if (textToAnalyze.contains('checkout') || textToAnalyze.contains('payment')) {
            incidentTitle = 'Checkout Service Disruption';
        } else if (textToAnalyze.contains('login') || textToAnalyze.contains('sso') || textToAnalyze.contains('auth')) {
            incidentTitle = 'Identity Service Outage';
        } else if (textToAnalyze.contains('slow') || textToAnalyze.contains('timeout') || textToAnalyze.contains('performance')) {
            incidentTitle = 'System Performance Degradation';
        } else if (textToAnalyze.contains('database') || textToAnalyze.contains('connection')) {
            incidentTitle = 'Database Connectivity Issue';
        }

        if (incidentTitle != null) {
            List<Incident> existingIncidents = [SELECT Id FROM Incident WHERE Subject = :incidentTitle AND Status != 'Closed' LIMIT 1];
            Id incidentId;
            if (!existingIncidents.isEmpty()) {
                incidentId = existingIncidents[0].Id;
            } else {
                Incident newInc = new Incident(Subject = incidentTitle, Description = 'Auto-detected via Keyword Fallback', Status = 'New', Priority = 'High');
                insert newInc;
                incidentId = newInc.Id;
            }
            insert new CaseRelatedIssue(CaseId = targetCase.Id, RelatedIssueId = incidentId, RelationshipType = 'Similar');
            postToChatter(targetCase.Id, 'Fallback Analysis: Match Found -> Linked to Incident: ' + incidentTitle);
        } else {
            postToChatter(targetCase.Id, 'Fallback Analysis: No Keyword Match Found.');
        }
    }

    private void postToChatter(Id caseId, String message) {
        if (Network.getNetworkId() == null) {
            System.debug('Skipping Chatter (no network in batch context): ' + message);
            return;
        }
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
        } catch (Exception e) {
            System.debug('Failed to post to Chatter: ' + e.getMessage());
        }
    }

    private void linkToIncident(Case targetCase, CaseBacklogHandler.IncidentResponse response) {
        Id matchedCaseId = (Id) response.matchedCaseId;
        List<CaseRelatedIssue> existingIssues = [
            SELECT RelatedIssueId
            FROM CaseRelatedIssue
            WHERE CaseId = :matchedCaseId
            LIMIT 1
        ];
        Id incidentId;
        if (!existingIssues.isEmpty()) {
            incidentId = existingIssues[0].RelatedIssueId;
        } else {
            Incident newInc = new Incident(
                Subject = response.incidentTitle,
                Description = 'Backlog AI Auto-Group: ' + response.reasoning,
                Status = 'New',
                Priority = 'Medium'
            );
            insert newInc;
            incidentId = newInc.Id;
            insert new CaseRelatedIssue(CaseId = matchedCaseId, RelatedIssueId = incidentId, RelationshipType = 'Similar');
        }
        List<CaseRelatedIssue> targetLinks = [SELECT Id FROM CaseRelatedIssue WHERE CaseId = :targetCase.Id AND RelatedIssueId = :incidentId LIMIT 1];
        if (targetLinks.isEmpty()) {
            insert new CaseRelatedIssue(CaseId = targetCase.Id, RelatedIssueId = incidentId, RelationshipType = 'Similar');
        }
    }

    public void finish(Database.BatchableContext BC) {
        // Optional: send email to admin
    }
}
