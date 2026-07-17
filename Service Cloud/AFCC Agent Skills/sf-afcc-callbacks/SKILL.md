---
name: sf-afcc-callbacks
description: Configure callback requests for native Salesforce Voice in Agentforce Contact Center. Use when setting up the Contact Request object with Omni-Channel, creating a callback service channel and queue, building a callback flow that captures a number and creates a Contact Request, and enabling automatic outbound dialing when a rep accepts.
disable-model-invocation: true
---
# AFCC Callbacks

## Use This Skill When

- You want to offer callers a callback instead of holding in queue.
- You need the Contact Request standard object wired into Omni-Channel routing.
- You need a flow that captures/confirms a callback number and creates a Contact Request.
- You need the outbound call to auto-dial when a rep accepts the request.

## Prerequisites

- Working Voice channel and Omni-Channel flows (`sf-afcc-voice-channel-setup`, `sf-afcc-ivr-flow`).
- Callback auto-dial targets must be **US numbers** (other countries not supported by AFCC as of March 2026).

## Core Workflow

1. **Create a Callback service channel**
   - Create a **Call Back** service channel for the **Contact Request** object and add it to your existing **Presence Statuses**.
2. **Create/route a callback queue**
   - Create a new **Callback Queue** for requests, give it a routing configuration, select the **Contact Request** object, and add your users as queue members. (You may reuse existing voice queues, but you must add the Contact Request object to them.)
3. **Decide when to offer a callback (in the flow)**
   - In the Omni-Channel flow, use a **Check Availability** action to see if reps are online.
   - Use a **Play Prompt** to confirm the callback number and/or capture a new number via DTMF (same pattern as the case-number capture in `sf-afcc-ivr-flow`).
4. **Create the Contact Request record**
   - Set **Preferred Phone** to the number to call back (if captured via DTMF, use that new-number variable).
   - **Available Callback Attempts**: up to 5. **Delay Between Callback Attempts**: up to 10,080 minutes (7 days).
   - Set **Is Callback = True** to auto-dial the outbound call after the rep accepts the request in Omni.
5. **Route and confirm**
   - Route the new Contact Request to your callback queue. Use a **Play Prompt** to confirm the callback was created, then an **End Call** action to hang up.
6. **Rep acceptance & auto-dial**
   - The Contact Request routes to the rep's console; on **Accept**, the outbound call auto-dials the Preferred Phone (US number).

## Guardrails

- **Stuck in "dialing"?** A flow triggered on Voice Call creation (e.g., `SDO Service - Voice Call - On Create`) is the usual culprit. Either disable it, or add a condition so it does **not** trigger on outbound calls.
- Alternative workaround: set **Is Callback = False** so no call auto-dials — the rep then uses **Click-to-Call** on the number instead.
- Auto-dial only supports **US numbers**; validate/normalize captured numbers before creating the request.
- Confirm the Contact Request object is added to whichever queue you route to, or requests won't route.

## Deliverables

- A Callback service channel + queue wired to the Contact Request object and presence statuses.
- A callback flow that captures/confirms a number, creates a Contact Request, and ends the call.
- Validated rep-accept auto-dial (or Click-to-Call fallback) for US numbers.

## Additional Resources

- Builds on: `sf-afcc-ivr-flow` (DTMF capture, Play Prompt, End Call), `sf-afcc-media-management`.
- Known issues: `sf-afcc-troubleshooting` (callback auto-dial not connecting).
- Pair with `sf-flow` for flow construction.
