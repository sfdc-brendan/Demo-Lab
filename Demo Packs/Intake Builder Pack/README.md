# Intake Builder Pack

This pack deploys the configurable **Intake Builder** solution for Salesforce.

It includes:

- Intake Builder admin app
- Runtime intake experience (`intakeRuntime`) for voice/case workflows
- Configurable intake data model (`Intake_Template__c`, `Intake_Question__c`, etc.)
- AI-assisted extraction controllers
- Generic intake PDF generation and file linking

---

## Prerequisites

- Salesforce CLI (`sf`) installed
- A target org authenticated with `sf org login web`
- (Optional) Einstein Generative AI entitlements for live AI extraction/generation features

---

## Deploy this pack

From the **Demo Packs** directory:

```bash
cd "Intake Builder Pack"
sf project deploy start --source-dir force-app --target-org YOUR_ORG_ALIAS
```

Or use the installer script from Demo Packs root:

```bash
./scripts/install-pack.sh
```

---

## Post-deploy setup

1. Assign permission sets:

```bash
sf org assign permset --name Intake_Builder_Admin --target-org YOUR_ORG_ALIAS
sf org assign permset --name Intake_Runtime_User --target-org YOUR_ORG_ALIAS
```

2. Open the **Intake Builder** app in the org.
3. Create or activate a template.
4. Place **Intake Runtime** (`c:intakeRuntime`) on a record/app page.

---

## What this pack is for

Use this pack when you want a reusable intake framework that supports:

- dynamic question sets
- conditional field visibility
- transcript-driven answer extraction
- PDF record output without hardcoded scenario dependencies
