---
name: sf-afcc-voice-channel-setup
description: Stand up the native Salesforce Voice channel in Agentforce Contact Center. Use when assigning AFCC permissions, claiming a phone number, configuring and activating the Voice channel, setting caller line identification, enabling recording/transcription, tuning the Voice routing configuration, and building the Voice Call record page.
disable-model-invocation: true
---
# AFCC Voice Channel Setup

## Use This Skill When

- You are configuring native Salesforce Voice (Native Telephony) in an SDO or customer org for the first time.
- You need to claim a 10DLC number and wire it to an Omni-Channel queue.
- You need the org to be "dial-ready" before adding Agentforce Voice or IVR.
- You need to enable call recording/transcription and the After Conversation Work experience.

## Prerequisites

- SDO provisioned Feb 21, 2026 or later, on a NA/AMER instance.
- Licenses present: `NativeNumber10DLCGroupA`, `InboundVoiceCredits`, `OutboundVoiceCredits`, `SalesforceVoice`.

## Core Workflow

1. **Assign AFCC permission sets**
   - Setup > Users > (your admin user) > Permission Set Assignments > Edit Assignments.
   - Add: **Agentforce Contact Center Admin (Salesforce Voice)**, **Agentforce Contact Center Rep (Salesforce Voice)**, **Agentforce Contact Center Supervisor (Salesforce Voice)**. (Often already in the "SERVICE - CCAAS PERMISSIONS" perm set group.)
   - Save (accept the community settings popup), then **refresh the browser** so Communication Channels options appear.
2. **Claim a phone number**
   - Setup > Communication Channels > **New Number** > Step 1: Country (US/CA) + Number Type (10-Digit Long Code) > Next.
   - Step 2: search an Area Code, select **exactly one** number > Next. Step 3: Review > **Finish**.
   - On the **Numbers** tab, refresh until **Status = Live**; if not Live, open the number and click **Refresh Number Status**. Save the number as a contact on your demo phone.
3. **Configure the Voice channel**
   - Communication Channels > **New Channel** > Start > select **Voice** > Next.
   - Select the claimed **Phone Number**; Call Routing Type = **Omni-Queue** (switch to Omni-Flow later for Agentforce Voice); Queue = **General Voice** > Next > **Done**. The channel appears under **All Channels** (activate later).
4. **Set Caller Line Identification (outbound)**
   - Numbers tab > open your number > **Edit** > check **Set number as the default Caller Line Identification (CLI) for outgoing calls** > Save > Confirm.
5. **Enable call recording & transcription**
   - Setup > **Call Recording and Transcription** > toggle both **Active** > Save.
6. **Tune the Voice routing configuration**
   - Setup > Omni-Channel > Routing Configurations > Edit next to **Voice** > Routing Model = **Least Active** (Most Available also OK) > Save.
7. **Build the Voice Call record page**
   - Temporary enabler: Setup > Partner Telephony Setup > toggle **Turn on Voice with Partner Telephony** (needed to access the Phone component).
   - Enable After Conversation Work: Setup > Presence Configurations > Edit **SDO - Service Presence Configuration** > enable **After Conversation Work Time**, set values > Save.
   - Object Manager > Voice Call > Lightning Record Pages > **Voice Call - Default** > Edit. Drag on **After Conversation Work** and any of: Enhanced Conversation, Phone, Call Recording Player, Highlights, Adjust NBA. (Empty preview is fine — no Voice Call records yet.) Save.
8. **Activate the channel**
   - Setup > Communication Channels > dropdown next to Voice > Edit > optionally rename > Save > **Activate**.
9. **Checkpoint test**
   - Associate your mobile number to a demo Contact (e.g., Lauren Bailey). Open **Service - Console**, accept the recording consent, allow mic access, set Omni-Channel to **Phone - Available**, and place a test call.

## Guardrails

- Only claim **one** number to avoid credit/routing confusion.
- Activation is easy to forget and fails silently — verify the channel shows **Active** before testing.
- If the call routes to a queue but never reaches you, confirm your user is a **member of the queue** (e.g., Default Queue Agentforce Contact Center / General Voice).
- If it takes multiple calls to connect, deactivate Voice Call `On Create` automations (see `sf-afcc-troubleshooting`).
- Add **Voice Calls** to the Service Console navigation for quick access during setup.

## Deliverables

- A live, activated native Voice channel bound to a claimed 10DLC number and the General Voice queue.
- Recording/transcription enabled and a configured Voice Call - Default record page.
- A validated inbound test call reaching an available rep.

## Additional Resources

- Next: `sf-afcc-agentforce-voice-agent` (add the AI voice agent), `sf-afcc-ivr-flow`, `sf-afcc-command-center`.
- Troubleshooting: `sf-afcc-troubleshooting`. Orchestration: `sf-afcc-build-orchestrator`.
