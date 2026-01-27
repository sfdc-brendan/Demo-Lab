public with sharing class RMAGeneratorController {
    
    @AuraEnabled
    public static String generateRMA(String rmaData) {
        try {
            // Parse the RMA data
            Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(rmaData);
            
            // Generate PDF content using Visualforce page
            PageReference rmaPage = Page.RMATemplate;
            rmaPage.getParameters().put('rmaData', rmaData);
            
            // Generate PDF content
            Blob pdfBlob = rmaPage.getContentAsPDF();
            
            // Create ContentVersion record
            ContentVersion cv = new ContentVersion();
            cv.Title = 'RMA-' + (String) data.get('rmaNumber') + '.pdf';
            cv.PathOnClient = 'RMA-' + (String) data.get('rmaNumber') + '.pdf';
            cv.VersionData = pdfBlob;
            cv.IsMajorVersion = true;
            
            insert cv;
            
            // Get the ContentDocument ID
            ContentVersion insertedCV = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
            
            // Create ContentDocumentLink to attach to Case
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = insertedCV.ContentDocumentId;
            cdl.LinkedEntityId = (String) data.get('caseId');
            cdl.ShareType = 'V';
            cdl.Visibility = 'AllUsers';
            
            insert cdl;
            
            // Return success response
            Map<String, Object> response = new Map<String, Object>{
                'success' => true,
                'fileId' => insertedCV.ContentDocumentId,
                'fileName' => cv.Title,
                'rmaNumber' => (String) data.get('rmaNumber')
            };
            
            return JSON.serialize(response);
            
        } catch (Exception e) {
            // Return error response
            Map<String, Object> response = new Map<String, Object>{
                'success' => false,
                'error' => e.getMessage(),
                'fileId' => '',
                'fileName' => '',
                'rmaNumber' => ''
            };
            
            return JSON.serialize(response);
        }
    }
    
    @AuraEnabled
    public static Map<String, Object> getCaseInfo(String caseId) {
        try {
            Case caseRecord = [SELECT Id, CaseNumber, Subject, Description, Priority, Type, Status 
                              FROM Case WHERE Id = :caseId LIMIT 1];
            
            Map<String, Object> caseInfo = new Map<String, Object>{
                'id' => caseRecord.Id,
                'caseNumber' => caseRecord.CaseNumber,
                'subject' => caseRecord.Subject,
                'description' => caseRecord.Description,
                'priority' => caseRecord.Priority,
                'type' => caseRecord.Type,
                'status' => caseRecord.Status
            };
            
            return caseInfo;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving case information: ' + e.getMessage());
        }
    }
}