import { LightningElement, api, track } from 'lwc';
import getSimilarCasesWithScores from '@salesforce/apex/SimilarCasesController.getSimilarCasesWithScores';
import { NavigationMixin } from 'lightning/navigation';

const STATUS_OPTIONS = [
    { label: 'All statuses', value: '' },
    { label: 'New', value: 'New' },
    { label: 'Working', value: 'Working' },
    { label: 'Escalated', value: 'Escalated' },
    { label: 'Closed', value: 'Closed' }
];

export default class SimilarCasesAndArticles extends NavigationMixin(LightningElement) {
    @api recordId;

    @track similarCases = [];
    @track relatedArticles = [];
    @track errorMessage = '';
    @track isLoading = false;
    @track hasLoadedOnce = false;
    @track statusFilter = '';

    statusFilterOptions = STATUS_OPTIONS;

    get hasError() {
        return this.errorMessage && this.hasLoadedOnce;
    }

    get hasData() {
        return this.hasLoadedOnce && !this.isLoading;
    }

    get hasSimilarCases() {
        return Array.isArray(this.similarCases) && this.similarCases.length > 0;
    }

    get hasRelatedArticles() {
        return Array.isArray(this.relatedArticles) && this.relatedArticles.length > 0;
    }

    get similarCasesWithUrls() {
        const baseUrl = window.location.origin;
        return (this.similarCases || []).map((c) => ({
            ...c,
            caseUrl: `${baseUrl}/lightning/r/Case/${c.caseId}/view`
        }));
    }

    get relatedArticlesWithUrls() {
        const baseUrl = window.location.origin;
        return (this.relatedArticles || []).map((a) => ({
            ...a,
            fullUrl: a.url ? (a.url.startsWith('http') ? a.url : baseUrl + a.url) : '#'
        }));
    }

    handleStatusFilterChange(event) {
        this.statusFilter = event.detail.value || '';
    }

    connectedCallback() {
        if (this.recordId) {
            // Don't auto-load; let user choose filter and click Find
        }
    }

    handleLoad() {
        this.loadSimilarCases();
    }

    loadSimilarCases() {
        if (!this.recordId) return;
        this.isLoading = true;
        this.errorMessage = '';
        const statusFilter = this.statusFilter || null;
        getSimilarCasesWithScores({ recordId: this.recordId, statusFilter })
            .then((response) => {
                this.hasLoadedOnce = true;
                this.similarCases = response.similarCases || [];
                this.relatedArticles = response.relatedArticles || [];
                this.errorMessage = response.errorMessage || '';
            })
            .catch((err) => {
                this.hasLoadedOnce = true;
                this.similarCases = [];
                this.relatedArticles = [];
                this.errorMessage = err.body?.message || err.message || 'Failed to load similar cases.';
            })
            .finally(() => {
                this.isLoading = false;
            });
    }
}
