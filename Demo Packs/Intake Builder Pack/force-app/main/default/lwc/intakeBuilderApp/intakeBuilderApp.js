import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LightningConfirm from 'lightning/confirm';
import listTemplates from '@salesforce/apex/IntakeBuilderController.listTemplates';
import createTemplate from '@salesforce/apex/IntakeBuilderController.createTemplate';
import cloneTemplate from '@salesforce/apex/IntakeBuilderController.cloneTemplate';
import deleteTemplate from '@salesforce/apex/IntakeBuilderController.deleteTemplate';

const STATUS_FILTERS = [
    { label: 'All', value: '' },
    { label: 'Draft', value: 'Draft' },
    { label: 'Active', value: 'Active' },
    { label: 'Archived', value: 'Archived' }
];

export default class IntakeBuilderApp extends LightningElement {
    @track view = 'list';
    @track selectedTemplateId;
    @track templates = [];
    @track statusFilter = '';

    statusFilters = STATUS_FILTERS;
    isLoading = false;
    error;

    connectedCallback() {
        this.loadList();
    }

    async loadList() {
        this.isLoading = true;
        try {
            this.templates = await listTemplates({ statusFilter: this.statusFilter });
        } catch (e) {
            this.error = this.reduceError(e);
        } finally {
            this.isLoading = false;
        }
    }

    get displayTemplates() {
        return (this.templates || []).map((t) => ({
            ...t,
            statusVariant: t.status === 'Active'
                ? 'success'
                : t.status === 'Archived'
                ? 'warning'
                : 'info'
        }));
    }

    get isListView() {
        return this.view === 'list';
    }

    get isEditorView() {
        return this.view === 'editor';
    }

    handleStatusFilterChange(event) {
        this.statusFilter = event.detail.value;
        this.loadList();
    }

    handleOpen(event) {
        this.selectedTemplateId = event.currentTarget.dataset.id;
        this.view = 'editor';
    }

    async handleClone(event) {
        const id = event.currentTarget.dataset.id;
        try {
            const newId = await cloneTemplate({ sourceId: id });
            this.toast('Cloned', 'Template was cloned.', 'success');
            this.selectedTemplateId = newId;
            this.view = 'editor';
        } catch (e) {
            this.toast('Clone failed', this.reduceError(e), 'error');
        }
    }

    async handleNew() {
        try {
            const newId = await createTemplate({ name: 'New Intake Template' });
            this.selectedTemplateId = newId;
            this.view = 'editor';
        } catch (e) {
            this.toast('Create failed', this.reduceError(e), 'error');
        }
    }

    async handleDelete(event) {
        const id = event.currentTarget.dataset.id;
        const confirmed = await LightningConfirm.open({
            message: 'Delete this template and all of its questions? This cannot be undone.',
            variant: 'headerless',
            label: 'Delete Intake Template'
        });
        if (!confirmed) return;

        try {
            await deleteTemplate({ templateId: id });
            this.toast('Deleted', 'Template was deleted.', 'success');
            await this.loadList();
        } catch (e) {
            this.toast('Delete failed', this.reduceError(e), 'error');
        }
    }

    handleBack() {
        this.selectedTemplateId = null;
        this.view = 'list';
        this.loadList();
    }

    toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    reduceError(error) {
        if (typeof error === 'string') return error;
        if (error?.body?.message) return error.body.message;
        if (error?.message) return error.message;
        return 'An unexpected error occurred.';
    }
}
