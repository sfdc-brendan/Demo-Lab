import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';

// Import Account fields
import ACCOUNT_NAME_FIELD from '@salesforce/schema/Account.Name';
import ACCOUNT_TYPE_FIELD from '@salesforce/schema/Account.Type';
import ACCOUNT_INDUSTRY_FIELD from '@salesforce/schema/Account.Industry';
import ACCOUNT_EMPLOYEES_FIELD from '@salesforce/schema/Account.NumberOfEmployees';
import ACCOUNT_REVENUE_FIELD from '@salesforce/schema/Account.AnnualRevenue';
import ACCOUNT_WEBSITE_FIELD from '@salesforce/schema/Account.Website';
import ACCOUNT_PHONE_FIELD from '@salesforce/schema/Account.Phone';
import ACCOUNT_BILLING_CITY_FIELD from '@salesforce/schema/Account.BillingCity';
import ACCOUNT_BILLING_STATE_FIELD from '@salesforce/schema/Account.BillingState';

// Import Apex controller
import getAccountMetrics from '@salesforce/apex/ModernAccountCardController.getAccountMetrics';

// Account fields to query
const ACCOUNT_FIELDS = [
    ACCOUNT_NAME_FIELD,
    ACCOUNT_TYPE_FIELD,
    ACCOUNT_INDUSTRY_FIELD,
    ACCOUNT_EMPLOYEES_FIELD,
    ACCOUNT_REVENUE_FIELD,
    ACCOUNT_WEBSITE_FIELD,
    ACCOUNT_PHONE_FIELD,
    ACCOUNT_BILLING_CITY_FIELD,
    ACCOUNT_BILLING_STATE_FIELD
];

// Logo field on Account (optional)
const LOGO_FIELD = 'Account.AccountCardLogo__c';

// Brand affinity fields on Account (optional)
const BRAND_FIELDS = [
    'Account.Brand_1_Name__c',
    'Account.Brand_1_Image__c',
    'Account.Brand_2_Name__c',
    'Account.Brand_2_Image__c',
    'Account.Brand_3_Name__c',
    'Account.Brand_3_Image__c',
    'Account.Brand_4_Name__c',
    'Account.Brand_4_Image__c'
];

export default class ModernAccountCard extends NavigationMixin(LightningElement) {
    @api recordId;
    @api objectApiName;

    // Theme Configuration
    @api themeMode = 'Light';
    
    // Header Background Configuration
    @api headerBackgroundUrl = '';
    
    // Logo Configuration
    @api logoUrl = '';
    @api fallbackLogoUrl = '';
    
    // Revenue Cloud Metric Fallbacks
    @api quoteCountFallback = '';
    @api quoteTotalFallback = '';
    @api assetCountFallback = '';
    @api orderTotalFallback = '';
    @api invoiceTotalFallback = '';
    
    // Metric Labels
    @api quoteCountLabel = 'QUOTES';
    @api quoteTotalLabel = 'QUOTE VALUE';
    @api assetCountLabel = 'ACTIVE ASSETS';
    @api orderTotalLabel = 'ORDER VALUE';
    @api invoiceTotalLabel = 'INVOICE TOTAL';
    
    // Show/Hide toggles
    @api showQuoteCount = false;
    @api showQuoteTotal = false;
    @api showAssetCount = false;
    @api showOrderTotal = false;
    @api showInvoiceTotal = false;
    
    // Brand Affinities Configuration (LWC settings are fallbacks; Account fields are primary)
    @api showBrandAffinities = false;
    @api brandAffinitiesTitle = 'Sub-Brands';
    @api brand1Name = '';
    @api brand1Image = '';
    @api brand2Name = '';
    @api brand2Image = '';
    @api brand3Name = '';
    @api brand3Image = '';
    @api brand4Name = '';
    @api brand4Image = '';
    
    // Chart Configuration
    @api showChart = false;
    @api chartTitle = 'Revenue Trend';
    @api chartLine1Data = '100,150,200,180,220,280,320,350,400,450,480,520';
    @api chartLine2Data = '80,120,160,140,180,220,260,290,340,380,420,460';
    @api chartLabels = 'Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec';
    @api chartLine1Label = 'Orders';
    @api chartLine2Label = 'Invoiced';
    @api chartLine1Color = '#0176d3';
    @api chartLine2Color = '#2e844a';

    // Internal state
    accountName = '';
    accountType = '';
    accountIndustry = '';
    accountEmployees = '';
    accountRevenue = '';
    accountWebsite = '';
    accountPhone = '';
    accountLocation = '';
    
    // Logo from Account record
    accountLogo = '';
    
