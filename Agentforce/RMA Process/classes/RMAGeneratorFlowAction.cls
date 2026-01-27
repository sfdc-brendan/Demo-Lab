public with sharing class RMAGeneratorFlowAction {
    
    // Input wrapper class for Flow
    public class FlowInput {
        @InvocableVariable(required=true label='Case ID' description='The ID of the Case to attach the RMA to')
        public String caseId;
        
        @InvocableVariable(required=true label='Customer Name' description='Customer name for the RMA')
        public String customerName;
        
        @InvocableVariable(required=true label='Customer Email' description='Customer email for the RMA')
        public String customerEmail;
        
        @InvocableVariable(required=false label='Customer Phone' description='Customer phone number')
        public String customerPhone;
        
        @InvocableVariable(required=true label='Product Name' description='Name/model of the product')
        public String productName;
        
        @InvocableVariable(required=true label='Serial Number' description='Product serial number')
        public String serialNumber;
        
        @InvocableVariable(required=false label='Part Number' description='Product part number')
        public String partNumber;
        
        @InvocableVariable(required=false label='Purchase Date' description='Date when product was purchased')
        public String purchaseDate;
        
        @InvocableVariable(required=false label='Warranty Expiration Date' description='Warranty expiration date')
        public String warrantyExpirationDate;
        
        @InvocableVariable(required=false label='Original Invoice Number' description='Original purchase invoice number')
        public String originalInvoiceNumber;
        
        @InvocableVariable(required=true label='Problem Description' description='Detailed description of the problem')
        public String problemDescription;
        
        @InvocableVariable(required=false label='Symptoms Observed' description='Specific symptoms observed')
        public String symptomsObserved;
        
        @InvocableVariable(required=false label='Steps to Reproduce' description='Steps to reproduce the issue')
        public String stepsToReproduce;
        
        @InvocableVariable(required=false label='Error Messages' description='Any error messages received')
        public String errorMessages;
        
        @InvocableVariable(required=false label='When Issue Started' description='When the issue first started')
        public String whenIssueStarted;
        
        @InvocableVariable(required=false label='Issue Frequency' description='How often the issue occurs')
        public String issueFrequency;
        
        @InvocableVariable(required=true label='Issue Category' description='Category of the issue')
        public String issueCategory;
        
        @InvocableVariable(required=true label='Severity Level' description='Severity of the issue')
        public String severityLevel;
        
        @InvocableVariable(required=true label='Repair vs Replace Decision' description='Whether to repair or replace')
        public String repairOrReplace;
        
        @InvocableVariable(required=false label='Estimated Resolution Time' description='Estimated time to resolve')
        public String estimatedResolutionTime;
        
        @InvocableVariable(required=false label='Replacement Product' description='Replacement product if different')
        public String replacementProduct;
        
        @InvocableVariable(required=false label='Shipping Method' description='Shipping method for replacement')
        public String shippingMethod;
        
        @InvocableVariable(required=false label='Return Shipping Label' description='Whether return shipping label is needed')
        public Boolean returnShippingLabel;
        
        @InvocableVariable(required=false label='Special Instructions' description='Any special instructions')
        public String specialInstructions;
        
        @InvocableVariable(required=false label='Approval Notes' description='Notes from approval process')
        public String approvalNotes;
        
        @InvocableVariable(required=false label='Processing Notes' description='Processing notes')
        public String processingNotes;
        
        @InvocableVariable(required=false label='Estimated Ship Date' description='Estimated ship date')
        public String estimatedShipDate;
        
        @InvocableVariable(required=false label='Shipping Address' description='Customer shipping address')
        public String shippingAddress;
        
        @InvocableVariable(required=false label='Product Category' description='Category of the product')
        public String productCategory;
        
        @InvocableVariable(required=false label='Warranty Status' description='Current warranty status')
        public String warrantyStatus;
    }
    
    // Output wrapper class for Flow
    public class FlowOutput {
        @InvocableVariable(label='Success' description='Whether the RMA was generated successfully')
        public Boolean isSuccess;
        
        @InvocableVariable(label='Error Message' description='Error message if RMA generation failed')
        public String errorMessage;
        
        @InvocableVariable(label='RMA Number' description='Generated RMA number')
        public String rmaNumber;
        
        @InvocableVariable(label='File ID' description='The ID of the generated RMA file')
        public String fileId;
        
        @InvocableVariable(label='File Name' description='The name of the generated RMA file')
        public String fileName;
    }
    
    @InvocableMethod(label='Generate RMA Document and Attach to Case' 
                     description='Generates an RMA document from case data and attaches it to a Case record')
    public static List<FlowOutput> generateRMAFromFlow(List<FlowInput> inputs) {
        List<FlowOutput> outputs = new List<FlowOutput>();
        
        for (FlowInput input : inputs) {
            FlowOutput output = new FlowOutput();
            
            try {
                // Validate required inputs
                if (String.isBlank(input.caseId)) {
                    throw new IllegalArgumentException('Case ID is required');
                }
                if (String.isBlank(input.customerName)) {
                    throw new IllegalArgumentException('Customer Name is required');
                }
                if (String.isBlank(input.customerEmail)) {
                    throw new IllegalArgumentException('Customer Email is required');
                }
                if (String.isBlank(input.productName)) {
                    throw new IllegalArgumentException('Product Name is required');
                }
                if (String.isBlank(input.serialNumber)) {
                    throw new IllegalArgumentException('Serial Number is required');
                }
                if (String.isBlank(input.problemDescription)) {
                    throw new IllegalArgumentException('Problem Description is required');
                }
                if (String.isBlank(input.issueCategory)) {
                    throw new IllegalArgumentException('Issue Category is required');
                }
                if (String.isBlank(input.severityLevel)) {
                    throw new IllegalArgumentException('Severity Level is required');
                }
                if (String.isBlank(input.repairOrReplace)) {
                    throw new IllegalArgumentException('Repair vs Replace Decision is required');
                }
                
                // Generate RMA number
                String rmaNumber = generateRMANumber();
                
                // Create the RMA data JSON
                Map<String, Object> rmaData = new Map<String, Object>{
                    'caseId' => input.caseId,
                    'caseNumber' => getCaseNumber(input.caseId),
                    'rmaNumber' => rmaNumber,
                    'dateCreated' => Datetime.now().format('MMM dd, yyyy'),
                    'customerName' => input.customerName,
                    'customerEmail' => input.customerEmail,
                    'customerPhone' => input.customerPhone != null ? input.customerPhone : '',
                    'productName' => input.productName,
                    'serialNumber' => input.serialNumber,
                    'partNumber' => input.partNumber != null ? input.partNumber : '',
                    'purchaseDate' => input.purchaseDate != null ? input.purchaseDate : '',
                    'warrantyExpirationDate' => input.warrantyExpirationDate != null ? input.warrantyExpirationDate : '',
                    'originalInvoiceNumber' => input.originalInvoiceNumber != null ? input.originalInvoiceNumber : '',
                    'problemDescription' => input.problemDescription,
                    'symptomsObserved' => input.symptomsObserved != null ? input.symptomsObserved : '',
                    'stepsToReproduce' => input.stepsToReproduce != null ? input.stepsToReproduce : '',
                    'errorMessages' => input.errorMessages != null ? input.errorMessages : '',
                    'whenIssueStarted' => input.whenIssueStarted != null ? input.whenIssueStarted : '',
                    'issueFrequency' => input.issueFrequency != null ? input.issueFrequency : '',
                    'issueCategory' => input.issueCategory,
                    'severityLevel' => input.severityLevel,
                    'repairOrReplace' => input.repairOrReplace,
                    'estimatedResolutionTime' => input.estimatedResolutionTime != null ? input.estimatedResolutionTime : '',
                    'replacementProduct' => input.replacementProduct != null ? input.replacementProduct : '',
                    'shippingMethod' => input.shippingMethod != null ? input.shippingMethod : '',
                    'returnShippingLabel' => input.returnShippingLabel != null ? input.returnShippingLabel : false,
                    'specialInstructions' => input.specialInstructions != null ? input.specialInstructions : '',
                    'approvalNotes' => input.approvalNotes != null ? input.approvalNotes : '',
                    'processingNotes' => input.processingNotes != null ? input.processingNotes : '',
                    'estimatedShipDate' => input.estimatedShipDate != null ? input.estimatedShipDate : '',
                    'shippingAddress' => input.shippingAddress != null ? input.shippingAddress : '',
                    'productCategory' => input.productCategory != null ? input.productCategory : '',
                    'warrantyStatus' => input.warrantyStatus != null ? input.warrantyStatus : 'In Warranty',
                    'generatedDate' => Datetime.now().format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'')
                };
                
                String rmaDataJson = JSON.serialize(rmaData);
                
                // Call the RMA generator (you'll need to create this)
                String result = RMAGeneratorController.generateRMA(rmaDataJson);
                
                // Parse the result to get file information
                Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(result);
                
                output.isSuccess = true;
                output.rmaNumber = rmaNumber;
                output.fileId = (String) resultMap.get('fileId');
                output.fileName = (String) resultMap.get('fileName');
                output.errorMessage = '';
                
            } catch (Exception e) {
                output.isSuccess = false;
                output.errorMessage = e.getMessage();
                output.rmaNumber = '';
                output.fileId = '';
                output.fileName = '';
            }
            
            outputs.add(output);
        }
        
        return outputs;
    }
    
    // Helper method to get Case Number
    private static String getCaseNumber(String caseId) {
        try {
            Case caseRecord = [SELECT CaseNumber FROM Case WHERE Id = :caseId LIMIT 1];
            return caseRecord.CaseNumber;
        } catch (Exception e) {
            return 'CASE-001'; // Fallback
        }
    }
    
    // Helper method to generate RMA number
    private static String generateRMANumber() {
        // Generate RMA number with format: RMA-YYYYMMDD-XXXX
        String dateStr = Datetime.now().format('yyyyMMdd');
        Integer randomNum = (Integer)(Math.random() * 9999) + 1;
        return 'RMA-' + dateStr + '-' + String.valueOf(randomNum).leftPad(4, '0');
    }
}