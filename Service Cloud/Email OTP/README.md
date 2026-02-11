# Email OTP (Service Cloud)

**One-time verification codes via email** for contact call-in verification. A CSR sends a 6-digit code to the contact’s email; the customer recites the code; the CSR verifies it in the LWC.

This package is **email-only**. SMS is not included due to current Salesforce product limitations (e.g. Messaging Notification / triggered outbound requirements).

---

## What’s included

| Component | Description |
|-----------|-------------|
| **customerVerification** (LWC) | Contact page component: “Send verification code” (email) and “Verify code” (6-digit input). |
| **CustomerVerificationCodeService** (Apex) | Generates code, sends email, validates code; uses `Customer_Verification_Code__c` for storage. |
| **Customer_Verification_Code__c** | Custom object: Contact, Verification_Code__c, Generated_At__c, Expires_At__c, Status__c, Delivery_Method__c, Generated_By__c. |
| **OTP Verification** (Permission Set) | Grants access to the object and Apex class. |

---

## Requirements

- **Salesforce:** Contact object; org must be able to send email (email deliverability, limits).
- **API version:** 65.0 (or compatible).

---

## Deployment

From the **Email OTP** folder:

```bash
sf project deploy start --source-dir "force-app" --target-org <your-org-alias>
```

Or deploy the `force-app` directory using your CI/CD or IDE.

---

## Setup after deploy

1. **Assign permission set**  
   Assign **OTP Verification** to users who need to send and verify codes (e.g. CSRs, System Administrators).

2. **Add the LWC to the Contact page**  
   Edit a Contact record page in Lightning App Builder → add **Customer Verification (OTP)** → Save and activate.

3. **Email**  
   Codes are sent with `Messaging.SingleEmailMessage` (plain text). The Contact must have an **Email** address. To use an email template instead, change `CustomerVerificationCodeService.sendCodeByEmail()`.

---

## Flow diagram

See **[docs/EMAIL_OTP_FLOW_DIAGRAM.md](docs/EMAIL_OTP_FLOW_DIAGRAM.md)** for a step-by-step and Mermaid diagram from LWC → email sent → PIN verified.

---

## Disclaimer

Part of [Demo-Lab](https://github.com/sfdc-brendan/Demo-Lab). For demos only; do not use in production without review and testing.
