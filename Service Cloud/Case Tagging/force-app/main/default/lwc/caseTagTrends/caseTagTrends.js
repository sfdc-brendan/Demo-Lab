import { LightningElement, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getDashboardData from '@salesforce/apex/CaseTaggingTrendsController.getDashboardData';
import getCasesByTag from '@salesforce/apex/CaseTaggingTrendsController.getCasesByTag';
import getTrendsSummary from '@salesforce/apex/CaseTaggingTrendsController.getTrendsSummary';
import runHistorical from '@salesforce/apex/CaseTaggingController.runHistorical';

/** Time period (months) used when running historical analysis from the button menu. */
const HISTORICAL_ANALYSIS_MONTHS = 3;

/** Number of top tags to show in the Top 5 module. */
const TOP_N = 5;

const COLOR_CLASSES = ['pill-blue', 'pill-green', 'pill-orange', 'pill-purple', 'pill-teal', 'pill-coral'];

export default class CaseTagTrends extends LightningElement {
    scopeMonths = '2';
    scopeOptions = [
        { label: 'Last 1 month', value: '1' },
        { label: 'Last 2 months', value: '2' },
        { label: 'Last 3 months', value: '3' },
        { label: 'Last 6 months', value: '6' },
        { label: 'Last 12 months', value: '12' },
    ];

    dashboardData = null;
    selectedTag = null;
    casesForTag = [];
    loadingCases = false;
    actionsLoading = false;
    summaryLoading = false;
    summaryText = '';
    wiredDashboardResult;

    @wire(getDashboardData, { scopeMonths: '$scopeMonthsNumber' })
    wiredDashboard(result) {
        this.wiredDashboardResult = result;
        const { data, error } = result;
        if (data) {
            this.dashboardData = data;
        } else if (error) {
            this.dashboardData = null;
            console.error('getDashboardData error', error);
        }
    }

    get actionsDisabled() {
        return this.actionsLoading;
    }

    get scopeMonthsNumber() {
        const n = parseInt(this.scopeMonths, 10);
        return isNaN(n) ? 2 : n;
    }

    get totalCasesTagged() {
        const d = this.dashboardData;
        return d && d.totalCasesTagged != null ? d.totalCasesTagged : 0;
    }

    get uniqueTagCount() {
        const d = this.dashboardData;
        return d && d.uniqueTagCount != null ? d.uniqueTagCount : 0;
    }

    get tagSummary() {
        const d = this.dashboardData;
        return (d && d.tagSummary) || [];
    }

    get hasTagSummary() {
        return this.tagSummary && this.tagSummary.length > 0;
    }

    get top5Tags() {
        const list = this.tagSummary.slice(0, TOP_N);
        return (list || []).map((item, idx) => ({
            ...item,
            rank: idx + 1,
            ariaLabelTop5: 'View cases for ' + item.tag,
        }));
    }

    get tagSummaryWithAria() {
        const base = 'caseTagTrends-pill';
        return (this.tagSummary || []).map((item, idx) => {
            const colorClass = COLOR_CLASSES[idx % COLOR_CLASSES.length];
            return {
                ...item,
                ariaLabel: 'View cases tagged with ' + item.tag,
                pillClass: `${base} ${colorClass}`,
            };
        });
    }

    get hasCases() {
        return this.casesForTag && this.casesForTag.length > 0;
    }

    get scopeLabel() {
        const n = this.scopeMonthsNumber;
        return n === 1 ? 'Last 1 month' : `Last ${n} months`;
    }

    get hasSummary() {
        return this.summaryText && this.summaryText.trim().length > 0;
    }

    handleScopeChange(event) {
        this.scopeMonths = event.detail.value || '2';
        this.selectedTag = null;
        this.casesForTag = [];
        this.summaryText = '';
    }

    handleTagClick(event) {
        const index = event.currentTarget.dataset.index;
        if (index === undefined || !this.tagSummary || !this.tagSummary[index]) return;
        const tag = this.tagSummary[index].tag;
        this.selectedTag = tag;
        this.loadingCases = true;
        this.casesForTag = [];
        getCasesByTag({ tag, scopeMonths: this.scopeMonthsNumber })
            .then((data) => {
                this.casesForTag = data || [];
            })
            .catch((err) => {
                console.error('getCasesByTag error', err);
                this.casesForTag = [];
            })
            .finally(() => {
                this.loadingCases = false;
            });
    }

    handleTop5TagClick(event) {
        const index = event.currentTarget.dataset.index;
        if (index === undefined || !this.top5Tags || !this.top5Tags[index]) return;
        const tag = this.top5Tags[index].tag;
        this.selectedTag = tag;
        this.loadingCases = true;
        this.casesForTag = [];
        getCasesByTag({ tag, scopeMonths: this.scopeMonthsNumber })
            .then((data) => {
                this.casesForTag = data || [];
            })
            .catch((err) => {
                console.error('getCasesByTag error', err);
                this.casesForTag = [];
            })
            .finally(() => {
                this.loadingCases = false;
            });
    }

    handleClearSelection() {
        this.selectedTag = null;
        this.casesForTag = [];
    }

    handleActionsMenuSelect(event) {
        const value = event.detail?.value;
        if (value === 'run_historical') {
            this.doRunHistorical();
        } else if (value === 'refresh') {
            this.doRefresh();
        }
    }

    async doRunHistorical() {
        this.actionsLoading = true;
        try {
            const msg = await runHistorical({ scopeMonths: HISTORICAL_ANALYSIS_MONTHS });
            this.showToast('Started', msg, 'success');
            await refreshApex(this.wiredDashboardResult);
            this.selectedTag = null;
            this.casesForTag = [];
            this.summaryText = '';
        } catch (e) {
            this.showToast('Error', e.body?.message || e.message || 'Failed to start historical analysis', 'error');
        } finally {
            this.actionsLoading = false;
        }
    }

    async doRefresh() {
        this.actionsLoading = true;
        try {
            await refreshApex(this.wiredDashboardResult);
            this.selectedTag = null;
            this.casesForTag = [];
            this.showToast('Refreshed', 'Dashboard updated.', 'success');
        } catch (e) {
            this.showToast('Error', e.body?.message || e.message || 'Refresh failed', 'error');
        } finally {
            this.actionsLoading = false;
        }
    }

    async handleGenerateSummary() {
        this.summaryLoading = true;
        this.summaryText = '';
        try {
            const text = await getTrendsSummary({ scopeMonths: this.scopeMonthsNumber });
            this.summaryText = text || '';
            if (this.summaryText) {
                this.showToast('Summary ready', 'AI summary generated.', 'success');
            }
        } catch (e) {
            this.showToast('Error', e.body?.message || e.message || 'Could not generate summary', 'error');
        } finally {
            this.summaryLoading = false;
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
