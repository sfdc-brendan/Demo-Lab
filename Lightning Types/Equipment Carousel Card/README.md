# Equipment Carousel Card

The devices installed at a service address, rendered as a horizontally scrolling strip inside an Agentforce conversation instead of a list the rep has to read out: a health pill per device, serial number, install date, the engineering note behind the reading, and a replacement button on the devices that genuinely warrant one.

Deploys into any org with no prerequisites. The action ships in demo mode, so the card renders correctly the moment it lands.

## What's in the box

| Piece | Name |
| --- | --- |
| Renderer DTO | `EquipmentCardData` (`equipmentJSON`) |
| Service | `EquipmentCardDemo` (`Get Equipment (Demo)`) |
| Lightning Type | `equipmentOutput` |
| LWC | `equipmentCard` |
| Permission set | `Equipment Card Access` |

## The states

| State | What it shows |
| --- | --- |
| `default` | Four devices at one address — one offline, one degraded, two healthy — so every health treatment is visible in a single screenshot. Only the degraded gateway offers a replacement. |
| `empty` | Nothing registered against the account. Styled as a neutral fact, not a failure: a self-install or a brand-new order lands here, and there is nothing for the rep to fix. |
| `error` | The `{ "error": "..." }` sentinel, rendered as a message rather than a blank card. |

## Install

```bash
sf project deploy start --source-dir "Lightning Types/Equipment Carousel Card" --target-org <alias>
sf org assign permset -n Equipment_Card_Access --target-org <alias>
```

For an **Einstein Service Agent** the permission set has to go to the bot user, not to you:

```bash
sf org assign permset -n Equipment_Card_Access --on-behalf-of <botUser> --target-org <alias>
```

For an **Employee Agent** it runs as the logged-in user, so assign it to the end users instead.

## Wire it to the agent

Create a custom agent action from the `Get Equipment (Demo)` Apex action, then set the outputs:

- `equipment` — displayable, `filter_from_agent: true`, complex data type `c__equipmentOutput`
- `narrative` — not displayable

Then paste this into the topic or subagent instructions. Without it the planner will summarize the card as plain text and the component never mounts — this is the single most common reason a correctly built card doesn't show up:

```
CRITICAL: After the "Get Equipment" action completes, you MUST present the
equipment output to the user. ALWAYS show the structured action output. Do NOT
rewrite, restate, or summarize it as plain text — the interactive UI is contained
in the equipment output and must be displayed as-is. Keep your text reply to
1-2 sentences of coaching color.
```

## Wire it to real data

`EquipmentCardDemo.sampleEquipment()` returns a hardcoded list. Replace its body with your own query — `Asset` filtered to the customer's contact is the obvious source — and keep the shape; `states.json` is the contract, and the LWC reads exactly these keys.

Each entry in `devices` is:

| Key | Notes |
| --- | --- |
| `name`, `deviceType` | `deviceType` also drives the placeholder tile: its initials are what the tile draws. |
| `serialNumber` | Shown in monospace, and quoted verbatim in the replacement request. |
| `installedOn` | Pre-formatted for display. Format it in Apex; the card does not parse dates. |
| `health` | `Healthy`, `Degraded`, or `Offline`. Anything else falls through to unstyled — add a `.sr-health_*` rule if you extend the set. |
| `note` | Optional. Omit it and the note block disappears. |
| `rmaEligible` | Whether this device gets a replacement button. |

Two rules worth keeping when you do:

- **Never return null** in `equipment`. On failure, return `{"error":"..."}` — the card renders the message, and the planner still treats the result as displayable.
- **Keep the payload a serialized JSON string** in the single `equipmentJSON` field. Typed or nested DTO fields don't round-trip reliably across the chat boundary, which matters here because the payload is an array.

One piece of judgement is worth carrying over from the original: set `rmaEligible` only for a genuine hardware fault. A device reading `Offline` is usually a symptom of an upstream outage, and offering to replace it sends the rep down an expensive wrong path. In the sample data that is exactly the difference between the degraded gateway and the offline fiber terminal.

## About the carousel

The strip is native `overflow-x` with `scroll-snap-type: x mandatory` — no JS, no touch library. It works by trackpad, touch, and arrow keys, and the tile width is set so a sliver of the next device always shows, which is what tells the rep the list keeps going. Tiles cap at `18rem`, so a wider host surface gains visible tiles rather than inflating them.

There is no product photography. Each tile draws a CSS placeholder with the device type's initials, so the bundle carries no static resources, deploys into any org, and looks identical everywhere.

## About the buttons

The per-device **Request replacement** button and the card-level **Explain to customer** button dispatch `acc:execute` and `copytochat` custom events (`bubbles` and `composed`, so they cross the shadow boundary). A host that isn't listening does nothing, which is deliberate — the card carries no dependency on the console APIs and therefore deploys anywhere.

Note what the replacement button does **not** do: it does not write. It pushes a request — device name and serial included — back into the conversation and lets the planner's own RMA action handle it, behind whatever confirmation that action requires. A card that creates `ReturnOrder` records on click would need object permissions, would fail to deploy into a bare org, and would give the rep no confirmation step.

To actually send text into a live messaging session, add a service module that calls `sendTextMessage` from `lightning/conversationToolkitApi`, resolving the session id from `lightning/platformWorkspaceApi` rather than from a SOQL fallback. Resolve the target from the tab the rep is looking at: an org can have several active sessions at once, and there is no undo on a message sent to the wrong customer.

## Gotchas

- `@api value` is a **plain property**. Converting it to a getter/setter pair breaks renderer registration and the card silently never mounts.
- The displayable output must never be null — hence the sentinel in the `catch`.
- Events need both `bubbles` and `composed` to escape the shadow boundary.

## Preview

`preview/` is the gallery simulation — static HTML plus the component's real stylesheet, which is a byte-identical copy of `equipmentCard.css`. It isn't deployed and isn't part of the package; it exists so the card can be test-driven in a browser. The strip scrolls for real there, because the overflow comes from the component's own CSS. If you restyle the component, copy the CSS across again.
