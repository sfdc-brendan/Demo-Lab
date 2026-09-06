import { LightningElement, api, track } from 'lwc';

export default class AppointmentSlotsCard extends LightningElement {
    // Simple @api, no getter/setter. A property accessor here breaks renderer
    // registration and the component silently never mounts.
    @api value;

    @track data = {};
    @track selectedId = null;
    @track errorMessage = '';
    @track bookingSent = false;

    connectedCallback() {
        // Keep this breadcrumb. When a card renders blank, the console in the
        // Agentforce iframe is the fastest way to see what actually arrived.
        console.log('#### AppointmentSlotsCard input:', this.value);

        try {
            if (!this.value || !this.value.slotsJSON) {
                this.errorMessage = 'No appointment data provided.';
                return;
            }

            const raw = this.value.slotsJSON;
            const parsed = typeof raw === 'string' ? JSON.parse(raw) : raw;

            if (parsed.error) {
                this.errorMessage = parsed.error;
                return;
            }

            this.data = parsed;
        } catch (e) {
            this.errorMessage = 'Error loading appointment slots.';
        }
    }

    get hasError() {
        return !!this.errorMessage;
    }

    get slots() {
        return this.data.slots || [];
    }

    get hasSlots() {
        return !this.errorMessage && this.slots.length > 0;
    }

    // No availability is a legitimate answer rather than a failure, so it gets
    // its own neutral panel instead of sharing the error treatment.
    get noSlots() {
        return !this.errorMessage && this.slots.length === 0;
    }

    get emptyMessage() {
        return this.data.message || 'No technician visit windows open in the next three business days.';
    }

    get emptyHint() {
        return this.data.hint || 'Offer the customer the first slot next week, or take a callback number and reach out if a cancellation frees something up sooner.';
    }

    get slotRows() {
        return this.slots.map((s) => ({
            ...s,
            className: s.slotId === this.selectedId ? 'sr-slot sr-slot_selected' : 'sr-slot'
        }));
    }

    get selectedSlot() {
        return this.slots.find((s) => s.slotId === this.selectedId);
    }

    get confirmDisabled() {
        return this.bookingSent || !this.selectedSlot;
    }

    get confirmLabel() {
        if (this.bookingSent) {
            return 'Appointment booked';
        }
        const s = this.selectedSlot;
        return s ? `Book ${s.dayName} ${s.window.toLowerCase()}` : 'Book this visit';
    }

    handleSelect(event) {
        if (this.bookingSent) {
            return;
        }
        this.selectedId = event.currentTarget.dataset.slotId;
    }

    // ---- Event dispatch ---------------------------------------------------
    // bubbles + composed are both required to cross the shadow boundary and
    // reach a host listener. A host that isn't listening is harmless, which is
    // why this card carries no console-API dependency of its own.

    postToChat(message) {
        this.dispatchEvent(new CustomEvent('acc:execute', {
            detail: { content: message },
            bubbles: true,
            composed: true
        }));
    }

    // The card never books the visit itself — it asks the conversation to. The
    // date and window are stated explicitly so a booking action can extract
    // them straight from the utterance, and the label flips locally so the rep
    // can see the request went out.
    handleBook() {
        const s = this.selectedSlot;
        if (!s) {
            return;
        }

        this.postToChat(
            `Book a technician visit for this customer on ${s.isoDate} ` +
            `during the ${s.window} window (${s.windowLabel}).`
        );
        this.bookingSent = true;
    }
}
