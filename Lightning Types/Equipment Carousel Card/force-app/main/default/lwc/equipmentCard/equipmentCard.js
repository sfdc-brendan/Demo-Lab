import { LightningElement, api, track } from 'lwc';

const DASH = '—';
const HEALTHY = 'Healthy';

export default class EquipmentCard extends LightningElement {
    // Simple @api, no getter/setter. A property accessor here breaks renderer
    // registration and the component silently never mounts.
    @api value;

    @track data = {};
    @track errorMessage = '';
    @track replySent = false;

    connectedCallback() {
        // Keep this breadcrumb. When a card renders blank, the console in the
        // Agentforce iframe is the fastest way to see what actually arrived.
        console.log('#### EquipmentCard input:', this.value);

        try {
            if (!this.value || !this.value.equipmentJSON) {
                this.errorMessage = 'No equipment data provided.';
                return;
            }

            const raw = this.value.equipmentJSON;
            const parsed = typeof raw === 'string' ? JSON.parse(raw) : raw;

            if (parsed.error) {
                this.errorMessage = parsed.error;
                return;
            }

            this.data = parsed;
        } catch (e) {
            this.errorMessage = 'Error loading equipment.';
        }
    }

    get hasError() {
        return !!this.errorMessage;
    }

    get devices() {
        return (this.data.devices || []).map((d, i) => {
            const health = d.health || HEALTHY;
            return {
                id: `device-${i}`,
                name: d.name || DASH,
                deviceType: d.deviceType || DASH,
                serialNumber: d.serialNumber || DASH,
                installedOn: d.installedOn || DASH,
                // No product photography. The tile draws its own initials
                // placeholder instead, so the bundle carries no static
                // resources and renders the same in every org.
                initials: this.initialsFor(d.deviceType || d.name),
                health: health,
                healthClass: `sr-health sr-health_${health.toLowerCase()}`,
                note: d.note,
                hasNote: !!d.note,
                rmaEligible: d.rmaEligible === true,
                rmaMessage: `Start a replacement RMA for the ${d.name}, serial ${d.serialNumber}.`
            };
        });
    }

    get hasDevices() {
        return !this.errorMessage && this.devices.length > 0;
    }

    get isEmpty() {
        return !this.errorMessage && this.devices.length === 0;
    }

    get hasMultiple() {
        return this.devices.length > 1;
    }

    get deviceCountLabel() {
        const count = this.devices.length;
        return `${count} ${count === 1 ? 'device' : 'devices'}`;
    }

    /**
     * "Set-Top Box" -> "STB". Splitting on non-alphanumerics keeps hyphenated
     * and multi-word device types readable in the placeholder tile.
     */
    initialsFor(label) {
        const letters = (label || '')
            .split(/[^A-Za-z0-9]+/)
            .filter((word) => word)
            .map((word) => word.charAt(0).toUpperCase())
            .join('');
        return letters.slice(0, 3) || DASH;
    }

    // ---- Suggested replies ------------------------------------------------

    // The strip has no single selected device, so the explanation leads with
    // the one that needs attention.
    get attentionDevice() {
        return this.devices.find((d) => d.health !== HEALTHY);
    }

    get explainMessage() {
        const device = this.attentionDevice;
        if (device) {
            return `Your ${device.name} is currently showing as ${device.health.toLowerCase()}. ${device.note || ''}`.trim();
        }
        return `All ${this.deviceCountLabel} at your service address are reporting healthy.`;
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

    // The replacement button asks the agent for an RMA rather than raising one.
    // The write stays behind whatever action the planner owns, so this card
    // never creates a record and is safe to drop into any org.
    handlePost(event) {
        this.postToChat(event.currentTarget.dataset.message);
    }
}
