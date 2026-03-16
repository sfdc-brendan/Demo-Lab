import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import generateCases from '@salesforce/apex/AICaseGeneratorController.generateCases';
import checkKnowledgeEnabled from '@salesforce/apex/AICaseGeneratorController.checkKnowledgeEnabled';

export default class AiCaseGenerator extends NavigationMixin(LightningElement) {
    // Form data properties
    @track industry = '';
    @track customerName = '';
    @track additionalDetails = '';
    @track caseCount = 3;
    @track createKnowledgeArticle = false;

    // State management
    @track isLoading = false;
    @track showResults = false;
    @track generatedCases = [];
    @track assignedContact = null;
    @track knowledgeArticle = null;
    @track errorMessage = '';
    @track isKnowledgeAvailable = false;
    @track demoScenario = null;
    @track isScenarioExpanded = true;
    @track scenarioCopied = false;

    _scenarioRendered = false;

    // Lifecycle methods
    connectedCallback() {
        this.checkKnowledgeAvailability();
    }

    renderedCallback() {
        if (this.hasScenario && this.isScenarioExpanded && !this._scenarioRendered) {
            const container = this.template.querySelector('.scenario-content');
            if (container) {
                container.innerHTML = this.formattedScenarioHtml;
                this._scenarioRendered = true;
            }
        }
    }

    // Check if Knowledge is available in this org
    async checkKnowledgeAvailability() {
        try {
            const result = await checkKnowledgeEnabled();
            this.isKnowledgeAvailable = result.knowledgeEnabled;
            console.log('Knowledge availability check:', result);
        } catch (error) {
            this.isKnowledgeAvailable = false;
            console.log('Knowledge check failed:', error);
        }
    }

    // Industry options for combobox (alphabetized)
    get industryOptions() {
        return [
            { label: 'Aerospace & Defense', value: 'Aerospace & Defense' },
            { label: 'Agriculture', value: 'Agriculture' },
            { label: 'Automotive', value: 'Automotive' },
            { label: 'Banking', value: 'Banking' },
            { label: 'Biotechnology', value: 'Biotechnology' },
            { label: 'Chemicals', value: 'Chemicals' },
            { label: 'Construction', value: 'Construction' },
            { label: 'Consulting', value: 'Consulting' },
            { label: 'Consumer Goods', value: 'Consumer Goods' },
            { label: 'Education', value: 'Education' },
            { label: 'Energy & Utilities', value: 'Energy & Utilities' },
            { label: 'Entertainment', value: 'Entertainment' },
            { label: 'Financial Services', value: 'Financial Services' },
            { label: 'Food & Beverage', value: 'Food & Beverage' },
            { label: 'Government', value: 'Government' },
            { label: 'Healthcare', value: 'Healthcare' },
            { label: 'High Tech', value: 'High Tech' },
            { label: 'Hospitality', value: 'Hospitality' },
            { label: 'Insurance', value: 'Insurance' },
            { label: 'Legal', value: 'Legal' },
            { label: 'Manufacturing', value: 'Manufacturing' },
            { label: 'Media', value: 'Media' },
            { label: 'Non-Profit', value: 'Non-Profit' },
            { label: 'Pharmaceuticals', value: 'Pharmaceuticals' },
            { label: 'Real Estate', value: 'Real Estate' },
            { label: 'Retail', value: 'Retail' },
            { label: 'Technology', value: 'Technology' },
            { label: 'Telecommunications', value: 'Telecommunications' },
            { label: 'Transportation & Logistics', value: 'Transportation & Logistics' },
            { label: 'Travel & Tourism', value: 'Travel & Tourism' },
            { label: 'Other', value: 'Other' }
        ];
    }

    // Computed properties for UI state
    get isFormValid() {
        return this.customerName && this.customerName.trim().length > 0 &&
               this.industry && this.industry.trim().length > 0;
    }

    get generateButtonDisabled() {
        return !this.isFormValid || this.isLoading;
    }

    get caseCountDisplay() {
        return `${this.caseCount} case${this.caseCount !== 1 ? 's' : ''}`;
    }

    get loadingMessage() {
        return `AI is generating ${this.caseCountDisplay} for ${this.customerName} employees...`;
    }

    get contactDisplayName() {
        return this.assignedContact ? this.assignedContact.Name : '';
    }

    get contactEmail() {
        return this.assignedContact && this.assignedContact.Email ? this.assignedContact.Email : 'No email on file';
    }

    get contactPhone() {
        return this.assignedContact && this.assignedContact.Phone ? this.assignedContact.Phone : 'No phone on file';
    }

    get contactAccountName() {
        return this.assignedContact && this.assignedContact.Account && this.assignedContact.Account.Name 
            ? this.assignedContact.Account.Name 
            : 'No account assigned';
    }

    // Event handlers for form inputs
    handleIndustryChange(event) {
        this.industry = event.detail.value;
        this.clearErrors();
    }

