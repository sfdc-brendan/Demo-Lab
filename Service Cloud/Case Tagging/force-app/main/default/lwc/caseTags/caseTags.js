import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import CASE_TAGS_FIELD from '@salesforce/schema/Case.Case_Tags__c';
import CASE_TAGS_LAST_ANALYZED from '@salesforce/schema/Case.Case_Tags_Last_Analyzed_Date__c';
import addTag from '@salesforce/apex/CaseTaggingController.addTag';
import removeTag from '@salesforce/apex/CaseTaggingController.removeTag';
import runAnalysis from '@salesforce/apex/CaseTaggingController.runAnalysis';

const CASE_FIELDS = [CASE_TAGS_FIELD, CASE_TAGS_LAST_ANALYZED];

export default class CaseTags extends LightningElement {
    @api recordId;

    caseTagsRaw;
    lastAnalyzedFormatted;
    newTagValue = '';
    tagList = [];
    isLoading = false;
    wiredRecordResult;

    @wire(getRecord, { recordId: '$recordId', fields: CASE_FIELDS })
    wiredCase(result) {
        this.wiredRecordResult = result;
        if (result.data) {
            this.caseTagsRaw = getFieldValue(result.data, CASE_TAGS_FIELD);
            const dt = getFieldValue(result.data, CASE_TAGS_LAST_ANALYZED);
            this.lastAnalyzedFormatted = dt ? new Date(dt).toLocaleString() : null;
            this.buildTagList();
        } else if (result.error) {
            this.tagList = [];
        }
    }

    get hasTags() {
        return this.tagList && this.tagList.length > 0;
    }

    get pillItems() {
        if (!this.tagList || this.tagList.length === 0) {
            return [];
        }
        return this.tagList.map((tag) => ({ label: tag, name: tag }));
    }

    get lastAnalyzed() {
        return this.lastAnalyzedFormatted || '';
    }

    get addTagDisabled() {
        return !this.newTagValue || this.newTagValue.trim() === '' || this.isLoading;
    }

    get analysisDisabled() {
        return !this.recordId || this.isLoading;
    }

    buildTagList() {
        if (!this.caseTagsRaw || this.caseTagsRaw.trim() === '') {
            this.tagList = [];
            return;
        }
        this.tagList = this.caseTagsRaw
            .split(',')
            .map((s) => s.trim())
            .filter((s) => s.length > 0);
    }

    handleNewTagChange(event) {
        this.newTagValue = event.target.value || '';
    }

    handleNewTagKeydown(event) {
        if (event.key === 'Enter') {
            event.preventDefault();
            this.handleAddTag();
        }
    }

    async handleAddTag() {
        const tag = (this.newTagValue || '').trim();
        if (!tag || !this.recordId) return;
        this.isLoading = true;
        try {
            await addTag({ caseId: this.recordId, newTag: tag });
            this.newTagValue = '';
            this.showToast('Success', 'Tag added.', 'success');
            await refreshApex(this.wiredRecordResult);
        } catch (e) {
            this.showToast('Error', e.body?.message || e.message || 'Failed to add tag', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    handleActionsMenuSelect(event) {
        const value = event.detail?.value;
        if (value === 'run_analysis') {
            this.doRunAnalysis();
        }
    }

    async doRunAnalysis() {
        if (!this.recordId) return;
        this.isLoading = true;
        try {
            await runAnalysis({ caseId: this.recordId });
            this.showToast('Success', 'Case analysis completed.', 'success');
            await refreshApex(this.wiredRecordResult);
        } catch (e) {
            this.showToast('Error', e.body?.message || e.message || 'Analysis failed', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    async handleRemoveTag(event) {
        const name = event.detail?.item;
        if (!name || !this.recordId) return;
        this.isLoading = true;
        try {
            await removeTag({ caseId: this.recordId, tagToRemove: name });
            this.showToast('Tag removed', `"${name}" removed.`, 'success');
            await refreshApex(this.wiredRecordResult);
        } catch (e) {
            this.showToast('Error', e.body?.message || e.message || 'Failed to remove tag', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
