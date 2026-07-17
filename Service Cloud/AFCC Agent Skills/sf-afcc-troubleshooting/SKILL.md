---
name: sf-afcc-troubleshooting
description: Diagnose and fix common Agentforce Contact Center native Voice demo issues. Use when calls won't connect or take multiple tries, calls reach a queue but not the agent, Agentforce Voice escalation never transfers, the agent's tone is inconsistent, Omni-Channel shows reconnecting, callbacks stay stuck dialing, voice reports won't install, or work summaries come back blank.
disable-model-invocation: true
---
# AFCC Troubleshooting (Demo Gotchas)

## Use This Skill When

- An AFCC voice demo behaves unexpectedly and you need a known-good workaround fast.
- You are validating a fresh setup and want to pre-empt the common failure modes.
- You are triaging routing, escalation, callback, reporting, or summary issues.

## Core Workflow

1. **Omni-Channel stuck "reconnecting" over statuses**
   - Known issue in Summer pre-release orgs. Use a **Spring** org until SDOs are approved for Summer.
2. **Calls take multiple attempts to connect**
   - Deactivate Voice Call-triggered flows: `SDO_Service_Voice_Call_On_Create`, `SDO_Service_Log_A_Call_from_Voice`, and any flow triggered by Voice Call creation (especially ones that create a case which triggers more flows). Add criteria to bypass when `Case Origin = Phone`. Running the newest Voice Q-Brix generally avoids this.
3. **Call reaches the queue but not the agent**
   - Confirm **queue membership**: Setup > Queues > (e.g., Default Queue Agentforce Contact Center) > Edit > add your user to Selected Members > Save.
4. **Agentforce Voice escalation never transfers to a rep**
   - Verify the **General Voice** routing configuration was updated (see `sf-afcc-voice-channel-setup`).
   - In the Omni-Flow, remove the **Screen Pop** action from the route-to-work path, delete it, and rebuild from scratch (fixes silent escalation errors).
5. **Inbound flow points to the agent but it never picks up**
   - Verify the **channel is fully Active**: Setup > Communication Channels > your Voice channel; if Inactive, assign a routing profile and Activate.
6. **Agentforce Voice tone is inconsistent across calls**
   - Setup > Agentforce Agents > your agent's current version > Connections > Telephony > Voice Settings > set **Stability ≥ 0.80** (default 0.5 causes variability).
7. **Calls route to the queue but never to your Omni-Channel widget (Storm/Solution Central login)**
   - Log in with the org's own credentials instead of the Storm/Solution Central link; try a separate Chrome profile via https://login.salesforce.com/; last resort clear cache/cookies.
8. **Number request failed or stuck for hours**
   - Uncommon in newer orgs — request a new number to resolve; post in `#pop-svc-contactcenter` for visibility.
9. **Conversation Helper / NBAs don't fire in AFCC**
   - The SCV Conversation Helpers didn't port to AFCC SDOs. Build a **Conversation Intelligence** rule to trigger NBAs/flags.
10. **Callback auto-dial stays "dialing" / never connects**
   - Same Voice Call `On Create` flow cause as #2 — disable it or exclude outbound calls. Or set **Is Callback = False** so the rep uses **Click-to-Call**. Auto-dial supports **US numbers** only.
11. **Voice metrics reports (Rep/IVR) won't install**
   - Enable **Skills-Based Routing** (for Rep Metrics). Rename the conflicting **Voice Calls** report type (`SDO_Service_VoiceCalls`) to e.g. "Voice Calls SDO", then re-run the install.
12. **Work Summaries for Voice are blank**
   - Ensure only **one** active Voice Call Summary prompt template. If none is listed, enable Setup > Partner Telephony Setup > **Turn on Voice with Partner Telephony**. Remember summaries need **10+ transcript entries**.

## Guardrails

- Prefer NA/AMER + Spring release orgs for AFCC voice demos.
- Most connect/dialing issues trace back to **Voice Call creation-triggered automations** — check these first.
- Escalation and pickup issues usually trace back to **queue membership**, **routing config**, or an **inactive channel**.
- Report and summary issues have known conflicts (report-type name, duplicate prompt templates) — apply the documented workarounds rather than rebuilding.

## Deliverables

- A diagnosis mapped to the specific known issue with the exact workaround.
- A pre-demo checklist to avoid the top failure modes (org type, deactivated automations, queue membership, active channel, stability ≥ 0.80).

## Additional Resources

- Related skills: `sf-afcc-voice-channel-setup`, `sf-afcc-agentforce-voice-agent`, `sf-afcc-callbacks`, `sf-afcc-command-center`, `sf-afcc-agentforce-for-service`.
- Escalate persistent issues in the `#pop-svc-contactcenter` Slack channel.
