# Service Cloud Pack

This pack deploys the full **Service Cloud** set from Demo-Lab plus **Sentiment and Coaching** (LWCs and related metadata for Voice and Messaging).

---

## Contents

| Package | Path | Description |
|---------|------|-------------|
| Incident Detection | `Service Cloud/Incident Detection` | Real-time incident detection for Cases (Flow, Apex, GenAI prompts). |
| Email OTP | `Service Cloud/Email OTP` | Email one-time verification (LWC + Apex). |
| Case Tagging | `Service Cloud/Case Tagging` | AI-powered case tagging (LWCs, flows, GenAI, invocable, batch). |
| Similar Cases | `Service Cloud/Similar Cases` | Similar cases and Knowledge articles on Case (Einstein Models API + SOSL). |
| Sentiment and Coaching | `LWCs/Sentiment and Coaching` | Sentiment and agent coaching for Voice Call and Messaging Session (flows, GenAI, LWCs). |

---

## Prerequisites

- **Incident Detection:** Create custom field **Case.AI_Summary__c** (Long Text Area) before deploying. Service Cloud (Case, Incident, CaseRelatedIssue); Einstein GenAI.
- **Email OTP:** Contact with Email; assign **OTP Verification** permission set; add **Customer Verification (OTP)** LWC to Contact page.
- **Case Tagging:** Service Cloud (Case); Einstein GenAI; API 65.0+. Assign **Case Tagging** permission set; add **Case Tags** and **Case Tag Trends** as needed.
- **Similar Cases:** Case record page; Einstein Models API; API 65.0+. Add **similarCasesAndArticles** to Case record page.
- **Sentiment and Coaching:** Service Cloud Voice and/or Messaging; Voice Call and/or Messaging Session; Einstein/GenAI; custom fields are included.

See the main [Demo-Lab README](https://github.com/sfdc-brendan/Demo-Lab#requirements-by-area) and each package folder for full requirements and setup.

---

## Deploy this pack manually

From the **Demo-Lab repo root**:

```bash
sf project deploy start \
  --source-dir "Service Cloud/Incident Detection" \
  --source-dir "Service Cloud/Email OTP" \
  --source-dir "Service Cloud/Case Tagging" \
  --source-dir "Service Cloud/Similar Cases" \
  --source-dir "LWCs/Sentiment and Coaching" \
  --target-org YOUR_ORG_ALIAS
```

Replace `YOUR_ORG_ALIAS` with your org alias or omit to use the default org.

---

## Post-deploy setup (configure the components before your demo)

Deploying puts the metadata in your org, but each feature still needs to be **assigned, placed on a page, and (for the AI pieces) have its prompt template verified**. Work through each section below in Lightning App Builder before the demo.

### 1. Assign permission sets

```bash
sf org assign permset --name OTP_Verification            --target-org YOUR_ORG_ALIAS
sf org assign permset --name Case_Tagging                --target-org YOUR_ORG_ALIAS
sf org assign permset --name Sentiment_Coaching_Fields   --target-org YOUR_ORG_ALIAS
```

Or via **Setup → Permission Sets →** open each (**OTP Verification**, **Case Tagging**, **Sentiment Coaching Fields**) **→ Manage Assignments → Add Assignment**.

### 2. Incident Detection (Flow / Apex / GenAI — no LWC to place)

1. **Before deploy** you should already have created the custom field **`Case.AI_Summary__c`** (Long Text Area). If you skipped it, create it now and redeploy.
2. **Setup → Einstein → Prompt Builder** — confirm the Incident Detection prompt template is **Published/Active**.
3. **Setup → Flows** — confirm the incident-detection flow is **Active**.
4. (Optional) Add the **Incident Dashboard** LWC (from *Pack 1*) to an App/Home page to visualize the incidents this creates.

### 3. Email OTP → Contact record page

The component's developer name is **`customerVerification`** (referred to as *Customer Verification (OTP)*), targeting the **Contact** record page.

1. Open a **Contact** → **Setup (gear) → Edit Page**.
2. Drag **customerVerification** from the **Custom** list into a column.
3. **Save → Activate**.
4. Ensure the Contact has a valid **Email**, and that **OTP Verification** permission set is assigned (step 1).

### 4. Case Tagging → Case page (+ optional trends)

Two components: **`caseTags`** (Case record page) and **`caseTagTrends`** (App / Home / Case record page). Requires Einstein GenAI and API 65.0+.

1. Open a **Case** → **Setup (gear) → Edit Page**.
2. Drag **caseTags** into a column on the Case page. **Save → Activate**.
3. (Optional) Add **caseTagTrends** to a **Home** or **App page** (**Setup → Lightning App Builder → New**) to show tag trends across cases.
4. **Setup → Einstein → Prompt Builder** — confirm the Case Tagging prompt template(s) are **Published/Active**.

### 5. Similar Cases → Case record page

Component **`similarCasesAndArticles`** (Case record page). Uses the Einstein Models API + SOSL; API 65.0+.

1. Open a **Case** → **Setup (gear) → Edit Page**.
2. Drag **similarCasesAndArticles** into a column (a side column works well).
3. In the property panel set:
   - **Max Similar Cases** (1–20, default 10)
   - **Max Related Articles** (1–20, default 10)
   - *(Record Id is set automatically.)*
4. **Save → Activate**. Knowledge should be enabled for the article results to populate.

### 6. Sentiment and Coaching → Voice Call / Messaging Session pages

Four components, each with its own target:

| Component | Add to | Page type |
|-----------|--------|-----------|
| **Voice Call Analytics** (`voiceCallAnalytics`) | Voice Call record page | Record |
| **Messaging Session Analytics** (`messagingSessionAnalytics`) | Messaging Session record page | Record |
| **Sentiment Tracker** (`sentimentTracker`) | Voice Call or Messaging Session record page (also App/Home) | Record / App / Home |
| **Historical Analysis Launcher** (`historicalAnalysisLauncher`) | App page, Home page, or a custom Tab | App / Home / Tab |

1. Open a **Voice Call** record → **Setup (gear) → Edit Page**, drag **Voice Call Analytics** (and optionally **Sentiment Tracker**) onto the page. **Save → Activate**.
2. Open a **Messaging Session** record → **Edit Page**, drag **Messaging Session Analytics** (and optionally **Sentiment Tracker**). **Save → Activate**.
3. Create an **App or Home page** and add **Historical Analysis Launcher** so presenters can run analysis on past calls/sessions (up to ~2 weeks old).
4. Confirm the sentiment/coaching **Flows** and **prompt templates** are **Active** in Setup, and that **Sentiment Coaching Fields** permission set is assigned.

### 7. Smoke-test before the demo

- Trigger OTP send/verify on a Contact.
- Open a Case and confirm tags generate and similar cases/articles appear.
- Open a completed Voice Call / Messaging Session and confirm analytics + sentiment render.
- Create a test Case to confirm Incident Detection populates `AI_Summary__c`.
