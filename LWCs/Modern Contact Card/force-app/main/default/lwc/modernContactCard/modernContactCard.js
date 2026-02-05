import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';

// Import Contact fields
import CONTACT_NAME_FIELD from '@salesforce/schema/Contact.Name';
import CONTACT_EMAIL_FIELD from '@salesforce/schema/Contact.Email';
import CONTACT_PHONE_FIELD from '@salesforce/schema/Contact.Phone';
import CONTACT_MAILING_CITY_FIELD from '@salesforce/schema/Contact.MailingCity';
import CONTACT_MAILING_STATE_FIELD from '@salesforce/schema/Contact.MailingState';

// Import Case and MessagingSession lookup fields
import CASE_CONTACTID_FIELD from '@salesforce/schema/Case.ContactId';
import MSG_CONTACTID_FIELD from '@salesforce/schema/MessagingSession.EndUserContactId';

// Parent record fields mapping (standard objects only)
const PARENT_RECORD_FIELDS = {
    Case: [CASE_CONTACTID_FIELD],
    MessagingSession: [MSG_CONTACTID_FIELD]
};
// Note: VoiceCall contact field is configurable via @api property to avoid package dependencies

// Contact fields to query
const CONTACT_FIELDS = [
    CONTACT_NAME_FIELD,
    CONTACT_EMAIL_FIELD,
    CONTACT_PHONE_FIELD,
    CONTACT_MAILING_CITY_FIELD,
    CONTACT_MAILING_STATE_FIELD
];

// Optional custom fields on Contact for metrics and card customization
const METRIC_FIELDS = [
    'Contact.Metric_1__c',
    'Contact.Metric_2__c',
    'Contact.Metric_3__c',
    'Contact.Metric_4__c',
    'Contact.Metric_5__c',
    'Contact.Metric_6__c'
];

// Tag color palette - visually distinct colors
const TAG_COLORS = [
    { bg: '#e8f4fd', text: '#0176d3' },  // Blue
    { bg: '#fef3e7', text: '#ba5d00' },  // Orange
    { bg: '#e7f6ed', text: '#2e844a' },  // Green
    { bg: '#fce9ea', text: '#c23934' },  // Red
    { bg: '#f3e8fd', text: '#7526ba' },  // Purple
    { bg: '#e8f7f8', text: '#0d9dda' },  // Cyan
    { bg: '#fef6e8', text: '#8e6d00' },  // Gold
    { bg: '#fce8f3', text: '#c41c7f' }   // Pink
];

export default class ModernContactCard extends NavigationMixin(LightningElement) {
    @api recordId;
    @api objectApiName;

    // Theme Configuration
    @api themeMode = 'Light';
    
    // Header Background Configuration
    @api headerBackgroundField = 'ContactCardBackground__c';
    @api headerBackgroundUrl = '';  // Fallback URL or default
    
    // Profile Configuration
    @api profileImageField = 'ContactCardPicture__c';
    @api profileImageUrl = ''; // Legacy fallback
    @api fallbackImageUrl = '';
    
    // Health Score Configuration
    @api healthScoreField = 'ContactCardHealthScore__c';
    @api healthScoreLabel = 'Health';
    @api healthScoreFallback = '';
    @api showHealthScore = false;
    
    // Tags Configuration
    @api tagsField = 'ContactCardTags__c';
    @api tags = '';  // Comma-separated tags (fallback)
    @api showTags = false;
    
    // VoiceCall Configuration (optional - leave blank if not using VoiceCall)
    @api voiceCallContactField = '';  // e.g., 'Contact__c' - the API name of the Contact lookup field on VoiceCall
    
    // Field Configuration - Row 1
    // Field 1: Value from Contact.Metric_1__c
    @api field1Label = 'ACCOUNT ID';
    @api field1Icon = 'utility:number_input';
    @api field1Value = ''; // Fallback if Metric_1__c is empty
    @api showField1 = false;
    
    // Field 2: Value from Contact.Metric_2__c
    @api field2Label = 'SUPPORT TIER';
    @api field2Icon = 'utility:ribbon';
    @api field2Value = ''; // Fallback if Metric_2__c is empty
    @api showField2 = false;
    
