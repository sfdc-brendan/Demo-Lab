# Appointment Slots Card

Technician visit windows rendered as a pick list inside an Agentforce conversation, instead of times the customer has to read back to you: one row per open window across the next three business days, a badge on the soonest slot, and a confirm button that names the choice before anything is booked.

Deploys into any org with no prerequisites. The action ships in demo mode, so the card renders correctly the moment it lands.

## What's in the box

| Piece | Name |
| --- | --- |
| Renderer DTO | `AppointmentSlotsCardData` (`slotsJSON`) |
| Service | `AppointmentSlotsCardDemo` (`Get Appointment Slots (Demo)`) |
| Lightning Type | `appointmentSlotsOutput` |
| LWC | `appointmentSlotsCard` |
| Permission set | `Appointment Slots Card Access` |

## The three states

- **Windows available** — five open windows over three business days. Selecting one highlights the row and rewrites the confirm button to `Book Monday afternoon`, so the commitment is legible before it is made. The button is disabled until something is selected.
- **Fully booked** — no windows in range. This gets its own neutral panel with a next step in it, deliberately *not* the red error treatment; a rep who sees an error box assumes the system is down when what they need is the next thing to say.
- **Error** — the `{"error":"..."}` sentinel, rendered as a message rather than an empty card.

## Install

```bash
sf project deploy start --source-dir "Lightning Types/Appointment Slots Card" --target-org <alias>
sf org assign permset -n Appointment_Slots_Card_Access --target-org <alias>
```

For an **Einstein Service Agent** the permission set has to go to the bot user, not to you:

```bash
sf org assign permset -n Appointment_Slots_Card_Access --on-behalf-of <botUser> --target-org <alias>
```

For an **Employee Agent** it runs as the logged-in user, so assign it to the end users instead.

## Wire it to the agent

Create a custom agent action from the `Get Appointment Slots (Demo)` Apex action, then set the outputs:

- `appointmentSlots` — displayable, `filter_from_agent: true`, complex data type `c__appointmentSlotsOutput`
- `narrative` — not displayable

Then paste this into the topic or subagent instructions. Without it the planner will summarize the card as plain text and the component never mounts — this is the single most common reason a correctly built card doesn't show up:

```
CRITICAL: After the "Get Appointment Slots" action completes, you MUST present
the appointmentSlots output to the user. ALWAYS show the structured action
output. Do NOT rewrite, restate, or summarize it as plain text — the interactive
UI is contained in the appointmentSlots output and must be displayed as-is. Keep
your text reply to 1-2 sentences of coaching color.
```

## Wire it to real data

`AppointmentSlotsCardDemo.sampleSlots()` returns a hardcoded map. Replace its body with your own availability query and keep the shape; `states.json` is the contract, and the LWC reads exactly these keys.

Each entry in `slots` is:

| Key | Example | Notes |
| --- | --- | --- |
| `slotId` | `2026-09-07_Afternoon` | Any stable string. Only used to track the selection. |
| `isoDate` | `2026-09-07` | Goes into the write-back utterance, so keep it `yyyy-MM-dd`. |
| `window` | `Afternoon` | Also written back, so keep the vocabulary your booking action expects. |
| `dayName` | `Monday` | Display only. |
| `dateLabel` | `Sep 7` | Display only. |
| `windowLabel` | `1:00 PM - 5:00 PM` | The arrival window shown to the customer. |
| `soonest` | `true` | Optional. Badges one row; it does **not** preselect it. |

The sample dates are fixed rather than generated, so `states.json` and the demo action stay diffable. A live version generates them: walk forward from `Date.today()`, skip Saturday and Sunday, take the first three business days, and drop any window that already has an appointment against the contact — booking one and re-running then visibly changes the card.

Three rules worth keeping when you do:

- **Never return null** in `appointmentSlots`. On failure, return `{"error":"..."}` — the card renders the message, and the planner still treats the result as displayable.
- **Return no availability as an empty `slots` array**, not as the `error` sentinel. Both render, but only the empty array gets the neutral panel; put the guidance in the optional `message` and `hint` keys, which override the component's defaults so you can name the next opening you found.
- **Keep the payload a serialized JSON string** in the single `slotsJSON` field. Typed or nested DTO fields don't round-trip reliably across the chat boundary.

## About the button

Confirming does not book anything. It dispatches an `acc:execute` custom event (`bubbles` and `composed`, so it crosses the shadow boundary) carrying an utterance that names the date and window explicitly — `Book a technician visit for this customer on 2026-09-07 during the Afternoon window (1:00 PM - 5:00 PM).` — for a booking action to extract. The card then flips its own label to `Appointment booked` and disables itself, so the rep can see the request went out without the card having to know whether it succeeded.

That split is deliberate. Writing records is the booking action's job, where you can set **Require confirmation** on it in Agent Builder and have the rep approve the write. A host that isn't listening for the event does nothing, which is why this card carries no dependency on the console APIs and therefore deploys anywhere.

## Preview

`preview/` is the gallery simulation — static HTML plus the component's real stylesheet, which is a byte-identical copy of `appointmentSlotsCard.css`. It isn't deployed and isn't part of the package; it exists so the card can be test-driven in a browser. Slot clicks are inert there, so the default block ships with one row already selected. If you restyle the component, copy the CSS across again.
