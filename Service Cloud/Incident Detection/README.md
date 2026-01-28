# Incident Detection

Real-time incident detection for Service Cloud Cases. This package detects when new Cases may be part of a broader incident, summarizes cases with GenAI, and automatically creates **Case Related Issue** links to group related Cases under an **Incident**.

## What's in this package

- **Flow**: `SDO_Service_Case_RealTime_Incident` — record-triggered on Case create; summarizes the Case, then invokes Apex to evaluate incident patterns.
- **Apex**: `CaseIncidentHandler` — evaluates new Cases against recent open Cases using a GenAI prompt; creates or reuses Incidents and **CaseRelatedIssue** records when a pattern is found.
- **GenAI prompt templates**: `Case_Summarizer`, `Case_RealTime_Similarity` — used for summarization and similarity analysis.
- **Custom field**: `Case.AI_Summary__c` — stores the GenAI-generated case summary.

## Prerequisites

Before deploying, create the following in your org (or ensure it already exists):

- **Case.AI_Summary__c** — Create a **Long Text Area** custom field on the **Case** object to store the GenAI-generated summary. The flow writes the summarizer output here; the Apex handler reads it for incident analysis.  
  - **Object**: Case  
  - **API Name**: `AI_Summary__c`  
  - **Type**: Long Text Area (or Text Area)  
  - **Visible to**: as needed for your profiles/layouts  

## Requirements

- Salesforce org with Einstein GenAI / Prompt Builder.
- Standard **Case**, **Incident**, and **CaseRelatedIssue** objects (Service Cloud).
- API 59.0+.

## Deployment

Deploy from this folder:

```bash
sf project deploy start --source-dir "Service Cloud/Incident Detection"
```

Or deploy the full repo and use the root `package.xml` as needed.

## Disclaimer

For demo use only. Do not use in production without review and testing.
