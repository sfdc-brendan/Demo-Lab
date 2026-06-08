import { LightningElement, api, track } from 'lwc';

const ANSWER_TYPE_OPTIONS = [
    { label: 'Text', value: 'text' },
    { label: 'Text Area (long)', value: 'textarea' },
    { label: 'Phone', value: 'phone' },
    { label: 'Email', value: 'email' },
    { label: 'Number', value: 'number' },
    { label: 'Date', value: 'date' },
    { label: 'Picklist', value: 'picklist' },
    { label: 'Multi-Select Picklist', value: 'multipicklist' },
    { label: 'Checkbox', value: 'boolean' },
    { label: 'Lookup', value: 'lookup' }
];

const PICKLIST_SOURCE_OPTIONS = [
    { label: 'Static (manage values here)', value: 'Static' },
    { label: 'From Field (pull from a Salesforce picklist field)', value: 'From_Field' }
];

export default class IntakeQuestionEditor extends LightningElement {
    @api question;
    @api picklistValues = [];
    @api visibilityRules = [];
    @api translations = [];
    @api siblingQuestions = [];
    @api targetObjectApiName;

    @track activeTab = 'basics';

    answerTypeOptions = ANSWER_TYPE_OPTIONS;
    picklistSourceOptions = PICKLIST_SOURCE_OPTIONS;

    get isPicklist() {
        return this.question?.answerType === 'picklist'
            || this.question?.answerType === 'multipicklist';
    }

    get isStaticPicklist() {
        return this.isPicklist && (this.question?.picklistSource || 'Static') === 'Static';
    }

    get isFromFieldPicklist() {
        return this.isPicklist && this.question?.picklistSource === 'From_Field';
    }

    get isLookup() {
        return this.question?.answerType === 'lookup';
    }

    get displayPicklistValues() {
        return (this.picklistValues || []).map((pv, idx) => ({
            ...pv,
            uiKey: `pv-${idx}`,
            index: idx
        }));
    }

    handleTabChange(event) {
        this.activeTab = event.target.value;
    }

    handleField(event) {
        const field = event.currentTarget.dataset.field;
        let value = event.detail?.value ?? event.target.value;
        if (field === 'isRequired') value = event.target.checked;
        if (field === 'orderNum') value = value === '' ? null : Number(value);
        this.dispatchEvent(new CustomEvent('questionchange', {
            detail: { field, value }
        }));
    }

    handleTargetField(event) {
        this.dispatchEvent(new CustomEvent('questionchange', {
            detail: { field: 'targetField', value: event.detail.value }
        }));
    }

    handleSourceObjectChange(event) {
        this.dispatchEvent(new CustomEvent('questionchange', {
            detail: { field: 'picklistSourceObject', value: event.detail.value }
        }));
    }

    handleSourceFieldChange(event) {
        this.dispatchEvent(new CustomEvent('questionchange', {
            detail: {
                field: 'picklistSourceField',
                value: event.detail.value,
                objectApiName: event.detail.objectApiName
            }
        }));
    }

    handleAddPicklistValue() {
        const next = [
            ...(this.picklistValues || []),
            { label: '', value: '', orderNum: (this.picklistValues || []).length + 1 }
        ];
        this.firePicklistChange(next);
    }

    handleDeletePicklistValue(event) {
        const idx = parseInt(event.currentTarget.dataset.index, 10);
        const next = (this.picklistValues || []).filter((_, i) => i !== idx);
        this.firePicklistChange(next);
    }

    handlePicklistValueField(event) {
        const idx = parseInt(event.currentTarget.dataset.index, 10);
        const field = event.currentTarget.dataset.field;
        const value = event.detail?.value ?? event.target.value;
        const next = (this.picklistValues || []).map((pv, i) =>
            i === idx ? { ...pv, [field]: field === 'orderNum' ? Number(value) : value } : pv
        );
        this.firePicklistChange(next);
    }

    firePicklistChange(next) {
        this.dispatchEvent(new CustomEvent('picklistvalueschange', {
            detail: { picklistValues: next }
        }));
    }

    handleRulesChange(event) {
        this.dispatchEvent(new CustomEvent('ruleschange', {
            detail: { rules: event.detail.rules }
        }));
    }

    handleTranslationsChange(event) {
        this.dispatchEvent(new CustomEvent('translationschange', {
            detail: { translations: event.detail.translations }
        }));
    }

    handleClose() {
        this.dispatchEvent(new CustomEvent('close'));
    }
}