    // Brand affinity values from Account record
    accountBrand1Name = '';
    accountBrand1Image = '';
    accountBrand2Name = '';
    accountBrand2Image = '';
    accountBrand3Name = '';
    accountBrand3Image = '';
    accountBrand4Name = '';
    accountBrand4Image = '';
    
    // Metrics from Apex
    metricsData = null;
    metricsError = null;
    
    isChartRendered = false;
    chartRenderAttempts = 0;
    resizeObserver;

    // Computed properties
    get cardContainerClass() {
        return `card-container ${this.themeMode === 'Dark' ? 'dark-theme' : 'light-theme'}`;
    }

    get displayName() {
        return this.accountName || 'Account Name';
    }

    get displayIndustry() {
        return this.accountIndustry || 'Industry';
    }

    get displayType() {
        return this.accountType || '';
    }

    get displayLogo() {
        // Priority: Account field > LWC logoUrl setting > fallback setting > default SVG
        return this.accountLogo || this.logoUrl || this.fallbackLogoUrl || this.defaultLogoUrl;
    }

    get defaultLogoUrl() {
        return 'data:image/svg+xml,' + encodeURIComponent(`
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
                <rect width="100" height="100" rx="12" fill="#e0e5ee"/>
                <rect x="20" y="35" width="60" height="8" rx="2" fill="#a0a5ae"/>
                <rect x="20" y="50" width="40" height="8" rx="2" fill="#a0a5ae"/>
                <rect x="20" y="65" width="50" height="8" rx="2" fill="#a0a5ae"/>
            </svg>
        `);
    }

    get headerBackgroundStyle() {
        if (this.headerBackgroundUrl) {
            return `background-image: url('${this.headerBackgroundUrl}'); background-size: cover; background-position: center;`;
        }
        return '';
    }

    // Account Info Display
    get displayLocation() {
        return this.accountLocation || '';
    }

    get displayEmployees() {
        if (!this.accountEmployees) return '';
        return this.formatNumber(this.accountEmployees) + ' employees';
    }

    get displayRevenue() {
        if (!this.accountRevenue) return '';
        return this.formatCurrency(this.accountRevenue);
    }

    get hasAccountDetails() {
        return this.displayType || this.displayLocation || this.displayEmployees;
    }

    // Revenue Cloud Metrics Display
    get displayQuoteCount() {
        if (this.metricsData?.quoteCount !== undefined && this.metricsData.quoteCount > 0) {
            return this.formatNumber(this.metricsData.quoteCount);
        }
        return this.quoteCountFallback || '0';
    }

    get displayQuoteTotal() {
        if (this.metricsData?.quoteTotalPrice !== undefined && this.metricsData.quoteTotalPrice > 0) {
            return this.formatCurrency(this.metricsData.quoteTotalPrice);
        }
        return this.quoteTotalFallback || '$0';
    }

    get displayAssetCount() {
        if (this.metricsData?.activeAssetCount !== undefined && this.metricsData.activeAssetCount > 0) {
            return this.formatNumber(this.metricsData.activeAssetCount);
        }
        return this.assetCountFallback || '0';
    }

    get displayOrderTotal() {
        if (this.metricsData?.orderTotalAmount !== undefined && this.metricsData.orderTotalAmount > 0) {
            return this.formatCurrency(this.metricsData.orderTotalAmount);
        }
        return this.orderTotalFallback || '$0';
    }

    get displayInvoiceTotal() {
        if (this.metricsData?.invoiceTotalAmount !== undefined && this.metricsData.invoiceTotalAmount > 0) {
            return this.formatCurrency(this.metricsData.invoiceTotalAmount);
        }
        return this.invoiceTotalFallback || '$0';
    }

    // Brand affinities display
    get showBrandSection() {
        return this.showBrandAffinities && this.displayBrands && this.displayBrands.length > 0;
    }

    get displayBrands() {
        const brands = [];
        
        // Brand 1 - Account field first, then LWC setting as fallback
        const brand1NameValue = this.accountBrand1Name || this.brand1Name;
        const brand1ImageValue = this.accountBrand1Image || this.brand1Image;
        if (brand1NameValue && brand1ImageValue) {
            brands.push({
                id: 'brand-1',
                name: brand1NameValue,
                image: brand1ImageValue
            });
        }
        
        // Brand 2
        const brand2NameValue = this.accountBrand2Name || this.brand2Name;
        const brand2ImageValue = this.accountBrand2Image || this.brand2Image;
        if (brand2NameValue && brand2ImageValue) {
            brands.push({
                id: 'brand-2',
                name: brand2NameValue,
                image: brand2ImageValue
            });
        }
        
        // Brand 3
        const brand3NameValue = this.accountBrand3Name || this.brand3Name;
        const brand3ImageValue = this.accountBrand3Image || this.brand3Image;
        if (brand3NameValue && brand3ImageValue) {
            brands.push({
                id: 'brand-3',
                name: brand3NameValue,
                image: brand3ImageValue
            });
        }
        
        // Brand 4
        const brand4NameValue = this.accountBrand4Name || this.brand4Name;
        const brand4ImageValue = this.accountBrand4Image || this.brand4Image;
        if (brand4NameValue && brand4ImageValue) {
            brands.push({
                id: 'brand-4',
                name: brand4NameValue,
                image: brand4ImageValue
            });
        }
        
        return brands;
    }

