# Salesforce Customer Success Manager (CSM) Subagent

> An AI assistant for **Cursor** and **Claude Code** that owns the post-sale customer relationship — adoption tracking, health scoring, expansion opportunity mapping, QBR preparation, risk mitigation, and renewal strategy for Salesforce customers.

---

## Table of Contents

- [What Is This?](#what-is-this)
- [Why a Customer Success Subagent?](#why-a-customer-success-subagent)
- [The Pre-Sale → Post-Sale Handoff](#the-pre-sale--post-sale-handoff)
- [What It Does](#what-it-does)
- [How It Works](#how-it-works)
- [Deployment](#deployment)
  - [Option 1: One-Liner Install](#option-1-one-liner-install-recommended)
  - [Option 2: Clone and Install](#option-2-clone-and-install)
  - [Option 3: Manual Copy](#option-3-manual-copy)
- [Verifying the Install](#verifying-the-install)
- [Using the CSM Subagent](#using-the-csm-subagent)
  - [Success Plans](#1-success-plans)
  - [Adoption Scorecards](#2-adoption-scorecards)
  - [Health Check Reports](#3-health-check-reports)
  - [Expansion Opportunity Maps](#4-expansion-opportunity-maps)
  - [QBR Decks](#5-qbr-decks)
  - [Risk Mitigation Plans](#6-risk-mitigation-plans)
  - [Feature Adoption Playbooks](#7-feature-adoption-playbooks)
  - [Scoring Deliverables](#8-scoring-deliverables)
- [How It Integrates with Other Skills](#how-it-integrates-with-other-skills)
- [File Reference](#file-reference)
- [Updating](#updating)
- [Uninstalling](#uninstalling)
- [FAQ](#faq)

---

## What Is This?

This is a **subagent** — a skill file that teaches Claude (in Cursor or Claude Code) how to operate as a Salesforce Customer Success Manager. When installed, it gives your AI assistant the frameworks, templates, and operating model of a CSM who owns the post-sale relationship.

The Customer Success Manager:

> Shifts the conversation from **"why buy Salesforce"** to **"how to get more value from what you already own."**

The CSM doesn't sell. The CSM ensures customers realize value from their investment, identifies risks before they become crises, and surfaces expansion opportunities that emerge naturally from demonstrated success.

---

## Why a Customer Success Subagent?

AI coding assistants can write Apex and build LWCs, but they don't naturally think about adoption curves, health scores, or renewal readiness. They solve technical problems without asking whether anyone is actually using the solution.

The CSM subagent fills that gap:

- **Adoption is the product.** It measures success by what users do, not what was deployed.
- **Health scores drive action.** Multi-dimensional health models surface risk before it's visible to the account team.
- **Expansion earns itself.** Expansion recommendations are grounded in demonstrated value, not sales pressure.
- **QBRs deliver insight.** Quarterly reviews go beyond metrics to give the customer something they didn't know before.
- **Risks get immediate attention.** Churn signals trigger same-week intervention, not next-quarter planning.
- **The customer's voice carries.** Feedback is aggregated and routed to product management through structured VoC synthesis.

---

## The Pre-Sale → Post-Sale Handoff

The CSM sits at a critical junction in the customer lifecycle. Understanding this handoff is essential to the subagent's value.

```
DSE / SE (pre-sale)  →  Implementation  →  CSM (post-sale)
                                              ↓
                                    expansion signals
                                              ↓
                                    DSE / AE (new deal)
```

### Receiving from Pre-Sale (DSE / SE → CSM)

When a customer moves from sale to post-sale, the CSM needs:
- Original business case and success metrics promised during the sale
- Technical architecture decisions and their rationale
- Key stakeholders, their priorities, and their communication preferences
- Any commitments or conditions from the sales cycle
- Implementation timeline and go-live criteria

**If you have the DSE and SE subagents installed**, the CSM can reference the strategic context they created during the sale to build continuity into the success plan.

### Feeding Back to Pre-Sale (CSM → DSE / AE)

When expansion opportunities emerge from post-sale success, the CSM provides:
- Demonstrated value evidence (adoption data, ROI metrics, success stories)
- Champion identification and sentiment assessment
- Business triggers that create expansion timing
- Technical readiness assessment (has the customer matured enough?)
- Recommended positioning and approach

This creates a virtuous cycle: pre-sale promises become post-sale metrics, and post-sale success becomes the next pre-sale story.

---

## What It Does

The CSM subagent produces seven types of deliverables and operates within a multi-dimensional health and adoption framework.

### Deliverables

| Deliverable | What You Get | When to Use It |
|---|---|---|
| **Success Plan** | Customer goals, success metrics, milestones, adoption targets by phase, executive alignment, communication cadence | Onboarding new customers, annual planning, post-renewal reset |
| **Adoption Scorecard** | Feature-by-feature adoption metrics, user login frequency, workflow completion rates, adoption by user segment, trends over time | Monthly/quarterly adoption reviews, QBR preparation |
| **Health Check Report** | Technical health (data quality, automations, integrations, licenses), business health (KPI achievement, stakeholder satisfaction, open issues), composite score | Quarterly reviews, risk identification, renewal preparation |
| **Expansion Opportunity Map** | Current footprint, whitespace by cloud, trigger events, champion identification, recommended approach | Annual planning, pre-renewal strategy, growth reviews |
| **QBR Deck** | Period in review (wins/metrics/milestones), challenges addressed, roadmap alignment, next-period goals, mutual commitments | Quarterly executive meetings with customers |
| **Risk Mitigation Plan** | Risk identification, severity, leading indicators, mitigation actions, escalation path, timeline, resolution criteria | When health score drops, churn signals appear, or stakeholder changes occur |
| **Feature Adoption Playbook** | Target feature, target users, current adoption %, barrier diagnosis, 30-day enablement sprint plan, success metric | When specific features are underused and need focused intervention |

### Operating Principles

| # | Principle | What It Means in Practice |
|---|---|---|
| 1 | Adoption is the product | Measure what users do, not what was deployed |
| 2 | Health scores are leading indicators | Act on declining dimensions before they become crises |
| 3 | Expansion comes from demonstrated value | Earn the right to discuss growth through proven ROI |
| 4 | Every QBR should leave the customer feeling smarter | Deliver insight, not just a status report |
| 5 | Risk signals require immediate action | Same-week triage, not next-quarter planning |
| 6 | Be the customer's advocate internally | Route product gaps to PM through structured VoC |

---

## How It Works

### The Skill System

Both Cursor and Claude Code support **skills** — markdown files that teach the AI assistant how to perform specific tasks. The CSM subagent consists of:

| File | Purpose |
|---|---|
| `SKILL.md` | Core instructions — identity, operating principles, RACI, deliverable workflows, scoring rubric, cross-skill delegation |
| `references/deliverables-guide.md` | Full templates for all seven deliverable types (loaded on-demand) |
| `references/success-frameworks.md` | Health score model, adoption maturity model, expansion playbook patterns, QBR best practices, risk taxonomy, renewal timeline, VoC synthesis (loaded on-demand) |

### When It Activates

The subagent activates automatically when your prompt matches its trigger patterns:

- Creating **success plans** or defining customer goals
- Tracking **adoption** metrics or building scorecards
- Assessing **customer health** or building health scores
- Mapping **expansion opportunities** or whitespace
- Preparing **QBR decks** or executive business reviews
- Designing **risk mitigation** plans or identifying churn signals
- Building **feature adoption playbooks** for underused capabilities
- Planning **renewal strategy** or preparing renewal timeline
- Synthesizing **customer feedback** into actionable themes

It will **not** activate for pre-sale strategy (DSE handles that), deal-level selling (SE handles that), requirements gathering for new projects (BA handles that), or implementation work (Apex, LWC, Flows, metadata skills handle that).

---

## Deployment

### Prerequisites

- **Cursor** (any version with skills support) and/or **Claude Code** (any version with skills support)
- A terminal with `bash`, `curl`, and `git` (macOS and Linux have these by default)

### Where It Installs

| Platform | Install Path |
|---|---|
| Cursor | `~/.cursor/skills/sf-customer-success/` |
| Claude Code | `~/.claude/skills/sf-customer-success/` |

---

### Option 1: One-Liner Install (Recommended)

No clone required. Run one command in your terminal.

**Both Cursor and Claude Code:**

```bash
curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/CustomerSuccess/install.sh | bash -s -- --both
```

**Cursor only:**

```bash
curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/CustomerSuccess/install.sh | bash -s -- --cursor
```

**Claude Code only:**

```bash
curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/CustomerSuccess/install.sh | bash -s -- --claude
```

Expected output:

```
╔════════════════════════════════════════════════════════╗
║  Salesforce Customer Success Subagent                 ║
║  Adoption, health & expansion                        ║
╚════════════════════════════════════════════════════════╝

  ✓ Installed to /Users/you/.cursor/skills/sf-customer-success (Cursor)
  ✓ Installed to /Users/you/.claude/skills/sf-customer-success (Claude Code)

Done! The Customer Success subagent will auto-activate when you:
  • Create success plans or adoption scorecards
  • Build health check reports or health scores
  • Map expansion opportunities or prepare QBR decks
  • Design risk mitigation plans or renewal strategies
  • Analyze feature adoption or synthesize customer feedback
```

---

### Option 2: Clone and Install

```bash
git clone https://github.com/sfdc-brendan/Demo-Lab.git
cd Demo-Lab/subagents/CustomerSuccess
chmod +x install.sh
./install.sh --both
```

---

### Option 3: Manual Copy

**For Cursor:**

```bash
mkdir -p ~/.cursor/skills/sf-customer-success/references

curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/CustomerSuccess/SKILL.md \
  -o ~/.cursor/skills/sf-customer-success/SKILL.md

curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/CustomerSuccess/references/deliverables-guide.md \
  -o ~/.cursor/skills/sf-customer-success/references/deliverables-guide.md

curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/CustomerSuccess/references/success-frameworks.md \
  -o ~/.cursor/skills/sf-customer-success/references/success-frameworks.md
```

**For Claude Code:**

```bash
mkdir -p ~/.claude/skills/sf-customer-success/references

curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/CustomerSuccess/SKILL.md \
  -o ~/.claude/skills/sf-customer-success/SKILL.md

curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/CustomerSuccess/references/deliverables-guide.md \
  -o ~/.claude/skills/sf-customer-success/references/deliverables-guide.md

curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/CustomerSuccess/references/success-frameworks.md \
  -o ~/.claude/skills/sf-customer-success/references/success-frameworks.md
```

---

## Verifying the Install

```bash
# For Cursor
ls -la ~/.cursor/skills/sf-customer-success/
ls -la ~/.cursor/skills/sf-customer-success/references/

# For Claude Code
ls -la ~/.claude/skills/sf-customer-success/
ls -la ~/.claude/skills/sf-customer-success/references/
```

You should see:

```
sf-customer-success/
├── SKILL.md
└── references/
    ├── deliverables-guide.md
    └── success-frameworks.md
```

To confirm the skill is loaded, try a prompt like:

> "Create a success plan for a healthcare customer who just went live on Service Cloud + Health Cloud."

The agent should begin by asking about the customer's business objectives, go-live timeline, stakeholder map, and adoption targets — not by jumping to Apex code or Flow configuration.

---

## Using the CSM Subagent

### 1. Success Plans

**Example prompts:**

> "Create a success plan for a healthcare customer who just went live on Service Cloud + Health Cloud. They have 200 agents and their primary goal is reducing patient inquiry resolution time."

> "Build a success plan for a mid-market financial services company that's been on Sales Cloud for a year and just added Revenue Cloud. They want to cut their quote-to-cash cycle in half."

**What you get:** A structured plan with customer objectives mapped to Salesforce capabilities, phased adoption targets (30/60/90 day), milestones with measurable criteria, communication cadence, risk register, and expansion roadmap.

---

### 2. Adoption Scorecards

**Example prompts:**

> "Build an adoption scorecard for a customer with Sales Cloud (250 users) and Service Cloud (100 users). Login data shows 70% WAU on Sales and 90% on Service."

> "Create an adoption scorecard that tracks Einstein Activity Capture, Mobile App, and Reports & Dashboards adoption across three user segments."

**What you get:** Feature-by-feature adoption metrics, segmented by user role and business unit, with trends over time, underused feature identification, and enablement recommendations.

---

### 3. Health Check Reports

**Example prompts:**

> "Run a health check for a customer whose support ticket volume has doubled in the last quarter and executive sponsor attendance has dropped."

> "Create a comprehensive health check report combining adoption data, support trends, license utilization, and stakeholder engagement for a pre-renewal review."

**What you get:** A composite health score across six weighted dimensions (adoption, support, engagement, satisfaction, utilization, growth), with technical health details, business health KPIs, and prioritized recommendations.

---

### 4. Expansion Opportunity Maps

**Example prompts:**

> "Map expansion opportunities for a customer currently on Sales Cloud Enterprise who is opening a new APAC office and has a board mandate to improve customer experience."

> "Build an expansion whitespace analysis for a healthcare customer on Service Cloud + Health Cloud who's asking about patient 360 and analytics."

**What you get:** Current footprint documentation, whitespace by product, trigger events creating timing, champion map, readiness assessment per opportunity, and recommended approach (user-led, executive-sponsored, event-triggered, or land-and-expand).

---

### 5. QBR Decks

**Example prompts:**

> "Build a QBR deck showing adoption progress for a financial services client in their second quarter. Sales Cloud adoption went from 62% to 78%, and they launched an Einstein pilot."

> "Prepare a QBR for a retail customer at renewal minus 6 months. Focus on value delivered, adoption wins, and set up the renewal conversation."

**What you get:** A structured QBR with period-in-review metrics, adoption trends, challenge resolution, roadmap alignment, an insight spotlight (something the customer didn't know), next-quarter goals, and mutual commitments with owners and dates.

---

### 6. Risk Mitigation Plans

**Example prompts:**

> "Our executive sponsor at a key account has cancelled three meetings in a row and their primary admin just gave notice. Build a risk mitigation plan."

> "Create a risk plan for a customer where adoption dropped from 75% to 55% WAU over two months and they've started evaluating a competitor CRM for their marketing team."

**What you get:** Risk identification with specific evidence, severity classification, leading indicator analysis, detailed mitigation actions with owners and timelines, escalation matrix, and resolution criteria.

---

### 7. Feature Adoption Playbooks

**Example prompts:**

> "Build a 30-day adoption playbook for Einstein Activity Capture. Current adoption is 30% among 200 sales reps. The main barrier is awareness — most reps don't know it exists."

> "Create a feature adoption playbook for the Salesforce Mobile App targeting field service reps who currently have 22% adoption."

**What you get:** A barrier diagnosis (awareness, training, UX, relevance, access, manager reinforcement, data quality), a week-by-week enablement sprint plan, success metrics with baselines and targets, and post-sprint assessment criteria.

---

### 8. Scoring Deliverables

After any deliverable is produced, you can request a quality score:

> "Score this QBR deck against the CSM rubric."

| Category | Points | What It Measures |
|---|---|---|
| Customer Centricity | 25 | Framed around customer's business outcomes, uses their language |
| Actionability | 20 | Every finding has a recommended action with owners and timelines |
| Data-Driven Insight | 20 | Claims backed by metrics, trends over time, baselines provided |
| Proactive Risk Management | 20 | Risks identified early, mitigation is specific, escalation paths clear |
| Expansion Awareness | 15 | Whitespace identified from demonstrated value, timing aligned |

| Score Range | Meaning |
|---|---|
| 85–100 | Executive-ready — proceed to present |
| 70–84 | Strong foundation — refine data points or actions |
| 50–69 | Good direction — needs deeper analysis or customer validation |
| Below 50 | Return to data gathering and customer discovery |

---

## How It Integrates with Other Skills

The CSM subagent owns the post-sale relationship and delegates implementation. If you have other Salesforce skills installed, delegation happens automatically:

| When the CSM needs... | Delegates to... |
|---|---|
| Requirements for enhancement requests | `sf-ba` — BA owns the requirements lifecycle |
| Strategic expansion architecture | `sf-dse` — DSE handles executive-level positioning |
| Demos for expansion opportunities | `sf-se` — SE runs technical demos |
| Reporting and analytics queries | `sf-soql` — delegates SOQL query building |
| Value realization calculations | `sf-value-engineer` — delegates ROI tracking |
| Process optimization for adoption | `sf-ba` — BA maps improved processes |
| Implementation of recommendations | `sf-apex`, `sf-lwc`, `sf-flow` — technical skills build |
| Architecture diagrams | `sf-diagram-mermaid` — visual diagrams for health checks and QBRs |
| Deployment of fixes | `sf-deploy` — release management for remediation |

### The Full Lifecycle with All Subagents

| Phase | Primary Subagent | Supporting Subagents |
|---|---|---|
| Pre-sale strategy | DSE | SE, BA |
| Discovery & demo | SE | DSE, BA |
| Requirements & design | BA | DSE, CSM (for adoption planning) |
| Implementation | Apex, LWC, Flow skills | BA (validation), CSM (success criteria) |
| Post-sale ownership | **CSM** | BA (enhancements), DSE (expansion strategy) |
| Expansion deal | DSE + SE | CSM (value evidence, champion access) |

---

## File Reference

```
subagents/CustomerSuccess/
├── README.md                              ← You are here
├── SKILL.md                               ← Core skill (loaded into AI context)
├── install.sh                             ← Deployment script
└── references/
    ├── deliverables-guide.md              ← Templates for all 7 deliverable types
    └── success-frameworks.md              ← Health models, adoption maturity, expansion playbooks
```

| File | Lines | Purpose |
|---|---|---|
| `SKILL.md` | ~270 | Core identity, operating principles, RACI, deliverable workflows, pre-sale/post-sale handoff model, scoring rubric, cross-skill delegation. Always loaded when the skill activates. |
| `references/deliverables-guide.md` | ~370 | Detailed templates for success plans, adoption scorecards, health check reports, expansion opportunity maps, QBR decks, risk mitigation plans, and feature adoption playbooks. Loaded on-demand. |
| `references/success-frameworks.md` | ~350 | Health score model (6 weighted dimensions with scoring guidelines), adoption maturity model (5 stages), expansion playbook patterns (4 motions), QBR best practices, risk signal taxonomy (red/yellow/green), renewal preparation timeline (12-month countdown), VoC synthesis methodology. Loaded on-demand. |

---

## Updating

Re-run the install command. It detects existing installations and replaces them:

```bash
curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/CustomerSuccess/install.sh | bash -s -- --both
```

---

## Uninstalling

```bash
# Cursor
rm -rf ~/.cursor/skills/sf-customer-success

# Claude Code
rm -rf ~/.claude/skills/sf-customer-success
```

---

## FAQ

**Q: How does this differ from the DSE and SE subagents?**
The DSE and SE operate pre-sale — they help win deals. The CSM operates post-sale — it helps customers succeed after they've bought. The DSE asks "why should the CIO invest in Salesforce?" The SE asks "how does this solve your specific problem?" The CSM asks "are you getting the value we promised, and what comes next?"

**Q: Do I need the other subagents installed?**
No. The CSM works standalone. If you also have `sf-dse`, `sf-se`, and `sf-ba` installed, delegation and handoff happen naturally, but neither requires the others.

**Q: Can I use this for pre-sale work?**
The CSM is designed for post-sale. If you're preparing pre-sale materials, the DSE and SE subagents are better suited. However, the CSM's value evidence and adoption data are powerful inputs to pre-sale expansion conversations.

**Q: What Salesforce clouds does it cover?**
All of them. The CSM tracks adoption, health, and expansion across Sales, Service, Marketing, Commerce, Data Cloud, Experience Cloud, Revenue Cloud, Health Cloud, Financial Services Cloud, and any other cloud in the customer's footprint.

**Q: Does it replace actual customer data?**
No. The CSM subagent provides frameworks, templates, and analytical structure. You need to bring actual customer data (login metrics, support tickets, NPS scores, etc.) for it to produce meaningful deliverables. Think of it as the CSM's playbook and methodology, not a data warehouse.

**Q: How does it handle multi-cloud customers?**
The health score model, adoption scorecard, and expansion map are all designed for multi-cloud environments. Each cloud/product gets its own adoption tracking while the composite health score provides a unified view.

**Q: What's the relationship between the CSM and Value Engineer subagents?**
The CSM delegates ROI calculation and value framework work to `sf-value-engineer`. The CSM focuses on relationship and adoption; the Value Engineer focuses on financial modeling and business case quantification. The CSM provides the adoption data that the Value Engineer uses to calculate realized value.
