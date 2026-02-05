import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue, notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// VoiceCall fields: performance + sentiment
import PERFORMANCE_RATING_FIELD from '@salesforce/schema/VoiceCall.Agent_Performance_Rating__c';
import PERFORMANCE_EVALUATION_FIELD from '@salesforce/schema/VoiceCall.Agent_Performance_Evaluation__c';
import SENTIMENT_RATING_FIELD from '@salesforce/schema/VoiceCall.Sentiment_Rating__c';
import CALL_SENTIMENT_FIELD from '@salesforce/schema/VoiceCall.Call_Sentiment__c';

const FIELDS = [
    PERFORMANCE_RATING_FIELD,
    PERFORMANCE_EVALUATION_FIELD,
    SENTIMENT_RATING_FIELD,
    CALL_SENTIMENT_FIELD
];

export default class VoiceCallAnalytics extends LightningElement {
    @api recordId;

    voiceCallData;
    error;
    isLoading = false;
    isEvaluationExpanded = false;
    isSentimentExpanded = false;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredVoiceCall({ error, data }) {
        if (data) {
            this.voiceCallData = data;
            this.error = undefined;
            this.isLoading = false;
        } else if (error) {
            const rawMessage = error?.body?.message || error?.message || 'Unknown error occurred';
            this.error = this.normalizeErrorMessage(rawMessage);
            this.voiceCallData = undefined;
            this.isLoading = false;
            this.showErrorToast();
        }
    }

    get performanceRating() {
        return getFieldValue(this.voiceCallData, PERFORMANCE_RATING_FIELD);
    }

    get performanceEvaluation() {
        return getFieldValue(this.voiceCallData, PERFORMANCE_EVALUATION_FIELD);
    }

    /**
     * Format evaluation text: escape HTML, bold section headers, preserve line breaks.
     * Section headers (Agent Process:, Customer Focus:, etc.) are wrapped in <strong>.
     */
    get formattedPerformanceEvaluation() {
        const raw = this.performanceEvaluation;
        if (!raw || typeof raw !== 'string') return raw;
        return this.formatEvaluationWithSections(raw);
    }

    get sentimentRating() {
        return getFieldValue(this.voiceCallData, SENTIMENT_RATING_FIELD);
    }

    get callSentiment() {
        return getFieldValue(this.voiceCallData, CALL_SENTIMENT_FIELD);
    }

    get hasPerformanceData() {
        return this.performanceRating !== null && this.performanceRating !== undefined;
    }

    get hasSentimentData() {
        return this.sentimentRating !== null && this.sentimentRating !== undefined;
    }

    get performanceScoreClass() {
        const rating = this.performanceRating;
        let baseClass = 'performance-score-display slds-text-heading_large';
        if (rating >= 8) return baseClass + ' score-excellent';
        if (rating >= 6) return baseClass + ' score-good';
        if (rating >= 4) return baseClass + ' score-fair';
        return baseClass + ' score-poor';
    }

    get sentimentBadgeClass() {
        const sentiment = this.sentimentRating;
        if (sentiment === 'Positive') return 'sentiment-positive';
        if (sentiment === 'Negative') return 'sentiment-negative';
        return 'sentiment-neutral';
    }

    normalizeErrorMessage(rawMessage) {
        if (!rawMessage || typeof rawMessage !== 'string') return 'Unable to load analytics.';
        const msg = rawMessage;
        if (msg.includes('No such column') || msg.includes('INVALID_FIELD') || msg.includes("doesn't exist")) {
            return 'Analytics custom fields are not available on Voice Call in this org. Deploy the package that adds Agent Performance, Call Sentiment, and Sentiment Rating to Voice Call.';
        }
        return msg;
    }

    showErrorToast() {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Error',
            message: 'Failed to load voice call analytics data',
            variant: 'error'
        }));
    }

    get evaluationTextClass() {
        return this.isEvaluationExpanded ? 'evaluation-text expanded' : 'evaluation-text collapsed';
    }

    get showExpandButton() {
        const evaluation = this.performanceEvaluation;
        if (!evaluation) return false;
        return this.getVisibleTextLength(evaluation) > 200;
    }

    get expandButtonLabel() {
        return this.isEvaluationExpanded ? 'Show Less' : 'Show More';
    }

    get expandButtonIcon() {
        return this.isEvaluationExpanded ? 'utility:chevronup' : 'utility:chevrondown';
    }

    toggleEvaluationExpanded() {
        this.isEvaluationExpanded = !this.isEvaluationExpanded;
    }

    get sentimentTextClass() {
        return this.isSentimentExpanded ? 'evaluation-text expanded' : 'evaluation-text collapsed';
    }

    get showSentimentExpandButton() {
        const sentiment = this.callSentiment;
        if (!sentiment) return false;
        return this.getVisibleTextLength(sentiment) > 200;
    }

    get sentimentExpandButtonLabel() {
        return this.isSentimentExpanded ? 'Show Less' : 'Show More';
    }

    get sentimentExpandButtonIcon() {
        return this.isSentimentExpanded ? 'utility:chevronup' : 'utility:chevrondown';
    }

    toggleSentimentExpanded() {
        this.isSentimentExpanded = !this.isSentimentExpanded;
    }

    getVisibleTextLength(htmlContent) {
        if (!htmlContent) return 0;
        const tempDiv = document.createElement('div');
        tempDiv.innerHTML = htmlContent;
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

    formatEvaluationWithSections(text) {
        if (!text) return '';
        const escaped = this.escapeHtml(text);
        let out = escaped.replace(/\r\n/g, '\n').replace(/\r/g, '\n');
        for (const header of VoiceCallAnalytics.PERFORMANCE_SECTION_HEADERS) {
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

    connectedCallback() {
        this.isLoading = true;
    }

    async handleRefresh() {
        this.isLoading = true;
        try {
            await notifyRecordUpdateAvailable([this.recordId]);
            this.dispatchEvent(new ShowToastEvent({
                title: 'Refreshed',
                message: 'Analytics data updated',
                variant: 'success'
            }));
        } catch (e) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Refresh failed',
                message: e?.body?.message || String(e),
                variant: 'error'
            }));
        } finally {
            this.isLoading = false;
        }
    }
}
