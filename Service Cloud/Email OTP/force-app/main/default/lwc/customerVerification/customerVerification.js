import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import generateAndSendCode from '@salesforce/apex/CustomerVerificationCodeService.generateAndSendCode';
import validateCode from '@salesforce/apex/CustomerVerificationCodeService.validateCode';
import getActiveCodeStatus from '@salesforce/apex/CustomerVerificationCodeService.getActiveCodeStatus';

export default class CustomerVerification extends LightningElement {
    @api recordId; // Contact Id from record page

    codeInput = '';
    isLoading = false;
    activeExpiresAt = null;

    get contactId() {
        return this.recordId || null;
    }

    get hasActiveCode() {
        return this.activeExpiresAt != null;
    }

    get activeCodeMessage() {
        if (!this.activeExpiresAt) return '';
        const d = new Date(this.activeExpiresAt);
        return `Code sent (expires ${d.toLocaleTimeString()})`;
    }

    @wire(getActiveCodeStatus, { contactId: '$contactId' })
    wiredActiveStatus({ data, error }) {
        if (data) {
            this.activeExpiresAt = data.hasActiveCode ? data.expiresAt : null;
        }
        if (error) {
            this.activeExpiresAt = null;
        }
    }

    handleCodeInputChange(event) {
        this.codeInput = event.target.value.replace(/\D/g, '').slice(0, 6);
        event.target.value = this.codeInput;
    }

    handleSendCode() {
        if (!this.contactId) {
            this.showToast('Error', 'No contact record in context.', 'error');
            return;
        }
        this.isLoading = true;
        generateAndSendCode({
            contactId: this.contactId,
            deliveryMethod: 'Email'
        })
            .then((result) => {
                this.isLoading = false;
                if (result.success) {
                    this.showToast('Success', result.message, 'success');
                    this.activeExpiresAt = result.expiresAt;
                } else {
                    this.showToast('Error', result.message, 'error');
                }
            })
            .catch((error) => {
                this.isLoading = false;
                this.showToast('Error', this.reduceErrors(error), 'error');
            });
    }

    handleVerify() {
        if (!this.contactId) {
            this.showToast('Error', 'No contact record in context.', 'error');
            return;
        }
        if ((this.codeInput || '').length !== 6) {
            this.showToast('Error', 'Enter the 6-digit code from the customer.', 'error');
            return;
        }
        this.isLoading = true;
        validateCode({
            contactId: this.contactId,
            codeEntered: this.codeInput
        })
            .then((result) => {
                this.isLoading = false;
                if (result.success) {
                    this.showToast('Success', result.message, 'success');
                    this.codeInput = '';
                    this.activeExpiresAt = null;
                } else {
                    this.showToast('Error', result.message, 'error');
                }
            })
            .catch((error) => {
                this.isLoading = false;
                this.showToast('Error', this.reduceErrors(error), 'error');
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    reduceErrors(error) {
        if (Array.isArray(error.body)) {
            return error.body.map((e) => e.message).join(', ');
        }
        if (error.body?.message) {
            return error.body.message;
        }
        return error.message || 'Unknown error';
    }
}
