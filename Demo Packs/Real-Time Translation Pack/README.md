# Real-Time Translation Pack

<p align="center">
  <img src="assets/card.png" alt="Virtual Customer chat component" width="520" />
</p>

This pack deploys the **Virtual Customer** — a Lightning Web Component that simulates a real customer messaging your contact center. It sends genuine inbound messages into a live **Messaging for In-App & Web (MIAW)** session so you can demo two stories from one tool:

- **Real-Time Conversation Translation** — the customer messages in Spanish or French and your org translates it for the human agent live.
- **Agentforce** — the same conversation can instead be answered by an **Agentforce Service Agent**, and after a few turns the customer asks for a human, triggering the agent's **transfer-to-human escalation**.

Because the messages are real inbound conversation entries, the agent's replies (human *or* Agentforce) flow back into the component automatically.

---

## Contents

| Component | Type | Description |
|-----------|------|-------------|
| `sdo_virtualCustomer` | LWC | Chat UI: pick a conversation route + scenario, **Check setup**, start the conversation, auto-respond after the agent replies, and watch the transcript. Exposed to App / Home / Record pages and the Utility Bar. |
| `sdo_VirtualCustomerCtrl` | Apex | Drives the MIAW inbound REST API, links a Contact to the session, generates dynamic customer turns via the Models API, defines scenarios, reads routes, and runs the preflight check. |
| `sdo_VirtualCustomerCtrl_Test` | Apex | Test class (mocks the MIAW callouts). |
| `Virtual_Customer_Route__mdt` | Custom Metadata Type | Lets you point the route picker at your org's deployment/channel **in Setup — no code change**. Built-in defaults are used if no records exist. |

---

## Prerequisites

These are org-setup items the component depends on — the same way other packs need Voice or Einstein:

- **Messaging for In-App & Web** with a **Published API (Custom Client)** deployment. This is what the component sends inbound messages through.
- A **MessagingChannel** (`EmbeddedMessaging`) tied to that deployment.
- A **routing target** on that channel:
  - *Translation story* → Omni-Channel routing to a **human queue with an available agent**, plus **Real-Time Conversation Translation** enabled (customer/agent languages must differ).
  - *Agentforce story* → an **Agentforce Service Agent connected to the channel**, with a transfer-to-human / escalation action.
- **Einstein Generative AI** (Models API) — only for the "Dynamic AI follow-ups" toggle; scripted scenarios work without it.
- At least one **Contact with a phone number**.

> Standard SDO Service demo orgs that include an API messaging deployment + an Agentforce Service Agent generally satisfy these out of the box.

---

## Deploy this pack

Self-contained with its own `sfdx-project.json`. From the **Demo Packs** directory:

```bash
cd "Real-Time Translation Pack"
sf project deploy start --source-dir force-app --target-org YOUR_ORG_ALIAS
```

Or use the installer from the Demo Packs root: `./scripts/install-pack.sh` → option 5.

---

## Post-deploy setup (3 steps)

**1. Authorize the messaging endpoint (one command).** Fixes the *"Unauthorized endpoint … salesforce-scrt.com"* error by creating the Remote Site Setting for your org's messaging host:

```bash
./scripts/setup-remote-site.sh YOUR_ORG_ALIAS
```

**2. Point the routes at your org.** The route picker reads `Virtual_Customer_Route__mdt`. Built-in defaults (`RTT_New` / `RTT` and `SDO_Messaging_API` / `Messaging_for_In_App_Web`) are used when no records exist. To use your own deployment, add/edit records in **Setup → Custom Metadata Types → Virtual Customer Route → Manage Records**:

| Field | Meaning |
|-------|---------|
| **ES Developer Name** | Your **Published API** deployment's developer name. |
| **Channel Dev Name** | The `EmbeddedMessaging` MessagingChannel developer name. |
| **Is Agentforce** | Check if this route is answered by an Agentforce agent (enables escalation after the 3rd turn). |
| **Is Active / Sort Order / Route Label** | Visibility, ordering, and the label shown in the picker. |

**3. Add the component.** In Lightning App Builder, place **Virtual Customer (Translation Demo)** on a page or the Utility Bar.

Then open it and click **Check setup** — it tells you exactly whether the selected route is reachable and published before you start.

---

## Troubleshooting (use the "Check setup" button)

| Message | Meaning / Fix |
|---------|---------------|
| `OK — deployment "…" is published and reachable` | Ready to start. |
| `Callout blocked: …salesforce-scrt.com` | Run `scripts/setup-remote-site.sh` (step 1). |
| `Not ready (400): The Embedded Service deployment developer name is invalid` | The route's **ES Developer Name** doesn't exist in this org — fix the Custom Metadata record. |
| `Not ready (400): …deployment isn't published` | Publish it: **Setup → Embedded Service Deployments → (your deployment) → Publish**. |
| Conversation starts but no replies | The channel isn't routing to an available human/agent, or (Agentforce) there's no agent connected to that channel. |

---

## Features

| Feature | Description |
|---------|-------------|
| **Conversation route picker** | Configurable via Custom Metadata — switch between human (translation) and Agentforce deployments. |
| **Check setup** | One-click preflight that verifies the route's deployment is published and reachable, with a precise fix message. |
| **Scenarios** | Spanish, French, and English scenarios, each with a persona and scripted opening lines. |
| **Dynamic AI follow-ups** | Opens with the scripted line, then the Models API generates each follow-up live in the scenario's language. |
| **Auto-respond** | After the agent replies, the customer automatically sends its next turn. |
| **Auto-escalation (Agentforce route)** | After the 3rd customer turn, the customer asks for a human in the scenario's language to trigger the agent's transfer action. |
| **Live contact linking** | A random demo Contact (with a phone) is linked to the messaging session. |

---

## Disclaimer

For demos and labs only. Not an official Salesforce product.
