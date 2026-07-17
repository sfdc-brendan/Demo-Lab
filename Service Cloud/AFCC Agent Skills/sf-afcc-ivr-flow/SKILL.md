---
name: sf-afcc-ivr-flow
description: Build IVR into Omni-Channel flows for native Salesforce Voice in Agentforce Contact Center. Use when adding Play Prompt elements, capturing DTMF input, branching on caller response, controlling speech with SSML, choosing voice profiles/languages, playing media prompts, and ending or controlling recording on a call path.
disable-model-invocation: true
---
# AFCC IVR Flow (Play Prompt, DTMF, SSML)

## Use This Skill When

- You are adding a traditional IVR / DTMF menu to an Omni-Channel flow (e.g., "Press 1 for Billing").
- You need spoken prompts via text-to-speech (voice profile) or prerecorded media.
- You need to capture and branch on caller input (single-digit menus, multi-digit account numbers, or raw capture).
- You need to shape pronunciation, pauses, dates/numbers/currency with SSML and text normalization.

## Prerequisites

- **Enhanced Omni-Channel** enabled in the org (required for IVR features).
- Permission set: **Agentforce Contact Center Admin (Salesforce Voice)**.
- An existing Omni-Channel flow to modify (see `sf-afcc-agentforce-voice-agent` for routing flows).

## Core Workflow

1. **Add a Play Prompt element**
   - Setup > Flows > open your Omni-Channel flow. Click **+** where IVR belongs > **Play Prompt**. Enter name, description, timeout length.
   - In **Prompt**, create the record ID and mark it **available for input**.
2. **Choose the prompt source**
   - **Message** = AI voice profile reads text. **Media** = prerecorded audio (see `sf-afcc-media-management`).
   - For Message: select a **language** + **voice profile** (each language has a default; click **Preview Voice**). See [reference.md](reference.md) for the full profile catalog.
3. **Static vs dynamic message**
   - Static: type the text directly, e.g. "Welcome to Astro Pop".
   - Dynamic: add a **Get Records** element before Play Prompt, then build a **Text Template** resource, e.g. "Hi {!Contact.FirstName}, welcome to Astro Pop". Text templates support SSML.
4. **Drive language/voice via variables (optional)**
   - New Resource > variables (available for input) for language + voice profile; add an **Assignment** before Play Prompt to set them from the values in [reference.md](reference.md); reference the variables in the action.
5. **Capture user response (DTMF)**
   - Response Details > turn on **User Response Settings**. Set **DTMF Response Values**, min/max input length, response **delimiter**, **response timeout**, and **digit timeout**. See DTMF patterns below.
6. **Configure retries**
   - Response Retry > turn on **User Response** > set **Retry Count** and optionally a **Customize retry message** (e.g. "We couldn't quite catch that."). Preview Voice, then Save.
7. **Branch and control the call**
   - Use the Play Prompt **DTMF** and **Retry Count** outputs in a Decision element to route the call.
   - Add **Set Recording and Transcription Behaviour** to disable recording/transcription on sensitive paths, and **End Call** to hang up after deflection/callback.

## DTMF Patterns

Copy the shape that matches your menu — full detail in [reference.md](reference.md).

- **Single-digit menu** ("Press 1 for Billing, 2 for Sales"): set DTMF Response Values to the supported digits; on match the flow continues, else it retries; branch on the DTMF output.
- **Multi-digit validated value** (e.g., 10-digit account number): pass a variable holding the expected value into DTMF Response Value; on match proceed, else turn on **Require Response Retry**; read the value from the DTMF output.
- **Capture without validation**: pass a **null/empty** variable into DTMF Response Value; any input is accepted and forwarded via the DTMF output.

## SSML Quick Reference

Supported tags: `<break>` (all languages) and `<phoneme>` (English only). Also supports text normalization (dates, numbers, currency, acronyms).

```xml
Thank you for calling. <break time="1s"/> Please stay on the line.
```

```xml
<phoneme alphabet="cmu-arpabet" ph="M AE1 D IH0 S AH0 N"> Madison </phoneme>
```

- `<break time="Xs"/>` — pause up to **3 seconds**; accepts fractions like `0.5s`.
- `<phoneme>` — per-word only; use CMU (recommended) or IPA. Create one tag per word (e.g., first and last name separately).

## Guardrails

- Requires **Enhanced Omni-Channel** — IVR behaves incorrectly without it.
- Phoneme tags are **English-only** and **single-word**; don't wrap phrases.
- Keep `<break>` ≤ 3 seconds (longer values are not honored).
- The **DTMF IVR journey is not transcribed or recorded** — the Enhanced Conversation transcript won't include audio prompts played by the Omni-Flow.
- Set **min/max input length** to match your DTMF values (single digit = min/max of 1) or callers can get stuck.

## Deliverables

- A working IVR segment in an Omni-Channel flow with prompts, DTMF capture, retries, and decision branching.
- Voice profile / language selection (or variable-driven) aligned to brand tone.
- SSML/normalization applied where clarity or compliance requires it.

## Additional Resources

- Full voice profile catalog, DTMF workflows, and text-normalization examples: [reference.md](reference.md)
- Media prompts: `sf-afcc-media-management`. Callbacks that build on IVR: `sf-afcc-callbacks`.
- Source docs: Add IVR — https://help.salesforce.com/s/articleView?id=service.afcc_sv_add_ivr.htm&type=5 ; Set DTMF — https://help.salesforce.com/s/articleView?id=service.afcc_sv_set_dtmf.htm&type=5 ; Voice Controls — https://help.salesforce.com/s/articleView?id=service.afcc_sv_voice_controls.htm&type=5
