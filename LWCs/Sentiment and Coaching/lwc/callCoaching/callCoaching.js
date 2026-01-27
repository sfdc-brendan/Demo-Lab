import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import RATING_FIELD from '@salesforce/schema/VoiceCall.Agent_Performance_Rating__c';
import EVALUATION_FIELD from '@salesforce/schema/VoiceCall.Agent_Performance_Evaluation__c';
import ID_FIELD from '@salesforce/schema/VoiceCall.Id';

export default class CallCoaching extends LightningElement {
    @api recordId;
    @api buttonColor = '#0176d3'; // Default Salesforce blue
    @track performanceRating;
    @track performanceEvaluation;
    @track isEditing = false;
    @track isLoading = true;
    @track isSaving = false;
    @track error;

    @wire(getRecord, { recordId: '$recordId', fields: [RATING_FIELD, EVALUATION_FIELD] })
    wiredRecord({ error, data }) {
        this.isLoading = false;
        if (data) {
            this.performanceRating = data.fields.Agent_Performance_Rating__c.value;
            this.performanceEvaluation = data.fields.Agent_Performance_Evaluation__c.value;
            this.isEditing = !this.performanceRating && !this.performanceEvaluation;
        } else if (error) {
            this.error = 'Failed to load record';
            console.error(error);
        }
    }

    get callAnalysisButtonStyle() {
        return `background-color: ${this.buttonColor}; color: #fff; border: none;`;
    }

    handleEdit() {
        this.isEditing = true;
    }

    handleCancel() {
        this.isEditing = false;
    }

    handleRatingChange(event) {
        this.performanceRating = event.target.value;
    }

    handleEvaluationChange(event) {
        this.performanceEvaluation = event.target.value;
    }

    handleSave() {
        this.isSaving = true;
        const fields = {};
        fields[ID_FIELD.fieldApiName] = this.recordId;
        fields[RATING_FIELD.fieldApiName] = this.performanceRating;
        fields[EVALUATION_FIELD.fieldApiName] = this.performanceEvaluation;

        const recordInput = { fields };

        updateRecord(recordInput)
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Record updated',
                        variant: 'success'
                    })
                );
                this.isEditing = false;
                this.isSaving = false;
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error updating record',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
                this.isSaving = false;
            });
    }

    openCallAnalysis() {
        window.open('https://storm-186cf5188ab07e.lightning.force.com/lightning/r/VoiceCall/0LQHs000005H6x4OAC/view', '_blank');
    }
}