    // Field Configuration - Row 2
    // Field 3: Value from Contact.Metric_3__c
    @api field3Label = 'CUSTOMER TYPE';
    @api field3Icon = 'utility:user';
    @api field3Value = ''; // Fallback if Metric_3__c is empty
    @api showField3 = false;
    
    // Field 4: Value from Contact.Metric_4__c
    @api field4Label = 'SINCE';
    @api field4Icon = 'utility:date_input';
    @api field4Value = ''; // Fallback if Metric_4__c is empty
    @api showField4 = false;
    
    // Field Configuration - Row 3
    // Field 5: Value from Contact.Metric_5__c
    @api field5Label = 'TRADE-IN';
    @api field5Icon = 'utility:money';
    @api field5Value = ''; // Fallback if Metric_5__c is empty
    @api showField5 = false;
    
    // Field 6: Value from Contact.Metric_6__c
    @api field6Label = 'RENEWAL';
    @api field6Icon = 'utility:event';
    @api field6Value = ''; // Fallback if Metric_6__c is empty
    @api showField6 = false;
    
    // Chart Configuration
    @api chartTitle = 'CSAT History';
    @api engagementData = '55,60,65,70,68,72,75,80,78,75,72,85';
    @api satisfactionData = '70,75,72,78,80,82,78,85,82,88,85,90';
    @api chartLabels = 'W14,W19,W24,W29,W34,W39,W44,W49,W2,W7,W12,W17';
    @api engagementLabel = 'Engage';
    @api satisfactionLabel = 'Sat';

    // Internal state
    contactIdToDisplay;
    contactName = '';
    contactLocation = '';
    contactEmail = '';
    contactProfileImageUrl = '';
    contactBackgroundUrl = '';
    contactHealthScore = '';
    contactTags = '';
    
    // Metric values from Contact record
    metric1Value = '';
    metric2Value = '';
    metric3Value = '';
    metric4Value = '';
    metric5Value = '';
    metric6Value = '';
    
    isChartRendered = false;
    chartRenderAttempts = 0;
    resizeObserver;

    // Computed properties
    get cardContainerClass() {
        return `card-container ${this.themeMode === 'Dark' ? 'dark-theme' : 'light-theme'}`;
    }

    get displayName() {
        return this.contactName || 'Contact Name';
    }

    get displayLocation() {
        return this.contactLocation || 'Location';
    }

    get displayProfileImage() {
        // Priority: Contact field value > fallbackImageUrl > legacy profileImageUrl > default avatar
        return this.contactProfileImageUrl || this.fallbackImageUrl || this.profileImageUrl || this.defaultAvatarUrl;
    }

    get defaultAvatarUrl() {
        return 'data:image/svg+xml,' + encodeURIComponent(`
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
                <circle cx="50" cy="50" r="50" fill="#e0e5ee"/>
                <circle cx="50" cy="40" r="18" fill="#a0a5ae"/>
                <ellipse cx="50" cy="85" rx="30" ry="25" fill="#a0a5ae"/>
            </svg>
        `);
    }

    // Header background style - uses Contact field, fallback URL, or default gradient
    get headerBackgroundStyle() {
        const bgUrl = this.contactBackgroundUrl || this.headerBackgroundUrl;
        if (bgUrl) {
            return `background-image: url('${bgUrl}'); background-size: cover; background-position: center;`;
        }
        return ''; // Use CSS default gradient
    }

    // Health score display
    get showHealthPill() {
        return this.showHealthScore && this.displayHealthScore;
    }

    get displayHealthScore() {
        return this.contactHealthScore || this.healthScoreFallback || '';
    }

    // Dynamic health dot color based on score value
    get healthDotStyle() {
        const score = parseInt(this.displayHealthScore, 10);
        if (isNaN(score)) {
            return 'background-color: #2e844a;'; // Default green
        }
        
        // Clamp score between 0 and 100
        const clampedScore = Math.max(0, Math.min(100, score));
        
        // Color gradient: Red (0) → Orange (35) → Yellow (50) → Light Green (70) → Green (100)
        let color;
        if (clampedScore <= 30) {
            // Red to Orange: 0-30
            const ratio = clampedScore / 30;
            color = this.interpolateColor('#dc3545', '#fd7e14', ratio); // Red to Orange
        } else if (clampedScore <= 50) {
            // Orange to Yellow: 31-50
            const ratio = (clampedScore - 30) / 20;
            color = this.interpolateColor('#fd7e14', '#ffc107', ratio); // Orange to Yellow
        } else if (clampedScore <= 70) {
            // Yellow to Light Green: 51-70
            const ratio = (clampedScore - 50) / 20;
            color = this.interpolateColor('#ffc107', '#7cb342', ratio); // Yellow to Light Green
        } else {
            // Light Green to Green: 71-100
            const ratio = (clampedScore - 70) / 30;
            color = this.interpolateColor('#7cb342', '#2e844a', ratio); // Light Green to Green
        }
        
        return `background-color: ${color};`;
    }

