# Router Health & Reset Card

A home gateway diagnosed and fixed in one card. Seven readings — status, WAN session, latency, jitter, packet loss, Wi-Fi channel congestion, connected devices — each measured against spec with a colored fill bar, the unit's own self-restart log underneath, a plain-language recommendation, and the remote restart button sitting directly below the evidence that justifies it.

That adjacency is the whole point. A paragraph of latency figures leaves the rep to decide what to do and then go find the action; this card makes the argument and hands over the remedy in the same breath.

Deploys into any org with no prerequisites. The action ships in demo mode, so the card renders correctly the moment it lands.

## What's in the box

| Piece | Name |
| --- | --- |
| Renderer DTO | `RouterResetCardData` (`routerJSON`) |
| Service | `RouterResetCardDemo` (`Get Router Health (Demo)`) |
| Lightning Type | `routerResetOutput` |
| LWC | `routerResetCard` |
| Permission set | `Router Reset Card Access` |

## The four states

- **`default` — degraded gateway.** The main case, and what the demo action returns. Latency and jitter are drifting, packet loss is out of spec, and the Wi-Fi radio is sharing a channel with eleven neighbors, so the card mixes pass, warn, and fail treatments rather than being uniformly alarming. The restart log shows the unit rebooting itself in the small hours every other day — that pattern, not any single reading, is what turns "try a restart" into "restart now and replace it".
- **`healthy` — everything in spec.** A genuinely different rendering, not the same card in green: no warning flag, no restart log, and the restart button is gone entirely, because restarting a healthy gateway drops the customer for ninety seconds and changes nothing. The recommendation says so, and the suggested reply to the customer says so too. Worth keeping, because a card that only ever looks alarming teaches the rep to stop reading it.
- **`empty` — no gateway on the account.** The customer runs their own router, so there is nothing to measure. It says why the check can't see anything rather than reporting that it found nothing, and it stays neutral grey — nothing found is not good news.
- **`error` — the sentinel.** `{"error":"..."}` rendered as a message, so the card still mounts.

## Install

```bash
sf project deploy start --source-dir "Lightning Types/Router Reset Card" --target-org <alias>
sf org assign permset -n Router_Reset_Card_Access --target-org <alias>
```

For an **Einstein Service Agent** the permission set has to go to the bot user, not to you:

```bash
sf org assign permset -n Router_Reset_Card_Access --on-behalf-of <botUser> --target-org <alias>
```

For an **Employee Agent** it runs as the logged-in user, so assign it to the end users instead.

## Wire it to the agent

Create a custom agent action from the `Get Router Health (Demo)` Apex action, then set the outputs:

- `routerHealth` — displayable, `filter_from_agent: true`, complex data type `c__routerResetOutput`
- `narrative` — not displayable

Then paste this into the topic or subagent instructions. Without it the planner will summarize the card as plain text and the component never mounts — this is the single most common reason a correctly built card doesn't show up:

```
CRITICAL: After the "Get Router Health" action completes, you MUST present the
routerHealth output to the user. ALWAYS show the structured action output. Do NOT
rewrite, restate, or summarize it as plain text — the interactive UI is contained
in the routerHealth output and must be displayed as-is. Keep your text reply to
1-2 sentences of coaching color.
```

## Wire it to real data

`RouterResetCardDemo.sampleGateway()` returns a hardcoded map. Replace its body with your own query and keep the shape; `states.json` is the contract, and the LWC reads exactly these keys.

Two rules worth keeping when you do:

- **Never return null** in `routerHealth`. On failure, return `{"error":"..."}` — the card renders the message, and the planner still treats the result as displayable.
- **Keep the payload a serialized JSON string** in the single `routerJSON` field. Typed or nested DTO fields don't round-trip reliably across the chat boundary.

Three things drive the rendering, so map them deliberately:

- `metrics` is `{ label, value, state, bar }`. `state` is `ok`, `warn`, or `fault` and colors both the number and the bar. `bar` is a 0-100 fill, a visual scale rather than a unit — a good reading is a full bar whichever direction the metric actually runs in, so invert it for things like packet loss where lower is better.
- `rebootHistory` is `{ when, reason }` and is meant to be capped. The card lists what you give it and counts the difference against `rebootCount`, so send the five most recent of fourteen rather than all fourteen.
- `canRestart` and `replacementRecommended` decide which buttons exist. Set `canRestart: false` when a restart can't help — during an upstream outage, for instance, where cutting the gateway costs the customer ninety seconds and fixes nothing.

`device.health` fills the pill and accepts `Healthy`, `Degraded`, or `Offline`. `device.imageUrl` is optional; leave it out and the card draws a neutral device placeholder rather than fetching anything.

## About the buttons

The buttons dispatch `copytochat` and `acc:execute` custom events (`bubbles` and `composed`, so they cross the shadow boundary). A host that isn't listening for them does nothing, which is deliberate — the card carries no dependency on the console APIs and therefore deploys anywhere.

**The card never performs the restart.** "Send network restart" posts an utterance and flips to "Restart sent"; the write itself belongs to a separate, confirmed action the agent runs. Keep it that way. A card that reboots a customer's gateway as a side effect of being rendered is a card that will eventually reboot the wrong one, and there is no undo.

To actually send text into a live messaging session, add a service module that calls `sendTextMessage` from `lightning/conversationToolkitApi`, resolving the session id from `lightning/platformWorkspaceApi` rather than from a SOQL fallback. Resolve the target from the tab the rep is looking at: an org can have several active sessions at once, and there is no undo on a message sent to the wrong customer.

## Preview

`preview/` is the gallery simulation — static HTML plus the component's real stylesheet, which is a byte-identical copy of `routerResetCard.css`. It isn't deployed and isn't part of the package; it exists so the card can be test-driven in a browser. If you restyle the component, copy the CSS across again.
