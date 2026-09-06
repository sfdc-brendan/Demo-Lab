# Plan Upgrade Card

A plan comparison rendered as a card inside an Agentforce conversation, instead of the agent reading two plans aloud: current and recommended side by side, the recommended tier marked, and the monthly difference stated once as a single number.

The argument for it is plain. Spoken, an upgrade offer asks the customer to hold four figures in their head and do the subtraction themselves. On the card the subtraction is already done, the trade-off is visible at a glance, and the decision is one button — which is why a comparison converts where a paragraph doesn't.

Deploys into any org with no prerequisites. The action ships in demo mode, so the card renders correctly the moment it lands.

## What's in the box

| Piece | Name |
| --- | --- |
| Renderer DTO | `PlanUpgradeCardData` (`upgradeJSON`) |
| Service | `PlanUpgradeCardDemo` (`Get Plan Options (Demo)`) |
| Lightning Type | `planUpgradeOutput` |
| LWC | `planUpgradeCard` |
| Permission set | `Plan Upgrade Card Access` |

## The three states

- **Upgrade available** (`default`) — two columns, the recommended one highlighted, a promo badge when the recommended plan carries one, and the delta strip underneath with the reason.
- **Already on the top plan** (`empty`) — the customer's plan with a line saying it is the fastest available. Worth designing deliberately rather than treating as a failure: "there is nothing faster to sell you" is a real and frequent answer, and a rep who sees it stated can close the topic instead of hunting for an offer that doesn't exist. Omitting `recommended` from the payload is what hides the second column, the delta, and both buttons.
- **Error** (`error`) — the sentinel shape, so the card still mounts and can say what went wrong.

## Install

```bash
sf project deploy start --source-dir "Lightning Types/Plan Upgrade Card" --target-org <alias>
sf org assign permset -n Plan_Upgrade_Card_Access --target-org <alias>
```

For an **Einstein Service Agent** the permission set has to go to the bot user, not to you:

```bash
sf org assign permset -n Plan_Upgrade_Card_Access --on-behalf-of <botUser> --target-org <alias>
```

For an **Employee Agent** it runs as the logged-in user, so assign it to the end users instead.

## Wire it to the agent

Create a custom agent action from the `Get Plan Options (Demo)` Apex action, then set the outputs:

- `planUpgrade` — displayable, `filter_from_agent: true`, complex data type `c__planUpgradeOutput`
- `narrative` — not displayable

Then paste this into the topic or subagent instructions. Without it the planner will summarize the card as plain text and the component never mounts — this is the single most common reason a correctly built card doesn't show up:

```
CRITICAL: After the "Get Plan Options" action completes, you MUST present the
planUpgrade output to the user. ALWAYS show the structured action output. Do NOT
rewrite, restate, or summarize it as plain text — the interactive UI is contained
in the planUpgrade output and must be displayed as-is. Keep your text reply to
1-2 sentences of coaching color.
```

## Wire it to real data

`PlanUpgradeCardDemo.samplePlans()` returns a hardcoded map. Replace its body with your own catalog lookup and keep the shape; `states.json` is the contract, and the LWC reads exactly these keys.

`current` and `recommended` are the same shape: `name`, `downloadMbps`, `uploadMbps`, `monthlyPrice`, `features[]`, and an optional `promo` string that drives the badge. `monthlyIncrease` is the delta you want shown — compute it in Apex rather than letting the component subtract, so the number on the card is the number the billing system will use. `reason` is the one line printed next to it.

To show the top-tier case, omit `recommended` and set `topTier: true` with a `note`.

Two rules worth keeping when you do:

- **Never return null** in `planUpgrade`. On failure, return `{"error":"..."}` — the card renders the message, and the planner still treats the result as displayable.
- **Keep the payload a serialized JSON string** in the single `upgradeJSON` field. Typed or nested DTO fields don't round-trip reliably across the chat boundary.

## About the buttons

Neither button changes anything by itself. They dispatch `acc:execute` and `copytochat` custom events (`bubbles` and `composed`, so they cross the shadow boundary), and a host that isn't listening for them does nothing — which is deliberate, and why the card carries no console-API dependency and deploys anywhere.

**Upgrade plan** asks the agent to run your upgrade action; it never calls one itself. Routing the commitment back through the agent keeps it in the transcript and behind whatever confirmation the topic already enforces. The button is one-shot: it disables itself and reads "Upgrade requested" after the first click, because there is no undo on a plan change and a double-click should not queue a second request.

**Explain the difference** copies a second-person, customer-ready explanation of the upgrade into the reply draft. It stays enabled, since a rep may well copy it again after editing.

If you wire the upgrade to a real write, put the guard in the Apex action rather than in the card: an agent retry that climbs another tier bills a customer for a plan nobody discussed.

## Preview

`preview/` is the gallery simulation — static HTML plus the component's real stylesheet, which is a byte-identical copy of `planUpgradeCard.css`. It isn't deployed and isn't part of the package; it exists so the card can be test-driven in a browser. If you restyle the component, copy the CSS across again.
