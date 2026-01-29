# Incident Detection

Real-time incident detection for Service Cloud Cases. This package detects when new Cases may be part of a broader incident, summarizes cases with GenAI, and automatically creates **Case Related Issue** links to group related Cases under an **Incident**.

## What's in this package

- **Flow**: `SDO_Service_Case_RealTime_Incident` — record-triggered on Case create; summarizes the Case, then invokes Apex to evaluate incident patterns.
- **Apex**:
  - **CaseIncidentHandler** — evaluates new Cases against recent open Cases using the **Models API** (GenAI); creates or reuses Incidents and **CaseRelatedIssue** when a pattern is found. Uses in-code prompt building and `aiplatform.ModelsAPI.createGenerations` (no ConnectApi prompt-template call). Falls back to keyword-based analysis if GenAI fails.
  - **CaseIncidentQueueable** — runs the incident evaluation in a callout-allowed context (flow enqueues it so the Models API call succeeds).
  - **CaseBacklogBatch** — batch job that evaluates open Cases (not yet linked to an Incident) using the same Models API path; use for backlog cleanup. Run with `Database.executeBatch(new CaseBacklogBatch(), 1);`
  - **CaseBacklogHandler** — inner class holding the GenAI response DTO (`IncidentResponse`: isMatch, matchedCaseId, incidentTitle, reasoning).
- **GenAI prompt templates**: `Case_Summarizer` (flow), `Case_RealTime_Similarity` (reference only; logic is in-code for Models API).
- **Custom field**: `Case.AI_Summary__c` — stores the GenAI-generated case summary.

## How it works

### Flow: SDO_Service_Case_RealTime_Incident

**Trigger:** Runs when a **Case is created** (record-triggered, after save, async).

1. **Summarize_Case** — Calls the GenAI prompt **Case_Summarizer** with the new Case and writes the result to **Case.AI_Summary__c**.
2. **Update_Case_Summary** — Updates the Case record with that summary.
3. **Detect_Incident_Pattern** — Invokes Apex **CaseIncidentHandler.evaluateCaseForIncident(List&lt;Id&gt; caseIds)** with the new Case Id. The invocable enqueues **CaseIncidentQueueable** so the GenAI call runs in a context that allows callouts (avoids "Failed to generate Einstein LLM generations response" in flow async context).

### Apex: CaseIncidentHandler and CaseIncidentQueueable

The handler compares the new Case to **recent open Cases** in a time window (not a relationship field). It uses two paths:

#### Main path (Models API / GenAI)

- **Implementation:** GenAI is called via **Models API in Apex** (`aiplatform.ModelsAPI.createGenerations`), not ConnectApi prompt templates. The prompt text is built in code (`CaseIncidentHandler` constants) and sent with model `sfdc_ai__DefaultGPT41` (configurable via `MODELS_API_MODEL`). This avoids "Failed to generate Einstein LLM generations response" in flow async and ensures callouts run inside **CaseIncidentQueueable**.
- **Time window:** Last **24 hours**.
- **Recent cases:** Up to **5** other open Cases (`Status != 'Closed'`, `CreatedDate = LAST_N_DAYS:1`, excluding the target, `ORDER BY CreatedDate DESC`, `LIMIT 5`).
- The target Case (preferring `AI_Summary__c`, else Subject + Description) and the recent Cases are sent to the same prompt logic (JSON output: isMatch, matchedCaseId, incidentTitle, reasoning). The model decides whether the new Case shares the **same root cause** with any of them.
- If the model returns a match (`isMatch` + `matchedCaseId`):
  - If the matched Case is already linked to an **Incident** → the new Case is linked to that same Incident via **CaseRelatedIssue**.
  - If not → a new **Incident** is created and both the matched Case and the new Case are linked to it via **CaseRelatedIssue**.
- If the Models API call throws or returns empty, execution falls back to **runFallbackAnalysis**.

#### Fallback path (keyword-based)

- **Time window:** Last **4 hours** (`CreatedDate >= System.now().addHours(-4)`).
- **Recent cases:** All other open Cases in that window (excluding the target).
- **detectIssueType(...)** uses simple keyword rules on Subject + Description + AI_Summary__c (e.g. "checkout"/"payment" → Checkout Service, "login"/"sso"/"auth" → Identity Service, "slow"/"timeout"/"performance" → Performance, "database"/"connection" → Database Connectivity, "vpn"/"network" → Network Infrastructure).
- Only if the target Case gets an issue type and **at least one** recent Case has the **same** issue type does the fallback create or reuse an **Incident** and link the target and all matching recent Cases via **CaseRelatedIssue**.

### Summary

| Aspect | Main path (GenAI) | Fallback (keyword) |
|--------|-------------------|--------------------|
| **When** | Every new Case (after summarize) | Only when GenAI call fails |
| **Time window** | Last **24 hours** | Last **4 hours** |
| **Recent cases** | Up to **5** open Cases | All open Cases in window |
| **How "related" is decided** | AI: same root cause? | Same keyword-derived issue type |
| **Creates Incident / CaseRelatedIssue** | Only if AI returns a match | Only if ≥1 other Case has same issue type |

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

## Backlog batch (CaseBacklogBatch)

For **existing open Cases** that are not yet linked to an Incident, run the batch job so they are evaluated with the same Models API + fallback logic:

```apex
Database.executeBatch(new CaseBacklogBatch(), 1);
```

Use batch size **1** to stay within callout limits. The batch uses **CaseIncidentHandler.generateSimilarityAnalysis** and **CaseBacklogHandler.IncidentResponse**; on failure it runs the same keyword fallback and can post to Chatter when a network context exists.

## Troubleshooting

See **[docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)** for detailed notes on:

- **Models API vs ConnectApi** — Why this package uses `aiplatform.ModelsAPI.createGenerations` and in-code prompt building.
- **Legacy "AI Analysis Failed: Failed to generate Einstein LLM generations response"** — Log analysis, likely causes (license, model, Trust Layer), and fallback behavior.

Quick checks if the main path still fails:

1. **Queueable** — Ensure **CaseIncidentQueueable** is deployed; the flow must enqueue it so callouts are allowed.
2. **Model** — In `CaseIncidentHandler`, `MODELS_API_MODEL` (e.g. `sfdc_ai__DefaultGPT41`) must be a model your org has enabled; adjust if needed.
3. **Einstein / credits** — Setup → Einstein GPT (or Model Settings); confirm the model is enabled and org has capacity.
4. **Debug logs** — Search for `[CaseIncidentHandler]` and `MAIN_PATH FAIL` to see the full exception and stack trace.

## Disclaimer

For demo use only. Do not use in production without review and testing.
