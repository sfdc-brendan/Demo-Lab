import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getConversationScreenshots from '@salesforce/apex/VisionAgentAssistController.getConversationScreenshots';
import analyzeScreenshot from '@salesforce/apex/VisionAgentAssistController.analyzeScreenshot';

const DEFAULT_POLL_SECONDS = 6;
const MIN_POLL_SECONDS = 3;
const MAX_SCREENSHOTS = 12;

export default class VisionAgentAssist extends LightningElement {
    @api recordId;

    // Design attributes (configurable in App Builder).
    @api autoAnalyze = false;
    @api pollIntervalSeconds = DEFAULT_POLL_SECONDS;

    @track screenshots = [];
    @track resultsByDoc = {};

    selectedDocId;
    customerDescription = '';
    analyzingDocId;
    lastNewestDocId;
    isScanning = false;
    errorMessage;

    _pollHandle;

    connectedCallback() {
        this.scan();
        this.startPolling();
    }

    disconnectedCallback() {
        this.stopPolling();
    }

    startPolling() {
        const seconds = Math.max(MIN_POLL_SECONDS, Number(this.pollIntervalSeconds) || DEFAULT_POLL_SECONDS);
        this.stopPolling();
        this._pollHandle = window.setInterval(() => this.scan(), seconds * 1000);
    }

    stopPolling() {
        if (this._pollHandle) {
            window.clearInterval(this._pollHandle);
            this._pollHandle = undefined;
        }
    }

    async scan() {
        if (this.analyzingDocId || !this.recordId) {
            return;
        }
        try {
            const list = await getConversationScreenshots({
                recordId: this.recordId,
                maxItems: MAX_SCREENSHOTS
            });
            this.errorMessage = undefined;
            this.screenshots = list || [];
            if (this.screenshots.length === 0) {
                this.selectedDocId = undefined;
                return;
            }

            const newest = this.screenshots[0].contentDocumentId;
            const newestChanged = newest !== this.lastNewestDocId;
            if (newestChanged) {
                this.lastNewestDocId = newest;
                // A new screenshot just arrived - surface it.
                this.selectedDocId = newest;
                if (this.autoAnalyze) {
                    this.analyze(newest);
                }
            } else if (!this.selectedDocId || !this.hasScreenshotFor(this.selectedDocId)) {
                this.selectedDocId = newest;
            }
        } catch (e) {
            this.errorMessage = this.reduceError(e);
        }
    }

    hasScreenshotFor(docId) {
        return this.screenshots.some((s) => s.contentDocumentId === docId);
    }

    async analyze(docId) {
        const targetId = docId || this.selectedDocId;
        if (!targetId || this.analyzingDocId) {
            return;
        }
        this.analyzingDocId = targetId;
        this.errorMessage = undefined;
        try {
            const res = await analyzeScreenshot({
                recordId: this.recordId,
                contentDocumentId: targetId,
                customerDescription: this.customerDescription
            });
            this.resultsByDoc = { ...this.resultsByDoc, [targetId]: res };
            if (res && res.success !== true) {
                this.errorMessage = res.message || 'The screenshot could not be analyzed.';
            }
        } catch (e) {
            this.errorMessage = this.reduceError(e);
        } finally {
            this.analyzingDocId = undefined;
        }
    }

    handleSelectThumbnail(event) {
        const docId = event.currentTarget.dataset.docId;
        if (!docId || docId === this.selectedDocId) {
            return;
        }
        this.selectedDocId = docId;
        this.errorMessage = undefined;
        if (this.autoAnalyze && !this.resultsByDoc[docId]) {
            this.analyze(docId);
        }
    }

    handleAnalyzeClick() {
        this.analyze(this.selectedDocId);
    }

    async handleRescan() {
        this.isScanning = true;
        try {
            await this.scan();
        } finally {
            this.isScanning = false;
        }
    }

