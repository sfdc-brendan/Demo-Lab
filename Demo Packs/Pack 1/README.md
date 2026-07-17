# Pack 1 – LWC Cards & Dashboard

This pack deploys three Lightning Web Component packages from Demo-Lab: **Incident Dashboard**, **Modern Account Card**, and **Modern Contact Card**.

---

## Contents

| Package | Path | Description |
|---------|------|-------------|
| Incident Dashboard | `LWCs/Incident Dashboard` | Active Incidents dashboard LWC; grid of cards for open Service Cloud Incidents and related Cases. |
| Modern Account Card | `LWCs/Modern Account Card` | Revenue Cloud–focused Account Card LWC with metrics, sub-brand affinities, and revenue trend chart. |
| Modern Contact Card | `LWCs/Modern Contact Card` | Configurable Contact Card LWC with health score, tags, brand affinities, and CSAT-style chart. |

---

## Prerequisites

- **Incident Dashboard:** Service Cloud (Incident, CaseRelatedIssue, Case). Optional companion to [Incident Detection](https://github.com/sfdc-brendan/Demo-Lab/tree/main/Service%20Cloud/Incident%20Detection).
- **Modern Account Card:** Account; Revenue Cloud objects (Quote, Order, Asset, Invoice) for metrics. Assign **Modern Account Card Access** permission set after deploy.
- **Modern Contact Card:** Contact; custom fields are included. Assign **Modern Contact Card Access** permission set after deploy. For Voice Call / Messaging Session pages, set the Contact lookup field in App Builder.

See the main [Demo-Lab README](https://github.com/sfdc-brendan/Demo-Lab#requirements-by-area) and each package folder in the repo for full requirements.

---

## Deploy this pack manually

From the **Demo-Lab repo root**:

```bash
sf project deploy start \
  --source-dir "LWCs/Incident Dashboard" \
  --source-dir "LWCs/Modern Account Card" \
  --source-dir "LWCs/Modern Contact Card" \
  --target-org YOUR_ORG_ALIAS
```

Replace `YOUR_ORG_ALIAS` with your org alias or omit to use the default org.

---

## Post-deploy setup (configure the LWCs before your demo)

Deploying only puts the components in your org — you still have to **place them on pages, assign permission sets, and set their properties** in Lightning App Builder. Do this once before the demo.

### 1. Assign permission sets

The two card components read custom fields that are gated by permission sets. Assign them to yourself (and any presenter user):

```bash
sf org assign permset --name Modern_Account_Card_Access --target-org YOUR_ORG_ALIAS
sf org assign permset --name Modern_Contact_Card_Access --target-org YOUR_ORG_ALIAS
```

Or via UI: **Setup → Permission Sets →** open **Modern Account Card Access** / **Modern Contact Card Access → Manage Assignments → Add Assignment**. (Incident Dashboard needs no permission set — just standard access to Incident and Case.)

### 2. Incident Dashboard → App or Home page

`incidentDashboard` targets **App pages and Home pages** (not record pages).

1. **Setup → Lightning App Builder → New → App Page** (or **Home Page**), give it a label (e.g. *Active Incidents*), pick a one-region layout.
2. Drag **incidentDashboard** from the **Custom** components list onto the canvas.
3. **Save → Activate**, assign it to the app(s) and profiles you demo with, then **Save**.
4. (Optional) Deploy the companion [Incident Detection](https://github.com/sfdc-brendan/Demo-Lab/tree/main/Service%20Cloud/Incident%20Detection) pack so the dashboard has live incidents to show.

### 3. Modern Account Card → Account record page

`modernAccountCard` (label **Modern Account Card**) targets the **Account** record page and is highly configurable.

1. Open any **Account** record → **Setup (gear) → Edit Page**.
2. Drag **Modern Account Card** into a column (a wide/main column looks best).
3. In the property panel on the right, set what you want to show:
   - **Theme Mode** — Light or Dark
   - **Show Quote/Asset/Order/Invoice** toggles and their **labels**
   - **Fallback values** (e.g. Quote Total Fallback `$125,000`) so the card looks populated even without Revenue Cloud data
   - **Show Brand Affinities** (reads `Account.Brand_1_Name__c`…`Brand_4_Name__c` / `Brand_x_Image__c`)
   - **Show Revenue Chart** + chart data/labels/colors
   - **Header Background URL** / **Account Logo URL** (or set `Account.AccountCardLogo__c` on the record)
4. **Save**, and **Activate** the page (Org Default or App/Profile as needed).

> The card reads live metrics from Quotes, Orders, Assets, and Invoices when present; use the **Fallback** properties to hard-code demo-ready numbers when those objects are empty.

### 4. Modern Contact Card → Contact / Case / Messaging Session / Voice Call page

`modernContactCard` (label **Modern Contact Card**) targets **Contact, Case, MessagingSession, and VoiceCall** record pages.

1. Open a **Contact** (or Case / Messaging Session / Voice Call) → **Setup (gear) → Edit Page**.
2. Drag **Modern Contact Card** into a column.
3. Configure the property panel:
   - **Theme Mode**, **Show Health Score / Tags / Chart**
   - **Field 1–6** labels/icons (values come from `Contact.Metric_1__c`…`Metric_6__c`; use the **Fallback** props for demo values)
   - Image/health/tags **field API names** if your org uses different fields (defaults: `ContactCardPicture__c`, `ContactCardHealthScore__c`, `ContactCardTags__c`)
   - **On Voice Call / Messaging Session pages:** set **VoiceCall Contact Field** to the Contact lookup API name on that object so the card can resolve the contact.
4. **Save → Activate**.

### 5. Smoke-test before the demo

- Open an Account with the card — metrics, chart, and (if enabled) brand affinities render.
- Open a Contact and confirm fields/health/tags show.
- Open your Active Incidents page and confirm the dashboard loads (empty state is fine if you haven't created incidents yet).
