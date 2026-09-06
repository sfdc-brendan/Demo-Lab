import { LightningElement, api, track } from 'lwc';

const DASH = '—';

// Above this, churn risk gets the warning treatment. Churn reads inversely to
// the other two metrics: for health and CSAT higher is better, here it isn't.
const CHURN_WARN_AT = 50;

export default class CustomerProfileCard extends LightningElement {
    // Simple @api, no getter/setter. A property accessor here breaks renderer
    // registration and the component silently never mounts.
    @api value;

    @track data = {};
    @track errorMessage = '';
    @track replySent = false;

    connectedCallback() {
        // Keep this breadcrumb. When a card renders blank, the console in the
        // Agentforce iframe is the fastest way to see what actually arrived.
        console.log('#### CustomerProfileCard input:', this.value);

        try {
            if (!this.value || !this.value.profileJSON) {
                this.errorMessage = 'No profile data provided.';
                return;
            }

            const raw = this.value.profileJSON;
            const parsed = typeof raw === 'string' ? JSON.parse(raw) : raw;

            if (parsed.error) {
                this.errorMessage = parsed.error;
                return;
            }

            this.data = parsed;
        } catch (e) {
            this.errorMessage = 'Error loading customer profile.';
        }
    }

    get hasError() {
        return !!this.errorMessage;
    }

    get profileFound() {
        return !this.errorMessage && this.data.profileFound === true;
    }

    get noProfile() {
        return !this.errorMessage && this.data.profileFound === false;
    }

    get searchedFor() {
        return this.data.searchedFor || 'that identifier';
    }

    get customerName() {
        return this.data.customerName || DASH;
    }

    get firstName() {
        return (this.data.customerName || 'there').split(' ')[0];
    }

    get photoUrl() {
        return this.data.photoUrl;
    }

    get hasPhoto() {
        return !!this.data.photoUrl;
    }

    // Fallback avatar, so a profile without a photo still gets a face-shaped
    // anchor in the header instead of a hole.
    get initials() {
        const parts = (this.data.customerName || '').split(' ').filter((p) => p);
        if (!parts.length) return '?';
        const last = parts.length > 1 ? parts[parts.length - 1] : '';
        return (parts[0].charAt(0) + last.charAt(0)).toUpperCase();
    }

    get accountNumber() {
        return this.data.accountNumber || DASH;
    }

    get tier() {
        return this.data.tier || DASH;
    }

    get plan() {
        return this.data.plan || DASH;
    }

    get customerSince() {
        return this.data.customerSince || DASH;
    }

    get tenure() {
        return this.data.tenure || '';
    }

    get phone() {
        return this.data.phone || DASH;
    }

    get email() {
        return this.data.email || DASH;
    }

    get address() {
        return this.data.address || DASH;
    }

    get preferredChannel() {
        return this.data.preferredChannel || DASH;
    }

    get healthScore() {
        return this.formatScore(this.data.healthScore);
    }

    get csat() {
        return this.formatScore(this.data.csat);
    }

    get churnRisk() {
        return this.formatScore(this.data.churnRisk);
    }

    get churnRiskClass() {
        const v = this.data.churnRisk;
        if (typeof v !== 'number') return 'sr-metric__value';
        return v >= CHURN_WARN_AT ? 'sr-metric__value sr-metric__value_warn' : 'sr-metric__value';
    }

    get alertActive() {
        return this.data.alertActive === true;
    }

    get alertMessage() {
        return this.data.alertMessage || 'This account needs attention.';
    }

    get tags() {
        return (this.data.tags || []).map((label, i) => ({ id: `tag-${i}`, label }));
    }

    get hasTags() {
        return this.tags.length > 0;
    }

    formatScore(v) {
        return typeof v === 'number' ? String(Math.round(v)) : DASH;
    }

    // ---- Suggested replies ------------------------------------------------

    get greetMessage() {
        return `Hi ${this.firstName}, thanks for getting in touch. I have your account (${this.accountNumber}) open in front of me and I can see you're on ${this.plan}, so you won't need to repeat any of your details.`;
    }

    get casesMessage() {
        return 'Show me the recent cases for this customer.';
    }

    get historyMessage() {
        return 'Show me the billing and payment history for this account.';
    }

    get greetLabel() {
        return this.replySent ? 'Copied to reply' : 'Greet customer';
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

    handleGreet(event) {
        this.copyToChat(event.currentTarget.dataset.message);
        this.replySent = true;
    }

    handlePost(event) {
        this.postToChat(event.currentTarget.dataset.message);
    }
}
