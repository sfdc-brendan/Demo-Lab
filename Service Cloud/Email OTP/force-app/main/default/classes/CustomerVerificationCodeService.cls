/**
 * Generates, sends via Email, and validates one-time verification (OTP)
 * codes for contact call-in verification. Email-only (no SMS).
 */
public with sharing class CustomerVerificationCodeService {
    private static final Integer CODE_LIFETIME_MINUTES = 15;

    /**
     * Generates a 6-digit OTP, saves it, and sends via Email.
     * Does not return the code to the client.
     */
    @AuraEnabled(cacheable=false)
    public static GenerateResult generateAndSendCode(Id contactId, String deliveryMethod) {
        GenerateResult result = new GenerateResult();
        if (contactId == null || String.isBlank(deliveryMethod)) {
            result.success = false;
            result.message = 'Contact and delivery method are required.';
            return result;
        }
        if (!'email'.equals(deliveryMethod.trim().toLowerCase())) {
            result.success = false;
            result.message = 'This package supports Email only.';
            return result;
        }

        Contact c = getContact(contactId);
        if (c == null) {
            result.success = false;
            result.message = 'Contact not found or not accessible.';
            return result;
        }
        if (String.isBlank(c.Email)) {
            result.success = false;
            result.message = 'Contact has no email address.';
            return result;
        }

        try {
            invalidateActiveCodesForContact(contactId);
            String code = generateSixDigitCode();
            Customer_Verification_Code__c vc = createVerificationRecord(contactId, code);
            insert vc;
            sendCodeByEmail(c, code);

            result.success = true;
            result.codeId = vc.Id;
            result.expiresAt = vc.Expires_At__c;
            result.message = 'Verification code sent to customer.';
        } catch (Exception e) {
            result.success = false;
            result.message = 'Failed to send code: ' + e.getMessage();
        }
        return result;
    }

    /**
     * Validates the code the customer recited. Marks the code as Used if valid.
     */
    @AuraEnabled(cacheable=false)
    public static ValidateResult validateCode(Id contactId, String codeEntered) {
        ValidateResult result = new ValidateResult();
        if (contactId == null || String.isBlank(codeEntered)) {
            result.success = false;
            result.message = 'Contact and code are required.';
            return result;
        }
        String normalized = codeEntered.trim();
        if (normalized.length() != 6) {
            result.success = false;
            result.message = 'Code must be 6 digits.';
            return result;
        }

        List<Customer_Verification_Code__c> matches = [
            SELECT Id
            FROM Customer_Verification_Code__c
            WHERE Contact__c = :contactId
              AND Verification_Code__c = :normalized
              AND Status__c = 'Active'
              AND Expires_At__c > :System.now()
            LIMIT 1
        ];
        if (matches.isEmpty()) {
            result.success = false;
            result.message = 'Invalid or expired code.';
            return result;
        }
        matches[0].Status__c = 'Used';
        update matches[0];
        result.success = true;
        result.message = 'Verified.';
        return result;
    }

    /**
     * Returns active code status (e.g. expires at) without exposing the code.
     */
    @AuraEnabled(cacheable=true)
    public static ActiveCodeStatus getActiveCodeStatus(Id contactId) {
        ActiveCodeStatus status = new ActiveCodeStatus();
        if (contactId == null) {
            return status;
        }
        List<Customer_Verification_Code__c> active = [
            SELECT Id, Expires_At__c, Delivery_Method__c
            FROM Customer_Verification_Code__c
            WHERE Contact__c = :contactId
              AND Status__c = 'Active'
              AND Expires_At__c > :System.now()
            ORDER BY Generated_At__c DESC
            LIMIT 1
        ];
        if (!active.isEmpty()) {
            status.hasActiveCode = true;
            status.expiresAt = active[0].Expires_At__c;
            status.deliveryMethod = active[0].Delivery_Method__c;
        }
        return status;
    }

    private static Contact getContact(Id contactId) {
        List<Contact> listContact = [
            SELECT Id, Email, FirstName, Name
            FROM Contact
            WHERE Id = :contactId
            LIMIT 1
        ];
        return listContact.isEmpty() ? null : listContact[0];
    }

    private static void invalidateActiveCodesForContact(Id contactId) {
        List<Customer_Verification_Code__c> toUpdate = [
            SELECT Id FROM Customer_Verification_Code__c
            WHERE Contact__c = :contactId AND Status__c = 'Active'
        ];
        for (Customer_Verification_Code__c v : toUpdate) {
            v.Status__c = 'Expired';
        }
        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }

    private static String generateSixDigitCode() {
        Integer n = Math.mod(Math.abs(Crypto.getRandomInteger()), 900000) + 100000;
        return String.valueOf(n);
    }

    private static Customer_Verification_Code__c createVerificationRecord(Id contactId, String code) {
        Datetime now = System.now();
        Customer_Verification_Code__c vc = new Customer_Verification_Code__c();
        vc.Contact__c = contactId;
        vc.Verification_Code__c = code;
        vc.Generated_At__c = now;
        vc.Expires_At__c = now.addMinutes(CODE_LIFETIME_MINUTES);
        vc.Status__c = 'Active';
        vc.Delivery_Method__c = 'Email';
        vc.Generated_By__c = UserInfo.getUserId();
        return vc;
    }

    private static void sendCodeByEmail(Contact c, String code) {
        Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();
        msg.setToAddresses(new List<String>{ c.Email });
        msg.setSubject('Your verification code');
        msg.setPlainTextBody(
            'Hi ' + (String.isNotBlank(c.FirstName) ? c.FirstName : 'there') +
            ', your verification code is: ' + code + '. It expires in ' + CODE_LIFETIME_MINUTES + ' minutes.'
        );
        msg.setSaveAsActivity(false);
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ msg });
    }

    public class GenerateResult {
        @AuraEnabled public Boolean success;
        @AuraEnabled public Id codeId;
        @AuraEnabled public Datetime expiresAt;
        @AuraEnabled public String message;
    }

    public class ValidateResult {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String message;
    }

    public class ActiveCodeStatus {
        @AuraEnabled public Boolean hasActiveCode = false;
        @AuraEnabled public Datetime expiresAt;
        @AuraEnabled public String deliveryMethod;
    }
}
