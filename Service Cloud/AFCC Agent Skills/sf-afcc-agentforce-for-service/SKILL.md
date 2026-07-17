---
name: sf-afcc-agentforce-for-service
description: Enable Agentforce for Service AI features on native Voice in Agentforce Contact Center. Use when turning on Conversation Catch-Up for Voice and configuring Work Summaries for Voice — creating summary fields and a quick action, adding Einstein Field Recommendations to the Voice Call page, and mapping summary fields with Voice Call as the response destination.
disable-model-invocation: true
---
# AFCC Agentforce for Service (Voice)

## Use This Skill When

- You want AI Conversation Catch-Up (supervisor/agent) on voice interactions.
- You want automatic Work Summaries (issue, summary, resolution) on Voice Call records.
- You need to map generated summaries to fields and surface them in the console.

## Prerequisites

- Working Voice channel and (ideally) Agentforce Voice agent.
- Run the **Einstein for Service Gen AI Setup** Q-Brix (App Launcher > Q Branch > Demo Wizard) OR manually enable the specific A4S features you need. Wait for success before continuing.
- **Temporary:** enable Setup > Partner Telephony Setup > **Turn on Voice with Partner Telephony** to ensure work summaries generate at call end.

## Core Workflow

1. **Confirm Conversation Catch-Up for Voice**
   - Setup > **Einstein Work Summaries** > **Conversation Catch-Up** tab > confirm **Supervisor** and **Agent** summaries are both **On**.
2. **Create Voice Call summary fields**
   - Setup > Object Manager > **Voice Call** > Fields & Relationships > create three **Text Area (Long)** fields on the Voice Call layout: **Call Issue**, **Call Summary**, **Call Resolution**.
   - (Optional) Reuse existing case fields (Close Summary, Contact Reason, Resolution) and the case "Work Summarization" quick action instead of creating new Voice Call fields.
3. **Create a Voice Summaries quick action**
   - Voice Call > Buttons, Links, and Actions > **New Action** > Type = **Update a Record**, Label = **Voice Summaries** > Save > drag the three new fields onto the action layout > Save.
4. **Add Einstein Field Recommendations to the record page**
   - Object Manager > Voice Call > Lightning Record Pages > **Voice Call - Default** > Edit > drag on **Einstein Field Recommendations** > set its Update Action to **Voice Summaries** > Save.
5. **Map the field mapping in Work Summaries**
   - Setup > Einstein Work Summaries > **Voice Calls** tab > Edit (fields may take a few minutes to display): Response Destination = **Use this Voice Call**; Summary = **Call Summary**; Issue = **Call Issue**; Resolution = **Call Resolution** > Save.
   - Toggle **Voice Call Summaries** to **On**.

## Guardrails

- A conversation needs **at least 10 text-based entries** before a summary or catch-up can generate.
- **Blank summaries** (no text at all)? Check for **duplicate active prompt templates** — only one Voice Call Summary / Summarize Voice Calls template should be active. If none is listed, apply the temporary Partner Telephony enablement above.
- The DTMF IVR journey isn't transcribed, so it won't contribute to the transcript entry count.

## Deliverables

- Conversation Catch-Up enabled for supervisors and agents on voice.
- Work Summaries generating into mapped Voice Call fields, surfaced via Einstein Field Recommendations.
- A validated summary on a call with 10+ transcript entries.

## Additional Resources

- See also the "Generative Service Agentforce - SDO Setup Guide" for A4S across channels.
- Related: `sf-afcc-agentforce-voice-agent`, `sf-afcc-command-center`, `sf-afcc-troubleshooting`.
