# Incident Detection – Troubleshooting

## Models API (Apex) vs ConnectApi prompt templates

Incident Detection uses the **Models API with Apex** (`aiplatform.ModelsAPI.createGenerations`) instead of `ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate`. This avoids the "Failed to generate Einstein LLM generations response" (INTERNAL_ERROR) that can occur with prompt templates in some orgs. The same prompt text is built in code (see `CaseIncidentHandler.PROMPT_TEMPLATE`) and sent via `createGenerations` with model `sfdc_ai__DefaultGPT41`. To use a different model, change `CaseIncidentHandler.MODELS_API_MODEL`.

- **Reference**: [Access Models API with Apex](https://developer.salesforce.com/docs/ai/agentforce/guide/access-models-api-with-apex.html)
- **Supported models**: [Supported Models](https://developer.salesforce.com/docs/ai/agentforce/guide/supported-models.html)

---

## (Legacy) "AI Analysis Failed: Failed to generate Einstein LLM generations response"

### Log analysis (apex-07LKj00004BJpv6MAD.log)

- **Queueable is running**: Execution starts with `CaseIncidentQueueable`; the flow correctly enqueues the job and the Queueable runs.
- **Main path is reached**: `[CaseIncidentHandler] MAIN_PATH: Calling Case_RealTime_Similarity` and inputs are built correctly (`Input:targetCase`, `Input:recentCases`).
- **GenAI call fails immediately**: `ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate('Case_RealTime_Similarity', promptInput)` is invoked, then **ConnectApi.ConnectApiException** is thrown with:
  - **inErrorCode**: `"INTERNAL_ERROR"`
  - **inMessage**: `"Failed to generate Einstein LLM generations response"`
- **No callout is made**: `CUMULATIVE_LIMIT_USAGE` shows **Number of callouts: 0 out of 100**. The failure happens inside the platform before any HTTP call to the Einstein/GenAI service. So this is not a timeout or network issue; the request is rejected or fails internally (e.g. license, feature, or model not available).

### Likely causes

1. **Einstein Generative Services not enabled / missing license**  
   The org (e.g. Winter 25 demo) may not have GenAI/Einstein LLM enabled. Internal reports often point to adding a license such as **Einstein Generative Service** or **EinsteinGenerativeServicesAddOn** so the LLM gateway is configured (otherwise you can see backend errors like "HTTP URL must not be null" that surface as INTERNAL_ERROR).

2. **Model not available**  
   The prompt template **Case_RealTime_Similarity** uses `sfdc_ai__DefaultGPT5` (active version). If that model is not provisioned or not allowed in the org, the platform can fail with INTERNAL_ERROR before making a callout.

3. **GenAI / Trust Layer not set up**  
   Einstein GPT or Trust Layer may need to be enabled in Setup (e.g. Setup → Einstein GPT or similar) for the org and for the running user.

### What to check (and what was verified via Salesforce CLI)

| Check | Where / How | Winter 25 (DX) |
|-------|-------------|----------------|
| Einstein / GenAI licenses | Setup → Company Information | **UserLicense**: Einstein Agent, Agentforce Guest User. **PermissionSetLicense**: Einstein Prompt Templates (3110), Agentforce Default (3105), Einstein Agent (51), plus others. |
| Running user PSLs | PermissionSetLicenseAssign for admin258 | **Has**: Einstein Prompt Templates, Agentforce (Default), Einstein Agent, plus several Einstein GPT PSLs. |
| Prompt template and model | **Case_RealTime_Similarity** active version | **Change applied**: active version switched from _2 (Default GPT 5) to _1 (Default GPT 4.1) and deployed. If INTERNAL_ERROR persists, try the other model in Setup → Prompt Templates. |
| Enable GenAI for the org | Setup → Einstein GPT / Generative AI | Complete any one-time activation if required. |

### Fallback behavior

When the main path fails, the handler posts "AI Analysis Failed: ... Attempting Fallback Logic." and runs **runFallbackAnalysis** (keyword-based). In the log, fallback completed successfully: the case was linked to **Database Connectivity Incident** and a FeedItem was posted. So incident detection still works; only the GenAI path is failing in this org.

### References

- [Agentforce and Generative AI Reference](https://developer.salesforce.com/docs/einstein/genai/references/about/about-genai-api.html)
- [Models API Apex Reference](https://developer.salesforce.com/docs/ai/agentforce/references/models-apex-api/models-apex-reference.html)
