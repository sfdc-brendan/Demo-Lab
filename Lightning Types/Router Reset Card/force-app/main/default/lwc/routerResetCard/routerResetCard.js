import { LightningElement, api, track } from 'lwc';

const DASH = '—';

export default class RouterResetCard extends LightningElement {
    // Simple @api, no getter/setter. A property accessor here breaks renderer
    // registration and the component silently never mounts.
    @api value;

    @track data = {};
    @track errorMessage = '';
    @track restartRequested = false;
    @track replySent = false;

    connectedCallback() {
        // Keep this breadcrumb. When a card renders blank, the console in the
        // Agentforce iframe is the fastest way to see what actually arrived.
        console.log('#### RouterResetCard input:', this.value);

        try {
            if (!this.value || !this.value.routerJSON) {
                this.errorMessage = 'No gateway data provided.';
                return;
            }

            const raw = this.value.routerJSON;
            const parsed = typeof raw === 'string' ? JSON.parse(raw) : raw;

            if (parsed.error) {
                this.errorMessage = parsed.error;
                return;
            }

            this.data = parsed;
        } catch (e) {
            this.errorMessage = 'Error loading gateway health.';
        }
    }

    // ---- State ------------------------------------------------------------

    get hasError() {
        return !!this.errorMessage;
    }

    get gatewayFound() {
        return !this.errorMessage && this.data.gatewayFound === true;
    }

    get noGateway() {
        return !this.errorMessage && this.data.gatewayFound === false;
    }

    get device() {
        return this.data.device || {};
    }

    get deviceName() {
        return this.device.name || DASH;
    }

    get serialNumber() {
        return this.device.serial || DASH;
    }

    // Optional. Left out of the demo payload so nothing is fetched over the
    // network; the template falls back to a drawn placeholder.
    get imageUrl() {
        return this.device.imageUrl;
    }

    get deviceHealth() {
        return this.device.health || DASH;
    }

    get healthClass() {
        const health = (this.device.health || 'healthy').toLowerCase();
        return `sr-health sr-health_${health}`;
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

    get restartStamp() {
        return this.data.lastRestarted ? `Restarted ${this.data.lastRestarted}` : '';
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

    // ---- Self-restart history ---------------------------------------------
    // The pattern is the argument. One restart is noise; a unit that reboots
    // itself in the small hours every other day has a hardware fault, and that
    // is what turns "try a restart" into "restart now, then replace it".

    get rebootHistory() {
        return (this.data.rebootHistory || []).map((r, i) => ({
            id: `reboot-${i}`,
            when: r.when,
            reason: r.reason
        }));
    }

    get hasRebootHistory() {
        return this.rebootHistory.length > 0;
    }

    /** The list is capped for readability, so account for the ones not shown. */
    get rebootMore() {
        const remaining = (this.data.rebootCount || 0) - this.rebootHistory.length;
        return remaining > 0
            ? `${remaining} earlier restarts in the last 30 days`
            : '';
    }

    get rebootWarning() {
        return this.data.replacementRecommended === true;
    }

    get rebootText() {
        const warranty = this.data.outOfWarranty === true ? ' and is out of warranty' : '';
        return `This gateway has restarted itself ${this.data.rebootCount} times in the `
            + `last 30 days${warranty}.`;
    }

    // ---- Actions ----------------------------------------------------------

    get canRestart() {
        return this.data.canRestart === true;
    }

    /**
     * A restart is triage, not a repair. When the unit is rebooting itself the
     * replacement offer sits alongside the restart rather than after it, so the
     * rep fixes today's call and the underlying fault in one pass.
     */
    get showReplace() {
        return this.data.replacementRecommended === true;
    }

    /** With nothing to fix, the only useful follow-up is to look again later. */
    get showRecheck() {
        return !this.canRestart && !this.showReplace;
    }

    get restartLabel() {
        return this.restartRequested ? 'Restart sent' : 'Send network restart';
    }

    get explainLabel() {
        return this.replySent ? 'Copied to reply' : 'Explain to customer';
    }

    // ---- Suggested replies ------------------------------------------------

    /**
     * Posted as an utterance, never executed here. The restart is a separate
     * confirmed action — this card diagnoses and asks, it does not write.
     */
    get restartMessage() {
        return `Send a network-side restart to the ${this.deviceName}, serial ${this.serialNumber}.`;
    }

    get replaceMessage() {
        return `Start a replacement for the ${this.deviceName}, serial ${this.serialNumber}.`;
    }

    get recheckMessage() {
        return 'Run the gateway health check again for this customer.';
    }

    /** Written in second person — this is the text the customer actually receives. */
    get explainMessage() {
        if (!this.canRestart) {
            return `I've run a full check on your gateway and everything is reading in spec `
                + `— it's holding a steady connection, there's no packet loss, and your `
                + `Wi-Fi channel is clear. Restarting it would knock you offline for about `
                + `90 seconds without changing any of that, so I'd rather look at what's `
                + `happening inside the home instead.`;
        }

        return `I can see exactly what's happening. The line into your home is fine, but `
            + `your gateway is dropping packets and its Wi-Fi is fighting with eleven `
            + `neighboring networks on the same channel — that's the buffering you're `
            + `seeing. I can send a restart from our side that re-establishes the `
            + `connection properly and moves you to a clear channel; it's deeper than `
            + `unplugging it. Give me about 90 seconds.`;
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

    handleRestart(event) {
        this.postToChat(event.currentTarget.dataset.message);
        this.restartRequested = true;
    }

    handlePost(event) {
        this.postToChat(event.currentTarget.dataset.message);
    }

    handleExplain(event) {
        this.copyToChat(event.currentTarget.dataset.message);
        this.replySent = true;
    }
}
