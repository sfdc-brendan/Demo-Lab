/**
 * Tests for CustomerVerificationCodeService (Email OTP only).
 */
@IsTest
private class CustomerVerificationCodeServiceTest {
    private static final String TEST_EMAIL = 'testcontact@example.com';

    @TestSetup
    static void setup() {
        Contact c = new Contact(
            LastName = 'VerifyTest',
            Email = TEST_EMAIL,
            FirstName = 'Test'
        );
        insert c;
    }

    @IsTest
    static void generateAndSendCode_email_success() {
        Contact c = [SELECT Id FROM Contact WHERE Email = :TEST_EMAIL LIMIT 1];
        Test.startTest();
        CustomerVerificationCodeService.GenerateResult result =
            CustomerVerificationCodeService.generateAndSendCode(c.Id, 'Email');
        Test.stopTest();
        System.assert(result.success, 'Expected success: ' + result.message);
        System.assert(result.codeId != null);
        System.assert(result.expiresAt != null);
        List<Customer_Verification_Code__c> codes = [
            SELECT Id, Verification_Code__c, Status__c, Delivery_Method__c
            FROM Customer_Verification_Code__c
            WHERE Contact__c = :c.Id
        ];
        System.assertEquals(1, codes.size());
        System.assertEquals('Active', codes[0].Status__c);
        System.assertEquals('Email', codes[0].Delivery_Method__c);
    }

    @IsTest
    static void generateAndSendCode_smsRejected() {
        Contact c = [SELECT Id FROM Contact WHERE Email = :TEST_EMAIL LIMIT 1];
        Test.startTest();
        CustomerVerificationCodeService.GenerateResult result =
            CustomerVerificationCodeService.generateAndSendCode(c.Id, 'SMS');
        Test.stopTest();
        System.assert(!result.success);
        System.assert(result.message != null);
    }

    @IsTest
    static void generateAndSendCode_invalidContact() {
        Test.startTest();
        CustomerVerificationCodeService.GenerateResult result =
            CustomerVerificationCodeService.generateAndSendCode(null, 'Email');
        Test.stopTest();
        System.assert(!result.success);
        System.assert(result.message != null);
    }

    @IsTest
    static void generateAndSendCode_contactNoEmail() {
        Contact c = [SELECT Id FROM Contact WHERE Email = :TEST_EMAIL LIMIT 1];
        c.Email = null;
        update c;
        Test.startTest();
        CustomerVerificationCodeService.GenerateResult result =
            CustomerVerificationCodeService.generateAndSendCode(c.Id, 'Email');
        Test.stopTest();
        System.assert(!result.success);
        System.assert(result.message.contains('email'));
    }

    @IsTest
    static void validateCode_success() {
        Contact c = [SELECT Id FROM Contact WHERE Email = :TEST_EMAIL LIMIT 1];
        Customer_Verification_Code__c vc = new Customer_Verification_Code__c(
            Contact__c = c.Id,
            Verification_Code__c = '123456',
            Generated_At__c = System.now(),
            Expires_At__c = System.now().addMinutes(15),
            Status__c = 'Active',
            Delivery_Method__c = 'Email'
        );
        insert vc;
        Test.startTest();
        CustomerVerificationCodeService.ValidateResult result =
            CustomerVerificationCodeService.validateCode(c.Id, '123456');
        Test.stopTest();
        System.assert(result.success);
        System.assertEquals('Used', [SELECT Status__c FROM Customer_Verification_Code__c WHERE Id = :vc.Id].Status__c);
    }

    @IsTest
    static void validateCode_wrongCode() {
        Contact c = [SELECT Id FROM Contact WHERE Email = :TEST_EMAIL LIMIT 1];
        Test.startTest();
        CustomerVerificationCodeService.ValidateResult result =
            CustomerVerificationCodeService.validateCode(c.Id, '999999');
        Test.stopTest();
        System.assert(!result.success);
        System.assert(result.message.contains('Invalid') || result.message.contains('expired'));
    }

    @IsTest
    static void validateCode_expired() {
        Contact c = [SELECT Id FROM Contact WHERE Email = :TEST_EMAIL LIMIT 1];
        Customer_Verification_Code__c vc = new Customer_Verification_Code__c(
            Contact__c = c.Id,
            Verification_Code__c = '123456',
            Generated_At__c = System.now().addMinutes(-20),
            Expires_At__c = System.now().addMinutes(-5),
            Status__c = 'Active',
            Delivery_Method__c = 'Email'
        );
        insert vc;
        Test.startTest();
        CustomerVerificationCodeService.ValidateResult result =
            CustomerVerificationCodeService.validateCode(c.Id, '123456');
        Test.stopTest();
        System.assert(!result.success);
    }

    @IsTest
    static void validateCode_blankCode() {
        Contact c = [SELECT Id FROM Contact WHERE Email = :TEST_EMAIL LIMIT 1];
        Test.startTest();
        CustomerVerificationCodeService.ValidateResult result =
            CustomerVerificationCodeService.validateCode(c.Id, '');
        Test.stopTest();
        System.assert(!result.success);
    }

    @IsTest
    static void getActiveCodeStatus_hasCode() {
        Contact c = [SELECT Id FROM Contact WHERE Email = :TEST_EMAIL LIMIT 1];
        Customer_Verification_Code__c vc = new Customer_Verification_Code__c(
            Contact__c = c.Id,
            Verification_Code__c = '123456',
            Generated_At__c = System.now(),
            Expires_At__c = System.now().addMinutes(15),
            Status__c = 'Active',
            Delivery_Method__c = 'Email'
        );
        insert vc;
        Test.startTest();
        CustomerVerificationCodeService.ActiveCodeStatus status =
            CustomerVerificationCodeService.getActiveCodeStatus(c.Id);
        Test.stopTest();
        System.assert(status.hasActiveCode);
        System.assert(status.expiresAt != null);
        System.assertEquals('Email', status.deliveryMethod);
    }

    @IsTest
    static void getActiveCodeStatus_noCode() {
        Contact c = [SELECT Id FROM Contact WHERE Email = :TEST_EMAIL LIMIT 1];
        Test.startTest();
        CustomerVerificationCodeService.ActiveCodeStatus status =
            CustomerVerificationCodeService.getActiveCodeStatus(c.Id);
        Test.stopTest();
        System.assert(!status.hasActiveCode);
    }

    @IsTest
    static void generateAndSendCode_invalidatesPrevious() {
        Contact c = [SELECT Id FROM Contact WHERE Email = :TEST_EMAIL LIMIT 1];
        CustomerVerificationCodeService.generateAndSendCode(c.Id, 'Email');
        Customer_Verification_Code__c first = [
            SELECT Id, Status__c FROM Customer_Verification_Code__c
            WHERE Contact__c = :c.Id
            ORDER BY Generated_At__c DESC
            LIMIT 1
        ];
        System.assertEquals('Active', first.Status__c);
        Test.startTest();
        CustomerVerificationCodeService.generateAndSendCode(c.Id, 'Email');
        Test.stopTest();
        List<Customer_Verification_Code__c> allCodes = [
            SELECT Id, Status__c FROM Customer_Verification_Code__c
            WHERE Contact__c = :c.Id
            ORDER BY Generated_At__c ASC
        ];
        System.assertEquals(2, allCodes.size());
        System.assertEquals('Expired', allCodes[0].Status__c);
        System.assertEquals('Active', allCodes[1].Status__c);
    }
}