    // Helper method to interpolate between two hex colors
    interpolateColor(color1, color2, ratio) {
        const hex = (color) => {
            const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(color);
            return result ? {
                r: parseInt(result[1], 16),
                g: parseInt(result[2], 16),
                b: parseInt(result[3], 16)
            } : { r: 0, g: 0, b: 0 };
        };
        
        const c1 = hex(color1);
        const c2 = hex(color2);
        
        const r = Math.round(c1.r + (c2.r - c1.r) * ratio);
        const g = Math.round(c1.g + (c2.g - c1.g) * ratio);
        const b = Math.round(c1.b + (c2.b - c1.b) * ratio);
        
        return `rgb(${r}, ${g}, ${b})`;
    }

    // Tags display
    get showTagsPills() {
        return this.showTags && this.displayTags && this.displayTags.length > 0;
    }

    get displayTags() {
        const tagsString = this.contactTags || this.tags || '';
        if (!tagsString.trim()) return [];
        
        return tagsString.split(',')
            .map((tag, index) => tag.trim())
            .filter(tag => tag.length > 0)
            .map((tag, index) => {
                const colorIndex = index % TAG_COLORS.length;
                const color = TAG_COLORS[colorIndex];
                return {
                    id: `tag-${index}`,
                    label: tag.toUpperCase(),
                    style: `background-color: ${color.bg}; color: ${color.text};`
                };
            });
    }

    // Display values - use Contact metric if available, otherwise use fallback from settings
    get displayField1Value() {
        return this.metric1Value || this.field1Value || '';
    }

    get displayField2Value() {
        return this.metric2Value || this.field2Value || '';
    }

    get displayField3Value() {
        return this.metric3Value || this.field3Value || '';
    }

    get displayField4Value() {
        return this.metric4Value || this.field4Value || '';
    }

    get displayField5Value() {
        return this.metric5Value || this.field5Value || '';
    }

    get displayField6Value() {
        return this.metric6Value || this.field6Value || '';
    }

    get parentFieldsToQuery() {
        // For VoiceCall, dynamically build the field list if configured
        if (this.objectApiName === 'VoiceCall' && this.voiceCallContactField) {
            return [`VoiceCall.${this.voiceCallContactField}`];
        }
        return PARENT_RECORD_FIELDS[this.objectApiName] || undefined;
    }

    // Build optional fields array dynamically to include all custom fields
    get optionalContactFields() {
        const fields = [...METRIC_FIELDS];
        
        // Profile image field
        if (this.profileImageField) {
            fields.push(`Contact.${this.profileImageField}`);
        }
        if (this.profileImageField !== 'ContactCardPicture__c') {
            fields.push('Contact.ContactCardPicture__c');
        }
        
        // Header background field
        if (this.headerBackgroundField) {
            fields.push(`Contact.${this.headerBackgroundField}`);
        }
        if (this.headerBackgroundField !== 'ContactCardBackground__c') {
            fields.push('Contact.ContactCardBackground__c');
        }
        
        // Health score field
        if (this.healthScoreField) {
            fields.push(`Contact.${this.healthScoreField}`);
        }
        if (this.healthScoreField !== 'ContactCardHealthScore__c') {
            fields.push('Contact.ContactCardHealthScore__c');
        }
        
        // Tags field
        if (this.tagsField) {
            fields.push(`Contact.${this.tagsField}`);
        }
        if (this.tagsField !== 'ContactCardTags__c') {
            fields.push('Contact.ContactCardTags__c');
        }
        
        return fields;
    }

