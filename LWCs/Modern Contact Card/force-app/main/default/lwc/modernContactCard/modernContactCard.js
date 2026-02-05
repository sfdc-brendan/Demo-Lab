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

// Parent record fields mapping
const PARENT_RECORD_FIELDS = {
    Case: [CASE_CONTACTID_FIELD],
    MessagingSession: [MSG_CONTACTID_FIELD]
};

// Contact fields to query
const CONTACT_FIELDS = [
    CONTACT_NAME_FIELD,
    CONTACT_EMAIL_FIELD,
    CONTACT_PHONE_FIELD,
    CONTACT_MAILING_CITY_FIELD,
    CONTACT_MAILING_STATE_FIELD
];

// Optional custom fields on Contact for metrics
const METRIC_FIELDS = [
    'Contact.Metric_1__c',
    'Contact.Metric_2__c',
    'Contact.Metric_3__c',
    'Contact.Metric_4__c',
    'Contact.Metric_5__c',
    'Contact.Metric_6__c'
];

export default class ModernContactCard extends NavigationMixin(LightningElement) {
    @api recordId;
    @api objectApiName;

    // Theme Configuration
    @api themeMode = 'Light';
    
    // Profile Configuration
    @api profileImageField = 'ContactCardPicture__c';
    @api profileImageUrl = ''; // Legacy fallback
    @api fallbackImageUrl = '';
    
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
        return PARENT_RECORD_FIELDS[this.objectApiName] || undefined;
    }

    // Build optional fields array dynamically to include profile image field
    get optionalContactFields() {
        const fields = [...METRIC_FIELDS];
        // Add the profile image field if configured
        if (this.profileImageField) {
            fields.push(`Contact.${this.profileImageField}`);
        }
        // Also always include the default field name in case it differs
        if (this.profileImageField !== 'ContactCardPicture__c') {
            fields.push('Contact.ContactCardPicture__c');
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

        // Get profile image and metric fields from the contact data
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
