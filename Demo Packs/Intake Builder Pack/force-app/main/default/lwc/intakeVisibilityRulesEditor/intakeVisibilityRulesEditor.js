import { LightningElement, api } from 'lwc';

const OPERATOR_OPTIONS = [
    { label: 'equals', value: 'equals' },
    { label: 'not equals', value: 'not_equals' },
    { label: 'contains', value: 'contains' },
    { label: 'in (semicolon list)', value: 'in' },
    { label: 'is blank', value: 'is_blank' },
    { label: 'is not blank', value: 'is_not_blank' }
];

export default class IntakeVisibilityRulesEditor extends LightningElement {
    @api rules = [];
    @api siblingQuestions = [];

    operatorOptions = OPERATOR_OPTIONS;

    get sourceOptions() {
        return (this.siblingQuestions || []).map((q) => ({
            label: q.questionText || q.developerName,
            value: q.developerName
        }));
    }

    get displayRules() {
        return (this.rules || []).map((r, idx) => ({
            ...r,
            uiKey: `rule-${idx}`,
            index: idx,
            valueDisabled: r.operator === 'is_blank' || r.operator === 'is_not_blank'
        }));
    }

    handleAdd() {
        const next = [
            ...(this.rules || []),
            {
                sourceQuestionDeveloperName: '',
                operator: 'equals',
                value: '',
                logicGroup: 'default'
            }
        ];
        this.fireChange(next);
    }

    handleDelete(event) {
        const idx = parseInt(event.currentTarget.dataset.index, 10);
        const next = (this.rules || []).filter((_, i) => i !== idx);
        this.fireChange(next);
    }

    handleField(event) {
        const idx = parseInt(event.currentTarget.dataset.index, 10);
        const field = event.currentTarget.dataset.field;
        const value = event.detail?.value ?? event.target.value;
        const next = (this.rules || []).map((r, i) =>
            i === idx ? { ...r, [field]: value } : r
        );
        this.fireChange(next);
    }

    fireChange(next) {
        this.dispatchEvent(new CustomEvent('ruleschange', { detail: { rules: next } }));
    }
}