    // Wire to get parent record (Case, MessagingSession) to find Contact ID
    @wire(getRecord, { recordId: '$recordId', fields: '$parentFieldsToQuery' })
    wiredParentRecord({ error, data }) {
        console.log('ModernContactCard - Parent record wire fired. ObjectApiName:', this.objectApiName, 'RecordId:', this.recordId);
        if (data) {
            console.log('ModernContactCard - Parent record data:', data);
            let foundContactId;
            switch (this.objectApiName) {
                case 'Case':
                    foundContactId = getFieldValue(data, CASE_CONTACTID_FIELD);
                    break;
                case 'MessagingSession':
                    foundContactId = getFieldValue(data, MSG_CONTACTID_FIELD);
                    console.log('ModernContactCard - MessagingSession EndUserContactId:', foundContactId);
                    break;
                case 'VoiceCall':
                    // Use configured field name for VoiceCall contact lookup
                    if (this.voiceCallContactField && data.fields?.[this.voiceCallContactField]) {
                        foundContactId = data.fields[this.voiceCallContactField].value;
                        console.log('ModernContactCard - VoiceCall', this.voiceCallContactField + ':', foundContactId);
                    }
                    break;
                default:
                    break;
            }
            if (foundContactId) {
                this.contactIdToDisplay = foundContactId;
                console.log('ModernContactCard - Set contactIdToDisplay to:', foundContactId);
            }
        } else if (error) {
            console.error('ModernContactCard - Error loading parent record:', error);
        }
    }

    // Wire to get Contact record details
    @wire(getRecord, { 
        recordId: '$contactIdToDisplay', 
        fields: CONTACT_FIELDS,
        optionalFields: '$optionalContactFields'
    })
    wiredContact({ error, data }) {
        console.log('ModernContactCard - Contact wire fired. contactIdToDisplay:', this.contactIdToDisplay);
        console.log('ModernContactCard - Optional fields being queried:', this.optionalContactFields);
        if (data) {
            console.log('ModernContactCard - Contact record received');
            this.updateContactInfo(data);
        } else if (error) {
            console.error('ModernContactCard - Error fetching contact:', error);
        }
    }

    connectedCallback() {
        console.log('ModernContactCard - connectedCallback. ObjectApiName:', this.objectApiName, 'RecordId:', this.recordId);
        // Handle direct Contact page placement
        if (this.objectApiName === 'Contact') {
            this.contactIdToDisplay = this.recordId;
            console.log('ModernContactCard - Direct Contact page, set contactIdToDisplay to:', this.recordId);
        }
    }

    disconnectedCallback() {
        // Clean up resize observer
        if (this.resizeObserver) {
            this.resizeObserver.disconnect();
        }
    }

    renderedCallback() {
        if (!this.isChartRendered && this.chartRenderAttempts < 5) {
            this.chartRenderAttempts++;
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            setTimeout(() => {
                this.initChart();
            }, 300 * this.chartRenderAttempts);
        }
    }

