import { LightningElement, api, track } from 'lwc';

const DASH = '—';

export default class PlanUpgradeCard extends LightningElement {
    // Simple @api, no getter/setter. A property accessor here breaks renderer
    // registration and the component silently never mounts.
    @api value;

    @track data = {};
    @track errorMessage = '';
    @track upgradeRequested = false;

    connectedCallback() {
        // Keep this breadcrumb. When a card renders blank, the console in the
        // Agentforce iframe is the fastest way to see what actually arrived.
        console.log('#### PlanUpgradeCard input:', this.value);

        try {
            if (!this.value || !this.value.upgradeJSON) {
                this.errorMessage = 'No plan data provided.';
                return;
            }

            const raw = this.value.upgradeJSON;
            const parsed = typeof raw === 'string' ? JSON.parse(raw) : raw;

            if (parsed.error) {
                this.errorMessage = parsed.error;
                return;
            }

            this.data = parsed;
        } catch (e) {
            this.errorMessage = 'Error loading plan options.';
        }
    }

    // ---- State ------------------------------------------------------------

    get hasError() {
        return !!this.errorMessage;
    }

    get hasPlans() {
        return !this.errorMessage && !!this.data.current;
    }

    get current() {
        return this.data.current || {};
    }

    get recommended() {
        return this.data.recommended || {};
    }

    get isTopTier() {
        return !!this.data.topTier;
    }

    get canUpgrade() {
        return this.hasPlans && !this.isTopTier && !!this.data.recommended;
    }

    get currentFeatures() {
        return (this.current.features || []).map((f, i) => ({ id: `c-${i}`, label: f }));
    }

    get recommendedFeatures() {
        return (this.recommended.features || []).map((f, i) => ({ id: `r-${i}`, label: f }));
    }

    get currentPrice() {
        return this.formatPrice(this.current.monthlyPrice);
    }

    get recommendedPrice() {
        return this.formatPrice(this.recommended.monthlyPrice);
    }

    get monthlyIncrease() {
        return this.formatPrice(this.data.monthlyIncrease);
    }

    formatPrice(v) {
        return v === undefined || v === null ? DASH : `$${Number(v).toFixed(2)}`;
    }

    get hasPromo() {
        return !!this.recommended.promo;
    }

    // ---- Suggested replies ------------------------------------------------

    get upgradeMessage() {
        return `Upgrade this customer to ${this.recommended.name}.`;
    }

    /** Written in second person — this is the text the customer actually receives. */
    get explainMessage() {
        const r = this.recommended;
        const promo = r.promo ? ` We'll also waive the $99 install fee.` : '';
        return `Good news — I can move you to ${r.name}. That takes you from `
            + `${this.current.downloadMbps} Mbps to ${r.downloadMbps} Mbps download and `
            + `${r.uploadMbps} Mbps upload, for ${this.formatPrice(r.monthlyPrice)} a month `
            + `(${this.monthlyIncrease} more than you pay today).${promo} `
            + `Would you like me to set that up?`;
    }

    get upgradeLabel() {
        return this.upgradeRequested ? 'Upgrade requested' : 'Upgrade plan';
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

    /**
     * The card never applies the upgrade itself. It asks the agent to run the
     * upgrade action, so the change is confirmed and stays in the transcript —
     * and so a stray click can't bill a customer for a plan nobody discussed.
     * One shot: the button disables itself rather than letting a second click
     * queue a second request.
     */
    handleUpgrade() {
        this.postToChat(this.upgradeMessage);
        this.upgradeRequested = true;
    }

    handleExplain() {
        this.copyToChat(this.explainMessage);
    }
}
