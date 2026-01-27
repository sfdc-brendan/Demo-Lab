import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

// Import schema for the objects and their respective Contact lookup fields
import CASE_CONTACTID_FIELD from '@salesforce/schema/Case.ContactId';
import MSG_CONTACTID_FIELD from '@salesforce/schema/MessagingSession.EndUserContactId';
import VOICECALL_CONTACT_FIELD from '@salesforce/schema/VoiceCall.Contact__c';

// Import Contact fields for the final data display
import CONTACT_NAME_FIELD from '@salesforce/schema/Contact.Name';
import CONTACT_EMAIL_FIELD from '@salesforce/schema/Contact.Email';
import CONTACT_PHONE_FIELD from '@salesforce/schema/Contact.Phone';
import CONTACT_MAILING_CITY_FIELD from '@salesforce/schema/Contact.MailingCity';
import CONTACT_MAILING_STATE_FIELD from '@salesforce/schema/Contact.MailingState';
import CONTACT_CARD_PICTURE_FIELD from '@salesforce/schema/Contact.ContactCardPicture__c';
import CONTACT_METRIC_1_FIELD from '@salesforce/schema/Contact.Metric_1__c';
import CONTACT_METRIC_2_FIELD from '@salesforce/schema/Contact.Metric_2__c';
import CONTACT_METRIC_3_FIELD from '@salesforce/schema/Contact.Metric_3__c';
import CONTACT_METRIC_4_FIELD from '@salesforce/schema/Contact.Metric_4__c';
import CONTACT_METRIC_5_FIELD from '@salesforce/schema/Contact.Metric_5__c';

// Define the fields to query for each object type
const PARENT_RECORD_FIELDS = {
    Case: [CASE_CONTACTID_FIELD],
    MessagingSession: [MSG_CONTACTID_FIELD],
    VoiceCall: [VOICECALL_CONTACT_FIELD]
};

// Salesforce Id prefixes: 003 = Contact, 500 = Case. Use to avoid requesting Contact fields for a Case id.
const CONTACT_ID_PREFIX = '003';

export default class Sdo_ContactCard extends LightningElement {
    @api recordId;
    @api objectApiName; // This is automatically provided by the framework

    // --- Component Configuration Properties ---
    @api themeMode = 'Dark';
    @api headerColor = '#0066CC';
    @api hideProfilePicture = false;
    
    // Chart Configuration
    @api engagementData = '60,65,70,75,80,85,90,95,85,80,75,70';
    @api happinessData = '70,75,80,85,80,75,70,65,70,75,80,85';
    @api chartLabels = 'W14,W19,W24,W29,W34,W39,W44,W49,W2,W7,W12,W17';
    @api engagementLabel = 'Listening Score';
    @api happinessLabel = 'Satisfaction Index';
    
    // Field Display Configuration
    @api field1Label = 'Field 1';
    @api field2Label = 'Field 2';
    @api field3Label = 'Field 3';
    @api field4Label = 'Field 4';
    @api field5Label = 'Field 5';
    @api field1Icon = 'utility:identity';
    @api field2Icon = 'utility:favorite';
    @api field3Icon = 'utility:groups';
    @api field4Icon = 'utility:radio_button';
    @api field5Icon = 'utility:currency';
    
    // Field Visibility Configuration
    @api showField1 = false;
    @api showField2 = false;
    @api showField3 = false;
    @api showField4 = false;
    @api showField5 = false;

    @track isChartRendered = false;
    @track chartRenderAttempts = 0;
    @track contactIdToDisplay; // This will hold the final Contact ID we need
    
    // Chart responsiveness
    resizeObserver;
    chartCanvas;
    
    // Dynamic Contact Data (populated from Contact fields)
    @track customerName = 'Loading...';
    @track customerLocation = '';
    @track profileImageUrl = 'https://via.placeholder.com/80x80/0066CC/FFFFFF?text=?';
    @track email = '';
    @track phoneNumber = '';
    @track field1Value = '';
    @track field2Value = '';
    @track field3Value = '';
    @track field4Value = '';
    @track field5Value = '';