    updateContactInfo(contactData) {
        if (!contactData) return;

        console.log('ModernContactCard - Contact data received:', contactData);
        console.log('ModernContactCard - Profile image field configured:', this.profileImageField);

        const name = getFieldValue(contactData, CONTACT_NAME_FIELD);
        const email = getFieldValue(contactData, CONTACT_EMAIL_FIELD);
        const city = getFieldValue(contactData, CONTACT_MAILING_CITY_FIELD);
        const state = getFieldValue(contactData, CONTACT_MAILING_STATE_FIELD);

        this.contactName = name || '';
        this.contactEmail = email || '';
        
        if (city || state) {
            this.contactLocation = `${city || ''}${city && state ? ', ' : ''}${state || ''}`.trim();
        }

        // Get custom fields from the contact data
        if (contactData.fields) {
            console.log('ModernContactCard - Available fields:', Object.keys(contactData.fields));
            
            // Profile image - try configured field first, then fallback to default field name
            let imageUrl = null;
            if (this.profileImageField && contactData.fields[this.profileImageField]) {
                imageUrl = contactData.fields[this.profileImageField].value;
                console.log('ModernContactCard - Found image in configured field:', imageUrl);
            }
            if (!imageUrl && contactData.fields.ContactCardPicture__c) {
                imageUrl = contactData.fields.ContactCardPicture__c.value;
                console.log('ModernContactCard - Found image in default field:', imageUrl);
            }
            if (imageUrl) {
                this.contactProfileImageUrl = imageUrl;
            }
            
            // Header background - try configured field first
            let bgUrl = null;
            if (this.headerBackgroundField && contactData.fields[this.headerBackgroundField]) {
                bgUrl = contactData.fields[this.headerBackgroundField].value;
            }
            if (!bgUrl && contactData.fields.ContactCardBackground__c) {
                bgUrl = contactData.fields.ContactCardBackground__c.value;
            }
            if (bgUrl) {
                this.contactBackgroundUrl = bgUrl;
            }
            
            // Health score - try configured field first
            let healthScore = null;
            if (this.healthScoreField && contactData.fields[this.healthScoreField]) {
                healthScore = contactData.fields[this.healthScoreField].value;
            }
            if (!healthScore && contactData.fields.ContactCardHealthScore__c) {
                healthScore = contactData.fields.ContactCardHealthScore__c.value;
            }
            if (healthScore !== null && healthScore !== undefined) {
                this.contactHealthScore = String(healthScore);
            }
            
            // Tags - try configured field first
            let tagsValue = null;
            if (this.tagsField && contactData.fields[this.tagsField]) {
                tagsValue = contactData.fields[this.tagsField].value;
            }
            if (!tagsValue && contactData.fields.ContactCardTags__c) {
                tagsValue = contactData.fields.ContactCardTags__c.value;
            }
            if (tagsValue) {
                this.contactTags = tagsValue;
            }
            
            // Metric fields - values for the 6 configurable fields
            this.metric1Value = contactData.fields.Metric_1__c?.value || '';
            this.metric2Value = contactData.fields.Metric_2__c?.value || '';
            this.metric3Value = contactData.fields.Metric_3__c?.value || '';
            this.metric4Value = contactData.fields.Metric_4__c?.value || '';
            this.metric5Value = contactData.fields.Metric_5__c?.value || '';
            this.metric6Value = contactData.fields.Metric_6__c?.value || '';
        }
    }

    handleImageError(event) {
        // Fallback to default avatar
        event.target.src = this.defaultAvatarUrl;
    }

    // Menu action handler
    handleMenuSelect(event) {
        const selectedAction = event.detail.value;
        
        switch (selectedAction) {
            case 'view':
                this.navigateToContact();
                break;
            case 'edit':
                this.editContact();
                break;
            case 'email':
                this.sendEmail();
                break;
            default:
                break;
        }
    }