    handleCustomerNameChange(event) {
        this.customerName = event.detail.value;
        this.clearErrors();
    }

    handleAdditionalDetailsChange(event) {
        this.additionalDetails = event.detail.value;
        this.clearErrors();
    }

    handleCaseCountChange(event) {
        this.caseCount = parseInt(event.detail.value, 10);
        this.clearErrors();
    }

    handleCreateKnowledgeArticleChange(event) {
        this.createKnowledgeArticle = event.target.checked;
        this.clearErrors();
    }

    // Main case generation handler
    async handleGenerateCases() {
        try {
            // Validate form before proceeding
            if (!this.validateForm()) {
                return;
            }

            // Set loading state
            this.isLoading = true;
            this.showResults = false;
            this.errorMessage = '';

            // Call Apex method
            const result = await generateCases({
                industry: this.industry,
                customerName: this.customerName.trim(),
                additionalDetails: this.additionalDetails || '',
                caseCount: this.caseCount,
                createKnowledgeArticle: this.createKnowledgeArticle
            });

            // Process successful response
            if (result.success) {
                this.generatedCases = (result.cases || []).map(caseItem => ({
                    ...caseItem,
                    priorityVariant: this.getPriorityVariant(caseItem.Priority),
                    typeVariant: this.getCaseTypeVariant(caseItem.Type),
                    formattedDescription: this.getFormattedDescription(caseItem.Description)
                }));
                this.assignedContact = result.contact || null;
                this.knowledgeArticle = result.knowledgeArticle || null;
                this.demoScenario = result.demoScenario || null;
                this.scenarioCopied = false;
                this.isScenarioExpanded = true;
                this._scenarioRendered = false;
                this.showResults = true;

                // Show success toast
                const successMessage = this.knowledgeArticle 
                    ? `Successfully generated ${this.generatedCases.length} cases and 1 knowledge article assigned to ${this.contactDisplayName}`
                    : `Successfully generated ${this.generatedCases.length} cases assigned to ${this.contactDisplayName}`;
                
                this.showToast(
                    'Success!',
                    successMessage,
                    'success'
                );
            } else {
                // Handle business logic errors
                this.errorMessage = result.message || 'An error occurred while generating cases.';
                this.showToast('Error', this.errorMessage, 'error');
            }

        } catch (error) {
            console.error('Error generating cases:', error);
            this.errorMessage = 'An unexpected error occurred. Please try again or contact your administrator.';
            this.showToast('Error', this.errorMessage, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    // Form validation
    validateForm() {
        let isValid = true;
        
        // Validate industry (required field)
        const industryInput = this.template.querySelector('[data-field="industry"]');
        if (!this.industry || this.industry.trim().length === 0) {
            industryInput.setCustomValidity('Industry selection is required');
            isValid = false;
        } else {
            industryInput.setCustomValidity('');
        }
        industryInput.reportValidity();
        
        // Validate company name (required field)
        const companyNameInput = this.template.querySelector('[data-field="customerName"]');
        if (!this.customerName || this.customerName.trim().length === 0) {
            companyNameInput.setCustomValidity('Company name is required');
            isValid = false;
        } else {
            companyNameInput.setCustomValidity('');
        }
        companyNameInput.reportValidity();

        // Validate case count range
        if (this.caseCount < 1 || this.caseCount > 10) {
            this.showToast('Invalid Input', 'Case count must be between 1 and 10', 'warning');
            isValid = false;
        }

        // Validate customer name length
        if (this.customerName && this.customerName.trim().length > 100) {
            this.showToast('Invalid Input', 'Customer name must be 100 characters or less', 'warning');
            isValid = false;
        }

        return isValid;
    }

    // Reset form to initial state
    handleReset() {
        this.industry = '';
        this.customerName = '';
        this.additionalDetails = '';
        this.caseCount = 3;
        this.createKnowledgeArticle = false;
        this.showResults = false;
        this.generatedCases = [];
        this.assignedContact = null;
        this.knowledgeArticle = null;
        this.demoScenario = null;
        this.scenarioCopied = false;
        this.isScenarioExpanded = true;
        this._scenarioRendered = false;
        this.isLoading = false;
        this.errorMessage = '';
        
        // Clear any validation errors
        this.clearErrors();
        
        this.showToast('Reset', 'Form has been reset', 'info');
    }

    // Clear validation errors
    clearErrors() {
        this.errorMessage = '';
        const inputElements = this.template.querySelectorAll('lightning-input, lightning-combobox, lightning-textarea');
        inputElements.forEach(element => {
            element.setCustomValidity('');
            element.reportValidity();
        });
    }

    // Navigate to case record
    handleViewCase(event) {
        const caseId = event.target.dataset.caseId;
        if (caseId) {
            // Navigate to case record using navigation service
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: caseId,
                    actionName: 'view'
                }
            });
        }
    }

