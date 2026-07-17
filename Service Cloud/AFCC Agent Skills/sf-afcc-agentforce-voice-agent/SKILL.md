---
name: sf-afcc-agentforce-voice-agent
description: Configure an Agentforce Voice agent on native Salesforce Voice in Agentforce Contact Center. Use when connecting an Agentforce Service Agent to Telephony, building the inbound routing and escalation Omni-Channel flows, tuning voice settings (voice profile, stability, pronunciation), and enabling seamless escalation to a human rep with full context.
disable-model-invocation: true
---
# AFCC Agentforce Voice Agent

## Use This Skill When

- You have a dial-ready native Voice channel and want an Agentforce Voice agent to handle inbound calls.
- You need to connect an Agentforce Service Agent to the Telephony channel and route calls to it.
- You need an escalation path from the AI agent to a human rep on the General Voice queue.
- You need to tune the spoken experience (voice profile, stability, pronunciation, key-term prompting).

## Prerequisites

- Voice channel live and activated (`sf-afcc-voice-channel-setup`).
- **Data 360 (Data Cloud) enabled** — required for Agentforce Voice. Enable OAuth username-password flows, then run the Data 360 setup automation or manual setup (~60 min to activate).
- **Enhanced Omni-Channel** enabled (required for Omni-Channel flows / IVR).

## Core Workflow

1. **Create the Agentforce Service Agent**
   - Fast path: App Launcher > Q Branch > Demo Wizard > Agentforce Demos > run the **Service Cloud | Agentforce Service Agent** Q-Brix (preconfigured for Account/Case/Order management), OR
   - From scratch: Setup > Agentforce Agents > toggle Agentforce On > **+ New Agent** > Agentforce Service Agent; configure details, data source, Topics, Instructions, and Actions.
2. **Connect the agent to Telephony**
   - Setup > Agentforce Agents > your agent > dropdown > **Open in Builder** > **Connections**.
   - If no Telephony connection exists, **New** > select **Telephony** > **Add to Agent**.
   - **Activate** the agent (Ignore & Activate) so it appears in the routing flow you build next.
3. **Build the inbound routing flow**
   - Setup > Flows > New Flow > **Omni-Channel Flow**.
   - Add a **Route Work** element under the Start element with: Label `Route to Agentforce Voice Agent`; API Name `Route_to_Agentforce_Voice_Agent`; Record ID Variable = new Text variable `recordId` (Available for Input); Service Channel = **Phone**; Route To = **Agentforce Service Agent**; select your agent; Fallback Queue = **General Voice**.
   - Save flow: Label `Agentforce Voice - Route to Voice Agent`, API `Agentforce_Voice_Route_to_Voice_Agent`. **Activate**.
4. **Associate the inbound flow to the Voice channel**
   - Setup > Communication Channels > dropdown next to Voice > Edit > Omni-Channel Routing > Edit: Routing Type = **Omni-Flow**; Flow Definition = **Agentforce Voice - Route to Voice Agent**; Fallback Queue = **General Voice** > Save.
5. **Build the escalation flow**
   - New Omni-Channel Flow > Route Work element: Label `Agentforce Voice - Escalate to Queue`; API `Agentforce_Voice_Escalate_to_Queue`; Record ID Variable = `recordId` (Text, Available for Input); Service Channel = **Phone**; Queue ID = **General Voice**. Save (same label/API) > **Activate**.
6. **Complete Telephony voice configuration**
   - Open the agent in Builder > Connections > **Telephony**. The Inbound Routing Flow is auto-populated (no action).
   - **Deactivate** the agent to edit Telephony config.
   - Escalations: Escalation Flow = **Agentforce Voice - Escalate to Queue**; Escalation Message e.g. "One moment while I transfer you to an expert for further assistance." Save.
   - **Voice Settings > Basic:** select a Voice (use **Voice Preview**). **Advanced:** tune Speed, Similarity, Stability (**Stability ≥ 0.80** recommended for a consistent voice); set Pronunciation and Key-term Prompting as desired. Save.
   - **Activate** the agent (Ignore & Activate).

## Guardrails

- When designing the agent's Topics, Instructions, and Actions, always ground the design in the official GenAI API references before building (see Additional Resources).
- Set **Stability to at least 0.80** — the 0.5 default causes inconsistent tone across calls.
- Native AFCC uses **one Voice Call record** for both the AI and rep legs (re-queued on transfer); recordings split into AI-leg and rep-leg (use next/previous recording). DTMF IVR audio is not transcribed or recorded.
- If escalation never transfers, verify the General Voice **routing configuration** and try removing/rebuilding the Screen Pop action in the route-to-work flow (see `sf-afcc-troubleshooting`).
- The agent must be **Active** to appear in routing flows, but must be **Deactivated** to edit Telephony escalation/voice settings — follow the activate/deactivate sequence above.

## Deliverables

- An active Agentforce Voice agent connected to Telephony with inbound routing and escalation flows.
- Tuned voice settings (profile, stability ≥ 0.80, pronunciation).
- A validated call: AI handles the call, escalates to a rep with full context on a single Voice Call record.

## Additional Resources

- REQUIRED before building agent Topics/Actions/Instructions: GenAI API — https://developer.salesforce.com/docs/einstein/genai/references/about/about-genai-api.html
- Add IVR/media: `sf-afcc-ivr-flow`, `sf-afcc-media-management`. Summaries: `sf-afcc-agentforce-for-service`. Monitoring: `sf-afcc-command-center`.
- Pair with `sf-flow` for Omni-Channel flow construction and `sf-ai-agentforce`/`sf-ai-agentscript` for agent authoring.
