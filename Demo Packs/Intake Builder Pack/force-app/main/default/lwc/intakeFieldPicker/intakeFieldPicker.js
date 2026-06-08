import { LightningElement, api, track } from 'lwc';
import listObjects from '@salesforce/apex/IntakeFieldDescribe.listObjects';
import listFields from '@salesforce/apex/IntakeFieldDescribe.listFields';

export default class IntakeFieldPicker extends LightningElement {
    @api label = 'Field';
    @api objectApiName;
    @api fieldApiName;
    @api typeFilter;
    @api allowObjectChange = false;

    @track objectOptions = [];
    @track fieldOptions = [];

    isLoadingObjects = false;
    isLoadingFields = false;
    error;

    connectedCallback() {
        if (this.allowObjectChange) this.loadObjects();
        if (this.objectApiName) this.loadFields();
    }

    async loadObjects() {
        this.isLoadingObjects = true;
        try {
            const data = await listObjects({ search: '' });
            this.objectOptions = (data || []).map((o) => ({
                label: `${o.label} (${o.apiName})`,
                value: o.apiName
            }));
        } catch (e) {
            this.error = 'Failed to load objects.';
        } finally {
            this.isLoadingObjects = false;
        }
    }

    async loadFields() {
        if (!this.objectApiName) {
            this.fieldOptions = [];
            return;
        }
        this.isLoadingFields = true;
        try {
            const data = await listFields({
                objectApiName: this.objectApiName,
                typeFilter: this.typeFilter || ''
            });
            this.fieldOptions = (data || []).map((f) => ({
                label: `${f.label} (${f.apiName})`,
                value: f.apiName
            }));
        } catch (e) {
            this.error = 'Failed to load fields.';
        } finally {
            this.isLoadingFields = false;
        }
    }

    handleObjectChange(event) {
        this.objectApiName = event.detail.value;
        this.fieldApiName = null;
        this.loadFields();
        this.dispatchEvent(new CustomEvent('objectchange', {
            detail: { value: this.objectApiName }
        }));
    }

    handleFieldChange(event) {
        this.fieldApiName = event.detail.value;
        this.dispatchEvent(new CustomEvent('fieldchange', {
            detail: { value: this.fieldApiName, objectApiName: this.objectApiName }
        }));
    }
}
