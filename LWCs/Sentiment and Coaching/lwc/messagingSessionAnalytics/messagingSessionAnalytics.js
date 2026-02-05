import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue, notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
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
            const rawMessage = this.getLdsErrorMessage(error);
            this.error = this.normalizeErrorMessage(rawMessage);
            this.messagingSessionData = undefined;
            this.isLoading = false;
            this.showErrorToast();
        }
    }

    /**
     * Extract message from LDS error. getRecord returns error.body as an array of error objects.
     */
    getLdsErrorMessage(error) {
        if (!error) return 'Unknown error occurred';
        const body = error.body;
        if (Array.isArray(body) && body.length > 0 && body[0].message) {
            return body[0].message;
        }
        if (body && typeof body === 'object' && body.message) {
            return body.message;
        }
        return error.message || 'Unknown error occurred';
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
     * Format evaluation text for display. If content is already HTML (from prompt), pass through
     * so lightning-formatted-rich-text renders it. Otherwise escape, bold section headers, and
     * convert newlines to <br/> for plain-text output (SLDS-friendly).
     */
    get formattedPerformanceEvaluation() {
        const raw = this.performanceEvaluation;
        if (!raw || typeof raw !== 'string') return raw;
        return this.formatEvaluationWithSections(raw);
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
     * Turn API errors into user-friendly messages (e.g. missing custom fields or no FLS).
     */
    normalizeErrorMessage(rawMessage) {
        if (!rawMessage || typeof rawMessage !== 'string') return 'Unable to load analytics.';
        const msg = rawMessage;
        const isFieldOrAccessError =
            msg.includes('No such column') ||
            msg.includes('INVALID_FIELD') ||
            msg.includes("doesn't exist") ||
            msg.includes('entity is not accessible') ||
            msg.includes('insufficient access') ||
            msg.includes('cannot access');
        if (isFieldOrAccessError) {
            return 'Analytics custom fields are not available on Messaging Session in this org. Deploy the Sentiment Coaching metadata (Messaging Session fields: Agent Performance Evaluation, Agent Performance Rating, Chat Sentiment, Sentiment Rating) and assign the Sentiment Coaching Fields permission set to your user.';
        }
        return msg;
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

    /** Section headers to bold (order: longer phrases first to avoid partial matches). */
    static get PERFORMANCE_SECTION_HEADERS() {
        return [
            'Tone, Language, and Clarity:',
            'Communication and Clarity:',
            'Agent Process:',
            'Customer Focus:',
            'Professional Conduct:',
            'Overall Summary:',
            'Soft Skills:',
            'Rating Score:'
        ];
    }

    /**
     * Returns true if the string looks like HTML (so we pass it through for rich-text rendering).
     */
    looksLikeHtml(text) {
        if (!text || typeof text !== 'string') return false;
        const trimmed = text.trim();
        return /<p\s*>|<p\s+|\<br\s*\/?>|\<\/p>|<b\s*>|<b\s+|\<\/b>|<div\s*>/i.test(trimmed);
    }

    formatEvaluationWithSections(text) {
        if (!text) return '';
        // If prompt already returned HTML, pass through so lightning-formatted-rich-text renders it (SLDS longform).
        if (this.looksLikeHtml(text)) {
            return text;
        }
        // Plain-text: escape, bold section headers, newlines to br (SLDS-safe).
        const escaped = this.escapeHtml(text);
        let out = escaped.replace(/\r\n/g, '\n').replace(/\r/g, '\n');
        for (const header of MessagingSessionAnalytics.PERFORMANCE_SECTION_HEADERS) {
            const re = new RegExp(this.escapeRegex(header), 'g');
            out = out.replace(re, `<strong>${header}</strong>`);
        }
        return out.replace(/\n/g, '<br/>');
    }

    escapeHtml(s) {
        const div = document.createElement('div');
        div.textContent = s;
        return div.innerHTML;
    }

    escapeRegex(s) {
        return s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    }

    /**
     * Handle component initialization
     */
    connectedCallback() {
        this.isLoading = true;
    }

    /**
     * Refresh record data from the server. Use when analysis may have completed in the background.
     * LDS does not auto-refresh when async flows update the record.
     */
    async handleRefresh() {
        this.isLoading = true;
        try {
            await notifyRecordUpdateAvailable([this.recordId]);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Refreshed',
                    message: 'Analytics data updated',
                    variant: 'success'
                })
            );
        } catch (e) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Refresh failed',
                    message: e?.body?.message || String(e),
                    variant: 'error'
                })
            );
        } finally {
            this.isLoading = false;
        }
    }
}