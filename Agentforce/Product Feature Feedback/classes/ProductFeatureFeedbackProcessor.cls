public with sharing class ProductFeatureFeedbackProcessor {
    
    /**
     * Wrapper class for feedback analysis data from the prompt template
     */
    public class FeedbackAnalysis {
        public String category; // Complaint or Suggestion
        public String sentiment; // Positive, Negative, Neutral
        public String featureTopic; // User Interface, Mobile Experience, etc.
        public String escalationLevel; // Critical, High, Medium, Low
        public String productTeamRouting; // Engineering Team, Mobile Team, etc.
        public List<String> keyInsights;
        public List<String> recommendedActions;
        public String subject;
        public String description;
        public String priority;
        public String status;
        public String reason;
    }
    
    /**
     * Result wrapper for the response
     */
    public class FeedbackProcessingResult {
        @InvocableVariable public Boolean success;
        @InvocableVariable public String message;
        @InvocableVariable public String caseId;
        @InvocableVariable public String escalationStatus;
        @InvocableVariable public String routingTeam;
        @InvocableVariable public String analysisInsights;
        
        public FeedbackProcessingResult() {
            this.success = false;
            this.caseId = '';
            this.escalationStatus = '';
            this.routingTeam = '';
            this.analysisInsights = '';
        }
    }
    
    /**
     * Processes feedback analysis from JSON and creates appropriate Case records with routing
     * @param feedbackAnalysisData JSON string containing analyzed feedback data
     * @param contactId Contact ID who provided the feedback
     * @param originalFeedback Original feedback text from user
     * @return FeedbackProcessingResult with success status and case details
     */
    @InvocableMethod(label='Process Product Feature Feedback' description='Creates Case records from analyzed product feedback data and handles escalation/routing')
    public static List<FeedbackProcessingResult> processFeedbackAnalysis(List<FeedbackProcessingRequest> requests) {
        List<FeedbackProcessingResult> results = new List<FeedbackProcessingResult>();
        
        for (FeedbackProcessingRequest request : requests) {
            FeedbackProcessingResult result = new FeedbackProcessingResult();
            
            try {
                // Validate inputs
                if (String.isBlank(request.contactId)) {
                    result.message = 'Contact ID is required';
                    results.add(result);
                    continue;
                }
                
                if (String.isBlank(request.feedbackAnalysisData)) {
                    result.message = 'Feedback analysis data is required';
                    results.add(result);
                    continue;
                }
                
                // Verify contact exists and get associated account
                List<Contact> contacts = [SELECT Id, Name, AccountId, Account.Name, Email, Phone FROM Contact WHERE Id = :request.contactId LIMIT 1];
                if (contacts.isEmpty()) {
                    result.message = 'Invalid Contact ID: ' + request.contactId;
                    results.add(result);
                    continue;
                }
                
                Contact contact = contacts[0];
                
                // Parse JSON analysis
                FeedbackAnalysis analysis = (FeedbackAnalysis) JSON.deserialize(
                    request.feedbackAnalysisData, 
                    FeedbackAnalysis.class
                );
                
                // Check for duplicate feedback within the last 2 minutes to prevent multiple cases
                DateTime twoMinutesAgo = DateTime.now().addMinutes(-2);
                List<Case> recentCases = [
                    SELECT Id, Subject 
                    FROM Case 
                    WHERE ContactId = :request.contactId 
                    AND CreatedDate > :twoMinutesAgo 
                    AND Subject = :analysis.subject
                    LIMIT 1
                ];
                
                if (!recentCases.isEmpty()) {
                    result.success = true;
                    result.caseId = recentCases[0].Id;
                    result.escalationStatus = analysis.escalationLevel;
                    result.routingTeam = analysis.productTeamRouting;
                    result.analysisInsights = String.join(analysis.keyInsights, '; ');
                    result.message = 'Duplicate feedback detected. Using existing case: ' + recentCases[0].Id;
                    results.add(result);
                    continue;
                }
                
                // Create Case record with analysis data
                Case feedbackCase = new Case();
                feedbackCase.ContactId = request.contactId;
                feedbackCase.AccountId = contact.AccountId;
                feedbackCase.Subject = analysis.subject;
                feedbackCase.Description = buildCaseDescription(analysis, request.originalFeedback);
                feedbackCase.Status = determineInitialStatus(analysis);
                feedbackCase.Priority = analysis.priority;
                feedbackCase.Origin = String.isNotBlank(request.sourceChannel) ? request.sourceChannel : 'Web';
                feedbackCase.Type = analysis.category.equals('Complaint') ? 'Problem' : 'Feature Request';
                feedbackCase.Reason = analysis.reason;
                
                // Set owner based on routing logic
                feedbackCase.OwnerId = determineOwner(analysis.productTeamRouting, analysis.escalationLevel);
                
                // Add custom fields for product feature analysis (these would need to be created)
                // feedbackCase.Product_Feature_Category__c = analysis.featureTopic;
                // feedbackCase.Sentiment_Analysis__c = analysis.sentiment;
                // feedbackCase.Escalation_Level__c = analysis.escalationLevel;
                // feedbackCase.Product_Team_Assignment__c = analysis.productTeamRouting;
                // feedbackCase.AI_Insights__c = String.join(analysis.keyInsights, '; ');
                // feedbackCase.Recommended_Actions__c = String.join(analysis.recommendedActions, '; ');
                
                // Set supplied contact info
                feedbackCase.SuppliedEmail = contact.Email;
                feedbackCase.SuppliedName = contact.Name;
                feedbackCase.SuppliedPhone = contact.Phone;
                
                insert feedbackCase;
                
                // Handle escalation if needed
                handleEscalation(feedbackCase.Id, analysis);
                
                // Create follow-up tasks for routing
                createRoutingTasks(feedbackCase.Id, analysis);
                
                // Build successful response
                result.success = true;
                result.caseId = feedbackCase.Id;
                result.escalationStatus = analysis.escalationLevel;
                result.routingTeam = analysis.productTeamRouting;
                result.analysisInsights = String.join(analysis.keyInsights, '; ');
                result.message = buildSuccessMessage(contact, analysis, feedbackCase.Id);
                
            } catch (JSONException e) {
                result.message = 'Invalid feedback analysis JSON: ' + e.getMessage();
                System.debug('JSON parsing error: ' + e.getMessage());
            } catch (DmlException e) {
                result.message = 'Error creating feedback case: ' + e.getMessage();
                System.debug('DML error: ' + e.getMessage());
            } catch (Exception e) {
                result.message = 'Unexpected error processing feedback: ' + e.getMessage();
                System.debug('Unexpected error: ' + e.getMessage());
            }
            
            results.add(result);
        }
        
        return results;
    }
    
    /**
     * Builds comprehensive case description including analysis
     */
    private static String buildCaseDescription(FeedbackAnalysis analysis, String originalFeedback) {
        String description = analysis.description;
        description += '\n\n--- AI ANALYSIS ---';
        description += '\nCategory: ' + analysis.category;
        description += '\nSentiment: ' + analysis.sentiment;
        description += '\nFeature Topic: ' + analysis.featureTopic;
        description += '\nEscalation Level: ' + analysis.escalationLevel;
        description += '\nRouted to: ' + analysis.productTeamRouting;
        
        if (analysis.keyInsights != null && !analysis.keyInsights.isEmpty()) {
            description += '\n\nKey Insights:\n• ' + String.join(analysis.keyInsights, '\n• ');
        }
        
        if (analysis.recommendedActions != null && !analysis.recommendedActions.isEmpty()) {
            description += '\n\nRecommended Actions:\n• ' + String.join(analysis.recommendedActions, '\n• ');
        }
        
        if (String.isNotBlank(originalFeedback)) {
            description += '\n\n--- ORIGINAL FEEDBACK ---\n' + originalFeedback;
        }
        
        return description;
    }
    
    /**
     * Determines initial case status based on escalation level
     */
    private static String determineInitialStatus(FeedbackAnalysis analysis) {
        if (analysis.escalationLevel == 'Critical' || analysis.escalationLevel == 'High') {
            return 'Escalated';
        } else if (analysis.status != null && analysis.status.equals('Escalated')) {
            return 'Escalated';
        }
        return 'New';
    }
    
    /**
     * Determines case owner based on product team routing and escalation
     */
    private static String determineOwner(String productTeam, String escalationLevel) {
        // In a real implementation, you'd query for specific users/queues
        // For now, return current user
        
        // This could be enhanced to route to specific queues or users:
        // if (productTeam == 'Mobile Team') return mobileQueueId;
        // if (productTeam == 'Engineering Team') return engineeringQueueId;
        // if (escalationLevel == 'Critical') return escalationQueueId;
        
        return UserInfo.getUserId();
    }
    
    /**
     * Handles escalation process for critical/high priority items
     */
    private static void handleEscalation(String caseId, FeedbackAnalysis analysis) {
        if (analysis.escalationLevel == 'Critical' || analysis.escalationLevel == 'High') {
            // Create escalation task
            Task escalationTask = new Task();
            escalationTask.WhatId = caseId;
            escalationTask.Subject = 'ESCALATION: ' + analysis.escalationLevel + ' priority product feedback';
            escalationTask.Description = 'High priority product feedback requires immediate attention from ' + analysis.productTeamRouting;
            escalationTask.Priority = 'High';
            escalationTask.Status = 'Not Started';
            escalationTask.ActivityDate = Date.today();
            escalationTask.OwnerId = UserInfo.getUserId(); // Route to escalation queue in real implementation
            
            insert escalationTask;
            
            // In real implementation, could also:
            // - Send Slack notification
            // - Create Chatter post
            // - Send email to product team
            // - Create Calendar event for review
        }
    }
    
    /**
     * Creates routing tasks for product teams
     */
    private static void createRoutingTasks(String caseId, FeedbackAnalysis analysis) {
        List<Task> tasksToCreate = new List<Task>();
        
        // Create routing task
        Task routingTask = new Task();
        routingTask.WhatId = caseId;
        routingTask.Subject = 'Review product feedback - ' + analysis.featureTopic;
        routingTask.Description = 'Product feedback routed to ' + analysis.productTeamRouting + ' for review and action';
        routingTask.Priority = analysis.priority;
        routingTask.Status = 'Not Started';
        routingTask.ActivityDate = Date.today().addDays(
            analysis.escalationLevel == 'Critical' ? 0 : 
            analysis.escalationLevel == 'High' ? 1 : 
            analysis.escalationLevel == 'Medium' ? 3 : 7
        );
        
        tasksToCreate.add(routingTask);
        
        // Create follow-up task if recommendations exist
        if (analysis.recommendedActions != null && !analysis.recommendedActions.isEmpty()) {
            Task followUpTask = new Task();
            followUpTask.WhatId = caseId;
            followUpTask.Subject = 'Implement recommended actions - ' + analysis.featureTopic;
            followUpTask.Description = String.join(analysis.recommendedActions, '\n');
            followUpTask.Priority = analysis.priority;
            followUpTask.Status = 'Not Started';
            followUpTask.ActivityDate = Date.today().addDays(7);
            
            tasksToCreate.add(followUpTask);
        }
        
        if (!tasksToCreate.isEmpty()) {
            insert tasksToCreate;
        }
    }
    
    /**
     * Builds success message for user feedback
     */
    private static String buildSuccessMessage(Contact contact, FeedbackAnalysis analysis, String caseId) {
        String message = 'Successfully processed product feedback from ' + contact.Name;
        message += '\n• Category: ' + analysis.category;
        message += '\n• Sentiment: ' + analysis.sentiment;  
        message += '\n• Feature Topic: ' + analysis.featureTopic;
        message += '\n• Escalation Level: ' + analysis.escalationLevel;
        message += '\n• Routed to: ' + analysis.productTeamRouting;
        message += '\n• Case ID: ' + caseId;
        
        if (analysis.escalationLevel == 'Critical' || analysis.escalationLevel == 'High') {
            message += '\n\n⚠️ This feedback has been ESCALATED due to ' + analysis.escalationLevel.toLowerCase() + ' priority level.';
        }
        
        return message;
    }
    
    /**
     * Input wrapper for the invocable method
     */
    public class FeedbackProcessingRequest {
        @InvocableVariable(label='Feedback Analysis Data' description='JSON containing analyzed product feedback data from prompt template' required=true)
        public String feedbackAnalysisData;
        
        @InvocableVariable(label='Contact ID' description='The Contact ID who provided the feedback' required=true)
        public String contactId;
        
        @InvocableVariable(label='Original Feedback' description='The original user feedback text' required=false)
        public String originalFeedback;
        
        @InvocableVariable(label='Source Channel' description='How the feedback was received (Web, Mobile, Email, etc.)' required=false)
        public String sourceChannel;
    }
}