    // Get the fields to query - including custom fields
    get contactFieldsToQuery() {
        try {
            const fields = [
                CONTACT_NAME_FIELD,
                CONTACT_EMAIL_FIELD,
                CONTACT_PHONE_FIELD,
                CONTACT_MAILING_CITY_FIELD,
                CONTACT_MAILING_STATE_FIELD,
                CONTACT_CARD_PICTURE_FIELD,
                CONTACT_METRIC_1_FIELD,
                CONTACT_METRIC_2_FIELD,
                CONTACT_METRIC_3_FIELD,
                CONTACT_METRIC_4_FIELD,
                CONTACT_METRIC_5_FIELD
            ];
            console.log('📋 contactFieldsToQuery returning:', fields);
            return fields;
        } catch (error) {
            console.error('❌ Error building contactFieldsToQuery:', error);
            // Fallback to just standard fields if custom fields cause issues
            const standardFields = [
                CONTACT_NAME_FIELD,
                CONTACT_EMAIL_FIELD,
                CONTACT_PHONE_FIELD,
                CONTACT_MAILING_CITY_FIELD,
                CONTACT_MAILING_STATE_FIELD
            ];
            console.log('🔄 Using fallback standard fields:', standardFields);
            return standardFields;
        }
    }

    /**
     * Record id for the parent wire. Null when recordId is a Contact (003) so we never request
     * Case/Msg/VoiceCall fields for a Contact id. Otherwise non-Contact recordId when we have
     * parent fields for this object.
     */
    get parentRecordId() {
        const rid = this.recordId;
        if (!rid || String(rid).substring(0, 3) === CONTACT_ID_PREFIX) {
            return null;
        }
        return PARENT_RECORD_FIELDS[this.objectApiName] ? rid : null;
    }

    /**
     * Id we pass to getRecord when fetching Contact details. We only use recordId when it is
     * actually a Contact id (prefix 003). Otherwise we use contactIdToDisplay from the parent wire.
     * This avoids "Contact fields for Case record" errors when objectApiName is unset or delayed.
     */
    get effectiveContactId() {
        const rid = this.recordId;
        if (rid && String(rid).substring(0, 3) === CONTACT_ID_PREFIX) {
            return rid;
        }
        return this.contactIdToDisplay || null;
    }

    /**
     * WIRE 1: Get the parent record (e.g., Case) to find the Contact ID.
     * Only runs when not on Contact (parentRecordId is null on Contact so wire doesn't run).
     */
    @wire(getRecord, { recordId: '$parentRecordId', fields: '$parentFieldsToQuery' })
    wiredParentRecord({ error, data }) {
        console.log('🔍 Parent Record Wire Fired for:', this.objectApiName);
        console.log('📋 recordId:', this.recordId);
        console.log('📋 parentFieldsToQuery:', this.parentFieldsToQuery);
        
        if (data) {
            console.log('✅ Parent record data received:', data);
            let foundContactId;
            switch (this.objectApiName) {
                case 'Case':
                    foundContactId = getFieldValue(data, CASE_CONTACTID_FIELD);
                    console.log('📞 Case ContactId found:', foundContactId);
                    break;
                case 'MessagingSession':
                    foundContactId = getFieldValue(data, MSG_CONTACTID_FIELD);
                    console.log('📞 MessagingSession ContactId found:', foundContactId);
                    break;
                case 'VoiceCall':
                    // Contact__c is the custom Lookup(Contact) on Voice Call
                    foundContactId = getFieldValue(data, VOICECALL_CONTACT_FIELD);
                    console.log('📞 VoiceCall Contact__c found:', foundContactId);
                    break;
                default:
                    console.log('⚠️ Unknown object type for parent lookup:', this.objectApiName);
            }
            if (foundContactId) {
                this.contactIdToDisplay = foundContactId;
                console.log('✅ Set contactIdToDisplay to:', foundContactId);
            } else {
                console.log('⚠️ No Contact ID found in parent record');
                this.customerName = 'No Contact linked to this record';
            }
        } else if (error) {
            console.error('❌ Error loading parent record to find Contact ID:', error);
            this.customerName = 'Error loading parent record';
        }
    }

