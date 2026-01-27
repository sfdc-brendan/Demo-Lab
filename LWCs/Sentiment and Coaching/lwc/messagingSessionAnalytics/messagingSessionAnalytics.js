import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// Import MessagingSession fields
import PERFORMANCE_RATING_FIELD from '@salesforce/schema/MessagingSession.AgentPerformanceRating__c';
import PERFORMANCE_EVALUATION_FIELD from '@salesforce/schema/MessagingSession.AgentPerformanceEvaluation__c';
import SENTIMENT_RATING_FIELD from '@salesforce/schema/MessagingSession.SentimentRating__c';
import CHAT_SENTIMENT_FIELD from '@salesforce/schema/MessagingSession.ChatSentiment__c';

// Define fields to retrieve
const FIELDS = [
    PERFORMANCE_RATING_FIELD,
    PERFORMANCE_EVALUATION_FIELD,
    SENTIMENT_RATING_FIELD,
    CHAT_SENTIMENT_FIELD
];

export default class MessagingSessionAnalytics extends LightningElement {
    @api recordId; // MessagingSession record ID
    
    messagingSessionData;
    error;
    isLoading = false;
    isEvaluationExpanded = false;
    isSentimentExpanded = false;

    /**
     * Wire to get MessagingSession record data
     */
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredMessagingSession({ error, data }) {
        if (data) {
            this.messagingSessionData = data;
            this.error = undefined;
            this.isLoading = false;
        } else if (error) {
            this.error = error?.body?.message || 'Unknown error occurred';
            this.messagingSessionData = undefined;
            this.isLoading = false;
            this.showErrorToast();
        }
    }

    /**
     * Get performance rating value
     */
    get performanceRating() {
        return getFieldValue(this.messagingSessionData, PERFORMANCE_RATING_FIELD);
    }

    /**
     * Get performance evaluation text
     */
    get performanceEvaluation() {
        return getFieldValue(this.messagingSessionData, PERFORMANCE_EVALUATION_FIELD);
    }

    /**
     * Get sentiment rating value
     */
    get sentimentRating() {
        return getFieldValue(this.messagingSessionData, SENTIMENT_RATING_FIELD);
    }

    /**
     * Get chat sentiment text
     */
    get chatSentiment() {
        return getFieldValue(this.messagingSessionData, CHAT_SENTIMENT_FIELD);
    }

    /**
     * Check if performance data is available
     */
    get hasPerformanceData() {
        return this.performanceRating !== null && this.performanceRating !== undefined;
    }

    /**
     * Check if sentiment data is available
     */
    get hasSentimentData() {
        return this.sentimentRating !== null && this.sentimentRating !== undefined;
    }

    /**
     * Dynamic CSS class for performance score based on rating
     */
    get performanceScoreClass() {
        const rating = this.performanceRating;
        let baseClass = 'performance-score-display slds-text-heading_large';
        
        if (rating >= 8) {
            return baseClass + ' score-excellent';
        } else if (rating >= 6) {
            return baseClass + ' score-good';
        } else if (rating >= 4) {
            return baseClass + ' score-fair';
        } else {
            return baseClass + ' score-poor';
        }
    }

    /**
     * Dynamic CSS class for sentiment badge
     */
    get sentimentBadgeClass() {
        const sentiment = this.sentimentRating;
        
        if (sentiment === 'Positive') {
            return 'sentiment-positive';
        } else if (sentiment === 'Negative') {
            return 'sentiment-negative';
        } else {
            return 'sentiment-neutral';
        }
    }

    /**
     * Show error toast when data loading fails
     */
    showErrorToast() {
        const event = new ShowToastEvent({
            title: 'Error',
            message: 'Failed to load messaging session analytics data',
            variant: 'error'
        });
        this.dispatchEvent(event);
    }

    /**
     * Dynamic CSS class for evaluation text (collapsed/expanded)
     */
    get evaluationTextClass() {
        return this.isEvaluationExpanded ? 'evaluation-text expanded' : 'evaluation-text collapsed';
    }

    /**
     * Show expand button if evaluation text is long enough
     */
    get showExpandButton() {
        const evaluation = this.performanceEvaluation;
        if (!evaluation) return false;

        // Calculate visible text length (strip HTML tags for length calculation)
        const visibleTextLength = this.getVisibleTextLength(evaluation);
        
        // Show expand button if text is longer than approximately 3 lines (200 characters)
        return visibleTextLength > 200;
    }

    /**
     * Label for expand/collapse button
     */
    get expandButtonLabel() {
        return this.isEvaluationExpanded ? 'Show Less' : 'Show More';
    }

    /**
     * Icon for expand/collapse button
     */
    get expandButtonIcon() {
        return this.isEvaluationExpanded ? 'utility:chevronup' : 'utility:chevrondown';
    }

    /**
     * Toggle evaluation expanded/collapsed state
     */
    toggleEvaluationExpanded() {
        this.isEvaluationExpanded = !this.isEvaluationExpanded;
    }

    /**
     * Dynamic CSS class for sentiment text (collapsed/expanded)
     */
    get sentimentTextClass() {
        return this.isSentimentExpanded ? 'evaluation-text expanded' : 'evaluation-text collapsed';
    }

    /**
     * Show expand button for sentiment if text is long enough
     */
    get showSentimentExpandButton() {
        const sentiment = this.chatSentiment;
        if (!sentiment) return false;

        // Calculate visible text length (strip HTML tags for length calculation)
        const visibleTextLength = this.getVisibleTextLength(sentiment);
        
        // Show expand button if text is longer than approximately 3 lines (200 characters)
        return visibleTextLength > 200;
    }

    /**
     * Label for sentiment expand/collapse button
     */
    get sentimentExpandButtonLabel() {
        return this.isSentimentExpanded ? 'Show Less' : 'Show More';
    }

    /**
     * Icon for sentiment expand/collapse button
     */
    get sentimentExpandButtonIcon() {
        return this.isSentimentExpanded ? 'utility:chevronup' : 'utility:chevrondown';
    }

    /**
     * Toggle sentiment expanded/collapsed state
     */
    toggleSentimentExpanded() {
        this.isSentimentExpanded = !this.isSentimentExpanded;
    }

    /**
     * Helper method to calculate visible text length (strips HTML tags)
     */
    getVisibleTextLength(htmlContent) {
        if (!htmlContent) return 0;
        
        // Create a temporary div to parse HTML and extract text content
        const tempDiv = document.createElement('div');
        tempDiv.innerHTML = htmlContent;
        
        // Get the text content without HTML tags
        const textContent = tempDiv.textContent || tempDiv.innerText || '';
        
        return textContent.trim().length;
    }

    /**
     * Handle component initialization
     */
    connectedCallback() {
        this.isLoading = true;
    }
}