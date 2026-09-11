import { LightningElement, api, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';
import getLatestInsight from '@salesforce/apex/CoachingInsightController.getLatestInsight';

const CATEGORY_LABELS = [
    { key: 'agentProcess', label: 'Agent Process' },
    { key: 'customerFocus', label: 'Customer Focus' },
    { key: 'softSkills', label: 'Soft Skills' },
    { key: 'toneLanguageClarity', label: 'Tone, Language & Clarity' },
    { key: 'professionalConduct', label: 'Professional Conduct' }
];

export default class CoachingInsightPanel extends LightningElement {
    @api recordId;

    insight;
    error;
    justUpdated = false;
    _wired;
    _subscription = {};
    channelName = '/event/Coaching_Insight_Ready__e';

    @wire(getLatestInsight, { recordId: '$recordId' })
    wiredInsight(result) {
        this._wired = result;
        if (result.data) {
            this.insight = result.data;
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error;
            this.insight = undefined;
        }
    }

    connectedCallback() {
        onError(() => {
            // empApi transport errors are non-fatal for this panel.
        });
        subscribe(this.channelName, -1, (message) => this.handleEvent(message)).then((response) => {
            this._subscription = response;
        });
    }

    disconnectedCallback() {
        if (this._subscription && this._subscription.id) {
            unsubscribe(this._subscription, () => {});
        }
    }

    handleEvent(message) {
        const payload = (message && message.data && message.data.payload) || {};
        // Match the 15-char event value against the (18-char) page record id.
        if (payload.Record_Id__c && this.recordId && this.recordId.indexOf(payload.Record_Id__c) === 0) {
            refreshApex(this._wired).then(() => this.flashUpdated());
        }
    }

    flashUpdated() {
        this.justUpdated = true;
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        setTimeout(() => {
            this.justUpdated = false;
        }, 4000);
    }

    get hasInsight() {
        return !!this.insight && this.insight.Status__c === 'Success';
    }

    get isFailed() {
        return !!this.insight && this.insight.Status__c === 'Failed';
    }

    get noData() {
        return !this.insight;
    }

    get performanceRating() {
        return this.insight ? this.insight.Performance_Rating__c : undefined;
    }

    get sentimentRating() {
        return this.insight ? this.insight.Sentiment_Rating__c : undefined;
    }

    get sentimentNarrative() {
        return this.insight ? this.insight.Sentiment_Narrative__c : undefined;
    }

    get evaluation() {
        return this.insight ? this.insight.Performance_Evaluation__c : undefined;
    }

    get agentName() {
        return this.insight && this.insight.Agent__r ? this.insight.Agent__r.Name : undefined;
    }

    get model() {
        return this.insight ? this.insight.Model__c : undefined;
    }

    get analysisType() {
        return this.insight ? this.insight.Analysis_Type__c : undefined;
    }

    get createdDate() {
        return this.insight ? this.insight.CreatedDate : undefined;
    }

    get scoreClass() {
        const r = this.performanceRating;
        let base = 'rating-score slds-text-heading_large ';
        if (r >= 8) return base + 'score-excellent';
        if (r >= 6) return base + 'score-good';
        if (r >= 4) return base + 'score-fair';
        return base + 'score-poor';
    }

    get sentimentClass() {
        const s = this.sentimentRating;
        if (s === 'Positive') return 'sentiment-badge sentiment-positive';
        if (s === 'Negative') return 'sentiment-badge sentiment-negative';
        return 'sentiment-badge sentiment-neutral';
    }

    get categories() {
        if (!this.insight || !this.insight.Category_Scores__c) {
            return [];
        }
        let parsed;
        try {
            parsed = JSON.parse(this.insight.Category_Scores__c);
        } catch (e) {
            return [];
        }
        return CATEGORY_LABELS.map((c) => ({ key: c.key, label: c.label, text: parsed[c.key] })).filter(
            (c) => c.text
        );
    }
}
