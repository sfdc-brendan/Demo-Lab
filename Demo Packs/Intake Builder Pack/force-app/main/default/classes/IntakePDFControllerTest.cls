@IsTest
private class IntakePDFControllerTest {

    @IsTest
    static void buildData_handlesNullId() {
        PageReference pr = Page.IntakePDF;
        Test.setCurrentPage(pr);
        IntakePDFController ctl = new IntakePDFController();
        ctl.intakeId = null;
        IntakePDFController.PageData data = ctl.getData();
        System.assertNotEquals(null, data.errorMessage);
    }

    @IsTest
    static void buildData_intakeSubmissionPath() {
        Intake_Template__c tpl = new Intake_Template__c(
            Name = 'PDF Test', Status__c = 'Active',
            Default_Locale__c = 'en_US', Version__c = 1,
            PDF_Header__c = '<p>Header</p>'
        );
        insert tpl;

        Intake_Question__c q = new Intake_Question__c(
            Intake_Template__c = tpl.Id,
            DeveloperName__c = 'Customer_Name',
            Question_Text__c = 'Name?',
            Category__c = 'Caller',
            Order__c = 1,
            Answer_Type__c = 'text'
        );
        insert q;

        Intake_Submission__c sub = new Intake_Submission__c(
            Intake_Template__c = tpl.Id,
            Status__c = 'Submitted',
            Answers_JSON__c = '{"Customer_Name":"Eve"}',
            Template_Version__c = 1
        );
        insert sub;

        PageReference pr = Page.IntakePDF;
        pr.getParameters().put('id', sub.Id);
        Test.setCurrentPage(pr);

        Test.startTest();
        IntakePDFController ctl = new IntakePDFController();
        IntakePDFController.PageData data = ctl.getData();
        Test.stopTest();

        System.assertEquals(null, data.errorMessage);
        System.assertEquals('PDF Test', data.templateName);
        System.assertEquals(1, data.sections.size());
        System.assertEquals('Caller', data.sections[0].category);
        System.assertEquals('Eve', data.sections[0].items[0].answer);
    }

    @IsTest
    static void buildData_targetObjectFallback_byActiveTemplate() {
        Intake_Template__c tpl = new Intake_Template__c(
            Name = 'Account PDF', Status__c = 'Active',
            Default_Locale__c = 'en_US', Version__c = 1,
            Target_Object_API_Name__c = 'Account'
        );
        insert tpl;

        Intake_Question__c q = new Intake_Question__c(
            Intake_Template__c = tpl.Id,
            DeveloperName__c = 'Customer_Name',
            Question_Text__c = 'Name?',
            Category__c = 'Caller',
            Order__c = 1,
            Answer_Type__c = 'text',
            Target_Field_API_Name__c = 'Name'
        );
        insert q;

        Account rec = new Account(
            Name = 'Frank'
        );
        insert rec;

        PageReference pr = Page.IntakePDF;
        pr.getParameters().put('id', rec.Id);
        Test.setCurrentPage(pr);

        Test.startTest();
        IntakePDFController ctl = new IntakePDFController();
        IntakePDFController.PageData data = ctl.getData();
        Test.stopTest();

        System.assertEquals(null, data.errorMessage);
        System.assertEquals('Frank', data.sections[0].items[0].answer);
    }
}
