# Salesforce Solution Architect (SA) Subagent

> An AI assistant for **Cursor** and **Claude Code** that owns the technical design layer — translating business requirements into buildable, scalable, maintainable Salesforce platform blueprints.

---

## Table of Contents

- [What Is This?](#what-is-this)
- [Why an SA Subagent?](#why-an-sa-subagent)
- [What It Does](#what-it-does)
- [How It Works](#how-it-works)
- [Deployment](#deployment)
  - [Option 1: One-Liner Install](#option-1-one-liner-install-recommended)
  - [Option 2: Clone and Install](#option-2-clone-and-install)
  - [Option 3: Manual Copy](#option-3-manual-copy)
- [Verifying the Install](#verifying-the-install)
- [Using the SA Subagent](#using-the-sa-subagent)
  - [Solution Design Documents](#1-solution-design-documents)
  - [Data Model Architecture](#2-data-model-architecture)
  - [Integration Architecture](#3-integration-architecture)
  - [Technical Decision Logs](#4-technical-decision-logs)
  - [Build vs Buy Analysis](#5-build-vs-buy-analysis)
  - [Environment Strategy](#6-environment-strategy)
  - [Scoring Deliverables](#7-scoring-deliverables)
- [How It Integrates with Other Skills](#how-it-integrates-with-other-skills)
- [File Reference](#file-reference)
- [Updating](#updating)
- [Uninstalling](#uninstalling)
- [FAQ](#faq)

---

## What Is This?

This is a **subagent** — a skill file that teaches Claude (in Cursor or Claude Code) how to operate as a Salesforce Solution Architect. When installed, it gives your AI assistant the frameworks, templates, and decision models of an SA who translates business requirements into platform blueprints.

A Salesforce Solution Architect:

> Owns *how* the Salesforce platform is structured to meet requirements. Designs data models, integration architectures, security models, automation strategies, and environment plans that are buildable, scalable, and maintainable.

The SA sits between strategy (DSE) and requirements (BA) — turning the "what" into a buildable "how." This subagent encodes that technical design authority.

---

## Why an SA Subagent?

AI coding assistants are good at writing code, but they don't naturally think in architecture. They'll build the component you asked for without asking whether the data model supports it, whether the integration pattern is sustainable, or whether the security model will break at scale.

The SA subagent fills that gap:

- **Thinks in data model first.** Before designing automation, it designs the objects, relationships, and sharing model that the automation depends on.
- **Declarative first, custom only when justified.** It starts every decision with the simplest correct pattern and escalates to custom code only with documented rationale.
- **Designs for scale, security, and maintainability.** Every design is evaluated: will it handle 10x growth, protect data properly, and make sense to a new team member in six months?
- **Documents decisions with rationale.** It doesn't just record what was decided — it records why, what alternatives were considered, and when the decision should be revisited.
- **Validates feasibility before committing.** It checks governor limits, licensing constraints, and implementation capacity before locking a design.
- **Knows when to delegate.** It doesn't write Apex or build LWCs — it creates the blueprint that developers implement.

---

## What It Does

The SA subagent produces six types of technical deliverables.

### Deliverables

| Deliverable | What You Get | When to Use It |
|---|---|---|
| **Solution Design Document** | End-to-end technical blueprint covering data model, automation, integration, security, migration, and risks | Starting the design phase of a project or feature area |
| **Data Model Diagram** | Object inventory, field specs, relationships with rationale, record types, sharing rules, storage estimates, ERD | Designing or reviewing the data foundation for a solution |
| **Integration Architecture** | Integration inventory, pattern selection with rationale, error handling, monitoring, API limit budgets | Designing connections between Salesforce and external systems |
| **Technical Decision Log** | ADR-format entries with options evaluated, chosen option, rationale, trade-offs, and review triggers | Any technical decision that has multiple valid approaches |
| **Build vs Buy Analysis** | Comparison of declarative, custom, and AppExchange options with weighted scoring matrix and recommendation | Evaluating how to implement a specific capability |
| **Environment Strategy** | Org topology, sandbox plan, CI/CD pipeline, data seeding, release cadence, rollback strategy | Planning the development and deployment infrastructure |

### RACI Boundaries

The SA knows what it leads and what it defers:

| Task | SA Role | Who Else Leads |
|---|---|---|
| Solution design | **Leads** | BA consulted, Dev informed |
| Data model architecture | **Leads** | BA consulted, Admin supports |
| Integration architecture | **Leads** | Dev consulted, BA informed |
| Technical decisions | **Leads** | Dev consulted, DSE consulted on strategy |
| Technical feasibility | **Leads** | Dev supports |
| Environment strategy | **Leads** | DevOps supports |
| Requirements gathering | Consulted | BA leads |
| Strategic architecture | Consulted | DSE leads |
| Code implementation | Informed | Dev leads |

---

## How It Works

### The Skill System

Both Cursor and Claude Code support **skills** — markdown files that teach the AI assistant how to perform specific tasks. The SA subagent consists of:

| File | Purpose |
|---|---|
| `SKILL.md` | Core instructions — identity, operating principles, deliverable workflows, RACI, scoring rubric, cross-skill delegation |
| `references/deliverables-guide.md` | Full templates for all six deliverable types (loaded on-demand) |
| `references/design-patterns.md` | Salesforce-specific architecture patterns: declarative-first decisions, data model patterns, integration patterns, security model, multi-cloud, governor limits (loaded on-demand) |

### When It Activates

The subagent activates automatically when your prompt matches its trigger patterns:

- Designing a **solution architecture** or technical blueprint
- Modeling **data** (objects, fields, relationships, sharing)
- Planning **integrations** between Salesforce and external systems
- Making **technical decisions** (declarative vs. custom, build vs. buy)
- Defining **environment strategy** (sandboxes, CI/CD, release cadence)
- Evaluating **technical feasibility** of requirements
- Reviewing an existing **solution design** for soundness

It will **not** activate for strategic work (executive briefings, GTM plays), requirements work (user stories, UAT plans), or implementation work (writing Apex, building LWCs, deploying metadata).

### What Changes When the SA Is Active

| Without SA | With SA |
|---|---|
| "Here's the Apex trigger for case assignment" | "First, let's validate the data model supports your assignment criteria, then decide if this is a Flow or Apex pattern" |
| Jumps to building a component | Designs the object model, automation approach, and security before building |
| One integration at a time | Creates an integration inventory, selects patterns per integration, plans error handling holistically |
| Implicit technical decisions | Explicit decision log with options, rationale, and trade-offs |

---

## Deployment

### Prerequisites

- **Cursor** (any version with skills support) and/or **Claude Code** (any version with skills support)
- A terminal with `bash`, `curl`, and `git` (macOS and Linux have these by default)

### Where It Installs

| Platform | Install Path |
|---|---|
| Cursor | `~/.cursor/skills/sf-sa/` |
| Claude Code | `~/.claude/skills/sf-sa/` |

The skill content is identical for both platforms. Only the directory differs.

---

### Option 1: One-Liner Install (Recommended)

No clone required. Run one command in your terminal.

**Install for both Cursor and Claude Code:**

```bash
curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/SA/install.sh | bash -s -- --both
```

**Install for Cursor only:**

```bash
curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/SA/install.sh | bash -s -- --cursor
```

**Install for Claude Code only:**

```bash
curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/SA/install.sh | bash -s -- --claude
```

You should see output like:

```
╔════════════════════════════════════════════════════════╗
║  Salesforce Solution Architect (SA) Subagent          ║
║  Technical design & platform architecture             ║
╚════════════════════════════════════════════════════════╝

  ✓ Installed to /Users/you/.cursor/skills/sf-sa (Cursor)
  ✓ Installed to /Users/you/.claude/skills/sf-sa (Claude Code)

Done! The SA subagent will auto-activate when you:
  • Design solution architectures or data models
  • Plan integrations or evaluate build-vs-buy options
  • Make declarative-vs-custom technical decisions
  • Define environment strategy or CI/CD pipelines
```

---

### Option 2: Clone and Install

If you prefer to inspect the files first or already have the repo cloned:

```bash
git clone https://github.com/sfdc-brendan/Demo-Lab.git
cd Demo-Lab/subagents/SA
chmod +x install.sh
./install.sh --both
```

---

### Option 3: Manual Copy

If you'd rather handle it yourself:

**For Cursor:**

```bash
mkdir -p ~/.cursor/skills/sf-sa/references

curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/SA/SKILL.md \
  -o ~/.cursor/skills/sf-sa/SKILL.md

curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/SA/references/deliverables-guide.md \
  -o ~/.cursor/skills/sf-sa/references/deliverables-guide.md

curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/SA/references/design-patterns.md \
  -o ~/.cursor/skills/sf-sa/references/design-patterns.md
```

**For Claude Code:**

```bash
mkdir -p ~/.claude/skills/sf-sa/references

curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/SA/SKILL.md \
  -o ~/.claude/skills/sf-sa/SKILL.md

curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/SA/references/deliverables-guide.md \
  -o ~/.claude/skills/sf-sa/references/deliverables-guide.md

curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/SA/references/design-patterns.md \
  -o ~/.claude/skills/sf-sa/references/design-patterns.md
```

---

## Verifying the Install

After installing, verify the files are in place:

```bash
# For Cursor
ls -la ~/.cursor/skills/sf-sa/
ls -la ~/.cursor/skills/sf-sa/references/

# For Claude Code
ls -la ~/.claude/skills/sf-sa/
ls -la ~/.claude/skills/sf-sa/references/
```

You should see three files:

```
sf-sa/
├── SKILL.md
└── references/
    ├── deliverables-guide.md
    └── design-patterns.md
```

To confirm the skill is loaded, open Cursor or Claude Code and try a prompt like:

> "I need to design the data model and integration architecture for a customer onboarding process in Service Cloud."

The agent should begin by asking about objects, relationships, external systems, and data volumes — not by jumping to building a Flow or writing Apex.

---

## Using the SA Subagent

Below are example prompts for each capability, along with what you can expect the agent to produce.

### 1. Solution Design Documents

**Example prompts:**

> "Design a solution for automating the lead-to-opportunity process. We have three regions, each with different qualification criteria, and we need to integrate with Marketo for lead scoring."

> "Create a solution design for a Service Cloud implementation. We need case routing, escalation, entitlements, and a customer portal on Experience Cloud."

**What you get:** An end-to-end blueprint with:
- Scope boundaries (in, out, deferred)
- Data model with ERD
- Automation design (Flow vs. Apex decisions per process)
- Integration architecture per external system
- Security model (OWD, sharing rules, FLS)
- Migration strategy if applicable
- Technical risk register with mitigations
- Sign-off section

---

### 2. Data Model Architecture

**Example prompts:**

> "Design the data model for a project management system on Salesforce. Projects have tasks, tasks have resources, and we need to track time entries."

> "Review our current Case data model. We're hitting performance issues with 5 million cases and need to plan for 20 million over the next two years."

**What you get:** A complete data model specification with:
- Object inventory (standard extended + custom)
- Field specifications with types and validation
- Relationship rationale (lookup vs. master-detail)
- Junction objects for many-to-many relationships
- Record types with business context
- Sharing rules and FLS design
- Storage estimates and LDV strategy
- ERD diagram

---

### 3. Integration Architecture

**Example prompts:**

> "We need to integrate Salesforce with SAP for order management, Workday for employee data, and DocuSign for contract signatures. Design the integration architecture."

> "Our current integration uses batch CSV uploads nightly. The business wants near-real-time sync. Design the migration from batch to event-driven."

**What you get:** A comprehensive integration architecture with:
- System context diagram
- Integration inventory (source, target, direction, pattern, frequency, volume)
- Pattern selection rationale per integration
- Error handling and retry strategy per integration
- Authentication strategy
- API limit budget analysis
- Monitoring and alerting design

---

### 4. Technical Decision Logs

**Example prompts:**

> "We need to decide whether case assignment should be done with assignment rules, a Flow, or custom Apex. Document the options."

> "The team is debating between using Platform Events and CDC for syncing Account changes to our data warehouse. Help us make the decision."

**What you get:** ADR-format decision records with:
- Context and constraints
- All options evaluated with pros/cons
- Chosen option with clear rationale
- Trade-offs accepted and why they're acceptable
- Stakeholders consulted
- Review trigger (when to revisit the decision)

---

### 5. Build vs Buy Analysis

**Example prompts:**

> "We need document generation for contracts. Should we build it with Apex/LWC, use Flows with email templates, or buy an AppExchange package like Conga or Nintex?"

> "The business wants a scheduling capability for field service. Evaluate declarative, custom, and AppExchange options."

**What you get:** A structured analysis with:
- Requirement summary
- Detailed evaluation of each option (declarative, custom, AppExchange)
- Weighted comparison matrix (time, cost, maintainability, scalability, coverage, risk)
- Clear recommendation with rationale
- Conditions under which the recommendation would change

---

### 6. Environment Strategy

**Example prompts:**

> "We're starting a new Salesforce implementation with Sales Cloud and Service Cloud. Design the environment strategy — sandboxes, CI/CD, release process."

> "We have 8 sandboxes and no consistent deployment process. Help us rationalize our environment strategy."

**What you get:** A complete environment plan with:
- Org topology rationale
- Sandbox plan (types, purposes, naming, refresh cadence)
- CI/CD pipeline design (source control, branching, pipeline stages)
- Data seeding approach per environment
- Release cadence with deployment windows
- Rollback strategy
- Salesforce release alignment approach

---

### 7. Scoring Deliverables

After the agent produces any deliverable, you can ask it to score the output:

> "Score this solution design against the SA rubric."

It evaluates on a 100-point scale:

| Category | Points | What It Measures |
|---|---|---|
| Technical Soundness | 25 | Correct patterns, governor-limit awareness, no anti-patterns, platform feasibility |
| Platform Alignment | 20 | Declarative-first, standard objects leveraged, AppExchange considered |
| Scalability | 20 | 10x growth handling, LDV strategy, async patterns, performance |
| Maintainability | 20 | Understandable by new team, documented decisions, separation of concerns |
| Documentation Quality | 15 | Complete deliverables, rationale captured, diagrams, risks identified |

| Score Range | Meaning |
|---|---|
| 85–100 | Build-ready — proceed to implementation |
| 70–84 | Strong foundation — minor design refinement needed |
| 50–69 | Good direction — needs architectural review before build |
| Below 50 | Revisit requirements understanding and design approach |

---

## How It Integrates with Other Skills

The SA subagent is the technical design authority. It creates blueprints and delegates implementation to specialized skills:

| When the SA designs... | Implementation goes to... |
|---|---|
| Data model (objects, fields, relationships) | `sf-metadata` |
| Declarative automation (Flows) | `sf-flow` |
| Custom automation (Apex) | `sf-apex` |
| UI components | `sf-lwc` |
| Integration patterns | `sf-integration` |
| Data Cloud architecture | `sf-datacloud` |
| Environment and CI/CD | `sf-deploy` |
| Architecture diagrams (ERDs, sequence diagrams) | `sf-diagram-mermaid` |
| SOQL query design | `sf-soql` |
| Agentforce agent design | `sf-ai-agentforce` |

The SA also pairs with the **DSE** and **BA** subagents:

| Relationship | How They Work Together |
|---|---|
| **DSE → SA** | DSE provides strategic architecture vision and cross-cloud direction. SA translates that into buildable technical designs. |
| **BA → SA** | BA provides documented requirements with acceptance criteria. SA designs the platform solution that meets those requirements. |
| **SA → Dev** | SA provides technical blueprints. Developers implement using `sf-apex`, `sf-lwc`, `sf-flow`, and other implementation skills. |

---

## File Reference

```
subagents/SA/
├── README.md                              ← You are here
├── SKILL.md                               ← Core skill (loaded into AI context)
├── install.sh                             ← Deployment script
└── references/
    ├── deliverables-guide.md              ← Templates for all 6 deliverable types
    └── design-patterns.md                 ← Salesforce architecture patterns and decision frameworks
```

| File | Lines | Purpose |
|---|---|---|
| `SKILL.md` | ~225 | Core identity, operating principles, RACI, deliverable workflows, scoring rubric, cross-skill delegation. Always loaded when the skill activates. |
| `references/deliverables-guide.md` | ~340 | Detailed templates for solution design docs, data models, integration architectures, decision logs, build-vs-buy analyses, and environment strategies. Loaded on-demand. |
| `references/design-patterns.md` | ~280 | Declarative-first decision tree, data model patterns (lookup vs. master-detail, junction objects, polymorphic keys, big objects), integration patterns (request-reply, fire-and-forget, batch, pub-sub, MuleSoft), security model patterns, multi-cloud architecture, governor limit awareness. Loaded on-demand. |

---

## Updating

To update to the latest version, re-run the install command. The installer detects an existing installation and replaces it:

```bash
curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/SA/install.sh | bash -s -- --both
```

You'll see:

```
  Existing install found at /Users/you/.cursor/skills/sf-sa — updating...
  ✓ Installed to /Users/you/.cursor/skills/sf-sa (Cursor)
```

---

## Uninstalling

```bash
# Cursor
rm -rf ~/.cursor/skills/sf-sa

# Claude Code
rm -rf ~/.claude/skills/sf-sa
```

---

## FAQ

**Q: Do I need the DSE or BA subagents installed for this to work?**
No. The SA works standalone. If you also have `sf-dse` and `sf-ba` installed, they form a natural chain: DSE (strategy) → SA (technical design) → BA (requirements) → implementation skills (code). Each works independently, but together they cover the full lifecycle.

**Q: Will this conflict with my other Salesforce skills?**
No. The SA has clear RACI boundaries. It only activates for solution design, data modeling, integration architecture, technical decisions, and environment strategy. Implementation tasks (Apex, LWC, Flows, metadata deployment) are handled by their respective skills.

**Q: Can I customize the templates?**
Yes. After installing, edit the files directly at `~/.cursor/skills/sf-sa/` or `~/.claude/skills/sf-sa/`. Changes persist until you re-run the installer (which overwrites).

**Q: What Salesforce clouds/products does it cover?**
All of them. The SA designs solutions across Sales Cloud, Service Cloud, Marketing Cloud, Commerce Cloud, Data Cloud, MuleSoft, Experience Cloud, Revenue Cloud, Agentforce, and Industries clouds. The data model, integration, and security patterns apply regardless of cloud.

**Q: Does it work on Windows?**
The skill files work on any platform. The `install.sh` script requires bash (available on macOS, Linux, and Windows via WSL or Git Bash). For native Windows without bash, use the [Manual Copy](#option-3-manual-copy) method with PowerShell equivalents.

**Q: How is this different from the DSE subagent?**
The DSE thinks at strategic altitude — executive briefings, cross-cloud architecture narratives, GTM plays. The SA thinks at technical design altitude — data models, integration patterns, security models, build-vs-buy decisions. The DSE asks "why should the CIO care?" The SA asks "will this data model support the requirement at scale?"

**Q: How is this different from the BA subagent?**
The BA owns the "what" — requirements, user stories, acceptance criteria, process maps. The SA owns the "how" — data model, integration architecture, automation approach, environment strategy. The BA asks "what does the business need?" The SA asks "how do we build it on the platform?"

**Q: When should I use the SA vs. just asking for code?**
Use the SA when the solution touches multiple objects, integrations, or when you're making design decisions that affect the long-term architecture. Skip straight to implementation skills for isolated, well-understood tasks (adding a field, writing a simple trigger, building a single Flow).
