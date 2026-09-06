# Outage Status Card

A network outage rendered as a status card inside an Agentforce conversation, instead of a paragraph the customer has to parse: a live indicator, restoration ETA, a progress rail through the repair stages, cause and crew detail, and impact.

Deploys into any org with no prerequisites. The action ships in demo mode, so the card renders correctly the moment it lands.

## What's in the box

| Piece | Name |
| --- | --- |
| Renderer DTO | `OutageStatusCardData` (`outageJSON`) |
| Service | `OutageStatusCardDemo` (`Get Outage Status (Demo)`) |
| Lightning Type | `outageStatusOutput` |
| LWC | `outageStatusCard` |
| Permission set | `Outage Status Card Access` |

## Install

```bash
sf project deploy start --source-dir "Lightning Types/Outage Status Card" --target-org <alias>
sf org assign permset -n Outage_Status_Card_Access --target-org <alias>
```

For an **Einstein Service Agent** the permission set has to go to the bot user, not to you:

```bash
sf org assign permset -n Outage_Status_Card_Access --on-behalf-of <botUser> --target-org <alias>
```

For an **Employee Agent** it runs as the logged-in user, so assign it to the end users instead.

## Wire it to the agent

Create a custom agent action from the `Get Outage Status (Demo)` Apex action, then set the outputs:

- `outageStatus` — displayable, `filter_from_agent: true`, complex data type `c__outageStatusOutput`
- `narrative` — not displayable

Then paste this into the topic or subagent instructions. Without it the planner will summarize the card as plain text and the component never mounts — this is the single most common reason a correctly built card doesn't show up:

```
CRITICAL: After the "Get Outage Status" action completes, you MUST present the
outageStatus output to the user. ALWAYS show the structured action output. Do NOT
rewrite, restate, or summarize it as plain text — the interactive UI is contained
in the outageStatus output and must be displayed as-is. Keep your text reply to
1-2 sentences of coaching color.
```

## Wire it to real data

`OutageStatusCardDemo.sampleOutage()` returns a hardcoded map. Replace its body with your own query and keep the shape; `states.json` is the contract, and the LWC reads exactly these keys.

Two rules worth keeping when you do:

- **Never return null** in `outageStatus`. On failure, return `{"error":"..."}` — the card renders the message, and the planner still treats the result as displayable.
- **Keep the payload a serialized JSON string** in the single `outageJSON` field. Typed or nested DTO fields don't round-trip reliably across the chat boundary.

The `steps` array drives the progress rail. Each entry is `{ label, state }` where `state` is `done`, `current`, or `pending`.

## About the buttons

The three buttons dispatch `copytochat` and `acc:execute` custom events (`bubbles` and `composed`, so they cross the shadow boundary). A host that isn't listening for them does nothing, which is deliberate — the card carries no dependency on the console APIs and therefore deploys anywhere.

To actually send text into a live messaging session, add a service module that calls `sendTextMessage` from `lightning/conversationToolkitApi`, resolving the session id from `lightning/platformWorkspaceApi` rather than from a SOQL fallback. Resolve the target from the tab the rep is looking at: an org can have several active sessions at once, and there is no undo on a message sent to the wrong customer.

## Preview

`preview/` is the gallery simulation — static HTML plus the component's real stylesheet, which is a byte-identical copy of `outageStatusCard.css`. It isn't deployed and isn't part of the package; it exists so the card can be test-driven in a browser. If you restyle the component, copy the CSS across again.
