import { LightningElement, track } from 'lwc';
import getCandidates from '@salesforce/apex/HistoricalAnalysisController.getCandidates';
import runHistoricalAnalysis from '@salesforce/apex/HistoricalAnalysisController.runHistoricalAnalysis';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const OBJECT_OPTIONS = [
    { label: 'Voice Calls only', value: 'VoiceCall' },
    { label: 'Messaging Sessions only', value: 'MessagingSession' },
    { label: 'Both', value: 'Both' }
];

const DAYS_OPTIONS = [
    { label: 'Last 7 days', value: '7' },
    { label: 'Last 14 days (2 weeks)', value: '14' }
];

export default class HistoricalAnalysisLauncher extends LightningElement {
    @track objectType = 'Both';
    @track daysBack = '14';
    @track candidates = [];
    @track message = '';
    @track isLoading = false;
    @track isRunning = false;
    @track selectedIds = [];

    get objectOptions() {
        return OBJECT_OPTIONS;
    }

    get daysOptions() {
        return DAYS_OPTIONS;
    }

    get hasCandidates() {
        return this.candidates && this.candidates.length > 0;
    }

    get candidateCount() {
        return this.candidates ? this.candidates.length : 0;
    }

    get hasSelection() {
        return this.selectedIds.length > 0;
    }

    get selectedCount() {
        return this.selectedIds.length;
    }

    get runButtonLabel() {
        if (this.selectedIds.length === 0) return 'Run analysis';
        return `Run analysis on ${this.selectedIds.length} record(s)`;
    }

    get allSelected() {
        return this.hasCandidates && this.selectedIds.length === this.candidates.length;
    }

    get someSelected() {
        return this.selectedIds.length > 0 && this.selectedIds.length < this.candidates.length;
    }

    handleObjectChange(event) {
        this.objectType = event.detail.value;
        this.candidates = [];
        this.message = '';
        this.selectedIds = [];
    }

    handleDaysChange(event) {
        this.daysBack = event.detail.value;
        this.candidates = [];
        this.message = '';
        this.selectedIds = [];
    }

    async handleFind() {
        this.isLoading = true;
        this.message = '';
        this.candidates = [];
        this.selectedIds = [];
        try {
            const result = await getCandidates({
                objectType: this.objectType,
                daysBack: parseInt(this.daysBack, 10) || 14
            });
            const raw = result.records || [];
            this.candidates = raw.map(c => ({
                ...c,
                recordUrl: '/' + c.id,
                createdDateFormatted: this.formatDate(c.createdDate),
                selected: this.selectedIds.includes(c.id)
            }));
            this.message = result.message || '';
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Search complete',
                    message: result.message || '',
                    variant: this.candidates.length > 0 ? 'success' : 'info'
                })
            );
        } catch (e) {
            this.message = e.body?.message || e.message || 'An error occurred.';
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: this.message,
                    variant: 'error'
                })
            );
        } finally {
            this.isLoading = false;
        }
    }

    handleSelectAll(event) {
        const checked = event.target.checked;
        if (checked) {
            this.selectedIds = this.candidates.map(c => c.id);
        } else {
            this.selectedIds = [];
        }
        this.refreshCandidatesSelection();
    }

    handleSelectRow(event) {
        const id = event.target.dataset.id;
        if (!id) return;
        const idx = this.selectedIds.indexOf(id);
        if (idx >= 0) {
            this.selectedIds = this.selectedIds.filter(s => s !== id);
        } else {
            this.selectedIds = [...this.selectedIds, id];
        }
        this.refreshCandidatesSelection();
    }

    refreshCandidatesSelection() {
        if (!this.candidates || this.candidates.length === 0) return;
        this.candidates = this.candidates.map(c => ({
            ...c,
            selected: this.selectedIds.includes(c.id)
        }));
    }

    get selectedIdList() {
        return [...this.selectedIds];
    }

    async handleRun() {
        if (this.selectedIds.length === 0) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'No selection',
                    message: 'Select at least one record to analyze.',
                    variant: 'warning'
                })
            );
            return;
        }

        this.isRunning = true;
        try {
            const result = await runHistoricalAnalysis({
                recordIds: this.selectedIdList
            });
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Analysis queued',
                    message: result,
                    variant: 'success',
                    mode: 'sticky'
                })
            );
            this.candidates = [];
            this.message = result;
            this.selectedIds = [];
        } catch (e) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: e.body?.message || e.message || 'Failed to queue analysis.',
                    variant: 'error'
                })
            );
        } finally {
            this.isRunning = false;
        }
    }

    formatDate(dateValue) {
        if (!dateValue) return '';
        const d = new Date(dateValue);
        return d.toLocaleDateString(undefined, {
            month: 'short',
            day: 'numeric',
            year: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        });
    }
}
