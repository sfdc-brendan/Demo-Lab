import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getScenarios from '@salesforce/apex/sdo_VirtualCustomerCtrl.getScenarios';
import getRoutes from '@salesforce/apex/sdo_VirtualCustomerCtrl.getRoutes';
import checkSetup from '@salesforce/apex/sdo_VirtualCustomerCtrl.checkSetup';
import startConversation from '@salesforce/apex/sdo_VirtualCustomerCtrl.startConversation';
import sendMessage from '@salesforce/apex/sdo_VirtualCustomerCtrl.sendMessage';
import locateSession from '@salesforce/apex/sdo_VirtualCustomerCtrl.locateSession';
import assignContactToSession from '@salesforce/apex/sdo_VirtualCustomerCtrl.assignContactToSession';
import getAgentEntries from '@salesforce/apex/sdo_VirtualCustomerCtrl.getAgentEntries';
import generateCustomerMessage from '@salesforce/apex/sdo_VirtualCustomerCtrl.generateCustomerMessage';

const POLL_INTERVAL_MS = 3000;
const LOCATE_RETRIES = 8;
const MAX_AI_TURNS = 8;
// After this many normal customer turns on the Agentforce route, the customer
// asks for a human, which triggers the agent's escalation/transfer action.
const ESCALATE_AFTER_TURNS = 3;

export default class Sdo_virtualCustomer extends LightningElement {
    scenarios = [];
    selectedLabel;
    autoRespond = true;
    aiMode = true;

    routes = [];
    selectedRouteValue;
    escalateToHuman = true;
    escalated = false;

    @track transcript = [];
    status = 'Idle';
    started = false;
    busy = false;

    accessToken;
    conversationId;
    messagingSessionId;
    sfConversationId;
    contactId;
    contactName;
    contactLinked = false;
    lineIndex = 0;
    customerTurns = 0;

    _pollTimer;
    _scenarioMap = {};
    _routeMap = {};
    _seenAgentIds = new Set();

    connectedCallback() {
        getScenarios()
            .then((data) => {
                this.scenarios = data;
                data.forEach((s) => (this._scenarioMap[s.label] = s));
                if (data.length) {
                    this.selectedLabel = data[0].label;
                }
            })
            .catch((e) => this.toast('Error', this.errMsg(e), 'error'));

        getRoutes()
            .then((data) => {
                this.routes = data;
                data.forEach((r) => (this._routeMap[r.esDeveloperName] = r));
                if (data.length) {
                    this.selectedRouteValue = data[0].esDeveloperName;
                }
            })
            .catch((e) => this.toast('Error', this.errMsg(e), 'error'));
    }

    disconnectedCallback() {
        this.stopPolling();
    }

    // ---- derived state -------------------------------------------------
    get scenarioOptions() {
        return this.scenarios.map((s) => ({ label: s.label, value: s.label }));
    }

    get scenario() {
        return this._scenarioMap[this.selectedLabel];
    }

    get routeOptions() {
        return this.routes.map((r) => ({ label: r.label, value: r.esDeveloperName }));
    }

    get route() {
        return this._routeMap[this.selectedRouteValue];
    }

    get isAgentforceRoute() {
        const r = this.route;
        return !!(r && r.agentforce);
    }

    get routeSelectDisabled() {
        return this.started;
    }

    get showEscalationToggle() {
        return this.isAgentforceRoute;
    }

    get routeHelp() {
        return this.isAgentforceRoute
            ? 'The conversation is answered by the Agentforce Service Agent first. With escalation on, the customer asks for a human after a few turns to trigger a transfer.'
            : 'The conversation routes straight to a human agent via Omni-Channel, so Real-Time Conversation Translation engages.';
    }

    get remainingLines() {
        const s = this.scenario;
        return s ? s.lines.length - this.lineIndex : 0;
    }

    get escalationPending() {
        return (
            this.isAgentforceRoute &&
            this.escalateToHuman &&
            !this.escalated &&
            this.customerTurns >= ESCALATE_AFTER_TURNS
        );
    }

    get canSendNext() {
        if (this.escalationPending) {
            return true;
        }
        if (this.aiMode) {
            return this.customerTurns < MAX_AI_TURNS;
        }
        return this.remainingLines > 0;
    }

