# Updates for Demo-Lab main README

When you add the **Email OTP** package to [Demo-Lab](https://github.com/sfdc-brendan/Demo-Lab), update the **root README.md** as follows.

---

## 1. Service Cloud table (new row)

In the **Service Cloud** section, add this row to the table (after Incident Detection):

```markdown
| **[Email OTP](/sfdc-brendan/Demo-Lab/blob/main/Service%20Cloud/Email%20OTP)** | **Email OTP**: one-time 6-digit verification codes sent to the contact’s email. LWC on Contact page (send code + verify); Apex and custom object `Customer_Verification_Code__c`. Email-only; SMS not included. |
```

---

## 2. Quick Reference table

In the **Quick Reference** table, update the **Service Cloud** row from:

```markdown
| **Service Cloud** | Incident Detection (flow + Apex + GenAI prompts) |
```

to:

```markdown
| **Service Cloud** | Incident Detection (flow + Apex + GenAI prompts), Email OTP (LWC + Apex, email verification) |
```

---

## 3. Deployment section

Add this line to the list of deploy examples:

```markdown
sf project deploy start --source-dir "Service Cloud/Email OTP"
```

---

## 4. Requirements (by area)

Add this bullet to **Requirements (by area)**:

```markdown
* **Email OTP** (folder: Service Cloud/Email OTP): Contact with Email; assign **OTP Verification** permission set; add **Customer Verification (OTP)** LWC to Contact page. See package README.
```

---

## 5. Optional: LWCs row in Quick Reference

If you want the LWC name listed in Quick Reference, add `customerVerification` to the LWCs row, e.g.:

```markdown
| **LWCs** | Modern Contact Card (sdo_ContactCard), Incident Dashboard (incidentDashboard), customerVerification (Email OTP), callCoaching, sentimentTracker, messagingSessionAnalytics |
```

Apply these edits in your local Demo-Lab repo after copying the `Service Cloud/Email OTP` folder, then commit and push.
