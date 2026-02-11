# Email OTP Flow Diagram

End-to-end process from the LWC on the Contact page through sending the email and verifying the PIN.

---

## Flow diagram (Mermaid)

```mermaid
flowchart TB
    subgraph LWC["1. LWC (Contact page)"]
        A[User selects Email]
        B[User clicks Send]
        A --> B
    end

    subgraph ApexSend["2. Apex: generateAndSendCode(contactId, 'email')"]
        C[Validate contactId & deliveryMethod]
        D[Get Contact record]
        E{Contact.Email present?}
        F[Invalidate any active codes for Contact]
        G[Generate 6-digit code]
        H[Create Customer_Verification_Code__c record]
        I[Insert verification record]
        J[sendCodeByEmail(Contact, code)]
        C --> D --> E
        E -->|No| Fail1[Return error: no email]
        E -->|Yes| F --> G --> H --> I --> J
    end

    subgraph Email["3. Send email"]
        K[Messaging.SingleEmailMessage]
        L[setToAddresses: Contact.Email]
        M[Subject: Your verification code]
        N[Body: Hi FirstName, your code is XXXXXX. Expires in 15 min.]
        O[Messaging.sendEmail]
        K --> L --> M --> N --> O
    end

    subgraph Return["4. Response to LWC"]
        P[Return success, codeId, expiresAt]
        Q[LWC shows toast: Verification code sent]
        P --> Q
    end

    subgraph Customer["5. Customer"]
        R[Customer receives email with 6-digit PIN]
    end

    subgraph Verify["6. CSR verifies PIN"]
        S[Customer recites code to CSR]
        T[CSR enters 6 digits in LWC]
        U[CSR clicks Verify]
        S --> T --> U
    end

    subgraph ApexVerify["7. Apex: validateCode(contactId, codeEntered)"]
        V[Validate contactId & 6-digit code]
        W[Query Customer_Verification_Code__c: Contact, code, Active, not expired]
        X{Match found?}
        Y[Set Status__c = Used, update record]
        Z[Return success: Verified]
        V --> W --> X
        X -->|No| Fail2[Return: Invalid or expired code]
        X -->|Yes| Y --> Z
    end

    subgraph Done["8. Complete"]
        AA[LWC shows toast: Verified]
        AB[Clear code input & active state]
        Z --> AA --> AB
    end

    B --> C
    J --> K
    O --> P
    Q --> R
    R --> S
    U --> V
```

---

## Step-by-step (Email OTP)

| Step | Where | What happens |
|------|--------|----------------|
| **1** | LWC | User chooses **Email**, then clicks **Send**. |
| **2** | Apex | `generateAndSendCode(contactId, 'email')`: validate input → get Contact → ensure Contact has Email → invalidate any active codes → generate 6-digit code → create and insert **Customer_Verification_Code__c** (Active, 15 min expiry) → call `sendCodeByEmail(Contact, code)`. |
| **3** | Apex | `sendCodeByEmail`: build **SingleEmailMessage** (to Contact.Email, subject "Your verification code", body with code and expiry) → **Messaging.sendEmail()**. |
| **4** | LWC | Apex returns success + codeId + expiresAt → LWC shows "Verification code sent to customer" and displays expiry. |
| **5** | Customer | Customer receives the email containing the 6-digit PIN. |
| **6** | LWC | CSR enters the 6 digits the customer recited and clicks **Verify**. |
| **7** | Apex | `validateCode(contactId, codeEntered)`: validate input → find **Customer_Verification_Code__c** for that Contact with matching code, Status = Active, Expires_At__c > now → set Status = **Used**, update record → return "Verified". |
| **8** | LWC | LWC shows "Verified" toast and clears the code field and active-code state. |

---

## Data flow (Email path)

```
LWC (recordId = Contact Id)
    → generateAndSendCode(contactId, "email")
        → Contact (Id, Email, FirstName)
        → Customer_Verification_Code__c (new: Contact__c, Verification_Code__c, Status=Active, Expires_At__c)
        → SingleEmailMessage → Contact.Email
    ← { success, codeId, expiresAt }

… later …

LWC (user entered 6 digits)
    → validateCode(contactId, codeEntered)
        → Customer_Verification_Code__c (lookup: Contact, code, Active, not expired)
        → update Status__c = 'Used'
    ← { success, message: "Verified." }
```

---

## Object used

- **Customer_Verification_Code__c**: stores each generated code (Contact__c, Verification_Code__c, Generated_At__c, Expires_At__c, Status__c = Active | Used | Expired, Delivery_Method__c = Email).

Email OTP does **not** use the OTP_Test flow; only the SMS path uses that flow.
