---
name: sf-ai-agentforce-vision
description: >-
  Give an Agentforce agent the ability to "see" — analyze a customer-uploaded
  photo (device, error screen, status light, fault code) on-platform and act on
  what it shows. Use when building or debugging vision/multimodal Agentforce
  agents, image analysis actions, or when the user mentions photo
  troubleshooting, "agent that can see", image diagnosis, ContentDocument to a
  vision model, or a flex prompt template bound to an image.
---

# Agentforce Vision — building agents that can see

This skill teaches how to give an Agentforce agent working vision: a customer uploads a photo in chat (or on a record), the agent analyzes it with a vision-capable model, and it acts on what it sees — all natively on the Salesforce platform, behind the Einstein Trust Layer.

It is distilled from a working reference implementation (the "Agentforce Vision" package: an image-troubleshooting service agent that diagnoses a photo, grounds a fix in Knowledge, and escalates to a virtual specialist Case).

> **Prerequisite (project rule):** before authoring any prompt template, Apex action, or agent topic, consult the GenAI API reference: https://developer.salesforce.com/docs/einstein/genai/references/about/about-genai-api.html

## The one idea that makes this work

An Agentforce agent **does not receive the chat image directly**, and the **Models API cannot accept images**. The supported path for multimodal analysis is:

> A **flex GenAI prompt template with a `ContentDocument` (file) input**, bound to a vision-capable model, invoked from an **Apex invocable action** via `ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate`.

The agent calls the Apex action; the Apex action resolves the uploaded image (a `ContentDocument`) and passes it to the prompt template as a file input. The model "sees" the file. Everything else (routing, grounding, escalation) is ordinary Agentforce wiring.

There is **no custom-trained vision model** — you use Salesforce's stock multimodal model reached through native platform APIs. All the cleverness is in the wiring.

## Architecture at a glance

```
Customer uploads photo (Enhanced Messaging attachment / Screen Flow / Files)
        │
        ▼
ContentVersion + ContentDocumentLink  (image stored on-platform, linked to the session/record)
        │
        ▼
Agent (Agent Script) ── photo_troubleshooting subagent
        │
        ▼
analyze_image  →  Apex invocable action (AgentforceVisionImageAction)
        │            • resolves the ContentDocument to analyze
        │            • calls the flex prompt template with the file
        ▼
Flex prompt template (ContentDocument input) + vision model
        │
        ▼
Structured output → DIAGNOSIS + KEYWORDS  (parsed by Apex, returned to agent)
        │
        ▼
(optional) ground in Knowledge, escalate to a Case, etc.
```

## Build workflow

Copy this checklist and work top-down. Each step links to a reference file with the full pattern.

```
- [ ] 1. Prompt template: flex template with a ContentDocument input, bound to a vision model
- [ ] 2. Apex action: resolve the uploaded image + call the template, return structured output
- [ ] 3. Agent Script: a subagent/topic that calls the action (with the upload guardrail)
- [ ] 4. Permissions + channel: perm set, and a channel that lets customers attach photos
- [ ] 5. Test: sf agent preview / Apex tests with a mocked prompt runner
```

### Step 1 — Flex prompt template with an image (file) input

Create a **flex** GenAI prompt template (`type = einstein_gpt__flex`) whose input is a `SOBJECT://ContentDocument`, bound to a vision-capable model. Force **structured output** so the Apex can parse it deterministically.

```xml
<inputs>
    <apiName>ImageFile</apiName>
    <definition>SOBJECT://ContentDocument</definition>
    <referenceName>Input:ImageFile</referenceName>
    <required>true</required>
</inputs>
```

The template body references the file (`{!$Input:ImageFile.Id}`) and instructs the model to read on-screen text/error codes and status-light colors, then respond in an exact `DIAGNOSIS:` / `KEYWORDS:` format. Full template anatomy, the `fileDroppingStrategy`, model selection, and the exact prompt text are in [reference-prompt-template.md](reference-prompt-template.md).

### Step 2 — Apex action that resolves the image and calls the template

The invocable action does two things: **find the right `ContentDocument`**, then **call the template with it**.

Resolve the image in priority order (this is what makes it robust across channels):
1. An explicit `ContentDocument` id if the agent passes one.
2. The most recent image `ContentDocument` linked to the conversation/record id.
3. Fallback: the most recent image uploaded org-wide in the last ~10 minutes (the photo the customer just sent when no context id is wired).

Call the template by wrapping the file as a `ConnectApi.WrappedValue` whose value is `{'id' => docId, 'type' => 'ContentDocument'}`:

