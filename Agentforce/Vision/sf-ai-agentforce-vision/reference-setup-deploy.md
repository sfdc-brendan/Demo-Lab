# Setup, deploy, channel, and testing reference

Everything around the vision pieces: prerequisites, permissions, the channel that lets a customer attach a photo, deployment order, and how to test and troubleshoot.

## Org prerequisites

You cannot turn these on via metadata deploy — confirm them first:

- **Agentforce enabled** with an **Agentforce (Einstein) Service Agent** license and a provisioned agent user (Profile = `Einstein Agent User`).
- **Einstein generative AI / Prompt Builder** enabled, with access to a **vision-capable model** (the prompt template's `primaryModel`).
- **Einstein / Trust Layer terms accepted**, plus any required data spaces.
- **Salesforce CLI (`sf`) v2** authenticated to the org with metadata-deploy rights.
- A **connection channel** for customers to chat and upload photos (see below) — configured separately from the agent metadata.
- If grounding in Knowledge: **Lightning Knowledge enabled** and a Knowledge-enabled user to publish articles.

## Permission set

Grant the agent (running) user access to everything the actions touch. `with sharing` Apex means missing object/field access silently breaks resolution or grounding.

```xml
<PermissionSet xmlns="http://soap.sforce.com/2006/04/metadata">
    <label>Agentforce Vision</label>
    <hasActivationRequired>false</hasActivationRequired>
    <classAccesses>
        <apexClass>AgentforceVisionImageAction</apexClass>
        <enabled>true</enabled>
    </classAccesses>
    <!-- add classAccesses for any companion actions (grounding, escalation) -->
    <!-- add objectPermissions / fieldPermissions for anything those actions read -->
</PermissionSet>
```

Notes:
- The action reads `ContentDocumentLink` / `ContentVersion` — these follow standard file sharing, so the agent user must be able to see the uploaded file (files uploaded in the session it owns are visible).
- Add read on any grounding object (e.g. `Knowledge__kav` + your body field) and CRUD on any escalation object (e.g. `Case`).

## Channel: let customers attach photos

To get an image *from* a customer *to* the agent, use **Enhanced Messaging / Messaging for In-App and Web (MIAW)** — the "v2" experience that supports inbound end-user attachments. Legacy Chat (v1 / Live Agent) does **not** offer inbound-image-to-agent.

1. Create a **Messaging for In-App and Web** channel and route it to your agent.
2. Channel > Edit > enable **"Let customers send attachments to agents."**
3. Create an **Embedded Service Deployment**. When asked for the type (Web / Mobile / **Custom Client**), pick **Custom Client** to get a pasteable bootstrap snippet for your own page.
4. Add your page's origin to the deployment's **allowed/trusted origins**, then **Publish**.

The action does not depend on the runtime handing the image to the model — it resolves the uploaded file itself (linked to the `MessagingSession`, or most-recent-upload). That makes photo analysis work reliably regardless of a given org's native multimodal-attachment support.

Non-chat upload paths that also work: a **Screen Flow** File Upload component on a Case/record, or **Files** attached to a related record.

## Deploy / publish / activate order

The compiled planner/bot is regenerated on publish, so you deploy source then publish the authoring bundle:

```bash
# 1. Deploy metadata (Apex, prompt template, perm set, fields, agent bundle)
sf project deploy start -d force-app -o <org>

# 2. Assign the permission set to the agent user
sf org assign permset -n Agentforce_Vision -o <org>

# 3. (If grounding) seed/publish Knowledge articles

# 4. Publish the Agent Script authoring bundle (regenerates the planner)
sf agent publish authoring-bundle -n <Agent_Api_Name> -o <org> --skip-retrieve

# 5. Activate
sf agent activate -n <Agent_Api_Name> -o <org>
```

If the agent bundle carries a placeholder agent user (e.g. `__AGENTFORCE_SERVICE_AGENT_USER__`), replace it with a real active agent user before publishing:

```bash
sf data query -o <org> -q "SELECT Username FROM User WHERE Profile.Name = 'Einstein Agent User' AND IsActive = true"
```

## Test it

```bash
sf agent preview -n <Agent_Api_Name> -o <org> --use-live-actions
```

Upload an image to a record (or attach it in a live chat), then ask the agent to look at it. Expect a plain-language diagnosis followed by grounded steps. For Apex logic, use the `PromptRunner` stub pattern (see [reference-apex.md](reference-apex.md)) so unit tests never make a model callout.

## Troubleshooting

| Symptom | Likely cause / fix |
| --- | --- |
| "No image was found" | Photo wasn't uploaded before analysis, or no context id wired and it's outside the fallback window. Upload first, then ask within ~10 min; pass the conversation id. |
| Model returns a blind/generic answer | `primaryModel` isn't vision-capable, or the file param key doesn't match the template `referenceName`. Repoint the model in Prompt Builder; verify `Input:ImageFile`. |
| Agent analyzes the wrong photo | Missing the upload guardrail (Step 3) or no conversation id passed, so it grabbed a stale image. Add the `CRITICAL:` instruction and pass `recordId`. |
| `sf agent publish` fails | Agentforce/Service Agent license off, or the bound agent user is missing/inactive. |
| Deploy fails on Knowledge field/object | Lightning Knowledge not enabled. |
| Model errors on invoke | Template points at a model the org lacks; change it in Prompt Builder. |
| Agent invents steps | Grounding action returned nothing but the reasoning didn't fall back safely — instruct it to only answer from returned content and offer escalation. |

## Rebranding / reuse

This pattern is domain-agnostic. To repurpose for a new use case: change the prompt template persona and structured fields, swap the grounding source (Knowledge → Assets, Products, work orders...), and adjust the subagent instructions. The image-resolution + `ConnectApi` call in the Apex action stays the same.
