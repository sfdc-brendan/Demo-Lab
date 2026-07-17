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

## Post-deploy setup (configure the components before your demo)

Deploying installs the app, objects, and LWCs — you still need to **assign access, build a template, and place the runtime component on a page**. Do this once before the demo.

### 1. Assign permission sets

```bash
sf org assign permset --name Intake_Builder_Admin --target-org YOUR_ORG_ALIAS
sf org assign permset --name Intake_Runtime_User  --target-org YOUR_ORG_ALIAS
```

- **Intake Builder Admin** — for you/admins who design templates.
- **Intake Runtime User** — for the agents/presenters who run intakes.

Or via **Setup → Permission Sets → Manage Assignments** for each.

### 2. Build a template in the Intake Builder app

The admin component **`intakeBuilderApp`** (label **Intake Builder**, targets App/Home pages) ships pre-placed in the **Intake Builder** app.

1. **App Launcher → Intake Builder**.
2. Create a new **Intake Template** (`Intake_Template__c`), add questions/fields, set any conditional visibility, and **Activate** it.

> If the app tab is missing, add **intakeBuilderApp** to a new App Page via **Setup → Lightning App Builder → New → App Page**.

### 3. Place Intake Runtime on a page

The runtime component **`intakeRuntime`** (label **Intake Runtime**) targets **Record pages and App pages**, and includes a Service Cloud Voice toolkit capability for Voice Call pages.

1. Choose where agents will run the intake — most commonly a **Voice Call** record page (or a Case/App page).
2. Open that record → **Setup (gear) → Edit Page** (or **Setup → Lightning App Builder → New → App Page**).
3. Drag **Intake Runtime** from the **Custom** components list onto the canvas.
4. In the property panel, set **Intake Template**:
   - Pick a specific template to pin it to this page, **or**
   - Leave it **blank** to let the agent choose from a runtime dropdown.
5. **Save → Activate** (Org Default or App/Profile as needed).

### 4. (Optional) Enable AI extraction

For live transcript-driven answer extraction and generation, ensure **Einstein Generative AI** entitlements are enabled and any related prompt templates are **Published/Active** in **Setup → Einstein → Prompt Builder**. Scripted/manual intake works without it.

### 5. Smoke-test before the demo

- Open the page hosting **Intake Runtime**, pick (or confirm) a template, and walk through the questions.
- Complete an intake and confirm the **PDF is generated and linked** to the record.

---

## What this pack is for

Use this pack when you want a reusable intake framework that supports:

- dynamic question sets
- conditional field visibility
- transcript-driven answer extraction
- PDF record output without hardcoded scenario dependencies