    /**
     * WIRE 2: Get the Contact record's details.
     * Uses effectiveContactId: on Contact page = recordId; on Case/Msg/VoiceCall = contactId from parent wire.
     */
    @wire(getRecord, {
        recordId: '$effectiveContactId',
        fields: '$contactFieldsToQuery'
    })
    wiredContact({ error, data }) {
        console.log('🔍 SDO Contact Card - Wire Contact Fired');
        console.log('📋 effectiveContactId:', this.effectiveContactId);
        console.log('📋 contactFieldsToQuery:', this.contactFieldsToQuery);
        
        if (data) {
            console.log('✅ Contact data received:', data);
            this.updateContactInfo(data);
        } else if (error) {
            console.error('❌ Error fetching contact details:', error);
            console.error('❌ Error details:', JSON.stringify(error, null, 2));
            
            // More specific error handling
            if (error.body && error.body.message) {
                console.error('❌ Error message:', error.body.message);
                this.customerName = `Error: ${error.body.message}`;
            } else if (error.message) {
                console.error('❌ Error message:', error.message);
                this.customerName = `Error: ${error.message}`;
            } else {
                this.customerName = 'Error loading contact - check console for details';
            }
        } else {
            console.log('⏳ No data and no error - wire method waiting for effectiveContactId');
            if (!this.effectiveContactId) {
                console.log('⚠️ effectiveContactId is null/undefined');
                this.customerName = 'No Contact ID available';
            }
        }
    }

    /**
     * This getter determines which fields to query in the first wire call.
     * If we are on a related object, it provides the lookup field. If not, it returns nothing.
     */
    get parentFieldsToQuery() {
        return PARENT_RECORD_FIELDS[this.objectApiName] || undefined;
    }

    connectedCallback() {
        // Debug logging
        console.log('SDO Contact Card - Connected Callback');
        console.log('Record ID:', this.recordId);
        console.log('Object API Name:', this.objectApiName);
        
        // Handle the case where the component is on a Contact page directly
        if (this.objectApiName === 'Contact') {
            this.contactIdToDisplay = this.recordId;
            console.log('Setting contactIdToDisplay to recordId:', this.contactIdToDisplay);
        } else {
            console.log('Not on Contact page, will need to get Contact ID from parent record');
        }
    }

    disconnectedCallback() {
        // Clean up resize observer
        if (this.resizeObserver) {
            this.resizeObserver.disconnect();
        }
        
        // Clean up window resize listener
        if (!window.ResizeObserver) {
            window.removeEventListener('resize', this.handleWindowResize);
        }
        
        // Clean up timeouts
        if (this.resizeTimeout) {
            clearTimeout(this.resizeTimeout);
        }
        if (this.windowResizeTimeout) {
            clearTimeout(this.windowResizeTimeout);
        }
    }

    renderedCallback() {
        this.applyHeaderColors();

        if (!this.isChartRendered && this.chartRenderAttempts < 5) {
            this.chartRenderAttempts++;
            setTimeout(() => {
                this.initChart();
            }, 500 * this.chartRenderAttempts);
        }
    }
    
    // --- DISPLAY GETTERS ---
    get containerClasses() { return `contact-card ${this.themeMode.toLowerCase()}-theme`; }
    get profileSectionClasses() { return `profile-section ${this.hideProfilePicture ? 'no-picture' : ''}`.trim(); }
    get displayCustomerName() { return this.customerName || 'Loading...'; }
    get displayCustomerLocation() { return this.customerLocation || ''; }
    get displayEmail() { return this.email || ''; }
    get displayPhoneNumber() { return this.phoneNumber || ''; }
    
    // --- DATA HANDLING & UI LOGIC ---
    
    // Note: We import the custom field schema references above for dependency detection,
    // but use dynamic field access below to avoid validation errors during packaging
    
