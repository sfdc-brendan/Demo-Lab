public with sharing class RMATemplateController {
    public String rmaData { get; set; }
    public Map<String, Object> parsedData { get; set; }

    public RMATemplateController() {
        this.rmaData = ApexPages.currentPage().getParameters().get('rmaData');
        this.parsedData = new Map<String, Object>();

        if (String.isNotBlank(this.rmaData)) {
            try {
                this.parsedData = (Map<String, Object>) JSON.deserializeUntyped(this.rmaData);
            } catch (Exception e) {
                System.debug('Error parsing RMA data: ' + e.getMessage());
            }
        }
    }

    // Helper methods to get specific values
    public String getRMANumber() { return (String) this.parsedData.get('rmaNumber'); }
    public String getDateCreated() { return (String) this.parsedData.get('dateCreated'); }
    public String getCustomerName() { return (String) this.parsedData.get('customerName'); }
    public String getCustomerEmail() { return (String) this.parsedData.get('customerEmail'); }
    public String getCustomerPhone() { return (String) this.parsedData.get('customerPhone'); }
    public String getProductName() { return (String) this.parsedData.get('productName'); }
    public String getSerialNumber() { return (String) this.parsedData.get('serialNumber'); }
    public String getPartNumber() { return (String) this.parsedData.get('partNumber'); }
    public String getPurchaseDate() { return (String) this.parsedData.get('purchaseDate'); }
    public String getWarrantyExpirationDate() { return (String) this.parsedData.get('warrantyExpirationDate'); }
    public String getOriginalInvoiceNumber() { return (String) this.parsedData.get('originalInvoiceNumber'); }
    public String getProblemDescription() { return (String) this.parsedData.get('problemDescription'); }
    public String getSymptomsObserved() { return (String) this.parsedData.get('symptomsObserved'); }
    public String getStepsToReproduce() { return (String) this.parsedData.get('stepsToReproduce'); }
    public String getErrorMessages() { return (String) this.parsedData.get('errorMessages'); }
    public String getWhenIssueStarted() { return (String) this.parsedData.get('whenIssueStarted'); }
    public String getIssueFrequency() { return (String) this.parsedData.get('issueFrequency'); }
    public String getIssueCategory() { return (String) this.parsedData.get('issueCategory'); }
    public String getSeverityLevel() { return (String) this.parsedData.get('severityLevel'); }
    public String getRepairOrReplace() { return (String) this.parsedData.get('repairOrReplace'); }
    public String getEstimatedResolutionTime() { return (String) this.parsedData.get('estimatedResolutionTime'); }
    public String getReplacementProduct() { return (String) this.parsedData.get('replacementProduct'); }
    public String getShippingMethod() { return (String) this.parsedData.get('shippingMethod'); }
    public Boolean getReturnShippingLabel() { return (Boolean) this.parsedData.get('returnShippingLabel'); }
    public String getSpecialInstructions() { return (String) this.parsedData.get('specialInstructions'); }
    public String getApprovalNotes() { return (String) this.parsedData.get('approvalNotes'); }
    public String getProcessingNotes() { return (String) this.parsedData.get('processingNotes'); }
    public String getEstimatedShipDate() { return (String) this.parsedData.get('estimatedShipDate'); }
    public String getShippingAddress() { return (String) this.parsedData.get('shippingAddress'); }
    public String getProductCategory() { return (String) this.parsedData.get('productCategory'); }
    public String getWarrantyStatus() { return (String) this.parsedData.get('warrantyStatus'); }
    public String getCaseNumber() { return (String) this.parsedData.get('caseNumber'); }

    public String getGeneratedDate() {
        String dateStr = (String) this.parsedData.get('generatedDate');
        if (String.isNotBlank(dateStr)) {
            try {
                Datetime dt = Datetime.valueOf(dateStr.replace('T', ' ').replace('Z', ''));
                return dt.format('MMM dd, yyyy HH:mm:ss');
            } catch (Exception e) {
                return Datetime.now().format('MMM dd, yyyy HH:mm:ss');
            }
        }
        return Datetime.now().format('MMM dd, yyyy HH:mm:ss');
    }

    public String getSeverityClass() {
        String severity = getSeverityLevel();
        if (String.isNotBlank(severity)) {
            return 'severity-' + severity.toLowerCase();
        }
        return '';
    }

    public String getWarrantyStatusClass() {
        String status = getWarrantyStatus();
        if (String.isNotBlank(status)) {
            return 'warranty-' + status.toLowerCase().replace(' ', '-');
        }
        return '';
    }
}