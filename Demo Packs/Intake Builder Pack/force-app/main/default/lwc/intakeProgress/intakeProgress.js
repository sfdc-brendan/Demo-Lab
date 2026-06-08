import { LightningElement, api } from 'lwc';

export default class IntakeProgress extends LightningElement {
    @api currentIndex = 0;
    @api totalQuestions = 0;
    @api completedSet = [];
    @api currentCategory = '';
    @api isReview = false;

    get percentComplete() {
        if (this.totalQuestions === 0) return 0;
        return Math.round((this.completedSet.length / this.totalQuestions) * 100);
    }

    get progressLabel() {
        if (this.isReview) {
            return `Review — ${this.completedSet.length} of ${this.totalQuestions} answered`;
        }
        return `Question ${this.currentIndex + 1} of ${this.totalQuestions}`;
    }

    get categoryLabel() {
        return this.isReview ? 'Final Review' : this.currentCategory;
    }

    get progressVariant() {
        return this.percentComplete === 100 ? 'circular' : '';
    }

    get dots() {
        const result = [];
        for (let i = 0; i < this.totalQuestions; i++) {
            const isCompleted = this.completedSet.includes(i);
            const isCurrent = i === this.currentIndex && !this.isReview;
            let cssClass = 'progress-dot';
            if (isCurrent) cssClass += ' progress-dot_current';
            else if (isCompleted) cssClass += ' progress-dot_completed';

            result.push({
                index: i,
                cssClass,
                title: `Question ${i + 1}`,
                ariaLabel: `Question ${i + 1}${isCompleted ? ' completed' : ''}${isCurrent ? ' current' : ''}`
            });
        }
        return result;
    }
}