    // Chart legend styles
    get chartLine1DotStyle() {
        return `background-color: ${this.chartLine1Color || '#0176d3'};`;
    }

    get chartLine2DotStyle() {
        return `background-color: ${this.chartLine2Color || '#2e844a'};`;
    }

    // Helper to convert hex to rgba
    hexToRgba(hexColor, opacity) {
        const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hexColor);
        if (result) {
            const r = parseInt(result[1], 16);
            const g = parseInt(result[2], 16);
            const b = parseInt(result[3], 16);
            return `rgba(${r}, ${g}, ${b}, ${opacity})`;
        }
        return `rgba(0, 0, 0, ${opacity})`;
    }

    // Format helpers
    formatNumber(value) {
        if (value === null || value === undefined) return '0';
        return new Intl.NumberFormat('en-US').format(value);
    }

    formatCurrency(value) {
        if (value === null || value === undefined) return '$0';
        return new Intl.NumberFormat('en-US', {
            style: 'currency',
            currency: 'USD',
            minimumFractionDigits: 0,
            maximumFractionDigits: 0
        }).format(value);
    }

    // Build optional fields for logo and brand affinities
    get optionalAccountFields() {
        const fields = [LOGO_FIELD]; // Always try to fetch logo
        if (this.showBrandAffinities) {
            fields.push(...BRAND_FIELDS);
        }
        return fields;
    }

    // Wire to get Account record
    @wire(getRecord, { recordId: '$recordId', fields: ACCOUNT_FIELDS, optionalFields: '$optionalAccountFields' })
    wiredAccount({ error, data }) {
        if (data) {
            this.updateAccountInfo(data);
        } else if (error) {
            console.error('ModernAccountCard - Error fetching account:', error);
        }
    }

    // Wire to get metrics from Apex
    @wire(getAccountMetrics, { accountId: '$recordId' })
    wiredMetrics({ error, data }) {
        if (data) {
            this.metricsData = data;
            this.metricsError = null;
        } else if (error) {
            this.metricsError = error;
            this.metricsData = null;
            console.error('ModernAccountCard - Error fetching metrics:', error);
        }
    }

    connectedCallback() {
        // Component connected
    }

    disconnectedCallback() {
        if (this.resizeObserver) {
            this.resizeObserver.disconnect();
        }
    }

    renderedCallback() {
        if (this.showChart && !this.isChartRendered && this.chartRenderAttempts < 5) {
            this.chartRenderAttempts++;
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            setTimeout(() => {
                this.initChart();
            }, 300 * this.chartRenderAttempts);
        }
    }

    updateAccountInfo(accountData) {
        if (!accountData) return;

        this.accountName = getFieldValue(accountData, ACCOUNT_NAME_FIELD) || '';
        this.accountType = getFieldValue(accountData, ACCOUNT_TYPE_FIELD) || '';
        this.accountIndustry = getFieldValue(accountData, ACCOUNT_INDUSTRY_FIELD) || '';
        this.accountEmployees = getFieldValue(accountData, ACCOUNT_EMPLOYEES_FIELD) || '';
        this.accountRevenue = getFieldValue(accountData, ACCOUNT_REVENUE_FIELD) || '';
        this.accountWebsite = getFieldValue(accountData, ACCOUNT_WEBSITE_FIELD) || '';
        this.accountPhone = getFieldValue(accountData, ACCOUNT_PHONE_FIELD) || '';
        
        const city = getFieldValue(accountData, ACCOUNT_BILLING_CITY_FIELD);
        const state = getFieldValue(accountData, ACCOUNT_BILLING_STATE_FIELD);
        if (city || state) {
            this.accountLocation = `${city || ''}${city && state ? ', ' : ''}${state || ''}`.trim();
        }
        
        // Extract optional fields if available
        if (accountData.fields) {
            // Logo field
            this.accountLogo = accountData.fields.AccountCardLogo__c?.value || '';
            
            // Brand affinity fields
            this.accountBrand1Name = accountData.fields.Brand_1_Name__c?.value || '';
            this.accountBrand1Image = accountData.fields.Brand_1_Image__c?.value || '';
            this.accountBrand2Name = accountData.fields.Brand_2_Name__c?.value || '';
            this.accountBrand2Image = accountData.fields.Brand_2_Image__c?.value || '';
            this.accountBrand3Name = accountData.fields.Brand_3_Name__c?.value || '';
            this.accountBrand3Image = accountData.fields.Brand_3_Image__c?.value || '';
            this.accountBrand4Name = accountData.fields.Brand_4_Name__c?.value || '';
            this.accountBrand4Image = accountData.fields.Brand_4_Image__c?.value || '';
        }
    }

    handleImageError(event) {
        event.target.src = this.defaultLogoUrl;
    }

    // Menu action handler
    handleMenuSelect(event) {
        const selectedAction = event.detail.value;
        
        switch (selectedAction) {
            case 'view':
                this.navigateToAccount();
                break;
            case 'edit':
                this.editAccount();
                break;
            case 'quotes':
                this.navigateToQuotes();
                break;
            case 'orders':
                this.navigateToOrders();
                break;
            default:
                break;
        }
    }

    navigateToAccount() {
        if (!this.recordId) return;
        
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'Account',
                actionName: 'view'
            }
        });
    }

    editAccount() {
        if (!this.recordId) return;
        
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'Account',
                actionName: 'edit'
            }
        });
    }

    navigateToQuotes() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordRelationshipPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'Account',
                relationshipApiName: 'Quotes',
                actionName: 'view'
            }
        });
    }

    navigateToOrders() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordRelationshipPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'Account',
                relationshipApiName: 'Orders',
                actionName: 'view'
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

        const container = canvas.parentElement;
        const displayWidth = container ? container.clientWidth : 400;
        const displayHeight = 140;

        const dpr = window.devicePixelRatio || 1;
        canvas.width = displayWidth * dpr;
        canvas.height = displayHeight * dpr;
        canvas.style.width = displayWidth + 'px';
        canvas.style.height = displayHeight + 'px';
        ctx.scale(dpr, dpr);

        const line1Data = this.chartLine1Data.split(',').map(v => parseInt(v.trim(), 10));
        const line2Data = this.chartLine2Data.split(',').map(v => parseInt(v.trim(), 10));
        const labels = this.chartLabels.split(',').map(l => l.trim());

        const padding = { top: 20, right: 20, bottom: 30, left: 50 };
        const chartWidth = displayWidth - padding.left - padding.right;
        const chartHeight = displayHeight - padding.top - padding.bottom;

        ctx.clearRect(0, 0, displayWidth, displayHeight);

        // Find max value for scaling
        const allValues = [...line1Data, ...line2Data];
        const maxValue = Math.max(...allValues);
        const minValue = 0;
        const valueRange = maxValue - minValue;

        // Colors
        const line1Hex = this.chartLine1Color || '#0176d3';
        const line2Hex = this.chartLine2Color || '#2e844a';
        
        const colors = {
            grid: 'rgba(176, 185, 195, 0.3)',
            text: 'rgba(84, 105, 141, 0.8)',
            line1: line1Hex,
            line1Fill: this.hexToRgba(line1Hex, 0.15),
            line2: line2Hex,
            line2Fill: this.hexToRgba(line2Hex, 0.1)
        };

        // Draw grid and Y-axis labels
        ctx.strokeStyle = colors.grid;
        ctx.lineWidth = 1;
        ctx.fillStyle = colors.text;
        ctx.font = '11px -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif';
        ctx.textAlign = 'right';
        ctx.textBaseline = 'middle';

        const ySteps = 4;
        for (let i = 0; i <= ySteps; i++) {
            const value = minValue + (valueRange / ySteps) * i;
            const y = padding.top + chartHeight - (i / ySteps) * chartHeight;
            
            ctx.beginPath();
            ctx.setLineDash([4, 4]);
            ctx.moveTo(padding.left, y);
            ctx.lineTo(displayWidth - padding.right, y);
            ctx.stroke();
            ctx.setLineDash([]);
            
            ctx.fillText(this.formatCurrency(value), padding.left - 8, y);
        }

        const drawAreaChart = (data, lineColor, fillColor) => {
            if (data.length === 0) return;

            const points = data.map((value, index) => ({
                x: padding.left + (chartWidth / (data.length - 1)) * index,
                y: padding.top + chartHeight - ((value - minValue) / valueRange) * chartHeight
            }));

            ctx.beginPath();
            ctx.moveTo(points[0].x, padding.top + chartHeight);
            points.forEach(point => ctx.lineTo(point.x, point.y));
            ctx.lineTo(points[points.length - 1].x, padding.top + chartHeight);
            ctx.closePath();
            ctx.fillStyle = fillColor;
            ctx.fill();

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

        drawAreaChart(line2Data, colors.line2, colors.line2Fill);
        drawAreaChart(line1Data, colors.line1, colors.line1Fill);

        // X-axis labels
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
