import { LightningElement, wire } from 'lwc';
import getActiveIncidentsWithCases from '@salesforce/apex/IncidentDashboardController.getActiveIncidentsWithCases';
import { NavigationMixin } from 'lightning/navigation';

const MAX_DESC_LENGTH = 120;
const STATUS_BADGE_MAP = {
    New: 'warning',
    'In Progress': 'inverse',
    Escalated: 'error',
    Closed: 'default'
};

export default class IncidentDashboard extends NavigationMixin(LightningElement) {
    incidents = [];
    error;
    isLoading = true;

    @wire(getActiveIncidentsWithCases)
    wiredIncidents({ error, data }) {
        this.isLoading = false;
        if (data) {
            this.incidents = data.map((inc) => this.mapIncident(inc));
            this.error = undefined;
        } else if (error) {
            this.error = this.reduceErrorMessage(error);
            this.incidents = [];
        }
    }

    get hasData() {
        return !this.error && this.incidents && this.incidents.length > 0;
    }

    get noData() {
        return !this.error && !this.isLoading && (!this.incidents || this.incidents.length === 0);
    }

    mapIncident(inc) {
        const desc = inc.description || '';
        const truncatedDesc = desc.length > MAX_DESC_LENGTH ? desc.substring(0, MAX_DESC_LENGTH) + '…' : desc;
        const relatedCases = (inc.relatedCases || []).map((c) => ({
            ...c,
            recordUrl: this.buildRecordUrl(c.id, 'Case')
        }));
        const caseCount = relatedCases.length;
        return {
            id: inc.id,
            subject: inc.subject || 'Untitled',
            description: truncatedDesc,
            status: inc.status || '',
            priority: inc.priority || '',
            statusBadgeVariant: STATUS_BADGE_MAP[inc.status] || 'inverse',
            createdDate: inc.createdDate,
            createdDateFormatted: this.formatDate(inc.createdDate),
            ownerId: inc.ownerId,
            ownerName: inc.ownerName || '',
            relatedCases,
            caseCount,
            caseCountLabel: caseCount === 1 ? '1 related case' : `${caseCount} related cases`,
            hasCases: caseCount > 0,
            recordUrl: this.buildRecordUrl(inc.id, 'Incident')
        };
    }

    formatDate(d) {
        if (!d) return '';
        const date = new Date(d);
        const now = new Date();
        const diffMs = now - date;
        const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24));
        if (diffDays === 0) {
            return date.toLocaleTimeString(undefined, { hour: '2-digit', minute: '2-digit' });
        }
        if (diffDays === 1) return 'Yesterday';
        if (diffDays < 7) return `${diffDays} days ago`;
        return date.toLocaleDateString();
    }

    buildRecordUrl(recordId, objectApiName) {
        if (!recordId || !objectApiName) return '#';
        return `/lightning/r/${objectApiName}/${recordId}/view`;
    }

    reduceErrorMessage(err) {
        if (!err) return 'Unknown error';
        if (err.body && typeof err.body.message === 'string') return err.body.message;
        if (typeof err.message === 'string') return err.message;
        return JSON.stringify(err);
    }
}