    get startDisabled() {
        return this.busy || this.started || !this.scenario || !this.route;
    }

    get checkDisabled() {
        return this.busy || this.started || !this.route;
    }

    get sendNextDisabled() {
        return this.busy || !this.started || !this.canSendNext;
    }

    get scenarioSelectDisabled() {
        return this.started;
    }

    get hasTranscript() {
        return this.transcript.length > 0;
    }

    get contactDisplay() {
        return this.contactName
            ? `Linked to Contact: ${this.contactName}`
            : 'A random Contact (with a phone) is linked each time you start.';
    }

    get sendNextLabel() {
        if (this.escalationPending) {
            return 'Ask for a human (escalate)';
        }
        if (this.aiMode) {
            return this.canSendNext ? 'Send next customer message' : 'Conversation wrapped up';
        }
        return this.remainingLines > 0
            ? `Send next customer line (${this.remainingLines} left)`
            : 'No more lines';
    }

    get modeHelp() {
        return this.aiMode
            ? 'Hybrid: opens with the scenario’s scripted line, then the Models API generates each follow-up live, reacting to the agent.'
            : 'Scripted mode: the customer sends the scenario’s predefined lines in order.';
    }

    // ---- handlers ------------------------------------------------------
    handleScenarioChange(e) {
        this.selectedLabel = e.detail.value;
    }

    handleRouteChange(e) {
        this.selectedRouteValue = e.detail.value;
    }

    handleEscalateToggle(e) {
        this.escalateToHuman = e.target.checked;
    }

    async handleCheckSetup() {
        if (!this.route) return;
        this.busy = true;
        this.status = `Checking setup for "${this.route.label}"…`;
        try {
            this.status = await checkSetup({ esDeveloperName: this.route.esDeveloperName });
        } catch (e) {
            this.status = this.errMsg(e);
        } finally {
            this.busy = false;
        }
    }

    handleAutoToggle(e) {
        this.autoRespond = e.target.checked;
        if (this.started && this.autoRespond) {
            this.startPolling();
        }
    }

    handleAiToggle(e) {
        this.aiMode = e.target.checked;
    }

    async handleStart() {
        const s = this.scenario;
        if (!s) return;
        this.busy = true;
        this.status = 'Starting conversation…';
        try {
            const start = await startConversation({
                contactId: null,
                esDeveloperName: this.route.esDeveloperName
            });
            this.accessToken = start.accessToken;
            this.conversationId = start.conversationId;
            this.contactId = start.contactId;
            this.contactName = start.contactName;
            this.started = true;
            const startedAt = new Date().toISOString();

            this.status = 'Sending the scenario’s opening message…';
            await this.sendCustomerTurn(true);
            this.status = 'Sent first message — routing to an agent…';

            this.locate(startedAt, LOCATE_RETRIES);
            if (this.autoRespond) {
                this.startPolling();
            }
        } catch (e) {
            this.toast('Could not start', this.errMsg(e), 'error');
            this.status = 'Error starting conversation';
            this.started = false;
        } finally {
            this.busy = false;
        }
    }

    async handleSendNext() {
        if (!this.canSendNext || this.busy) return;
        this.busy = true;
        try {
            await this.sendCustomerTurn(false);
        } catch (e) {
            this.toast('Send failed', this.errMsg(e), 'error');
        } finally {
            this.busy = false;
        }
    }

    handleReset() {
        this.stopPolling();
        this.started = false;
        this.busy = false;
        this.accessToken = undefined;
        this.conversationId = undefined;
        this.messagingSessionId = undefined;
        this.sfConversationId = undefined;
        this.contactId = undefined;
        this.contactName = undefined;
        this.contactLinked = false;
        this.lineIndex = 0;
        this.customerTurns = 0;
        this.escalated = false;
        this._seenAgentIds = new Set();
        this.transcript = [];
        this.status = 'Idle';
    }