    handleDescriptionChange(event) {
        this.customerDescription = event.target.value;
    }

    handleCopySteps() {
        if (!this.hasSteps) {
            return;
        }
        const text = this.result.steps.map((step, i) => `${i + 1}. ${step}`).join('\n');
        this.copyToClipboard(text, 'Troubleshooting steps copied to your clipboard.');
    }

    copyToClipboard(text, successMessage) {
        if (navigator.clipboard && navigator.clipboard.writeText) {
            navigator.clipboard
                .writeText(text)
                .then(() => this.toast('Copied', successMessage, 'success'))
                .catch(() => this.toast('Copy failed', 'Could not access the clipboard.', 'error'));
        } else {
            this.toast('Copy unavailable', 'Clipboard access is not available here.', 'warning');
        }
    }

    toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    reduceError(error) {
        if (!error) {
            return 'Unknown error';
        }
        if (Array.isArray(error.body)) {
            return error.body.map((e) => e.message).join(', ');
        }
        if (error.body && typeof error.body.message === 'string') {
            return error.body.message;
        }
        if (typeof error.message === 'string') {
            return error.message;
        }
        return 'Unexpected error';
    }

    /* -------------------------- view getters -------------------------- */

    get selectedScreenshot() {
        return this.screenshots.find((s) => s.contentDocumentId === this.selectedDocId);
    }

    get hasScreenshot() {
        return !!this.selectedScreenshot;
    }

    get screenshotCount() {
        return this.screenshots.length;
    }

    get hasMultiple() {
        return this.screenshots.length > 1;
    }

    get countLabel() {
        const n = this.screenshots.length;
        return n === 1 ? '1 screenshot' : `${n} screenshots`;
    }

    get thumbnails() {
        return this.screenshots.map((s, index) => {
            const isSelected = s.contentDocumentId === this.selectedDocId;
            const analyzed = !!this.resultsByDoc[s.contentDocumentId];
            return {
                contentDocumentId: s.contentDocumentId,
                previewUrl: s.previewUrl,
                title: s.title,
                position: index + 1,
                isSelected,
                analyzed,
                cssClass: isSelected ? 'va-thumb-chip va-thumb-chip_selected' : 'va-thumb-chip'
            };
        });
    }

    get result() {
        return this.selectedDocId ? this.resultsByDoc[this.selectedDocId] : undefined;
    }

    get isAnalyzing() {
        return !!this.analyzingDocId && this.analyzingDocId === this.selectedDocId;
    }

    get hasResult() {
        return !!this.result && this.result.success === true;
    }

    get hasSteps() {
        return this.hasResult && this.result.grounded && this.result.steps && this.result.steps.length > 0;
    }

    get numberedSteps() {
        if (!this.hasSteps) {
            return [];
        }
        return this.result.steps.map((step, index) => ({
            key: `step-${index}`,
            number: index + 1,
            text: step
        }));
    }

    get keywordPills() {
        if (!this.hasResult || !this.result.keywords) {
            return [];
        }
        return this.result.keywords
            .split(',')
            .map((k) => k.trim())
            .filter((k) => k.length > 0)
            .map((label, index) => ({ key: `kw-${index}`, label }));
    }

    get hasKeywords() {
        return this.keywordPills.length > 0;
    }

    get hasArticles() {
        return this.hasResult && this.result.articles && this.result.articles.length > 0;
    }

    get showNoStepsNotice() {
        return this.hasResult && !this.hasSteps;
    }

    get showEmptyState() {
        return !this.hasScreenshot && !this.errorMessage;
    }

    get analyzeDisabled() {
        return !!this.analyzingDocId || !this.hasScreenshot;
    }

    get analyzeLabel() {
        return this.hasResult ? 'Re-analyze screenshot' : 'Analyze screenshot';
    }

    get isNewSelection() {
        return this.hasScreenshot && !this.result && !this.isAnalyzing;
    }
}
