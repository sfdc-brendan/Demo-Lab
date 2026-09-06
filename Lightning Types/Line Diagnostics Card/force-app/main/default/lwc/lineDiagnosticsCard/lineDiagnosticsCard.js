import { LightningElement, api, track } from 'lwc';

const DASH = '—';

export default class LineDiagnosticsCard extends LightningElement {
    // Simple @api, no getter/setter. A property accessor here breaks renderer
    // registration and the component silently never mounts.
    @api value;

    @track data = {};
    @track errorMessage = '';
    @track replySent = false;

    connectedCallback() {
        // Keep this breadcrumb. When a card renders blank, the console in the
        // Agentforce iframe is the fastest way to see what actually arrived.
        console.log('#### LineDiagnosticsCard input:', this.value);

        try {
            if (!this.value || !this.value.diagnosticsJSON) {
                this.errorMessage = 'No diagnostics data provided.';
                return;
            }

            const raw = this.value.diagnosticsJSON;
            const parsed = typeof raw === 'string' ? JSON.parse(raw) : raw;

            if (parsed.error) {
                this.errorMessage = parsed.error;
                return;
            }

            this.data = parsed;
        } catch (e) {
            this.errorMessage = 'Error loading line diagnostics.';
        }
    }

    get hasError() {
        return !!this.errorMessage;
    }

    get hasData() {
        return !this.errorMessage && !!this.data.verdict;
    }

    // A payload with no verdict means the test never produced a reading. That is
    // a different answer from an error, so it gets its own neutral treatment.
    get noData() {
        return !this.errorMessage && !this.data.verdict;
    }

    get noDataMessage() {
        return this.data.reason || 'The remote line test returned no readings for this connection.';
    }

    get verdict() {
        return this.data.verdict || DASH;
    }

    get verdictClass() {
        return `sr-verdict sr-verdict_${this.data.verdictState || 'ok'}`;
    }

    get summary() {
        return this.data.summary || '';
    }

    get recommendation() {
        return this.data.recommendation || '';
    }

    get testedAt() {
        return this.data.testedAt || DASH;
    }

    get metrics() {
        return (this.data.metrics || []).map((m, i) => ({
            id: `metric-${i}`,
            label: m.label,
            value: m.value,
            valueClass: `sr-metric__value sr-metric__value_${m.state}`,
            barClass: `sr-bar__fill sr-bar__fill_${m.state}`,
            barStyle: `width: ${m.bar}%;`
        }));
    }

    // ---- Suggested replies ------------------------------------------------

    get explainMessage() {
        return `I ran a line test on your connection. ${this.summary} ${this.recommendation}`;
    }

    get retestMessage() {
        return 'Run the line test again for this customer.';
    }

    get appointmentMessage() {
        return 'Show me available technician appointment slots for this customer.';
    }

    get explainLabel() {
        return this.replySent ? 'Copied to reply' : 'Explain to customer';
    }

    // ---- Event dispatch ---------------------------------------------------
    // bubbles + composed are both required to cross the shadow boundary and
    // reach a host listener. A host that isn't listening is harmless, which is
    // why this card carries no console-API dependency of its own.

    copyToChat(message) {
        this.dispatchEvent(new CustomEvent('copytochat', {
            detail: { content: message },
            bubbles: true,
            composed: true
        }));
    }

    postToChat(message) {
        this.dispatchEvent(new CustomEvent('acc:execute', {
            detail: { content: message },
            bubbles: true,
            composed: true
        }));
    }

    handleExplain(event) {
        this.copyToChat(event.currentTarget.dataset.message);
        this.replySent = true;
    }

    handlePost(event) {
        this.postToChat(event.currentTarget.dataset.message);
    }
}