    // ---- internals -----------------------------------------------------
    async sendCustomerTurn(isFirst) {
        const s = this.scenario;
        let text;
        let isEscalation = false;

        const hasOpener = s.lines && s.lines.length > 0;
        if (isFirst && hasOpener) {
            // Always kick off with the scenario's scripted opening line.
            text = s.lines[0];
            this.lineIndex = 1;
        } else if (this.escalationPending) {
            // On the Agentforce route, after a few turns the customer asks for a
            // human so the agent's transfer-to-human action fires.
            text = s.escalationLine;
            isEscalation = true;
        } else if (this.aiMode) {
            // Dynamic from here on: generate the next line reacting to the agent.
            const history = this.transcript.map((m) => ({ sender: m.who, text: m.text }));
            text = await generateCustomerMessage({
                languageCode: s.language,
                persona: s.persona,
                historyJson: JSON.stringify(history)
            });
        } else {
            if (this.remainingLines <= 0) return;
            text = s.lines[this.lineIndex];
            this.lineIndex += 1;
        }

        if (!text) return;

        await sendMessage({
            accessToken: this.accessToken,
            conversationId: this.conversationId,
            text,
            languageCode: s.language,
            isFirst,
            esDeveloperName: this.route.esDeveloperName
        });
        this.customerTurns += 1;
        this.pushTranscript('customer', this.contactName || `${s.firstName} ${s.lastName}`, text);

        if (isEscalation) {
            this.escalated = true;
            this.status = 'Customer asked for a human — Agentforce should transfer to a live agent now.';
        }
    }

    async locate(startedAt, retriesLeft) {
        try {
            const ref = await locateSession({
                startedAfter: startedAt,
                channelDevName: this.route.channelDevName
            });
            if (ref && ref.messagingSessionId) {
                this.messagingSessionId = ref.messagingSessionId;
                this.sfConversationId = ref.conversationId;
                this.status = 'Live session connected — linking contact…';
                this.linkContact(5);
                return;
            }
        } catch (e) {
            // swallow; retry below
        }
        if (retriesLeft > 0) {
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            setTimeout(() => this.locate(startedAt, retriesLeft - 1), 2000);
        }
    }

    async linkContact(retriesLeft) {
        if (this.contactLinked || !this.messagingSessionId || !this.contactId) return;
        let linked = false;
        try {
            linked = await assignContactToSession({
                messagingSessionId: this.messagingSessionId,
                contactId: this.contactId
            });
        } catch (e) {
            linked = false;
        }
        if (linked) {
            this.contactLinked = true;
            this.status = `Session linked to ${this.contactName || 'contact'} — translation will engage on the agent console.`;
            return;
        }
        if (retriesLeft > 0) {
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            setTimeout(() => this.linkContact(retriesLeft - 1), 2000);
        }
    }

    startPolling() {
        this.stopPolling();
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this._pollTimer = setInterval(() => this.pollAgentReplies(), POLL_INTERVAL_MS);
    }

    stopPolling() {
        if (this._pollTimer) {
            clearInterval(this._pollTimer);
            this._pollTimer = undefined;
        }
    }

    async pollAgentReplies() {
        if (!this.accessToken || !this.conversationId) return;
        let entries;
        try {
            entries = await getAgentEntries({
                accessToken: this.accessToken,
                conversationId: this.conversationId
            });
        } catch (e) {
            return;
        }
        if (!entries || !entries.length) return;

        let sawNewReply = false;
        entries.forEach((entry) => {
            const key = entry.identifier || `${entry.timestamp}-${entry.text}`;
            if (this._seenAgentIds.has(key)) return;
            this._seenAgentIds.add(key);
            if (entry.text) {
                this.pushTranscript('agent', entry.actorName || 'Agent', entry.text);
                sawNewReply = true;
            }
        });

        if (sawNewReply && this.autoRespond && this.canSendNext && !this.busy) {
            this.status = this.aiMode
                ? 'Agent replied — generating the customer’s response…'
                : 'Agent replied — sending the customer’s response…';
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            setTimeout(() => this.handleSendNext(), 1500);
        }
    }

    pushTranscript(who, name, text) {
        this.transcript = [
            ...this.transcript,
            {
                id: `${who}-${this.transcript.length}-${Date.now()}`,
                who,
                name,
                text,
                isCustomer: who === 'customer',
                rowClass:
                    who === 'customer'
                        ? 'slds-chat-listitem slds-chat-listitem_inbound'
                        : 'slds-chat-listitem slds-chat-listitem_outbound'
            }
        ];
    }

    errMsg(e) {
        return (e && e.body && e.body.message) || (e && e.message) || 'Unexpected error';
    }

    toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}