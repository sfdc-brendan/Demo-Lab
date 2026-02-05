import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, updateRecord, notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

export default class SentimentTracker extends LightningElement {
    @api recordId;
    @api objectApiName;
    
    @track sentimentRating = '';
    @track callSentiment = '';
    @track isLoading = true;
    @track isSaving = false;
    @track error;
    @track saveStatus = '';
    @track originalData = {};
    @track isEditing = true;
    
    // Wire the record data
    wiredRecordResult;

    get sentimentRatingFields() {
        // Define fields based on object type
        if (this.objectApiName === 'MessagingSession') {
            return ['MessagingSession.SentimentRating__c', 'MessagingSession.ChatSentiment__c'];
        } else {
            return ['VoiceCall.Sentiment_Rating__c', 'VoiceCall.Call_Sentiment__c'];
        }
    }

    @wire(getRecord, { 
        recordId: '$recordId', 
        fields: '$sentimentRatingFields' 
    })
    wiredRecord(result) {
        this.wiredRecordResult = result;
        this.isLoading = true;
        
        if (result.data) {
            this.handleRecordData(result.data);
        } else if (result.error) {
            this.error = result.error.body?.message || 'Error loading record data';
            this.isLoading = false;
        }
    }

    handleRecordData(data) {
        try {
            const fields = data.fields;
            
            // Handle both Voice Call and Messaging Session fields
            if (this.objectApiName === 'MessagingSession') {
                this.sentimentRating = fields.SentimentRating__c?.value || '';
                this.callSentiment = fields.ChatSentiment__c?.value || '';
            } else {
                this.sentimentRating = fields.Sentiment_Rating__c?.value || '';
                this.callSentiment = fields.Call_Sentiment__c?.value || '';
            }
            
            // Store original data for comparison
            this.originalData = {
                sentimentRating: this.sentimentRating,
                callSentiment: this.callSentiment
            };
            
            // Set editing mode: if no sentiment, allow editing; otherwise, view mode
            this.isEditing = !this.sentimentRating;
            this.error = null;
        } catch (error) {
            this.error = 'Error processing record data: ' + error.message;
        } finally {
            this.isLoading = false;
        }
    }

    // Computed properties for sentiment selection
    get isPositiveSelected() {
        return this.sentimentRating === 'Positive';
    }

    get isNeutralSelected() {
        return this.sentimentRating === 'Neutral';
    }

    get isNegativeSelected() {
        return this.sentimentRating === 'Negative';
    }

    // Handle sentiment rating change
    handleSentimentChange(event) {
        const rating = event.currentTarget.dataset.rating;
        this.sentimentRating = rating;
        this.clearSaveStatus();
    }

    // Handle call sentiment text change
    handleSentimentTextChange(event) {
        this.callSentiment = event.target.value;
        this.clearSaveStatus();
    }

    // Handle save action
    async handleSave() {
        if (!this.sentimentRating) {
            this.showToast('Error', 'Please select a sentiment rating', 'error');
            return;
        }

        this.isSaving = true;
        this.clearSaveStatus();

        try {
            const fields = {};
            fields.Id = this.recordId;
            
            // Set fields based on object type
            if (this.objectApiName === 'MessagingSession') {
                fields.SentimentRating__c = this.sentimentRating;
                fields.ChatSentiment__c = this.callSentiment;
            } else {
                fields.Sentiment_Rating__c = this.sentimentRating;
                fields.Call_Sentiment__c = this.callSentiment;
            }

            const recordInput = { fields };
            await updateRecord(recordInput);

            // Update original data
            this.originalData = {
                sentimentRating: this.sentimentRating,
                callSentiment: this.callSentiment
            };

            // Refresh the record data
            await refreshApex(this.wiredRecordResult);

            this.saveStatus = 'Sentiment data saved successfully!';
            this.showToast('Success', 'Sentiment data saved successfully!', 'success');
            this.isEditing = false;

        } catch (error) {
            console.error('Error saving sentiment data:', error);
            this.error = error.body?.message || 'Error saving sentiment data';
            this.showToast('Error', 'Failed to save sentiment data', 'error');
        } finally {
            this.isSaving = false;
        }
    }

    // Handle cancel action
    handleCancel() {
        this.sentimentRating = this.originalData.sentimentRating || '';
        this.callSentiment = this.originalData.callSentiment || '';
        this.clearSaveStatus();
        this.error = null;
        this.isEditing = false;
    }

    // Handle edit action
    handleEdit() {
        this.isEditing = true;
    }

    // Clear save status
    clearSaveStatus() {
        this.saveStatus = '';
    }

    // Show toast notification
    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(evt);
    }

    // Check if data has changed
    get hasChanges() {
        return this.sentimentRating !== this.originalData.sentimentRating ||
               this.callSentiment !== this.originalData.callSentiment;
    }

    /**
     * Refresh record data from the server. Use when analysis may have completed in the background.
     * LDS does not auto-refresh when async flows update the record.
     */
    async handleRefresh() {
        this.isLoading = true;
        try {
            await notifyRecordUpdateAvailable([this.recordId]);
            this.showToast('Refreshed', 'Sentiment data updated', 'success');
        } catch (e) {
            this.showToast('Refresh failed', e?.body?.message || String(e), 'error');
        } finally {
            this.isLoading = false;
        }
    }
}