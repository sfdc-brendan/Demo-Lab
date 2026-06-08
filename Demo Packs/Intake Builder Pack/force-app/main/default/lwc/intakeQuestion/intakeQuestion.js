import { LightningElement, api } from 'lwc';

export default class IntakeQuestion extends LightningElement {
    @api question;
    @api value = '';
    @api locale = 'en_US';

    customError = '';

    get displayQuestionText() {
        return this.localizedField('questionText', this.question?.questionText);
    }

    get displayHelpText() {
        return this.localizedField('helpText', this.question?.helpText);
    }

    localizedField(fieldName, fallback) {
        const t = (this.question?.translations || []).find((tr) => tr.locale === this.locale);
        return t && t[fieldName] ? t[fieldName] : fallback;
    }

    get isText() {
        return this.question?.answerType === 'text';
    }
    get isPhone() {
        return this.question?.answerType === 'phone';
    }
    get isEmail() {
        return this.question?.answerType === 'email';
    }
    get isNumber() {
        return this.question?.answerType === 'number';
    }
    get isDate() {
        return this.question?.answerType === 'date';
    }
    get isTextarea() {
        return this.question?.answerType === 'textarea';
    }
    get isPicklist() {
        return this.question?.answerType === 'picklist';
    }
    get isMultiPicklist() {
        return this.question?.answerType === 'multipicklist';
    }
    get isBoolean() {
        return this.question?.answerType === 'boolean';
    }
    get isLookup() {
        return this.question?.answerType === 'lookup';
    }

    get booleanChecked() {
        return this.value === true || this.value === 'true';
    }

    get multiPicklistValue() {
        if (!this.value) return [];
        return String(this.value).split(';').filter((v) => v);
    }

    get hasCustomError() {
        return this.customError !== '';
    }

    handleChange(event) {
        const detail = event.detail;
        let val;
        if (this.isBoolean) {
            val = event.target.checked;
        } else if (this.isMultiPicklist) {
            val = (detail.value || []).join(';');
        } else {
            val = detail?.value ?? event.target.value;
        }

        this.runRegexValidation(val);

        this.dispatchEvent(
            new CustomEvent('answerchange', {
                detail: {
                    questionName: this.question.developerName,
                    value: val
                }
            })
        );
    }

    runRegexValidation(val) {
        const pattern = this.question?.validationRegex;
        if (!pattern || !val) {
            this.customError = '';
            return;
        }
        try {
            const regex = new RegExp(pattern);
            if (regex.test(String(val))) {
                this.customError = '';
            } else {
                this.customError =
                    this.question.validationErrorMessage ||
                    'The value entered does not match the required format.';
            }
        } catch (e) {
            this.customError = '';
        }
    }

    @api
    validate() {
        this.runRegexValidation(this.value);
        if (this.customError) return false;

        const inputs = this.template.querySelectorAll(
            'lightning-input, lightning-textarea, lightning-combobox, lightning-dual-listbox'
        );
        let valid = true;
        inputs.forEach((input) => {
            if (!input.reportValidity()) valid = false;
        });
        return valid;
    }
}
