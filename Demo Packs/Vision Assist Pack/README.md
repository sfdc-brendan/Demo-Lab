# Vision Assist Pack

This pack deploys **Vision Assist** — a Case / Messaging Session record-page LWC that "watches" a conversation for a customer-uploaded screenshot, analyzes the error with a vision-capable model, and hands the customer service rep a **diagnosis plus grounded troubleshooting steps** — entirely on the Salesforce platform, behind the Einstein Trust Layer.

It's the rep-facing (human-in-the-loop) counterpart to an autonomous vision agent: instead of the agent answering the customer, the rep gets an assist panel that reads the screenshot the customer sent (in a chat, or attached to an inbound email on a Case) and tells them what's wrong and how to fix it.

---

## Contents

| Component | Type | Description |
|-----------|------|-------------|
| visionAgentAssist | LWC | Case / Messaging Session record-page panel. Polls the conversation for the latest screenshot(s), shows a selectable thumbnail gallery when several arrive, and displays the diagnosis, detected-keyword pills, grounded troubleshooting steps (with copy-to-clipboard), and related articles. Container-query responsive (two-column in a wide region, stacked in a narrow rail). App Builder properties: **Auto-analyze new screenshots** and **Scan interval (seconds)**. |
| VisionAgentAssistController | Apex | Detects screenshots on the conversation and runs the analyze → ground pipeline. `getConversationScreenshots` returns recent images (files linked to the record, plus a Case's inbound-email attachments with a signature/logo size filter); `analyzeScreenshot` calls the vision action and grounds the fix in Knowledge. |
| VisionAgentAssistControllerTest | Apex | Unit tests for screenshot resolution (direct + email attachment), the size filter, step parsing, and the analyze/ground flow (prompt runner + Knowledge search are stubbed — no live callout). |
| AgentforceVisionImageAction | Apex | Resolves the image `ContentDocument` and calls the flex prompt template via `ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate`, returning a parsed diagnosis + keywords. Mockable `PromptRunner` seam. |
| AgentforceVisionImageActionTest | Apex | Unit tests for image resolution and structured-output parsing (stubbed runner). |
| VisionArticleRelevance | Apex | Relevance guard that re-ranks Knowledge search candidates by distinct meaningful term matches so a loose keyword collision can't surface the wrong article's steps. |
| VisionArticleRelevanceTest | Apex | Unit tests for term extraction and relevance selection. |
| AgentforceVision_ImageDiagnosis | GenAI Prompt Template | Flex template with a `ContentDocument` (file) input, bound to a vision-capable model. Reads on-screen text/error codes and returns an exact `DIAGNOSIS:` / `KEYWORDS:` format. |
| FAQ_Answer__c | Custom Field (`Knowledge__kav`) | Rich-text field that holds the troubleshooting answer the grounded steps are parsed from. |
| Vision_Assist | Permission Set | Grants Apex class access to the controller + dependencies and read on `Knowledge__kav` / `FAQ_Answer__c`. |

---

## Prerequisites

- **Einstein Generative AI / Prompt Builder** enabled, with access to a **vision-capable model**. The template targets `sfdc_ai__DefaultGPT55`; model names and availability vary by org, edition, and region — you may need to point the template at a different vision model in Prompt Builder.
- **Einstein / Trust Layer terms accepted**, and any required data spaces configured where applicable.
- **Lightning Knowledge** enabled (required for the `Knowledge__kav` object and the `FAQ_Answer__c` field to deploy). Publish at least one article per problem so the grounded steps have something to match — without a matching article the panel still shows the diagnosis and prompts the rep to escalate.
- **Service Cloud (Case)** and/or **Enhanced Messaging (Messaging Session)** for the record pages you'll host the component on.
  - To pick up a screenshot from a **chat**, use **Messaging for In-App & Web (MIAW)** with "Let customers send attachments" enabled.
  - To pick up a screenshot from an **inbound email on a Case**, use **Email-to-Case** (attachments arrive as Files linked to the `EmailMessage`; the component resolves them from the Case).
- The running (rep) user needs standard read access to Cases, Email Messages, and Files in their org.

---

## Deploy this pack

This pack is self-contained with its own `sfdx-project.json`. From the **Demo Packs** directory:

```bash
cd "Vision Assist Pack"
sf project deploy start --source-dir force-app --target-org YOUR_ORG_ALIAS
```

Or use the installer script from the Demo Packs root:

```bash
./scripts/install-pack.sh
```

---

## Post-deploy setup

1. **Assign the permission set** — `sf org assign permset --name Vision_Assist` (or **Setup → Permission Sets → Vision Assist → Manage Assignments**).
2. **Verify the prompt template** — **Setup → Einstein → Prompt Builder** and confirm **Agentforce Vision - Image Diagnosis** is **Published/Active** and bound to a vision-capable model. If it shows as Draft or the model is unavailable in your org, open it and re-save/activate against a model you have.
3. **Add the component to a record page** — Open a **Case** (or **Messaging Session**) → **Setup (gear) → Edit Page**, drag **Vision Assist** onto the Lightning record page. Configure:
   - **Auto-analyze new screenshots** — analyze automatically on detection, or leave off so the rep clicks **Analyze**.
   - **Scan interval (seconds)** — how often to poll the conversation for a new screenshot (minimum 3).
4. **Publish a matching Knowledge article** (optional but recommended for the demo) — create/publish a `Knowledge__kav` article whose Title/Summary matches the problem and whose `FAQ_Answer__c` contains the fix steps (a numbered or bulleted list works best).
5. **Test it** — Open a Case with an inbound email that has an image attachment (or a Messaging Session with a customer-sent photo). The panel detects the screenshot; click **Analyze screenshot** to see the diagnosis, keyword pills, and grounded steps.

---

## How it works

| Step | What happens |
|------|--------------|
| **Detect** | `getConversationScreenshots` finds recent images on the conversation: files linked directly to the record, plus (on a Case) attachments on related inbound emails — those link to the `EmailMessage`, not the Case, and tiny signature/logo graphics are filtered out by size. Newest first, de-duplicated. |
| **Select** | The panel defaults to the newest screenshot and, when several arrived, shows a thumbnail gallery so the rep can analyze any one of them (each result is cached per image). |
| **Analyze** | `analyzeScreenshot` sends the chosen image to the **Agentforce Vision - Image Diagnosis** flex prompt template (the supported path for multimodal input — the Models API can't accept images) and parses a `DIAGNOSIS:` + `KEYWORDS:` response. |
| **Ground** | The keywords drive a Knowledge search; `VisionArticleRelevance` drops loose keyword collisions, and the top article's `FAQ_Answer__c` is parsed into ordered troubleshooting steps. Nothing is invented — if no article is a confident match, the panel shows the diagnosis and suggests escalating. |

---

## Notes

- **On-platform & Trust Layer.** The screenshot is a Salesforce File; the model call runs through `ConnectApi.EinsteinLLM`. No external service is required.
- **Grounded, not hallucinated.** Vision tells the rep *what* is wrong; the *how-to* steps come only from Knowledge, with a relevance guard so a single shared word can't surface the wrong article.
- **Prompt template model & identifier.** The template ships **Published** with an `activeVersionIdentifier`; if your org rejects the identifier on deploy, or the target model isn't available, open the template in Prompt Builder and re-save/activate against a vision-capable model.
- **Fictional demo content.** Any company/product references in the prompt text are fictional and safe to edit for your own demo narrative.
- **Demos and labs only** — not an official Salesforce product; review and test before any use.