    // Navigate to Contact record page
    navigateToContact() {
        if (!this.contactIdToDisplay) return;
        
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.contactIdToDisplay,
                objectApiName: 'Contact',
                actionName: 'view'
            }
        });
    }

    // Open Contact record in edit mode
    editContact() {
        if (!this.contactIdToDisplay) return;
        
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.contactIdToDisplay,
                objectApiName: 'Contact',
                actionName: 'edit'
            }
        });
    }

    // Open email composer
    sendEmail() {
        if (!this.contactEmail) {
            // If no email, navigate to contact record instead
            this.navigateToContact();
            return;
        }
        
        // Use standard email compose action
        this[NavigationMixin.Navigate]({
            type: 'standard__quickAction',
            attributes: {
                apiName: 'Global.SendEmail'
            },
            state: {
                recordId: this.contactIdToDisplay,
                defaultFieldValues: `RelatedToId=${this.contactIdToDisplay}`
            }
        });
    }

    initChart() {
        const canvas = this.refs.chartCanvas;
        if (!canvas) {
            return;
        }

        this.setupChartResizing(canvas);
        this.drawChart(canvas);
    }

    setupChartResizing(canvas) {
        if (window.ResizeObserver && !this.resizeObserver) {
            this.resizeObserver = new ResizeObserver(() => {
                if (this.resizeTimeout) {
                    clearTimeout(this.resizeTimeout);
                }
                // eslint-disable-next-line @lwc/lwc/no-async-operation
                this.resizeTimeout = setTimeout(() => {
                    this.drawChart(canvas);
                }, 100);
            });

            const chartContainer = this.template.querySelector('.chart-container');
            if (chartContainer) {
                this.resizeObserver.observe(chartContainer);
            }
        }
    }

    drawChart(canvas) {
        const ctx = canvas.getContext('2d');
        if (!ctx) return;

        // Get dimensions
        const container = canvas.parentElement;
        const displayWidth = container ? container.clientWidth : 400;
        const displayHeight = 140;

        // Handle high DPI displays
        const dpr = window.devicePixelRatio || 1;
        canvas.width = displayWidth * dpr;
        canvas.height = displayHeight * dpr;
        canvas.style.width = displayWidth + 'px';
        canvas.style.height = displayHeight + 'px';
        ctx.scale(dpr, dpr);

        // Parse data
        const engageData = this.engagementData.split(',').map(v => parseInt(v.trim(), 10));
        const satData = this.satisfactionData.split(',').map(v => parseInt(v.trim(), 10));
        const labels = this.chartLabels.split(',').map(l => l.trim());

        // Chart dimensions
        const padding = { top: 20, right: 20, bottom: 30, left: 35 };
        const chartWidth = displayWidth - padding.left - padding.right;
        const chartHeight = displayHeight - padding.top - padding.bottom;

        // Clear canvas
        ctx.clearRect(0, 0, displayWidth, displayHeight);

        // Colors - SLDS 2 compatible
        const colors = {
            grid: 'rgba(176, 185, 195, 0.3)',
            text: 'rgba(84, 105, 141, 0.8)',
            engage: '#0176d3',
            engageFill: 'rgba(1, 118, 211, 0.15)',
            sat: '#1b96ff',
            satFill: 'rgba(27, 150, 255, 0.1)'
        };

        // Draw horizontal grid lines and Y-axis labels
        ctx.strokeStyle = colors.grid;
        ctx.lineWidth = 1;
        ctx.fillStyle = colors.text;
        ctx.font = '11px -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif';
        ctx.textAlign = 'right';
        ctx.textBaseline = 'middle';

        const ySteps = [0, 25, 50, 75, 100];
        ySteps.forEach(value => {
            const y = padding.top + chartHeight - (value / 100) * chartHeight;
            
            // Grid line
            ctx.beginPath();
            ctx.setLineDash([4, 4]);
            ctx.moveTo(padding.left, y);
            ctx.lineTo(displayWidth - padding.right, y);
            ctx.stroke();
            ctx.setLineDash([]);
            
            // Y-axis label
            ctx.fillText(value.toString(), padding.left - 8, y);
        });

        // Helper function to draw filled area chart
        const drawAreaChart = (data, lineColor, fillColor) => {
            if (data.length === 0) return;

            const points = data.map((value, index) => ({
                x: padding.left + (chartWidth / (data.length - 1)) * index,
                y: padding.top + chartHeight - (value / 100) * chartHeight
            }));

            // Draw filled area
            ctx.beginPath();
            ctx.moveTo(points[0].x, padding.top + chartHeight);
            points.forEach(point => ctx.lineTo(point.x, point.y));
            ctx.lineTo(points[points.length - 1].x, padding.top + chartHeight);
            ctx.closePath();
            ctx.fillStyle = fillColor;
            ctx.fill();

            // Draw line
            ctx.beginPath();
            ctx.strokeStyle = lineColor;
            ctx.lineWidth = 2.5;
            ctx.lineCap = 'round';
            ctx.lineJoin = 'round';
            points.forEach((point, index) => {
                if (index === 0) {
                    ctx.moveTo(point.x, point.y);
                } else {
                    ctx.lineTo(point.x, point.y);
                }
            });
            ctx.stroke();
        };

        // Draw satisfaction area (behind)
        drawAreaChart(satData, colors.sat, colors.satFill);
        
        // Draw engagement area (in front)
        drawAreaChart(engageData, colors.engage, colors.engageFill);

        // Draw X-axis labels (show only key labels)
        ctx.fillStyle = colors.text;
        ctx.textAlign = 'center';
        ctx.textBaseline = 'top';
        ctx.font = '10px -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif';

        const labelIndices = [0, Math.floor(labels.length / 3), Math.floor(2 * labels.length / 3), labels.length - 1];
        labelIndices.forEach(index => {
            if (index < labels.length) {
                const x = padding.left + (chartWidth / (labels.length - 1)) * index;
                ctx.fillText(labels[index], x, displayHeight - padding.bottom + 10);
            }
        });

        this.isChartRendered = true;
    }
}
