import { LightningElement, api } from 'lwc';

export default class IntakeReview extends LightningElement {
    @api questions = [];
    @api answers = {};

    get groupedSections() {
        const groups = new Map();

        this.questions.forEach((q, idx) => {
            const cat = q.category || 'Other';
            if (!groups.has(cat)) groups.set(cat, []);
            const answer = this.answers[q.developerName] || '';
            groups.get(cat).push({
                developerName: q.developerName,
                label: q.questionText,
                answer,
                hasAnswer: answer !== '',
                index: idx,
                editLabel: `Edit ${q.questionText}`
            });
        });

        const sections = [];
        groups.forEach((items, category) => sections.push({ category, items }));
        return sections;
    }

    get hasMissingRequired() {
        return this.questions.some(
            (q) => q.isRequired && !this.answers[q.developerName]
        );
    }

    handleEdit(event) {
        const index = parseInt(event.currentTarget.dataset.index, 10);
        this.dispatchEvent(new CustomEvent('edit', { detail: { index } }));
    }
}
