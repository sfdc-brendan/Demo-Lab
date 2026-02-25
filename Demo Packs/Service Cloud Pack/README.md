# Service Cloud Pack

This pack deploys the full **Service Cloud** set from Demo-Lab plus **Sentiment and Coaching** (LWCs and related metadata for Voice and Messaging).

---

## Contents

| Package | Path | Description |
|---------|------|-------------|
| Incident Detection | `Service Cloud/Incident Detection` | Real-time incident detection for Cases (Flow, Apex, GenAI prompts). |
| Email OTP | `Service Cloud/Email OTP` | Email one-time verification (LWC + Apex). |
| Case Tagging | `Service Cloud/Case Tagging` | AI-powered case tagging (LWCs, flows, GenAI, invocable, batch). |
| Similar Cases | `Service Cloud/Similar Cases` | Similar cases and Knowledge articles on Case (Einstein Models API + SOSL). |
| Unified Phone Controls | `Service Cloud/Unified Phone Controls` | Service Cloud Voice LWC: call controls and timers on Voice Call pages. |
| Sentiment and Coaching | `LWCs/Sentiment and Coaching` | Sentiment and agent coaching for Voice Call and Messaging Session (flows, GenAI, LWCs). |

---

## Prerequisites

- **Incident Detection:** Create custom field **Case.AI_Summary__c** (Long Text Area) before deploying. Service Cloud (Case, Incident, CaseRelatedIssue); Einstein GenAI.
- **Email OTP:** Contact with Email; assign **OTP Verification** permission set; add **Customer Verification (OTP)** LWC to Contact page.
- **Case Tagging:** Service Cloud (Case); Einstein GenAI; API 65.0+. Assign **Case Tagging** permission set; add **Case Tags** and **Case Tag Trends** as needed.
- **Similar Cases:** Case record page; Einstein Models API; API 65.0+. Add **similarCasesAndArticles** to Case record page.
- **Unified Phone Controls:** Service Cloud Voice; add **Unified Phone Controls** to Voice Call record page.
- **Sentiment and Coaching:** Service Cloud Voice and/or Messaging; Voice Call and/or Messaging Session; Einstein/GenAI; custom fields are included.

See the main [Demo-Lab README](https://github.com/sfdc-brendan/Demo-Lab#requirements-by-area) and each package folder for full requirements and setup.

---

## Deploy this pack manually

From the **Demo-Lab repo root**:

```bash
sf project deploy start \
  --source-dir "Service Cloud/Incident Detection" \
  --source-dir "Service Cloud/Email OTP" \
  --source-dir "Service Cloud/Case Tagging" \
  --source-dir "Service Cloud/Similar Cases" \
  --source-dir "Service Cloud/Unified Phone Controls" \
  --source-dir "LWCs/Sentiment and Coaching" \
  --target-org YOUR_ORG_ALIAS
```

Replace `YOUR_ORG_ALIAS` with your org alias or omit to use the default org.
