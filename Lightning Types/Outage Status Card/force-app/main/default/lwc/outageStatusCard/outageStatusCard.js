import { LightningElement, api, track } from 'lwc';

const DASH = '—';

export default class OutageStatusCard extends LightningElement {
    // Simple @api, no getter/setter. A property accessor here breaks renderer
    // registration and the component silently never mounts.
    @api value;

    @track data = {};
    @track errorMessage = '';
    @track replySent = false;

    connectedCallback() {
        // Keep this breadcrumb. When a card renders blank, the console in the
        // Agentforce iframe is the fastest way to see what actually arrived.
        console.log('#### OutageStatusCard input:', this.value);

        try {
            if (!this.value || !this.value.outageJSON) {
                this.errorMessage = 'No outage data provided.';
                return;
            }

            const raw = this.value.outageJSON;
            const parsed = typeof raw === 'string' ? JSON.parse(raw) : raw;

            if (parsed.error) {
                this.errorMessage = parsed.error;
                return;
            }

            this.data = parsed;
        } catch (e) {
            this.errorMessage = 'Error loading outage status.';
        }
    }

    get hasError() {
        return !!this.errorMessage;
    }

    get outageFound() {
        return !this.errorMessage && this.data.outageFound === true;
    }

    get noOutage() {
        return !this.errorMessage && this.data.outageFound === false;
    }

    get ticketNumber() {
        return this.data.ticketNumber || DASH;
    }

    get cause() {
        return this.data.cause || DASH;
    }

    get area() {
        return this.data.area || DASH;
    }

    get crewStatus() {
        return this.data.crewStatus || DASH;
    }

    get etaTime() {
        return this.data.etaTime || DASH;
    }

    get etaCountdown() {
        return this.data.etaCountdown || '';
    }

    get startedAt() {
        return this.data.startedAt || DASH;
    }

    get elapsed() {
        return this.data.elapsed || '';
    }

    get affectedCustomers() {
        const v = this.data.affectedCustomers;
        return typeof v === 'number' ? v.toLocaleString() : DASH;
    }

    get steps() {
        return (this.data.steps || []).map((s, i) => ({
            id: `step-${i}`,
            label: s.label,
            markerClass: `sr-step__marker sr-step__marker_${s.state}`,
            labelClass: `sr-step__label sr-step__label_${s.state}`,
            // The connector runs from this step to the next, so the last omits it.
            showConnector: i < this.data.steps.length - 1,
            connectorClass: s.state === 'done' ? 'sr-step__line sr-step__line_done' : 'sr-step__line'
        }));
    }

    // ---- Suggested replies ------------------------------------------------

    get explainMessage() {
        return `I've confirmed there's a network outage affecting your area (${this.area}). The cause is ${this.cause}. Our crew is on it — ${this.crewStatus} — and we expect service back around ${this.etaTime}. You don't need to reset any equipment; it will come back on its own.`;
    }

    get equipmentMessage() {
        return 'Show me the equipment at this service address.';
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
