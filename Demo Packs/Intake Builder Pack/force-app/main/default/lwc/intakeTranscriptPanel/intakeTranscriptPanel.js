import { LightningElement, api } from 'lwc';

export default class IntakeTranscriptPanel extends LightningElement {
    @api entries = [];

    isExpanded = true;
    clipboardError = '';

    get customerEntries() {
        return this.entries.filter((e) => e.isCustomer).slice(0, 5);
    }

    get hasEntries() {
        return this.customerEntries.length > 0;
    }

    get toggleIcon() {
        return this.isExpanded ? 'utility:chevrondown' : 'utility:chevronright';
    }

    get toggleLabel() {
        return this.isExpanded ? 'Collapse transcript' : 'Expand transcript';
    }

    get showClipboardError() {
        return this.clipboardError !== '';
    }

    handleToggle() {
        this.isExpanded = !this.isExpanded;
    }

    handleUseAnswer(event) {
        const message = event.currentTarget.dataset.message;
        this.dispatchEvent(
            new CustomEvent('useanswer', { detail: { value: message } })
        );
    }

    handlePaste(event) {
        const text = (event.clipboardData || window.clipboardData)?.getData('text');
        if (text) {
            this.clipboardError = '';
            this.dispatchEvent(
                new CustomEvent('transcriptpaste', { detail: { text } })
            );
        }
    }

    async handleCaptureClipboard() {
        try {
            const text = await navigator.clipboard.readText();
            if (text) {
                this.clipboardError = '';
                const textarea = this.template.querySelector('.transcript-paste-area');
                if (textarea) textarea.value = text;
                this.dispatchEvent(
                    new CustomEvent('transcriptpaste', { detail: { text } })
                );
            }
        } catch (e) {
            this.clipboardError = 'Clipboard access denied. Please paste manually (Ctrl+V).';
        }
    }
}