    updateContactInfo(contactData) {
        console.log('SDO Contact Card - updateContactInfo called with:', contactData);
        
        if (!contactData) {
            console.log('No contact data provided');
            return;
        }

        // Update properties directly from the wired contact data
        const name = getFieldValue(contactData, CONTACT_NAME_FIELD);
        const email = getFieldValue(contactData, CONTACT_EMAIL_FIELD);
        const phone = getFieldValue(contactData, CONTACT_PHONE_FIELD);
        const city = getFieldValue(contactData, CONTACT_MAILING_CITY_FIELD);
        const state = getFieldValue(contactData, CONTACT_MAILING_STATE_FIELD);
        
        console.log('Extracted values - Name:', name, 'Email:', email, 'Phone:', phone, 'City:', city, 'State:', state);
        
        this.customerName = name || 'No Name';
        this.email = email || '';
        this.phoneNumber = phone || '';

        if (city || state) {
            this.customerLocation = `${city || ''}${city && state ? ', ' : ''}${state || ''}`.trim();
        } else {
            this.customerLocation = '';
        }

        console.log('Final values set - customerName:', this.customerName, 'customerLocation:', this.customerLocation);

        // Handle custom fields gracefully - get values if they exist
        this.updateCustomFieldValues(contactData);
    }

    updateCustomFieldValues(contactData) {
        console.log('updateCustomFieldValues called with:', contactData);
        
        // Get profile picture from custom field
        const contactPictureUrl = getFieldValue(contactData, CONTACT_CARD_PICTURE_FIELD);
        if (contactPictureUrl) {
            this.profileImageUrl = contactPictureUrl;
            console.log('Profile picture URL set:', contactPictureUrl);
        }

        // Get metric field values from Contact custom fields
        this.field1Value = getFieldValue(contactData, CONTACT_METRIC_1_FIELD) || '';
        this.field2Value = getFieldValue(contactData, CONTACT_METRIC_2_FIELD) || '';
        this.field3Value = getFieldValue(contactData, CONTACT_METRIC_3_FIELD) || '';
        this.field4Value = getFieldValue(contactData, CONTACT_METRIC_4_FIELD) || '';
        this.field5Value = getFieldValue(contactData, CONTACT_METRIC_5_FIELD) || '';
        
        console.log('Custom field values set:', {
            field1: this.field1Value,
            field2: this.field2Value,
            field3: this.field3Value,
            field4: this.field4Value,
            field5: this.field5Value
        });
    }

    hexToRgb(hex) {
        // Remove # if present
        hex = hex.replace('#', '');
        
        // Parse RGB values
        const num = parseInt(hex, 16);
        const r = num >> 16;
        const g = (num >> 8) & 0x00FF;
        const b = num & 0x0000FF;
        
        return { r, g, b };
    }

    darkenColor(hex, percent) {
        const rgb = this.hexToRgb(hex);
        const r = Math.floor(rgb.r * (1 - percent / 100));
        const g = Math.floor(rgb.g * (1 - percent / 100));
        const b = Math.floor(rgb.b * (1 - percent / 100));
        
        return `#${r.toString(16).padStart(2, '0')}${g.toString(16).padStart(2, '0')}${b.toString(16).padStart(2, '0')}`;
    }

