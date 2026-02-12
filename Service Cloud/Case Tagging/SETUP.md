# Case Tagging – Post-Deploy Setup

After deploying to your org, complete these steps in **agentforce-demo** (or your target org).

## 1. Prompt Template and Flow (Deployed)

The **Case Tagging Analysis** prompt template and **Case Tagging Analysis Flow** are deployed and wired for AI tags.

- **Prompt template** `Case_Tagging_Analysis`: Flex template with one input (Case SObject). It instructs the model to return only a comma-separated list of short tags (1–3 words) from Subject, Description, Type, Priority, Origin, and Status.
- **Flow**: Gets the Case by **CaseId** → calls **Generate Prompt Response** (Case_Tagging_Analysis) with that record → updates the Case with **Case_Tags__c** = AI response and **Case_Tags_Last_Analyzed_Date__c** = current time.

No manual Prompt Builder or flow-editing steps are required for AI tagging. To change the prompt text, edit **Case_Tagging_Analysis.genAiPromptTemplate-meta.xml** and redeploy.

## 2. Autolaunched Flow (Deployed and Active)

The **Case Tagging Analysis Flow** is deployed and active. It has one input variable **`CaseId`** and:

1. **Get Case** – Gets the Case record by Id.
2. **Generate Case Tags** – Calls the **Case Tagging Analysis** prompt template with that Case; AI returns comma-separated tags.
3. **Update Case With Tags** – Writes the AI response to **Case_Tags__c** and sets **Case_Tags_Last_Analyzed_Date__c**.

## 3. Record-Triggered Flow (Day-Forward Analysis)

So that new cases get tagged automatically when created:

1. **Setup** → **Flows** → **New Flow** → **Record-Triggered Flow**.
2. **Object**: Case. **Trigger**: When a record is **created**.
3. Add an **Action**: **Run Case Tagging Analysis** (the invocable). Set **Case IDs** to a collection containing `{!$Record.Id}` (e.g. use an Assignment to build a list of one ID, then pass it).
4. **Save** and **Activate**.

## 4. Case Tag Trends Dashboard

The **Case Tag Trends** LWC is a modular dashboard with:

- **KPI tiles**: Cases tagged, Unique tags, Time scope
- **Top 10 trending tags**: Clickable list with relative bar length
- **Trends summary**: "Generate summary" shows a short narrative. By default this is an Apex-built summary. For an **AI-generated narrative**, create in Prompt Builder a Flex template with one text input (e.g. `TagSummaryText`), output a 2–4 sentence summary, then create an autolaunched flow that accepts `TagSummaryText`, calls that template, and outputs `SummaryText`. Deploy the flow with API name `Case_Tagging_Trends_Summary_Flow`; the dashboard will then use it when available.
- **All tags**: Colorful pills; click to filter cases below.

Add the **Case Tag Trends** component to a tab or app page so supervisors can view it.

## 5. Add the LWC to the Case Record Page

1. Go to any **Case** record.
2. Click the **gear** (Setup) → **Edit Page**.
3. From the **Custom** components, drag **Case Tags** onto the page.
4. **Save** and **Activate** (if required).

## 6. Optional: Default Historical Scope

- **Setup** → **Custom Metadata Types** → **Case Tagging Config** → **Manage Records** → **Case Tagging Default**.
- **Default Historical Scope (Months)** is set to **2**. Change it if you want a different default for “Run historical analysis” in the LWC.

## 7. Run Historical Analysis (One-Time Backfill)

- Open any Case record that has the **Case Tags** component.
- Choose the **Historical scope (months)** (e.g. 2).
- Click **Run historical analysis**. The batch job will run for cases created in that window; tags will appear as the job processes.

You can also run the batch from **Setup** → **Apex Jobs** by invoking `CaseTaggingBatch.enqueue(2)` in **Execute Anonymous**.

---

## Troubleshooting: “Nothing written to Case Tags”

- **Error in log: “Invalid type: Case_Tagging_Analysis_Flow”**  
  The autolaunched flow is missing or the API name doesn’t match. Apex calls `Flow.Interview.createInterview(flowApiName, ...)`; the flow must exist, be **Active**, and have **API Name** = `Case_Tagging_Analysis_Flow` (or whatever is in **Case Tagging Config** → **Flow API Name**). Create the flow per **Section 2** above and ensure:
  1. Flow type is **Autolaunched** (not Screen or Record-Triggered).
  2. **API Name** in flow properties is exactly `Case_Tagging_Analysis_Flow`.
  3. There is an **input variable** with API name **`CaseId`** and **Available for input** checked.
  4. The flow is **Active** (not just saved).
- After creating/activating the flow, run **Run analysis** again on a Case; the LWC will now show a clear error message if the flow still can’t be found.