```apex
ConnectApi.WrappedValue fileValue = new ConnectApi.WrappedValue();
fileValue.value = new Map<String, String>{ 'id' => contentDocumentId, 'type' => 'ContentDocument' };
Map<String, ConnectApi.WrappedValue> params = new Map<String, ConnectApi.WrappedValue>();
params.put('Input:ImageFile', fileValue);

ConnectApi.EinsteinPromptTemplateGenerationsInput input = new ConnectApi.EinsteinPromptTemplateGenerationsInput();
input.inputParams = params;
input.additionalConfig = new ConnectApi.EinsteinLlmAdditionalConfigInput();
input.additionalConfig.applicationName = 'PromptTemplateGenerationsInvocable';

ConnectApi.EinsteinPromptTemplateGenerationsRepresentation response =
    ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate('YourTemplate_ApiName', input);
String raw = response.generations[0].text;
```

The complete class (image resolution, response parsing, and a `PromptRunner` interface seam so tests never make a callout) is in [reference-apex.md](reference-apex.md).

### Step 3 — Agent Script wiring (with the critical guardrail)

Add a subagent/topic that owns photo troubleshooting and exposes the `analyze_image` action targeting your Apex class. Pass the conversation id (e.g. `@variables.RoutableId` from `@MessagingSession.Id`) so the action can locate the image.

**The single most important reasoning instruction:** only call `analyze_image` when the customer has *actually uploaded a photo* in this conversation. If you call it on a text-only description, the "most recent image" fallback may pick up a **stale or unrelated image** and confidently return a wrong diagnosis.

```
CRITICAL: Only call analyze_image if the customer has ACTUALLY uploaded a photo
in this conversation. NEVER call it based only on a text description of a problem.
If they only described the problem, do not call analyze_image — ask them to upload
a photo, or search Knowledge from their described keywords instead.
```

Full subagent, action binding, input/output mapping, and `filter_from_agent` guidance are in [reference-agent-script.md](reference-agent-script.md).

### Step 4 — Permissions and a channel that accepts photos

- **Permission set:** grant Apex class access to the action(s) plus read on any objects/fields they touch. See [reference-setup-deploy.md](reference-setup-deploy.md).
- **Channel:** to let a customer upload a photo in chat, use **Enhanced Messaging / Messaging for In-App and Web (MIAW)** and enable **"Let customers send attachments to agents."** Legacy Chat (v1/Live Agent) does not support the inbound-image-to-agent flow. Non-chat upload paths also work: a Screen Flow File Upload on a Case, or Files on a record.

### Step 5 — Test

```bash
sf agent preview -n <Your_Agent_Api_Name> -o <org> --use-live-actions
```

Upload an image to a record (or attach it in a live chat), then ask the agent to look at it. For Apex, inject a stub `PromptRunner` so tests assert parsing/resolution logic without a live model callout. Details in [reference-setup-deploy.md](reference-setup-deploy.md).

## Design principles that keep vision agents reliable

- **Force structured model output.** A free-text diagnosis is hard to act on. Make the template emit labeled fields (`DIAGNOSIS:`, `KEYWORDS:`) and parse them in Apex, with a fallback to the raw text if the model drifts.
- **Be tolerant of imperfect photos.** Instruct the model to make a genuine best effort on dim/blurry images and only decline when the image is essentially blank or unrelated — otherwise agents refuse too easily.
- **Never let the agent invent the fix.** Vision tells you *what* is wrong; ground the *how-to* in Knowledge (or another system of record) and answer only from returned content. Add a relevance guard so a loose keyword match doesn't surface an unrelated article. See [reference-apex.md](reference-apex.md).
- **Guard the trigger.** Only analyze when a photo was really uploaded (Step 3).
- **Keep plumbing out of the model.** Mark internal outputs (ids, raw keywords, success flags) with `filter_from_agent: True` so the reasoning model only sees what it needs.
- **Everything stays on-platform.** The image is a Salesforce File; the model call runs through `ConnectApi.EinsteinLLM` behind the Trust Layer. No external service is required.

## Reference files

- [reference-prompt-template.md](reference-prompt-template.md) — flex template anatomy, file input, model selection, structured-output prompt.
- [reference-apex.md](reference-apex.md) — the orchestrator action, image resolution, ConnectApi call, testable runner seam, and Knowledge grounding + relevance guard.
- [reference-agent-script.md](reference-agent-script.md) — subagent/topic wiring, action binding, guardrails, `filter_from_agent`.
- [reference-setup-deploy.md](reference-setup-deploy.md) — permission set, MIAW channel + attachments, deploy/publish/activate, testing, troubleshooting.