    applyHeaderColors() {
        const container = this.template.querySelector('.contact-card');
        if (container) {
            const baseColor = this.headerColor;
            const baseRgb = this.hexToRgb(baseColor);
            const mediumColor = this.darkenColor(baseColor, 20);
            const mediumRgb = this.hexToRgb(mediumColor);
            const darkColor = this.darkenColor(baseColor, 40);
            const darkRgb = this.hexToRgb(darkColor);
            
            // Set CSS custom properties for solid colors
            container.style.setProperty('--header-color-light', baseColor);
            container.style.setProperty('--header-color-medium', mediumColor);
            container.style.setProperty('--header-color-dark', darkColor);
            
            // Set CSS custom properties for RGBA overlay colors
            container.style.setProperty('--header-overlay-light', `rgba(${baseRgb.r}, ${baseRgb.g}, ${baseRgb.b}, 0.8)`);
            container.style.setProperty('--header-overlay-medium', `rgba(${mediumRgb.r}, ${mediumRgb.g}, ${mediumRgb.b}, 0.6)`);
            container.style.setProperty('--header-overlay-dark', `rgba(${darkRgb.r}, ${darkRgb.g}, ${darkRgb.b}, 0.8)`);
            
            // Set profile picture border color to match header color
            container.style.setProperty('--profile-border-color', `rgba(${baseRgb.r}, ${baseRgb.g}, ${baseRgb.b}, 0.8)`);
            
            // Set chart background colors to match header color
            // Dark theme chart colors
            container.style.setProperty('--chart-section-bg-dark', `rgba(${baseRgb.r}, ${baseRgb.g}, ${baseRgb.b}, 0.08)`);
            container.style.setProperty('--chart-section-border-dark', `rgba(${baseRgb.r}, ${baseRgb.g}, ${baseRgb.b}, 0.2)`);
            container.style.setProperty('--chart-canvas-bg-dark', `linear-gradient(180deg, rgba(${baseRgb.r}, ${baseRgb.g}, ${baseRgb.b}, 0.12) 0%, rgba(${baseRgb.r}, ${baseRgb.g}, ${baseRgb.b}, 0.04) 100%)`);
            container.style.setProperty('--chart-canvas-border-dark', `rgba(${baseRgb.r}, ${baseRgb.g}, ${baseRgb.b}, 0.15)`);
            
            // Light theme chart colors
            container.style.setProperty('--chart-section-bg-light', `rgba(${baseRgb.r}, ${baseRgb.g}, ${baseRgb.b}, 0.05)`);
            container.style.setProperty('--chart-section-border-light', `rgba(${baseRgb.r}, ${baseRgb.g}, ${baseRgb.b}, 0.15)`);
            container.style.setProperty('--chart-canvas-bg-light', `linear-gradient(180deg, rgba(${baseRgb.r}, ${baseRgb.g}, ${baseRgb.b}, 0.08) 0%, rgba(${baseRgb.r}, ${baseRgb.g}, ${baseRgb.b}, 0.02) 100%)`);
            container.style.setProperty('--chart-canvas-border-light', `rgba(${baseRgb.r}, ${baseRgb.g}, ${baseRgb.b}, 0.12)`);
            
            // Set engagement legend color to match header color
            container.style.setProperty('--engagement-legend-color', baseColor);
        }
    }

    handleImageError(event) {
        // Fallback to a default avatar if image fails to load
        event.target.src = 'data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 80 80"><circle cx="40" cy="40" r="40" fill="%230066CC"/><text x="40" y="45" text-anchor="middle" fill="white" font-size="24" font-family="Arial">👤</text></svg>';
    }

    initChart() {
        const canvas = this.template.querySelector('canvas.chart-canvas');
        if (!canvas) {
            console.log('❌ Canvas element not found');
            return;
        }

        if (this.chart) {
            this.chart.destroy();
        }

        // Store canvas reference for resize handling
        this.chartCanvas = canvas;
        
        // Set up resize observer for responsive charts
        this.setupChartResizing();

        // Defer chart creation to ensure the canvas is ready
        setTimeout(() => {
            this.drawChart(canvas);
        }, 0);
    }

    setupChartResizing() {
        if (!this.chartCanvas) return;

        // Set up ResizeObserver to watch for container size changes
        if (window.ResizeObserver && !this.resizeObserver) {
            this.resizeObserver = new ResizeObserver((entries) => {
                // Debounce resize handling to prevent excessive redraws
                if (this.resizeTimeout) {
                    clearTimeout(this.resizeTimeout);
                }
                this.resizeTimeout = setTimeout(() => {
                    this.handleChartResize();
                }, 100);
            });

            // Observe the chart container for size changes
            const chartSection = this.template.querySelector('.chart-section');
            if (chartSection) {
                this.resizeObserver.observe(chartSection);
            }
        }

        // Fallback: window resize listener for older browsers
        if (!window.ResizeObserver) {
            window.addEventListener('resize', this.handleWindowResize.bind(this));
        }
    }

