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
