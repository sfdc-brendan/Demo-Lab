# Demo Packs

Curated bundles of [Demo-Lab](https://github.com/sfdc-brendan/Demo-Lab) metadata (LWCs, Flows, Apex, etc.) that you can deploy to a Salesforce org in a few terminal steps. Each pack is a predefined set of packages; no need to deploy folders one by one.

**Do not use these in production.** For demos and labs only.

---

## Prerequisites

- **Git** – to clone the repo
- **Salesforce CLI (sf)** – [Install the Salesforce CLI](https://developer.salesforce.com/tools/sfdxcli) and ensure `sf` is on your PATH

---

## 5-step install (copy & paste)

Run this in your terminal. Steps 1–2 get the repo and go to Demo Packs; step 3 runs the installer, which opens the browser to log in (step 4) and then lets you choose and deploy a pack (step 5).

```bash
# Step 1: Clone the repo (skip if you already have it)
git clone https://github.com/sfdc-brendan/Demo-Lab.git && cd Demo-Lab

# Step 2: Go to Demo Packs
cd "Demo Packs"

# Step 3: Run the installer (browser login + pack selection + deploy)
./scripts/install-pack.sh
```

The script will:

1. **Step 4:** Open your browser so you can log in to the Salesforce org you want (`sf org login web --set-default`).
2. **Step 5:** Ask you to choose a pack (Pack 1, Service Cloud Pack, or both), then deploy to the default org.

---

## Packs

| Pack | Description |
|------|-------------|
| **[Pack 1](Pack%201/README.md)** | Incident Dashboard, Modern Account Card, Modern Contact Card (LWCs) |
| **[Service Cloud Pack](Service%20Cloud%20Pack/README.md)** | Full Service Cloud set (Incident Detection, Email OTP, Case Tagging, Similar Cases, Unified Phone Controls) plus Sentiment and Coaching |

See each pack’s README for contents, prerequisites, and post-deploy steps.

---

## Running the script from an existing clone

If you already have Demo-Lab cloned:

```bash
cd /path/to/Demo-Lab
cd "Demo Packs"
./scripts/install-pack.sh
```

---

## Disclaimer

Demo-Lab and Demo Packs are not an official Salesforce product. Use at your own risk; review and test before any use.
