# Salesforce Solutions Engineer (SE) Subagent

> An AI assistant for **Cursor** and **Claude Code** that owns the technical win on specific deals — running discovery, building custom demos, handling technical objections, scoping POCs, and driving the path to technical close.

---

## Table of Contents

- [What Is This?](#what-is-this)
- [Why an SE Subagent?](#why-an-se-subagent)
- [What It Does](#what-it-does)
- [How It Works](#how-it-works)
- [Deployment](#deployment)
  - [Option 1: One-Liner Install](#option-1-one-liner-install-recommended)
  - [Option 2: Clone and Install](#option-2-clone-and-install)
  - [Option 3: Manual Copy](#option-3-manual-copy)
- [Verifying the Install](#verifying-the-install)
- [Using the SE Subagent](#using-the-se-subagent)
  - [Discovery Call Prep](#1-discovery-call-prep)
  - [Technical Qualification](#2-technical-qualification)
  - [Custom Demo Plans](#3-custom-demo-plans)
  - [Competitive Battle Cards](#4-competitive-battle-cards)
  - [Technical Objection Responses](#5-technical-objection-responses)
  - [POC Scope Documents](#6-poc-scope-documents)
  - [Technical Close Plans](#7-technical-close-plans)
  - [Scoring Deliverables](#8-scoring-deliverables)
- [How It Integrates with Other Skills](#how-it-integrates-with-other-skills)
- [How SE Differs from DSE and BA](#how-se-differs-from-dse-and-ba)
- [File Reference](#file-reference)
- [Updating](#updating)
- [Uninstalling](#uninstalling)
- [FAQ](#faq)

---

## What Is This?

This is a **subagent** — a skill file that teaches Claude (in Cursor or Claude Code) how to operate as a Salesforce Solutions Engineer. When installed, it gives your AI assistant the frameworks, discovery techniques, demo planning methodology, and deal management discipline of an SE who owns the technical win on live deals.

A Solutions Engineer:

> Owns the day-to-day technical relationship on a deal. They run discovery, build tailored demos, handle objections, scope POCs, and drive every customer interaction toward a technical yes.

The SE is not a DSE (who operates across an OU or segment), not a BA (who owns requirements and UAT), and not an architect (who designs long-term systems). The SE converts customer pain into platform conviction, one deal at a time.

---

## Why an SE Subagent?

AI assistants default to implementation mode — give them a problem and they write code. But the SE's job starts long before code. It starts with understanding the customer, mapping their pain to platform capabilities, and building conviction through tailored proof.

The SE subagent fills that gap:

- **Discovery before demo.** It asks about the customer's world before proposing solutions. It prepares structured discovery organized by persona, not generic question lists.
- **Demos to the pain.** Every demo beat maps to a stated customer problem. Features without context don't appear. Pain with a solution creates conviction.
- **Handles objections as buying signals.** When a technical evaluator pushes back, the SE subagent digs into the root concern, frames a response with proof, and advances the deal.
- **Tailors everything.** No two accounts get the same output. Discovery questions, demo flows, battle cards, and POC scopes are built for the specific deal context.
- **Drives toward close.** Every deliverable includes clear next steps, stakeholder-specific actions, and measurable milestones.
- **Knows the competitive landscape.** Battle cards, landmine questions, and proof points are structured to win against specific competitors.

---

## What It Does

The SE subagent produces seven types of deal-level deliverables.

### Deliverables

| Deliverable | What You Get | When to Use It |
|---|---|---|
| **Discovery Call Prep** | Account research, stakeholder intel, discovery questions by persona, tech stack assessment, competitive landscape, talk track | Before any discovery or qualification call |
| **Technical Qualification** | MEDDPICC technical overlay, platform fit assessment, integration complexity, risk factors, technical health score | After initial discovery to assess deal viability |
| **Custom Demo Plan** | Persona-scenario mapping, demo flow with talk track per beat, data/config requirements, objection prep, wow moments | Before building or presenting a tailored demo |
| **Competitive Battle Card** | Competitor profile, their pitch vs. ours, feature matrix, landmine questions, proof points, counter-responses | When a known competitor is in the deal |
| **Technical Objection Responses** | Cataloged objections with root concern, ARPA response framework, proof points, follow-up actions | When objections surface during evaluation |
| **POC Scope Document** | Success criteria, in/out scope, timeline, resource requirements, evaluation rubric, exit criteria | When the deal requires a proof of concept |
| **Technical Close Plan** | Remaining concerns with resolution plans, timeline to technical win, stakeholder alignment status | Final push from evaluation to technical yes |

### Discovery & Competitive Depth

The SE subagent also provides:

| Capability | What It Does |
|---|---|
| **Discovery question bank** | Structured by persona (exec, business user, IT, technical evaluator) with follow-up guidance |
| **MEDDPICC technical overlay** | Maps each MEDDPICC element to the SE's specific responsibilities |
| **Competitive discovery** | Questions that expose competitor weaknesses without naming competitors |
| **Demo-to-discovery bridge** | Techniques for turning demo reactions into deeper customer insight |
| **Objection pattern library** | Pre-built responses for common Salesforce objections (security, scale, customization, pricing, integration, AI) |

---

## How It Works

### The Skill System

Both Cursor and Claude Code support **skills** — markdown files that teach the AI assistant how to perform specific tasks. The SE subagent consists of:

| File | Purpose |
|---|---|
| `SKILL.md` | Core instructions — identity, operating principles, deliverable workflows, scoring rubric, cross-skill delegation |
| `references/deliverables-guide.md` | Full templates for all seven deliverable types (loaded on-demand) |
| `references/discovery-frameworks.md` | Discovery question banks, MEDDPICC overlay, competitive discovery, objection patterns (loaded on-demand) |

### When It Activates

The subagent activates automatically when your prompt matches its trigger patterns:

- Preparing for a **discovery call** or **qualification meeting**
- Building a **custom demo plan** for a specific account
- Creating a **competitive battle card** or positioning against alternatives
- Handling **technical objections** from evaluators
- Scoping a **proof of concept** (POC)
- Building a **technical close plan** to drive the deal home
- Asking for **SE-level review** of deal strategy

It will **not** activate for OU-level strategy (DSE), requirements gathering (BA), or implementation work (Apex, LWC, Flows, metadata) — those are handled by their respective skills.

### What Changes When the SE Is Active

| Without SE | With SE |
|---|---|
| "Here's how to configure Service Cloud" | "Before we demo anything, let's understand their pain. What did the business users say about their current process?" |
| Generic product walkthrough | Demo flow where every beat maps to a stated customer problem |
| Ignores competitive context | Prepares landmine questions, feature comparison, and proof points against the specific competitor |
| No next steps | Every deliverable ends with mutual commitments, owners, and deadlines |
| Treats objections as problems | Treats objections as buying signals and digs into root concerns |

---

## Deployment

### Prerequisites

- **Cursor** (any version with skills support) and/or **Claude Code** (any version with skills support)
- A terminal with `bash`, `curl`, and `git` (macOS and Linux have these by default)

### Where It Installs

| Platform | Install Path |
|---|---|
| Cursor | `~/.cursor/skills/sf-se/` |
| Claude Code | `~/.claude/skills/sf-se/` |

---

### Option 1: One-Liner Install (Recommended)

No clone required. Run one command in your terminal.

**Both Cursor and Claude Code:**

```bash
curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/SE/install.sh | bash -s -- --both
```

**Cursor only:**

```bash
curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/SE/install.sh | bash -s -- --cursor
```

**Claude Code only:**

```bash
curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/SE/install.sh | bash -s -- --claude
```

Expected output:

```
╔════════════════════════════════════════════════════════╗
║  Salesforce Solutions Engineer (SE) Subagent          ║
║  Deal-level technical win management                 ║
╚════════════════════════════════════════════════════════╝

  ✓ Installed to /Users/you/.cursor/skills/sf-se (Cursor)
  ✓ Installed to /Users/you/.claude/skills/sf-se (Claude Code)

Done! The SE subagent will auto-activate when you:
  • Prepare for discovery calls or technical qualification
  • Plan custom demos tailored to a specific account
  • Build competitive battle cards or handle objections
  • Scope POCs or create technical close plans
```

---

### Option 2: Clone and Install

```bash
git clone https://github.com/sfdc-brendan/Demo-Lab.git
cd Demo-Lab/subagents/SE
chmod +x install.sh
./install.sh --both
```

---

### Option 3: Manual Copy

**For Cursor:**

```bash
mkdir -p ~/.cursor/skills/sf-se/references

curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/SE/SKILL.md \
  -o ~/.cursor/skills/sf-se/SKILL.md

curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/SE/references/deliverables-guide.md \
  -o ~/.cursor/skills/sf-se/references/deliverables-guide.md

curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/SE/references/discovery-frameworks.md \
  -o ~/.cursor/skills/sf-se/references/discovery-frameworks.md
```

**For Claude Code:**

```bash
mkdir -p ~/.claude/skills/sf-se/references

curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/SE/SKILL.md \
  -o ~/.claude/skills/sf-se/SKILL.md

curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/SE/references/deliverables-guide.md \
  -o ~/.claude/skills/sf-se/references/deliverables-guide.md

curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/SE/references/discovery-frameworks.md \
  -o ~/.claude/skills/sf-se/references/discovery-frameworks.md
```

---

## Verifying the Install

```bash
# For Cursor
ls -la ~/.cursor/skills/sf-se/
ls -la ~/.cursor/skills/sf-se/references/

# For Claude Code
ls -la ~/.claude/skills/sf-se/
ls -la ~/.claude/skills/sf-se/references/
```

You should see:

```
sf-se/
├── SKILL.md
└── references/
    ├── deliverables-guide.md
    └── discovery-frameworks.md
```

To confirm the skill is loaded, try a prompt like:

> "I have a discovery call with a telecom company evaluating Service Cloud and Agentforce. Help me prepare."

The agent should ask about the account, stakeholders, and competitive landscape — not jump to configuring Service Cloud.

---

## Using the SE Subagent

### 1. Discovery Call Prep

**Example prompts:**

> "I have a first discovery call with a mid-market healthcare company. They reached out about Service Cloud. Help me prepare."

> "We have a follow-up meeting with the VP of IT at a financial services firm. They're evaluating us against ServiceNow. Prepare my discovery plan."

**What you get:** Account research structure, stakeholder intel template, discovery questions organized by persona (exec sponsor, business user, IT admin, technical evaluator), competitive landscape assessment, current tech stack analysis, and a talk track for opening and closing the meeting.

---

### 2. Technical Qualification

**Example prompts:**

> "After our discovery call with Acme Corp, help me assess the technical health of this deal. They need Sales Cloud, Data Cloud, and integration with SAP."

> "Score this deal's technical viability. They're on Dynamics 365 today, evaluating us for a full platform swap."

**What you get:** MEDDPICC technical overlay mapping each element to your deal, platform fit assessment (declarative vs. custom breakdown), integration complexity analysis, risk factors with mitigation plans, and a technical health score.

---

### 3. Custom Demo Plans

**Example prompts:**

> "Build a demo plan for a 30-minute Service Cloud + Agentforce demo. The audience is the VP of Customer Service and two team leads at a retail company. Their pain: agents can't find customer history, cases fall through the cracks, and escalations are manual."

> "I need a custom demo for a manufacturing company evaluating Data Cloud. The CTO wants to see unified customer data across their ERP, e-commerce, and service systems."

**What you get:** Persona-scenario mapping (each stakeholder's pain connected to a demo beat), scripted demo flow with talk track, data and configuration requirements, wow moments designed to create emotional response, objection prep for likely pushback, and a dry-run checklist.

---

### 4. Competitive Battle Cards

**Example prompts:**

> "Build a battle card for a deal where we're competing against ServiceNow for an enterprise service management deployment."

> "The customer mentioned they've had a great demo from HubSpot. Help me differentiate and prepare landmine questions."

**What you get:** Competitor profile with strengths and weaknesses (honest about both), "their pitch vs. our story" comparison, feature matrix with advantage markers, landmine questions that expose weaknesses without naming the competitor, proof points (references, analyst reports, benchmarks), and counter-responses for when the customer quotes competitor claims.

---

### 5. Technical Objection Responses

**Example prompts:**

> "The technical evaluator at our healthcare account said 'We're worried Salesforce can't handle our data volume — we process 50 million records a month.' Help me respond."

> "The IT director keeps bringing up security concerns about cloud data. Prepare objection responses I can use in our next meeting."

**What you get:** Each objection cataloged with the root concern identified, response using the ARPA framework (Acknowledge, Reframe, Prove, Advance), specific proof points, and follow-up actions with deadlines.

---

### 6. POC Scope Documents

**Example prompts:**

> "The customer wants a POC before they commit. They need to validate Service Cloud case management with Agentforce triage and SAP integration. Help me scope it."

> "We need to propose a 3-week POC for a Data Cloud + Marketing Cloud evaluation. The customer has three use cases they want to validate."

**What you get:** Mutually agreed success criteria with measurable targets, explicit in/out scope boundaries, timeline with milestones, resource requirements for both sides, weighted evaluation rubric, and exit criteria (pass, conditional pass, fail).

---

### 7. Technical Close Plans

**Example prompts:**

> "We're in the final stretch with a retail account. Two technical concerns remain: SSO integration complexity and reporting performance at scale. Build the close plan."

> "I need to get this deal to technical win by end of month. Three stakeholders are green, one is yellow. Help me plan the final push."

**What you get:** All remaining technical concerns listed with resolution plans (action, owner, deadline, proof required), timeline from today to technical win, stakeholder alignment status (green/yellow/red per person), risk register, and draft technical win communications for both internal and external audiences.

---

### 8. Scoring Deliverables

After any deliverable is produced, you can request a quality score:

> "Score this demo plan against the SE rubric."

| Category | Points | What It Measures |
|---|---|---|
| Customer Relevance | 25 | Tailored to this account's pain, personas, and environment |
| Technical Credibility | 20 | Accurate platform knowledge, honest about limits, evaluator-ready depth |
| Competitive Awareness | 20 | Knows the landscape, positions against alternatives, plants landmines |
| Demo Narrative Quality | 20 | Story arc tied to customer pain, natural talk track, engineered wow moments |
| Deal Progression | 15 | Clear next steps, stakeholder actions, measurable milestones |

| Score Range | Meaning |
|---|---|
| 85–100 | Deal-ready — execute it |
| 70–84 | Strong foundation — needs account-specific sharpening |
| 50–69 | Good framework — needs more discovery or competitive intel |
| Below 50 | Return to discovery — not enough customer context |

---

## How It Integrates with Other Skills

The SE subagent owns the deal-level technical win and delegates implementation and adjacent concerns to specialized skills:

| When the SE identifies... | It delegates to... |
|---|---|
| Need for OU-level strategy or executive overlay | `sf-dse` |
| Requirements for a POC build phase | `sf-ba` |
| Apex code to customize a demo org | `sf-apex` |
| LWC component for a demo scenario | `sf-lwc` |
| Flow automation for a demo | `sf-flow` |
| Architecture diagram for a customer presentation | `sf-diagram-mermaid` |
| Data Cloud in the deal scope | `sf-datacloud` |
| Agentforce agent design for demo/POC | `sf-ai-agentforce` |
| Metadata for a demo org | `sf-metadata` |
| Deployment to a demo environment | `sf-deploy` |
| SOQL queries for demo data setup | `sf-soql` |

The SE also collaborates with:
- **DSE** — the DSE provides strategic overlay on must-win deals, executive engagement coaching, and cross-cloud architecture narratives. The SE executes the deal-level strategy.
- **BA** — once a deal progresses to POC or implementation, the BA picks up requirements, user stories, and UAT. The SE's POC scope becomes the BA's starting point.

---

## How SE Differs from DSE and BA

This is the most common question. Here's the clear distinction:

| Dimension | SE (this skill) | DSE | BA |
|---|---|---|---|
| **Altitude** | Single deal | OU, segment, or territory | Project or feature |
| **Primary customer** | Technical evaluator + champion | CIO/CRO/C-suite | Business stakeholders + sprint team |
| **Core question** | "How do we win this deal technically?" | "How should the CIO think about platform strategy?" | "Can a developer build from this? Can a tester validate it?" |
| **Key deliverables** | Discovery prep, demo plan, battle card, POC scope, close plan | Executive briefing, GTM play, POV, enablement | Requirements doc, user stories, UAT plan, training |
| **Success metric** | Technical win on the deal | Strategic influence across the business | Sprint-ready artifacts |
| **When they engage** | Throughout the sales cycle on a specific deal | On must-win deals, territory planning, GTM design | After the deal is won, during implementation |
| **Competitive focus** | Deep — knows the specific competitor's pitch and how to counter it | Broad — positions Salesforce strategically vs. alternatives | Minimal — focuses on what to build, not who to beat |

**Think of it this way:**
- The **DSE** convinces the CIO that Salesforce is the right strategic platform.
- The **SE** convinces the technical evaluator that Salesforce can solve their specific problems.
- The **BA** makes sure what gets built matches what was promised.

---

## File Reference

```
subagents/SE/
├── README.md                              ← You are here
├── SKILL.md                               ← Core skill (loaded into AI context)
├── install.sh                             ← Deployment script
└── references/
    ├── deliverables-guide.md              ← Templates for all 7 deliverable types
    └── discovery-frameworks.md            ← Discovery questions, MEDDPICC, competitive, objections
```

| File | Purpose |
|---|---|
| `SKILL.md` | Core identity, operating principles, deliverable workflows, scoring rubric, cross-skill delegation. Always loaded when the skill activates. |
| `references/deliverables-guide.md` | Detailed templates for discovery call prep, technical qualification, custom demo plan, competitive battle card, objection responses, POC scope, and technical close plan. Loaded on-demand when generating a specific deliverable. |
| `references/discovery-frameworks.md` | Discovery question banks by persona, MEDDPICC technical overlay, competitive discovery questions, demo-to-discovery bridge techniques, technical qualification scoring model, and response patterns for common Salesforce objections. Loaded on-demand. |

---

## Updating

Re-run the install command. It detects existing installations and replaces them:

```bash
curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/SE/install.sh | bash -s -- --both
```

You'll see:

```
  Existing install found at /Users/you/.cursor/skills/sf-se — updating...
  ✓ Installed to /Users/you/.cursor/skills/sf-se (Cursor)
```

---

## Uninstalling

```bash
# Cursor
rm -rf ~/.cursor/skills/sf-se

# Claude Code
rm -rf ~/.claude/skills/sf-se
```

---

## FAQ

**Q: Do I need the DSE or BA subagents installed too?**
No. The SE works standalone. If you also have `sf-dse` installed, the SE will escalate to the DSE for strategic overlay on must-win deals. If you have `sf-ba` installed, the SE's POC scope documents can feed directly into BA requirements. They complement each other but are independent.

**Q: Will this conflict with my other Salesforce skills?**
No. The SE has clear trigger boundaries. It only activates for deal-level work: discovery, qualification, demos, objections, POCs, and close plans. Implementation tasks (Apex, LWC, Flows, metadata) are handled by their respective skills.

**Q: How is this different from the DSE subagent?**
The DSE operates at strategic altitude — executive briefings, GTM plays, cross-cloud architecture narratives for an OU or territory. The SE operates at deal altitude — discovery, demos, battle cards, and close plans for a specific account. The DSE asks "how should the CIO think about platform strategy?" The SE asks "how do we win this deal technically?"

**Q: How is this different from the BA subagent?**
The BA owns the requirements lifecycle — user stories, acceptance criteria, process maps, UAT. The SE owns the technical win — discovery, demos, objections, POC scoping. The SE's work happens during the sales cycle; the BA's work happens during implementation. The SE's POC scope document often becomes the BA's starting point for requirements.

**Q: Can I customize the templates?**
Yes. Edit the files at `~/.cursor/skills/sf-se/` or `~/.claude/skills/sf-se/`. Changes persist until you re-run the installer.

**Q: What Salesforce clouds/products does it cover?**
All of them. The SE subagent builds discovery, demos, and deal strategy across Sales Cloud, Service Cloud, Marketing Cloud, Commerce Cloud, Data Cloud, MuleSoft, Tableau, Agentforce, Experience Cloud, Revenue Cloud, and Industries. It adapts to whatever clouds are in scope for the specific deal.

**Q: Does it work on Windows?**
The skill files work on any platform. The `install.sh` script requires bash (available on macOS, Linux, and Windows via WSL or Git Bash). For native Windows, use the [Manual Copy](#option-3-manual-copy) method.

**Q: How do I know it's active?**
When you ask about a specific deal scenario (discovery prep, demo planning, competitive positioning), the agent will ask about the account context, stakeholders, and competitive landscape before producing deliverables. If it jumps straight to product configuration, the SE skill isn't activated — try a more deal-oriented prompt.

**Q: Can I use it for internal demos or practice?**
Absolutely. Use it to plan enablement demos, practice discovery with realistic scenarios, or prepare for demo certifications. The templates work for any demo scenario, internal or customer-facing.
