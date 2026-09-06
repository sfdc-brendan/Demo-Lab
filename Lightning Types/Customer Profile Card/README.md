# Customer Profile Card

The customer, rendered as a card at the top of an Agentforce conversation instead of a paragraph the rep has to parse: name and account in a header, plan and contact detail in a two-column grid, account flags as pills, and health, CSAT and churn risk as three numbers.

**Start here if you are adapting one card.** "Show me who I'm talking to" is the one requirement every industry shares, so this is the pattern most people port first — the payload keys change, the layout usually doesn't.

Deploys into any org with no prerequisites. The action ships in demo mode, so the card renders correctly the moment it lands.

## What's in the box

| Piece | Name |
| --- | --- |
| Renderer DTO | `CustomerProfileCardData` (`profileJSON`) |
| Service | `CustomerProfileCardDemo` (`Get Customer Profile (Demo)`) |
| Lightning Type | `customerProfileOutput` |
| LWC | `customerProfileCard` |
| Permission set | `Customer Profile Card Access` |

## The states

Four, all in `states.json`:

- **`default`** — a resolved customer with the full profile filled in. This is what the demo action returns.
- **`at-risk`** — the same card under a different reading. Churn risk at or above 50 turns that number red, and `alertActive` raises a banner above the grid. Worth looking at before you restyle anything, because it is the only state where the card is trying to change the rep's behaviour.
- **`empty`** — the identifier matched nothing. The card echoes back what it searched for and names the identifier to ask for next, which is more useful to a rep than an apology.
- **`error`** — the `{"error":"..."}` sentinel.

## Install

```bash
sf project deploy start --source-dir "Lightning Types/Customer Profile Card" --target-org <alias>
sf org assign permset -n Customer_Profile_Card_Access --target-org <alias>
```

For an **Einstein Service Agent** the permission set has to go to the bot user, not to you:

```bash
sf org assign permset -n Customer_Profile_Card_Access --on-behalf-of <botUser> --target-org <alias>
```

For an **Employee Agent** it runs as the logged-in user, so assign it to the end users instead.

## Wire it to the agent

Create a custom agent action from the `Get Customer Profile (Demo)` Apex action, then set the outputs:

- `customerProfile` — displayable, `filter_from_agent: true`, complex data type `c__customerProfileOutput`
- `narrative` — not displayable

Then paste this into the topic or subagent instructions. Without it the planner will summarize the card as plain text and the component never mounts — this is the single most common reason a correctly built card doesn't show up:

```
CRITICAL: After the "Get Customer Profile" action completes, you MUST present the
customerProfile output to the user. ALWAYS show the structured action output. Do NOT
rewrite, restate, or summarize it as plain text — the interactive UI is contained
in the customerProfile output and must be displayed as-is. Keep your text reply to
1-2 sentences of coaching color.
```

## Wire it to real data

`CustomerProfileCardDemo.sampleProfile()` returns a hardcoded map. Replace its body with your own query and keep the shape; `states.json` is the contract, and the LWC reads exactly these keys.

Two rules worth keeping when you do:

- **Never return null** in `customerProfile`. On failure, return `{"error":"..."}` — the card renders the message, and the planner still treats the result as displayable.
- **Keep the payload a serialized JSON string** in the single `profileJSON` field. Typed or nested DTO fields don't round-trip reliably across the chat boundary.

Notes on the keys that carry logic rather than text:

- `profileFound` drives which of the three data branches renders. `true` gives the profile, `false` gives the empty state, and anything else falls through to the error box — so set it explicitly.
- `tags` is a plain array of strings. Each one becomes a pill, in order, so keep the list short enough to fit two lines at the panel's width.
- `churnRisk` is compared against `50`, the `CHURN_WARN_AT` constant at the top of the JS. If your churn metric runs on a different scale, change the constant rather than pre-formatting the number.
- `photoUrl` is optional. Supply it and the header renders an image; leave it out and the card derives initials from `customerName`, which is why the preview needs no network image.
- `alertActive` plus `alertMessage` is the generic hook for "the rep needs to know this first" — an open outage, a fraud hold, a payment failure, an expiring authorization. It is deliberately not tied to any one of those.

Whatever your identifier is — account number, policy number, member id, loyalty number — resolve it before this action runs and pass it in as `customerIdentifier`. The demo action ignores the input on purpose so that a misconfigured agent still renders something.

## About the buttons

The three buttons dispatch `copytochat` and `acc:execute` custom events (`bubbles` and `composed`, so they cross the shadow boundary). A host that isn't listening for them does nothing, which is deliberate — the card carries no dependency on the console APIs and therefore deploys anywhere.

To actually send text into a live messaging session, add a service module that calls `sendTextMessage` from `lightning/conversationToolkitApi`, resolving the session id from `lightning/platformWorkspaceApi` rather than from a SOQL fallback. Resolve the target from the tab the rep is looking at: an org can have several active sessions at once, and there is no undo on a message sent to the wrong customer.

## Preview

`preview/` is the gallery simulation — static HTML plus the component's real stylesheet, which is a byte-identical copy of `customerProfileCard.css`. It isn't deployed and isn't part of the package; it exists so the card can be test-driven in a browser. If you restyle the component, copy the CSS across again.
