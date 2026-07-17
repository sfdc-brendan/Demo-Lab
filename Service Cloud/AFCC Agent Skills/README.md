# Agentforce Contact Center (AFCC) Agent Skills

A suite of 9 Agent Skills for building a comprehensive **Agentforce Contact Center with native Salesforce Voice** — from a dial-ready voice channel to an Agentforce Voice agent, IVR, media, callbacks, Agentforce for Service, and supervisor Command Center — plus a troubleshooting playbook.

Compatible with Cursor, Claude Code, Windsurf, and any AI coding agent with a skills directory.

> Scope: **native Salesforce Voice (Native Telephony)** in Agentforce Contact Center. Not for Salesforce Voice + Amazon Connect / BYOT. Assumes an SDO provisioned Feb 21, 2026 or later on a NA/AMER instance.

---

## Quick Install

Copy and paste into your terminal:

```bash
curl -sSL "https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/Service%20Cloud/AFCC%20Agent%20Skills/install.sh" | bash
```

Or with `wget`:

```bash
wget -qO- "https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/Service%20Cloud/AFCC%20Agent%20Skills/install.sh" | bash
```

The unified installer auto-detects your IDE and installs all `sf-afcc-*` skills.

- Cursor: `~/.cursor/skills/`
- Claude Code: `~/.claude/skills/`
- Windsurf: `~/.windsurf/skills/`

Restart your IDE after installing.

---

## Skills Included

- `sf-afcc-build-orchestrator`: End-to-end build sequence with phase gates; routes you to the right focused skill for each step.
- `sf-afcc-voice-channel-setup`: Permissions, claim a 10DLC number, configure/activate the Voice channel, CLI, recording/transcription, routing config, Voice Call record page.
- `sf-afcc-agentforce-voice-agent`: Connect an Agentforce Service Agent to Telephony, build inbound routing + escalation Omni-Channel flows, tune voice settings, seamless human escalation.
- `sf-afcc-ivr-flow` *(hybrid — patterns + reference)*: Play Prompt IVR, DTMF capture/branching, SSML, voice profiles, media prompts. Quick patterns in SKILL.md, full DTMF/SSML/voice-profile catalog in reference.md.
- `sf-afcc-media-management`: Upload/manage .mp3/.wav media, custom and default media labels for prompts, hold music, and announcements.
- `sf-afcc-callbacks`: Contact Request object + callback queue + callback flow with rep-accept auto-dial.
- `sf-afcc-agentforce-for-service`: Conversation Catch-Up and Work Summaries for Voice (fields, quick action, field mapping).
- `sf-afcc-command-center`: Supervisor Configurations (visible tabs, visible Agentforce agents) and Service reports/dashboards install + workarounds.
- `sf-afcc-troubleshooting`: Known demo gotchas and fixes (connect issues, silent escalation, stuck callbacks, report conflicts, blank summaries).

---

## Suggested Usage

Ask naturally, for example:

- "Plan the end-to-end build for an Agentforce Contact Center voice agent."
- "Set up a native Salesforce Voice channel and get my org dial-ready."
- "Connect my Agentforce Service Agent to Telephony and add an escalation flow."
- "Add a DTMF IVR menu with a welcome prompt and route to billing or sales."
- "Upload hold music and map it to a custom media label."
- "Configure callback requests with auto-dial for US numbers."
- "Turn on Work Summaries for Voice and map the summary fields."
- "Set up the supervisor Command Center and fix the Voice Calls report install."
- "My Agentforce Voice escalation never transfers — how do I fix it?"

---

## Notes

- These skills are primarily **planning/runbook altitude** (Setup click-paths and configuration sequences), matching how native Voice is configured in the UI. Pair them with `sf-flow` (Omni-Channel flows), `sf-ai-agentforce`/`sf-ai-agentscript` (agent authoring), and `sf-deploy`/`sf-data` for execution.
- `sf-afcc-ivr-flow` is **hybrid** (Quick Start patterns in SKILL.md + full DTMF/SSML/voice-profile reference in reference.md).
- When developing the Agentforce agent's planner, topics, and actions, always ground the design in the official GenAI API references: https://developer.salesforce.com/docs/einstein/genai/references/about/about-genai-api.html
- Grounded in official Salesforce Help (Add IVR, Manage Media, Set DTMF, Voice Control Options, Languages & Voice Profiles) and the AFCC Salesforce Voice SDO Setup Guide.