    // Navigate to contact record
    handleViewContact() {
        if (this.assignedContact && this.assignedContact.Id) {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.assignedContact.Id,
                    actionName: 'view'
                }
            });
        }
    }

    // Navigate to knowledge article record
    handleViewKnowledgeArticle() {
        if (this.knowledgeArticle && this.knowledgeArticle.Id) {
            // Try to navigate to the knowledge article
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.knowledgeArticle.KnowledgeArticleId || this.knowledgeArticle.Id,
                    objectApiName: 'Knowledge__kav',
                    actionName: 'view'
                }
            }).catch(error => {
                // If navigation fails, show a toast with article details
                this.showToast(
                    'Article Created', 
                    `Knowledge Article "${this.knowledgeArticle.Title}" was created successfully. Article Number: ${this.knowledgeArticle.ArticleNumber}. Search for it in the Knowledge tab.`, 
                    'info'
                );
                console.error('Navigation error:', error);
            });
        }
    }

    // Utility method for showing toast notifications
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

    // Demo scenario computed properties
    get hasScenario() {
        return this.demoScenario != null && this.demoScenario.length > 0;
    }

    get scenarioToggleIcon() {
        return this.isScenarioExpanded ? 'utility:chevrondown' : 'utility:chevronright';
    }

    get copyButtonLabel() {
        return this.scenarioCopied ? 'Copied!' : 'Copy Script';
    }

    get copyButtonVariant() {
        return this.scenarioCopied ? 'success' : 'neutral';
    }

    get formattedScenarioHtml() {
        if (!this.demoScenario) return '';
        return this.markdownToHtml(this.demoScenario);
    }

    // Toggle demo scenario visibility
    handleToggleScenario() {
        this.isScenarioExpanded = !this.isScenarioExpanded;
        if (this.isScenarioExpanded) {
            this._scenarioRendered = false;
        }
    }

    // Copy demo scenario to clipboard
    handleCopyScenario() {
        if (!this.demoScenario) return;
        navigator.clipboard.writeText(this.demoScenario).then(() => {
            this.scenarioCopied = true;
            this.showToast('Copied', 'Demo scenario copied to clipboard', 'success');
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            setTimeout(() => { this.scenarioCopied = false; }, 2500);
        }).catch(() => {
            this.showToast('Error', 'Could not copy to clipboard', 'error');
        });
    }

    /**
     * Lightweight Markdown-to-HTML for the scenario display.
     * Handles ##/### headings, **bold**, bullet lists, and paragraphs.
     */
    markdownToHtml(md) {
        const escaped = md
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;');

        const lines = escaped.split('\n');
        const htmlLines = [];
        let inList = false;

        for (const line of lines) {
            const trimmed = line.trim();

            if (trimmed.startsWith('### ')) {
                if (inList) { htmlLines.push('</ul>'); inList = false; }
                htmlLines.push('<h3 class="scenario-h3">' + this.inlineBold(trimmed.substring(4)) + '</h3>');
            } else if (trimmed.startsWith('## ')) {
                if (inList) { htmlLines.push('</ul>'); inList = false; }
                htmlLines.push('<h2 class="scenario-h2">' + this.inlineBold(trimmed.substring(3)) + '</h2>');
            } else if (trimmed.startsWith('- ')) {
                if (!inList) { htmlLines.push('<ul class="scenario-list">'); inList = true; }
                htmlLines.push('<li>' + this.inlineBold(trimmed.substring(2)) + '</li>');
            } else if (trimmed === '') {
                if (inList) { htmlLines.push('</ul>'); inList = false; }
            } else {
                if (inList) { htmlLines.push('</ul>'); inList = false; }
                htmlLines.push('<p class="scenario-p">' + this.inlineBold(trimmed) + '</p>');
            }
        }
        if (inList) htmlLines.push('</ul>');
        return htmlLines.join('');
    }

    inlineBold(text) {
        return text.replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>');
    }

    // Component lifecycle - cleanup on disconnect
    disconnectedCallback() {
        // Reset component state when component is removed
        this.isLoading = false;
        this.showResults = false;
    }

    // Get priority badge variant for styling
    getPriorityVariant(priority) {
        switch (priority?.toLowerCase()) {
            case 'high':
                return 'error';
            case 'medium':
                return 'warning';
            case 'low':
                return 'success';
            default:
                return 'neutral';
        }
    }

    // Get case type variant for styling  
    getCaseTypeVariant(type) {
        switch (type?.toLowerCase()) {
            case 'incident':
                return 'error';
            case 'problem':
                return 'warning';
            case 'feature request':
                return 'success';
            case 'question':
                return 'neutral';
            default:
                return 'neutral';
        }
    }

    // Format case description for display (truncate if too long)
    getFormattedDescription(description) {
        if (!description) return '';
        return description.length > 150 
            ? description.substring(0, 150) + '...' 
            : description;
    }
}