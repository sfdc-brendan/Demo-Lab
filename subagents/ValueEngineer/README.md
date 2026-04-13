# Value Engineer Subagent

> A quantitative AI advisor for **Cursor** and **Claude Code** that builds defensible business cases, ROI models, TCO comparisons, and value realization frameworks for Salesforce investments.

---

## Table of Contents

- [What Is This?](#what-is-this)
- [Why a Value Engineer Subagent?](#why-a-value-engineer-subagent)
- [How It Pairs with DSE and SE](#how-it-pairs-with-dse-and-se)
- [What It Does](#what-it-does)
- [Deployment](#deployment)
  - [Option 1: One-Liner Install](#option-1-one-liner-install-recommended)
  - [Option 2: Clone and Install](#option-2-clone-and-install)
  - [Option 3: Manual Copy](#option-3-manual-copy)
- [Verifying the Install](#verifying-the-install)
- [Using the Value Engineer](#using-the-value-engineer)
  - [ROI Models](#1-roi-models)
  - [TCO Comparisons](#2-tco-comparisons)
  - [Business Case Documents](#3-business-case-documents)
  - [Value Realization Dashboards](#4-value-realization-dashboards)
  - [Benchmark Comparisons](#5-benchmark-comparisons)
  - [Cost of Inaction](#6-cost-of-inaction)
  - [Scoring Deliverables](#7-scoring-deliverables)
- [How It Integrates with Other Skills](#how-it-integrates-with-other-skills)
- [File Reference](#file-reference)
- [Updating](#updating)
- [Uninstalling](#uninstalling)
- [FAQ](#faq)

---

## What Is This?

This is a **subagent** — a skill file that teaches Claude (in Cursor or Claude Code) how to operate as a Salesforce Value Engineer. When installed, it gives your AI assistant the financial modeling methodology, industry benchmarks, and business case frameworks needed to quantify Salesforce investments.

A Value Engineer is the person who puts numbers behind the narrative:

> The DSE says "this will transform your customer experience." The Value Engineer says "this will save $4.2M annually by reducing handle time 23%."

This subagent encodes that operating model — conservative methodology, transparent math, industry-specific benchmarks, and CFO-ready formatting.

---

## Why a Value Engineer Subagent?

Strategic conversations without numbers are opinions. ROI claims without methodology are wishful thinking. The Value Engineer fills the gap between "this is a great solution" and "here's why the CFO should fund it."

The Value Engineer subagent:

- **Quantifies every claim.** No "significant improvement" — only "$1.8M annual savings from 34% AHT reduction." Every number traces back to a baseline, an assumption, a source, and a formula.
- **Uses conservative estimates.** Rounds down, applies risk adjustments, leads with the low end of benchmark ranges. Business cases that survive CFO scrutiny are worth more than inflated projections that get rejected.
- **Shows all the math.** Every deliverable includes a methodology appendix. If someone asks "where did that number come from?" the answer is one sentence away.
- **Benchmarks by industry.** A telecom's handle time is different from a bank's. A retailer's churn economics are different from a SaaS company's. The Value Engineer uses industry-specific data.
- **Tracks realization.** A business case that only exists in the sales cycle is a broken promise. The Value Engineer defines the KPIs, baselines, targets, and dashboards to prove value was delivered.

---

## How It Pairs with DSE and SE

The Value Engineer is designed to work alongside the DSE and SE subagents. Each plays a distinct role:

| Role | What They Do | Example Output |
|---|---|---|
| **DSE** (sf-dse) | Frames the strategic narrative — business outcomes, architecture vision, executive engagement | "Your unified customer data strategy will transform how you compete on experience." |
| **Value Engineer** (sf-value-engineer) | Quantifies the narrative — ROI models, TCO, benchmarks, financial justification | "That strategy will deliver $6.2M NPV over 3 years with a 14-month payback, driven by 28% handle time reduction and 15% churn reduction." |
| **SE** (sf-se) | Executes the deal — demos, proof of concept, technical validation | "Here's the live demo showing Agentforce resolving 45% of cases autonomously with a 92% CSAT score." |

**Typical flow**: DSE designs the strategic narrative → Value Engineer quantifies the business case → SE demonstrates the solution → Value Engineer tracks realization post-implementation.

---

## What It Does

The Value Engineer produces six types of financial deliverables.

| Deliverable | What You Get | When to Use It |
|---|---|---|
| **ROI Model** | 3-year cash flow with NPV, payback, IRR, sensitivity analysis, and three scenarios (conservative/expected/optimistic) | Justifying a Salesforce investment to a CFO or procurement team |
| **TCO Comparison** | Side-by-side total cost analysis: Salesforce vs. incumbent vs. status quo, including hidden costs and platform consolidation | Competitive displacement or vendor selection decisions |
| **Business Case Document** | Executive-ready document with quantified pain points, benefit categories, risk-adjusted ROI, and implementation timeline | Formal investment approval process |
| **Value Realization Dashboard Spec** | KPI definitions, baselines, targets, data sources, and layout for tracking actual vs. projected value | Post-implementation value tracking and proof |
| **Benchmark Comparison** | Industry-specific performance comparison with gap analysis, financial impact, and maturity model | Establishing urgency and quantifying improvement potential |
| **Cost of Inaction** | Compounding cost model showing what happens at 12/24/36 months if nothing changes — labor inflation, competitive erosion, opportunity cost | Overcoming "do nothing" inertia |

---

## Deployment

### Prerequisites

- **Cursor** (any version with skills support) and/or **Claude Code** (any version with skills support)
- A terminal with `bash`, `curl`, and `git` available (macOS and Linux have these by default)

### Where It Installs

| Platform | Install Path |
|---|---|
| Cursor | `~/.cursor/skills/sf-value-engineer/` |
| Claude Code | `~/.claude/skills/sf-value-engineer/` |

---

### Option 1: One-Liner Install (Recommended)

No clone required. Run one command in your terminal.

**Install for both Cursor and Claude Code:**

```bash
curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/ValueEngineer/install.sh | bash -s -- --both
```

**Install for Cursor only:**

```bash
curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/ValueEngineer/install.sh | bash -s -- --cursor
```

**Install for Claude Code only:**

```bash
curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/ValueEngineer/install.sh | bash -s -- --claude
```

You should see output like:

```
╔════════════════════════════════════════════════════════╗
║  Salesforce Value Engineer Subagent                   ║
║  ROI, TCO & business case quantification             ║
╚════════════════════════════════════════════════════════╝

  ✓ Installed to /Users/you/.cursor/skills/sf-value-engineer (Cursor)
  ✓ Installed to /Users/you/.claude/skills/sf-value-engineer (Claude Code)

Done! The Value Engineer subagent will auto-activate when you:
  • Build ROI models, TCO comparisons, or business cases
  • Need benchmark comparisons or cost-of-inaction analysis
  • Create value realization dashboards or executive justification
```

---

### Option 2: Clone and Install

If you prefer to inspect the files first or already have the repo cloned:

```bash
git clone https://github.com/sfdc-brendan/Demo-Lab.git
cd Demo-Lab/subagents/ValueEngineer
chmod +x install.sh
./install.sh --both
```

---

### Option 3: Manual Copy

If you'd rather handle it yourself:

**For Cursor:**

```bash
mkdir -p ~/.cursor/skills/sf-value-engineer/references

curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/ValueEngineer/SKILL.md \
  -o ~/.cursor/skills/sf-value-engineer/SKILL.md

curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/ValueEngineer/references/deliverables-guide.md \
  -o ~/.cursor/skills/sf-value-engineer/references/deliverables-guide.md

curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/ValueEngineer/references/value-frameworks.md \
  -o ~/.cursor/skills/sf-value-engineer/references/value-frameworks.md
```

**For Claude Code:**

```bash
mkdir -p ~/.claude/skills/sf-value-engineer/references

curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/ValueEngineer/SKILL.md \
  -o ~/.claude/skills/sf-value-engineer/SKILL.md

curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/ValueEngineer/references/deliverables-guide.md \
  -o ~/.claude/skills/sf-value-engineer/references/deliverables-guide.md

curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/ValueEngineer/references/value-frameworks.md \
  -o ~/.claude/skills/sf-value-engineer/references/value-frameworks.md
```

---

## Verifying the Install

After installing, verify the files are in place:

```bash
# For Cursor
ls -la ~/.cursor/skills/sf-value-engineer/
ls -la ~/.cursor/skills/sf-value-engineer/references/

# For Claude Code
ls -la ~/.claude/skills/sf-value-engineer/
ls -la ~/.claude/skills/sf-value-engineer/references/
```

You should see three files:

```
sf-value-engineer/
├── SKILL.md
└── references/
    ├── deliverables-guide.md
    └── value-frameworks.md
```

To confirm the skill is loaded, open Cursor or Claude Code and try:

> "Build an ROI model for Service Cloud replacing a legacy ticketing system at a mid-market telecom."

The agent should respond with financial modeling structure (investment costs, benefit categories, NPV calculation) rather than jumping to product configuration.

---

## Using the Value Engineer

Below are example prompts for each capability, along with what you can expect.

### 1. ROI Models

**Example prompts:**

> "Build an ROI model for Service Cloud + Agentforce replacing a legacy IVR system at a Tier 2 telecom with 500 agents and 2M annual interactions."

> "Create a 3-year ROI model for Data Cloud + Marketing Cloud at a retail bank with 5M customers. They currently use a CDP from a competitor and Marketo for campaigns."

> "Model the ROI of Agentforce for a healthcare payer handling 3M member calls annually. Average handle time is 11 minutes at $18/hour loaded cost."

**What you get:** A complete financial model with:
- Investment breakdown (licensing, implementation, training, ongoing operations)
- Benefits by category with methodology for each calculation
- 3-year cash flow with quarterly Year 1 granularity
- NPV at customer's discount rate, payback period, IRR
- Sensitivity analysis on top 3 assumptions with break-even thresholds
- Conservative, expected, and optimistic scenarios

---

### 2. TCO Comparisons

**Example prompts:**

> "Compare TCO for Salesforce Service Cloud vs. Zendesk vs. status quo (homegrown system) for a 200-agent contact center over 3 years."

> "Build a TCO comparison for Sales Cloud + Revenue Cloud vs. HubSpot Enterprise for a SaaS company with 150 reps."

**What you get:** A side-by-side comparison including:
- Licensing and subscription costs normalized to the same scope
- Implementation costs (professional services, migration, integration, training)
- Ongoing operations (admin FTEs, developer FTEs, support, upgrades)
- Hidden costs (opportunity cost, technical debt, talent premium, EOL risk)
- Cost per user, per transaction, or per customer served
- Platform consolidation opportunities

---

### 3. Business Case Documents

**Example prompts:**

> "Write a business case for implementing Sales Cloud + Data Cloud at a manufacturing company that currently runs SAP CRM with spreadsheet-based forecasting."

> "Create an executive business case for Agentforce at a financial services firm. The CFO needs hard savings to approve — focus on headcount avoidance and license consolidation."

**What you get:** A formal business case with:
- One-page executive summary (problem, solution, impact, recommendation)
- Current state with quantified costs and pain points
- Benefit categories separated by confidence level (hard savings, productivity, revenue)
- Risk-adjusted ROI with implementation timeline
- Risk assessment with mitigation strategies
- Methodology appendix

---

### 4. Value Realization Dashboards

**Example prompts:**

> "Spec a value realization dashboard for a Service Cloud + Agentforce implementation. The business case projected $2.4M in annual savings from case deflection and handle time reduction."

> "Design a post-implementation KPI tracking framework for a Data Cloud deployment at a retail company. We promised improved personalization and reduced CAC."

**What you get:** A complete dashboard specification with:
- KPIs mapped to business case benefit categories
- Baseline measurements with data sources
- Targets at 6-month, 12-month, and 24-month milestones
- Executive view (headline KPIs with trends) and operational view (detail with drill-down)
- Value scorecard comparing actuals to projections
- Alerting rules for KPIs trending below target

---

### 5. Benchmark Comparisons

**Example prompts:**

> "Compare a telecom's service metrics against industry benchmarks. Their AHT is 11.5 minutes, FCR is 58%, NPS is 22, and cost per contact is $10.50."

> "Build a benchmark comparison for a mid-market bank's sales organization. They have a 45-day average sales cycle, 18% win rate, and $85K quota attainment average."

**What you get:** An industry-contextualized comparison with:
- Customer's current performance vs. bottom quartile, median, and top quartile
- Financial impact of each gap (what the gap costs annually)
- Salesforce capabilities mapped to each gap with expected improvement
- Maturity model showing current state, target state, and leadership state
- Prioritized improvement roadmap by financial impact and effort

---

### 6. Cost of Inaction

**Example prompts:**

> "Create a cost-of-inaction analysis for a company still using spreadsheets for pipeline management. They have 80 reps, $200M pipeline, and 22% win rate."

> "Model what happens if a healthcare payer doesn't modernize their member service platform over the next 3 years. They're on a 15-year-old homegrown system with 400 agents."

**What you get:** A compounding cost model showing:
- Year-by-year cost trajectory (labor inflation, system maintenance, competitive erosion)
- Competitive risk assessment (what competitors gain while they wait)
- Opportunity cost of deferred capabilities
- Talent risk on legacy systems
- Cumulative "doing nothing tax" — total cost of inaction at 12, 24, and 36 months
- Comparison of inaction cost to proposed investment

---

### 7. Scoring Deliverables

After any deliverable is produced, you can request a quality score:

> "Score this ROI model against the Value Engineer rubric."

It evaluates on a 100-point scale:

| Category | Points | What It Measures |
|---|---|---|
| Quantitative Rigor | 25 | Calculations backed, assumptions documented, sensitivity included |
| Methodology Transparency | 25 | Sources cited, formulas shown, risk adjustments explained |
| Industry Relevance | 20 | Benchmarks specific to industry, KPIs match vertical norms |
| Executive Readiness | 15 | CFO-ready formatting, exec summary, clear recommendation |
| Conservatism | 15 | Low-end estimates, risk adjustments, break-even analysis |

| Score Range | Meaning |
|---|---|
| 85–100 | CFO-ready — defensible under scrutiny |
| 70–84 | Strong model — needs tighter assumptions or sources |
| 50–69 | Good structure — needs more rigorous quantification |
| Below 50 | Rethink methodology and data foundations |

---

## How It Integrates with Other Skills

The Value Engineer puts numbers behind other skills' work and receives inputs from them:

| When the Value Engineer needs... | It works with... | How |
|---|---|---|
| Strategic narrative for the numbers | `sf-dse` | DSE provides qualitative story; Value Engineer adds quantitative proof |
| Deal-specific financial justification | `sf-se` | SE owns the deal; Value Engineer arms them with ROI |
| Post-implementation KPIs | `sf-ba` | BA defines success criteria; Value Engineer defines financial targets |
| Dashboard SOQL queries | `sf-soql` | Value realization dashboards need data queries |
| Solution architecture for costing | `sf-sa` | SA defines the solution scope; Value Engineer costs it |
| Implementation effort estimates | `sf-apex` | Development effort feeds investment cost modeling |

If those skills aren't installed, the Value Engineer still produces all financial deliverables — it just won't have specialized support for architecture costing or query generation.

---

## File Reference

```
subagents/ValueEngineer/
├── README.md                            ← You are here
├── SKILL.md                             ← Core skill (loaded into AI context)
├── install.sh                           ← Deployment script
└── references/
    ├── deliverables-guide.md            ← Full templates for all 6 deliverable types
    └── value-frameworks.md              ← Value drivers, benchmarks, ROI methodology, objection handling
```

| File | Purpose |
|---|---|
| `SKILL.md` | Core identity, operating principles, deliverable workflows, financial modeling standards, scoring rubric, cross-skill delegation. Always loaded when the skill activates. |
| `references/deliverables-guide.md` | Detailed markdown templates for ROI models, TCO comparisons, business cases, value realization dashboards, benchmark comparisons, and cost-of-inaction analyses. Loaded on-demand. |
| `references/value-frameworks.md` | Salesforce value drivers by cloud, industry benchmark ranges (telecom, FSI, healthcare, retail, manufacturing), ROI calculation methodology, value selling conversation framework, executive objection handling, and value realization tracking patterns. Loaded on-demand. |

---

## Updating

To update to the latest version, re-run the install command:

```bash
curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/ValueEngineer/install.sh | bash -s -- --both
```

You'll see:

```
  Existing install found at /Users/you/.cursor/skills/sf-value-engineer — updating...
  ✓ Installed to /Users/you/.cursor/skills/sf-value-engineer (Cursor)
```

---

## Uninstalling

```bash
# Cursor
rm -rf ~/.cursor/skills/sf-value-engineer

# Claude Code
rm -rf ~/.claude/skills/sf-value-engineer
```

---

## FAQ

**Q: Do I need the DSE or SE subagents installed for this to work?**
No. The Value Engineer works standalone. When paired with DSE and SE, it creates a complete deal team: strategy (DSE) + numbers (Value Engineer) + execution (SE). Without them, it still produces all financial deliverables.

**Q: Where do the benchmarks come from?**
The `references/value-frameworks.md` file contains industry benchmark ranges based on published sources (analyst reports, Salesforce customer data, industry associations). Benchmarks are presented as ranges and should be validated against customer-specific data whenever possible.

**Q: Can I customize the benchmark data?**
Yes. Edit `~/.cursor/skills/sf-value-engineer/references/value-frameworks.md` directly. Add your own industry benchmarks, adjust ranges based on your experience, or add new verticals. Changes persist until you re-run the installer.

**Q: Will it give me exact numbers for a customer?**
No. The Value Engineer provides methodology, frameworks, and benchmark-informed estimates. It will clearly distinguish between numbers from customer data and numbers from benchmark assumptions. Every model is designed to be refined with the customer's actual data.

**Q: What if I don't have any customer data yet?**
The Value Engineer can build a benchmark-based model using industry data and company-profile proxies (revenue, employee count, customer base). It will flag every assumption that needs validation. This is a starting point for a value conversation, not a final business case.

**Q: Does the scoring actually work?**
Yes. Ask "Score this against the Value Engineer rubric" after any deliverable. It evaluates against the 100-point rubric and provides specific feedback on what to improve. It's most useful for ensuring methodology rigor and executive readiness before sharing externally.

**Q: How does this differ from the DSE subagent?**
The DSE thinks qualitatively — strategic narrative, architecture vision, executive engagement. The Value Engineer thinks quantitatively — financial models, benchmark data, NPV calculations. The DSE says "this will transform your business." The Value Engineer says "here's the $4.2M proof." They are complementary, not competing.