    handleChartResize() {
        if (!this.chartCanvas || !this.isChartRendered) return;
        
        // Check if canvas is still in DOM
        if (!this.chartCanvas.isConnected) {
            console.log('📏 Canvas no longer in DOM, skipping resize');
            return;
        }
        
        console.log('📏 Chart resize detected, redrawing...');
        
        // Clear canvas before resize to prevent artifacts
        const ctx = this.chartCanvas.getContext('2d');
        if (ctx) {
            ctx.clearRect(0, 0, this.chartCanvas.width, this.chartCanvas.height);
        }
        
        // Add small delay to ensure DOM has settled
        setTimeout(() => {
            if (this.chartCanvas && this.chartCanvas.isConnected) {
                this.drawChart(this.chartCanvas);
            }
        }, 10);
    }

    handleWindowResize = () => {
        // Debounced window resize handler for older browsers
        if (this.windowResizeTimeout) {
            clearTimeout(this.windowResizeTimeout);
        }
        this.windowResizeTimeout = setTimeout(() => {
            this.handleChartResize();
        }, 200);
    }
    
    drawChart(canvas) {
        console.log('🎨 DRAW CHART - Starting...');
        
        const ctx = canvas.getContext('2d');
        if (!ctx) {
            console.log('❌ Cannot get canvas context');
            return;
        }

        // Get the computed styles to respect CSS dimensions
        const computedStyle = getComputedStyle(canvas);
        let displayWidth = parseInt(computedStyle.width, 10);
        let displayHeight = parseInt(computedStyle.height, 10);
        
        // Fallback to canvas parent container if computed style fails
        if (!displayWidth || isNaN(displayWidth) || displayWidth <= 0) {
            const container = canvas.parentElement;
            displayWidth = container ? container.clientWidth - 40 : 450; // Account for padding
        }
        
        if (!displayHeight || isNaN(displayHeight) || displayHeight <= 0) {
            displayHeight = 120; // Default height
        }
        
        // Ensure minimum dimensions
        displayWidth = Math.max(displayWidth, 300);
        displayHeight = Math.max(displayHeight, 80);
        
        console.log(`📏 Canvas dimensions: ${displayWidth}x${displayHeight}`);
        
        // Account for device pixel ratio for crisp rendering
        const devicePixelRatio = window.devicePixelRatio || 1;
        const width = displayWidth * devicePixelRatio;
        const height = displayHeight * devicePixelRatio;

        // Set canvas actual size and scale context
        canvas.width = width;
        canvas.height = height;
        canvas.style.width = displayWidth + 'px';
        canvas.style.height = displayHeight + 'px';
        
        // Scale the context to match device pixel ratio
        ctx.scale(devicePixelRatio, devicePixelRatio);
        
        // Use display dimensions for drawing calculations
        const drawWidth = displayWidth;
        const drawHeight = displayHeight;

        const isLightTheme = this.themeMode === 'Light';
        const baseRgb = this.hexToRgb(this.headerColor);
        const colors = isLightTheme ? {
            backgroundStart: `rgba(${baseRgb.r}, ${baseRgb.g}, ${baseRgb.b}, 0.08)`,
            backgroundEnd: `rgba(${baseRgb.r}, ${baseRgb.g}, ${baseRgb.b}, 0.02)`,
            gridLines: 'rgba(0, 0, 0, 0.1)',
            textColor: 'rgba(51, 51, 51, 0.8)',
            engagement: this.headerColor,
            happiness: '#00CCFF',
            pointBorder: '#FFFFFF'
        } : {
            backgroundStart: `rgba(${baseRgb.r}, ${baseRgb.g}, ${baseRgb.b}, 0.15)`,
            backgroundEnd: `rgba(${baseRgb.r}, ${baseRgb.g}, ${baseRgb.b}, 0.05)`,
            gridLines: 'rgba(255, 255, 255, 0.1)',
            textColor: 'rgba(255, 255, 255, 0.8)',
            engagement: this.headerColor,
            happiness: '#00CCFF',
            pointBorder: '#FFFFFF'
        };

        // Validate dimensions before creating gradient
        if (drawWidth > 0 && drawHeight > 0 && isFinite(drawWidth) && isFinite(drawHeight)) {
            const gradient = ctx.createLinearGradient(0, 0, 0, drawHeight);
            gradient.addColorStop(0, colors.backgroundStart);
            gradient.addColorStop(1, colors.backgroundEnd);
            
            ctx.fillStyle = gradient;
            ctx.fillRect(0, 0, drawWidth, drawHeight);
        } else {
            console.error('❌ Invalid canvas dimensions for gradient:', { drawWidth, drawHeight });
            // Fallback to solid background
            ctx.fillStyle = colors.backgroundStart;
            ctx.fillRect(0, 0, drawWidth || 450, drawHeight || 120);
        }

        const engagementData = this.engagementData.split(',').map(v => parseInt(v.trim()));
        const happinessData = this.happinessData.split(',').map(v => parseInt(v.trim()));
        const labels = this.chartLabels.split(',').map(label => label.trim());
        
        const padding = 30;
        const chartWidth = drawWidth - (padding * 2);
        const chartHeight = drawHeight - (padding * 2);

        ctx.strokeStyle = colors.gridLines;
        ctx.lineWidth = 1;
        
        for (let i = 0; i <= 4; i++) {
            const y = padding + (chartHeight / 4) * i;
            ctx.beginPath();
            ctx.moveTo(padding, y);
            ctx.lineTo(drawWidth - padding, y);
            ctx.stroke();
        }

        // Draw engagement line
        if (engagementData.length > 0) {
            ctx.strokeStyle = colors.engagement;
            ctx.lineWidth = 3;
            ctx.lineCap = 'round';
            ctx.lineJoin = 'round';
            ctx.beginPath();
            engagementData.forEach((value, index) => {
                const x = padding + (chartWidth / (engagementData.length - 1)) * index;
                const y = padding + chartHeight - (value / 100) * chartHeight;
                if (index === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y);
            });
            ctx.stroke();

            ctx.fillStyle = colors.engagement;
            engagementData.forEach((value, index) => {
                const x = padding + (chartWidth / (engagementData.length - 1)) * index;
                const y = padding + chartHeight - (value / 100) * chartHeight;
                ctx.beginPath();
                ctx.arc(x, y, 3, 0, 2 * Math.PI);
                ctx.fill();
                ctx.strokeStyle = colors.pointBorder;
                ctx.lineWidth = 2;
                ctx.stroke();
            });
        }

        // Draw satisfaction line
        if (happinessData.length > 0) {
            ctx.strokeStyle = colors.happiness;
            ctx.lineWidth = 3;
            ctx.beginPath();
            happinessData.forEach((value, index) => {
                const x = padding + (chartWidth / (happinessData.length - 1)) * index;
                const y = padding + chartHeight - (value / 100) * chartHeight;
                if (index === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y);
            });
            ctx.stroke();

            ctx.fillStyle = colors.happiness;
            happinessData.forEach((value, index) => {
                const x = padding + (chartWidth / (happinessData.length - 1)) * index;
                const y = padding + chartHeight - (value / 100) * chartHeight;
                ctx.beginPath();
                ctx.arc(x, y, 3, 0, 2 * Math.PI);
                ctx.fill();
                ctx.strokeStyle = colors.pointBorder;
                ctx.lineWidth = 2;
                ctx.stroke();
            });
        }

        ctx.fillStyle = colors.textColor;
        ctx.font = '11px Arial';
        ctx.textAlign = 'right';
        ctx.textBaseline = 'middle';
        
        for (let i = 0; i <= 4; i++) {
            const value = 100 - (i * 25);
            const y = padding + (chartHeight / 4) * i;
            ctx.fillText(value.toString(), padding - 8, y);
        }

        ctx.textAlign = 'center';
        ctx.textBaseline = 'top';
        ctx.font = '10px Arial';
        
        const keyIndices = [0, Math.floor(labels.length / 3), Math.floor(2 * labels.length / 3), labels.length - 1];
        
        keyIndices.forEach(index => {
            if (index < labels.length) {
                const x = padding + (chartWidth / (labels.length - 1)) * index;
                const y = drawHeight - padding + 8;
                ctx.fillText(labels[index], x, y);
            }
        });

        this.isChartRendered = true;
        console.log(`🎉 CHART COMPLETE - ${isLightTheme ? 'Light' : 'Dark'} theme styling applied!`);
    }
}