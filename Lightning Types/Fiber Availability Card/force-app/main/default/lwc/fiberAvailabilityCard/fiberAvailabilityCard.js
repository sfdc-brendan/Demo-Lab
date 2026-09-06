import { LightningElement, api, track } from 'lwc';

export default class FiberAvailabilityCard extends LightningElement {
    // Simple @api, no getter/setter. A property accessor here breaks renderer
    // registration and the component silently never mounts.
    @api value;

    @track data = {};
    @track errorMessage = '';
    @track replySent = false;

    connectedCallback() {
        // Keep this breadcrumb. When a card renders blank, the console in the
        // Agentforce iframe is the fastest way to see what actually arrived.
        console.log('#### FiberAvailabilityCard input:', this.value);

        try {
            if (!this.value || !this.value.fiberJSON) {
                this.errorMessage = 'No fiber availability data provided.';
                return;
            }

            const raw = this.value.fiberJSON;
            const parsed = typeof raw === 'string' ? JSON.parse(raw) : raw;

            if (parsed.error) {
                this.errorMessage = parsed.error;
                return;
            }

            this.data = parsed;
        } catch (e) {
            this.errorMessage = 'Error loading fiber availability.';
        }
    }

    // ---- State ------------------------------------------------------------

    get hasError() {
        return !!this.errorMessage;
    }

    get hasData() {
        return !this.errorMessage && !!this.data.headline;
    }

    /**
     * A payload with no headline is an address the footprint lookup couldn't
     * answer for at all — different from a confident "not yet". Say so rather
     * than rendering an empty card the rep has to interpret.
     */
    get noData() {
        return !this.errorMessage && !this.data.headline;
    }

    get emptyMessage() {
        return this.data.message || 'No fiber build data for this service address yet.';
    }

    get isServiceable() {
        return this.data.serviceable === true;
    }

    get statusClass() {
        return `sr-status sr-status_${this.isServiceable ? 'live' : 'none'}`;
    }

    get location() {
        return [this.data.neighborhood, this.data.city, this.data.postalCode]
            .filter(Boolean)
            .join(' · ');
    }

    get facts() {
        return (this.data.facts || []).map((f, i) => ({
            id: `fact-${i}`,
            label: f.label,
            value: f.value
        }));
    }

    get hasFacts() {
        return this.facts.length > 0;
    }

    /**
     * The jump the customer would actually feel: their plan today against the tier
     * we're recommending, not the street's ceiling. Hidden unless both ends are
     * known, since "500 Mbps → undefined" is worse than no hero row at all.
     */
    get showSpeedJump() {
        return this.isServiceable
            && !!this.data.currentDownloadMbps
            && !!this.data.recommendedDownloadMbps;
    }

    get currentSpeedLabel() {
        return this.speedLabel(this.data.currentDownloadMbps);
    }

    get upgradeSpeedLabel() {
        return this.speedLabel(this.data.recommendedDownloadMbps);
    }

    speedLabel(mbps) {
        if (!mbps) {
            return '';
        }
        return mbps >= 1000 ? `${mbps / 1000} Gbps` : `${mbps} Mbps`;
    }

    get hasPromo() {
        return this.isServiceable && !!this.data.promo;
    }

    get promoText() {
        return this.data.promoEnds
            ? `${this.data.promo} — ends ${this.data.promoEnds}`
            : this.data.promo;
    }

    // ---- Suggested replies -------------------------------------------------

    get comparePlansMessage() {
        return 'Show me the plan upgrade options for this customer.';
    }

    /**
     * Written in second person — this is the text the customer actually receives.
     * Assembled from the payload rather than hardcoded so the rep never sends a
     * speed or a date the card itself isn't showing.
     */
    get explainMessage() {
        const d = this.data;
        const parts = [
            `Good news — I've just checked your address and Gigabit Fiber is live in `
                + `your neighborhood.`
        ];

        if (d.buildCompleted) {
            parts.push(`The build through ${d.neighborhood} finished on ${d.buildCompleted}, `
                + `and the fiber drop is already at your property.`);
        }

        if (this.showSpeedJump) {
            const multiplier = d.speedMultiplier ? ` — about ${d.speedMultiplier} faster` : '';
            parts.push(`That means we can move you from ${this.currentSpeedLabel} up to `
                + `${this.upgradeSpeedLabel} on ${d.recommendedPlan}${multiplier} than you `
                + `have today.`);
        }

        if (d.headroom) {
            parts.push(`The fiber at your address can go all the way to ${d.headroom} if you `
                + `ever want more, so there's plenty of room to grow.`);
        }

        if (this.hasPromo) {
            parts.push(`And if you upgrade before ${d.promoEnds}, the $99 white-glove `
                + `installation is waived: a certified technician comes out, sets up the `
                + `new equipment, and verifies the speed before they leave.`);
        }

        parts.push('Would you like me to get that started for you?');
        return parts.join(' ');
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
