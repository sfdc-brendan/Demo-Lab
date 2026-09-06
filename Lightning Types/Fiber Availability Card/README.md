# Fiber Availability Card

A serviceability check rendered as a card inside an Agentforce conversation, instead of a paragraph the rep has to trust: a status pill, when the build through the neighborhood completed, how many neighbors on the route are already connected, the top speed now available, and the jump from the customer's plan today to the tier worth offering.

Deploys into any org with no prerequisites. The action ships in demo mode, so the card renders correctly the moment it lands.

## What's in the box

| Piece | Name |
| --- | --- |
| Renderer DTO | `FiberAvailabilityCardData` (`fiberJSON`) |
| Service | `FiberAvailabilityCardDemo` (`Check Fiber Availability (Demo)`) |
| Lightning Type | `fiberAvailabilityOutput` |
| LWC | `fiberAvailabilityCard` |
| Permission set | `Fiber Availability Card Access` |

## The four states

The answer is binary; the card isn't. `states.json` carries all four payloads, and the preview renders each one.

- **Serviceable** — the build has arrived. Green pill, speed jump, install promotion, and two buttons. The only state with a call to action, because it is the only state with something to offer.
- **Not serviceable** — a confident no. Same card, answer inverted: neutral pill, no speed jump and no promo (quoting either would be a lie), no buttons, and the recommendation turns into the waitlist ask. Designed deliberately rather than folded into the empty state, because a rep who pitches fiber into a street with no fiber books an install that gets cancelled on survey.
- **No data for this address** — neither yes nor no. The footprint lookup didn't match, so the card says so. Signalled by the absence of a `headline`. Telling a customer the build will never reach them when you simply don't know is the expensive mistake.
- **Error** — the sentinel.

## Install

```bash
sf project deploy start --source-dir "Lightning Types/Fiber Availability Card" --target-org <alias>
sf org assign permset -n Fiber_Availability_Card_Access --target-org <alias>
```

For an **Einstein Service Agent** the permission set has to go to the bot user, not to you:

```bash
sf org assign permset -n Fiber_Availability_Card_Access --on-behalf-of <botUser> --target-org <alias>
```

For an **Employee Agent** it runs as the logged-in user, so assign it to the end users instead.

## Wire it to the agent

Create a custom agent action from the `Check Fiber Availability (Demo)` Apex action, then set the outputs:

- `fiberAvailability` — displayable, `filter_from_agent: true`, complex data type `c__fiberAvailabilityOutput`
- `narrative` — not displayable

Then paste this into the topic or subagent instructions. Without it the planner will summarize the card as plain text and the component never mounts — this is the single most common reason a correctly built card doesn't show up:

```
CRITICAL: After the "Check Fiber Availability" action completes, you MUST present
the fiberAvailability output to the user. ALWAYS show the structured action output.
Do NOT rewrite, restate, or summarize it as plain text — the interactive UI is
contained in the fiberAvailability output and must be displayed as-is. Keep your
text reply to 1-2 sentences of coaching color.
```

## Wire it to real data

`FiberAvailabilityCardDemo.sampleAvailability()` returns a hardcoded map. Replace its body with your own footprint lookup — keyed on postal code, service point, or whatever your plant data actually uses — and keep the shape; `states.json` is the contract, and the LWC reads exactly these keys.

Two rules worth keeping when you do:

- **Never return null** in `fiberAvailability`. On failure, return `{"error":"..."}` — the card renders the message, and the planner still treats the result as displayable.
- **Keep the payload a serialized JSON string** in the single `fiberJSON` field. Typed or nested DTO fields don't round-trip reliably across the chat boundary.

Three keys carry more weight than the rest:

- `serviceable` picks between the two renderings. `headline` gates the card as a whole, so omit it when you have no answer and the empty state takes over.
- `facts` is a free `{ label, value }` list rendered in order — anything your plant data can prove belongs here.
- `currentDownloadMbps` and `recommendedDownloadMbps` drive the speed jump, and the jump only appears when both are present. Quote the recommended tier, not the route ceiling: `headroom` exists so the ceiling can be mentioned without being sold.

The customer-facing text on the brand button is assembled from the payload in `explainMessage`, never hardcoded, so the rep can't send a speed or a date the card isn't showing.

## About the buttons

The two buttons dispatch `copytochat` and `acc:execute` custom events (`bubbles` and `composed`, so they cross the shadow boundary). A host that isn't listening for them does nothing, which is deliberate — the card carries no dependency on the console APIs and therefore deploys anywhere.

To actually send text into a live messaging session, add a service module that calls `sendTextMessage` from `lightning/conversationToolkitApi`, resolving the session id from `lightning/platformWorkspaceApi` rather than from a SOQL fallback. Resolve the target from the tab the rep is looking at: an org can have several active sessions at once, and there is no undo on a message sent to the wrong customer.

## Preview

`preview/` is the gallery simulation — static HTML plus the component's real stylesheet, which is a byte-identical copy of `fiberAvailabilityCard.css`. It isn't deployed and isn't part of the package; it exists so the card can be test-driven in a browser. If you restyle the component, copy the CSS across again.

## Gotchas

- `@api value` must stay a plain property. A getter/setter pair breaks renderer registration and the card silently never mounts.
- The displayable output must never be null — hence the `{"error":"..."}` sentinel.
- Custom events need both `bubbles` and `composed` to reach a host listener.
