---
name: sf-afcc-build-orchestrator
description: End-to-end build orchestrator for Agentforce Contact Center (AFCC) with native Salesforce Voice. Use when standing up a comprehensive AFCC voice agent from scratch — sequencing licenses, the Voice channel, Agentforce Voice, Agentforce for Service, Command Center, and advanced IVR/callbacks — and to decide which focused AFCC skill to hand off to next.
disable-model-invocation: true
---
# AFCC Build Orchestrator

## Use This Skill When

- You are building a full Agentforce Contact Center with native Salesforce Voice and need the correct end-to-end sequence.
- You need to decide which focused AFCC skill applies to the current step (channel, voice agent, IVR, media, callbacks, Agentforce for Service, Command Center).
- You are validating readiness at each phase gate before moving on (dial-ready, agent-ready, escalation-ready, supervisor-ready).
- You want a single map of prerequisites, dependencies, and demo checkpoints for AFCC.

## Prerequisites

- A Salesforce demo org (SDO) provisioned **Feb 21, 2026 or later** on a **NA/AMER** instance. Use a **Spring** release org until SDOs are approved for Summer.
- Licenses enabled: `NativeNumber10DLCGroupA`, `InboundVoiceCredits`, `OutboundVoiceCredits`, `SalesforceVoice`.
- Admin user assigned the AFCC permission sets (see `sf-afcc-voice-channel-setup`).
- This scope is **native Voice only** — do not combine with Salesforce Voice + Amazon Connect / BYOT in the same org.

## Core Workflow

1. **Phase 1 — Voice channel foundation** → hand off to `sf-afcc-voice-channel-setup`
   - Assign permission sets, claim a phone number, configure and activate the Voice channel, set CLI, enable recording/transcription, set routing config, build the Voice Call record page.
   - **Gate:** place a live inbound test call that routes to your agent in the Service Console.
2. **Phase 2 — Data 360 enablement** → prerequisite for Agentforce Voice
   - Enable OAuth username-password flows, then run the Data 360 setup automation (Q-Brix) or manual Data Cloud setup. Activation takes ~60 minutes.
   - **Gate:** Data Cloud setup reports success.
3. **Phase 3 — Agentforce Voice agent** → hand off to `sf-afcc-agentforce-voice-agent`
   - Create/enable the Agentforce Service Agent, connect Telephony, build the inbound routing flow and escalation flow, tune voice settings, activate.
   - **Gate:** an inbound call is handled by Agentforce Voice and escalates cleanly to a human rep with full context (single Voice Call record, split recordings).
4. **Phase 4 — IVR & media (optional/advanced)** → hand off to `sf-afcc-ivr-flow` and `sf-afcc-media-management`
   - Add Play Prompt IVR (DTMF, SSML, voice profiles), manage audio media, set recording/transcription behavior, add End Call.
   - **Gate:** DTMF menu branches correctly; prompts play with the intended voice/media.
5. **Phase 5 — Callbacks (advanced)** → hand off to `sf-afcc-callbacks`
   - Configure the Contact Request object, callback queue, and callback flow with auto-dial.
   - **Gate:** a requested callback routes to a rep and auto-dials a US number.
6. **Phase 6 — Agentforce for Service** → hand off to `sf-afcc-agentforce-for-service`
   - Enable Conversation Catch-Up and Work Summaries for Voice; map summary fields.
   - **Gate:** a call with 10+ transcript entries generates a summary.
7. **Phase 7 — Command Center (Supervisor)** → hand off to `sf-afcc-command-center`
   - Configure Supervisor tabs, visible Agentforce agents, and Service reports/dashboards.
   - **Gate:** supervisor can monitor queues, reps, and Agentforce Voice sessions.
8. **Throughout — Troubleshooting** → consult `sf-afcc-troubleshooting`
   - Apply known-issue workarounds (connection retries, silent escalation errors, stuck callbacks, report install conflicts, blank work summaries).

## Guardrails

- Follow the phase order — Agentforce Voice depends on Data 360, and escalation depends on an activated channel and correct queue routing config.
- Consider the Q-Brix automation ("Salesforce Voice | SDO Q Brix") to get dial-ready fast, but do a manual pass at least once so you can credibly answer "how hard is this to set up?"
- Deactivate Voice Call `On Create` automations that create cases/log calls before relying on outbound/callback flows — they commonly cause stuck "dialing" and multi-call connect issues.
- Keep one Voice Call record mental model: native AFCC re-queues the same record on escalation (unlike Amazon/BYOT which creates two).

## Deliverables

- A phased AFCC build plan with per-phase gates and the specific skill to execute each phase.
- A prerequisite and dependency checklist (org age/instance, licenses, permissions, Data 360).
- A demo-readiness checklist mapped to capabilities to show (softphone, transcription, escalation, summaries, supervisor).

## Additional Resources

- Focused skills: `sf-afcc-voice-channel-setup`, `sf-afcc-agentforce-voice-agent`, `sf-afcc-ivr-flow`, `sf-afcc-media-management`, `sf-afcc-callbacks`, `sf-afcc-agentforce-for-service`, `sf-afcc-command-center`, `sf-afcc-troubleshooting`.
- Pair with `sf-flow` (Omni-Channel flows), `sf-data`/`sf-deploy` for execution, and the Service Cloud `sf-service-*` skills for adjacent config.
- Agentforce agent design must reference the official GenAI API docs: https://developer.salesforce.com/docs/einstein/genai/references/about/about-genai-api.html
