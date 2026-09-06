# Line Diagnostics Card

A remote line test rendered as a card inside an Agentforce conversation: the raw readings the test came back with, each one colour-coded and bar-scaled, and above them a plain-language verdict on where the fault actually sits.

That pairing is the whole point. Optical Rx power, ONT sync status, gateway uptime, connected clients and last recorded throughput are five numbers a network engineer reads fluently and a service rep does not. Handing them over as a paragraph makes the rep do the interpreting — and they will get it wrong, or hedge, or escalate a line that is perfectly fine. The card keeps the readings visible so the rep can point at them, and puts the conclusion on top so they don't have to derive it.

Deploys into any org with no prerequisites. The action ships in demo mode, so the card renders correctly the moment it lands.

## What's in the box

| Piece | Name |
| --- | --- |
| Renderer DTO | `LineDiagnosticsCardData` (`diagnosticsJSON`) |
| Service | `LineDiagnosticsCardDemo` (`Run Line Test (Demo)`) |
| Lightning Type | `lineDiagnosticsOutput` |
| LWC | `lineDiagnosticsCard` |
| Permission set | `Line Diagnostics Card Access` |

## The states

Four, and the second one matters more than it looks.

- **Fault found** (`default`) — two failed readings, one marginal, two healthy, and a verdict placing the fault upstream of the home. This is what the demo action returns, and it is the default deliberately: it is the only state that shows the pass, warn and fail treatments side by side.
- **Line healthy** (`all-clear`) — every reading in spec. Not a cosmetic variant of the first one but a different answer to a different question: the line is clean, so whatever the customer is complaining about is somewhere the line test can't see, and the recommendation has to send the rep toward in-home WiFi rather than toward the network.
- **No readings** (`empty`) — the test ran and nothing came back. Rendered neutral grey rather than green, because an unpowered ONT is not a pass.
- **Error** (`error`) — the sentinel, so the card still mounts and can say what went wrong.

## Install

```bash
sf project deploy start --source-dir "Lightning Types/Line Diagnostics Card" --target-org <alias>
sf org assign permset -n Line_Diagnostics_Card_Access --target-org <alias>
```

For an **Einstein Service Agent** the permission set has to go to the bot user, not to you:

```bash
sf org assign permset -n Line_Diagnostics_Card_Access --on-behalf-of <botUser> --target-org <alias>
```

For an **Employee Agent** it runs as the logged-in user, so assign it to the end users instead.

## Wire it to the agent

Create a custom agent action from the `Run Line Test (Demo)` Apex action, then set the outputs:

- `lineDiagnostics` — displayable, `filter_from_agent: true`, complex data type `c__lineDiagnosticsOutput`
- `narrative` — not displayable

Then paste this into the topic or subagent instructions. Without it the planner will summarize the card as plain text and the component never mounts — this is the single most common reason a correctly built card doesn't show up:

```
CRITICAL: After the "Run Line Test" action completes, you MUST present the
lineDiagnostics output to the user. ALWAYS show the structured action output. Do
NOT rewrite, restate, or summarize it as plain text — the interactive UI is
contained in the lineDiagnostics output and must be displayed as-is. Keep your
text reply to 1-2 sentences of coaching color.
```

## Wire it to real data

`LineDiagnosticsCardDemo.sampleDiagnostics()` returns a hardcoded map. Replace its body with your own call into whatever holds the telemetry and keep the shape; `states.json` is the contract, and the LWC reads exactly these keys.

The `metrics` array drives the readings. Each entry is `{ label, value, state, bar }`:

- `value` is a **preformatted string**, not a number — `"-18.2 dBm"`, `"41 days"`, `"No signal"`. Units and rounding are decisions about how the reading should be read, and they belong on the service side where the thresholds live, not in the component.
- `state` is `ok`, `warn` or `fault`, and colours both the value and the bar.
- `bar` is a 0-100 fill. It is a visual scale, not a unit: it lets a reading with no natural percentage (uptime, signal strength) still show relative health. A `fault` bar keeps a visible sliver of red even at 0, so an empty track never reads as "no data".

`verdictState` is `ok` or `fault` and picks the banner colour. Whatever produces `verdict`, `summary` and `recommendation` is doing the interpretation the card exists to deliver — if you replace the demo service with a raw telemetry passthrough and leave those three empty, you have rebuilt the spec sheet.

Two rules worth keeping when you swap the body:

- **Never return null** in `lineDiagnostics`. On failure, return `{"error":"..."}` — the card renders the message, and the planner still treats the result as displayable.
- **Keep the payload a serialized JSON string** in the single `diagnosticsJSON` field. Typed or nested DTO fields don't round-trip reliably across the chat boundary.

## About the buttons

The three buttons dispatch `copytochat` and `acc:execute` custom events (`bubbles` and `composed`, so they cross the shadow boundary). A host that isn't listening for them does nothing, which is deliberate — the card carries no dependency on the console APIs and therefore deploys anywhere. "Re-run test" posts an utterance back into the conversation rather than calling the action itself, so the planner stays in charge of when the test actually runs.

To actually send text into a live messaging session, add a service module that calls `sendTextMessage` from `lightning/conversationToolkitApi`, resolving the session id from `lightning/platformWorkspaceApi` rather than from a SOQL fallback. Resolve the target from the tab the rep is looking at: an org can have several active sessions at once, and there is no undo on a message sent to the wrong customer.

## Gotchas

- `@api value` is a **plain property**. Converting it to a getter/setter pair breaks renderer registration and the card silently never mounts — no error, just an empty bubble.
- The displayable output must never be null. That is what the `{"error":"..."}` sentinel is for.
- Events need both `bubbles` and `composed`; one without the other stops at the shadow boundary.

## Preview

`preview/` is the gallery simulation — static HTML plus the component's real stylesheet, which is a byte-identical copy of `lineDiagnosticsCard.css`. It isn't deployed and isn't part of the package; it exists so the card can be test-driven in a browser. If you restyle the component, copy the CSS across again.
