# Salesforce Demo Engineer Subagent

> An AI subagent for **Cursor** and **Claude Code** that operates as a Salesforce Demo Engineer — the person who makes sure demo environments work, data is curated, and demos are repeatable every time.

---

## Table of Contents

- [What Is This?](#what-is-this)
- [Why a Demo Engineer Subagent?](#why-a-demo-engineer-subagent)
- [What It Does](#what-it-does)
- [How It Works](#how-it-works)
- [Deployment](#deployment)
  - [Option 1: One-Liner Install](#option-1-one-liner-install-recommended)
  - [Option 2: Clone and Install](#option-2-clone-and-install)
  - [Option 3: Manual Copy](#option-3-manual-copy)
- [Verifying the Install](#verifying-the-install)
- [Using the Demo Engineer Subagent](#using-the-demo-engineer-subagent)
  - [Demo Org Setup](#1-demo-org-setup)
  - [Sample Data Generation](#2-sample-data-generation)
  - [Demo Reset Procedures](#3-demo-reset-procedures)
  - [Environment Runbooks](#4-environment-runbooks)
  - [Persona Data Packages](#5-persona-data-packages)
  - [Environment Dependency Maps](#6-environment-dependency-maps)
  - [Scoring Demo Environments](#7-scoring-demo-environments)
- [How It Relates to DSE and SE](#how-it-relates-to-dse-and-se)
- [How It Integrates with Other Skills](#how-it-integrates-with-other-skills)
- [File Reference](#file-reference)
- [Updating](#updating)
- [Uninstalling](#uninstalling)
- [FAQ](#faq)

---

## What Is This?

This is a **subagent** — a skill file that teaches Claude (in Cursor or Claude Code) how to operate as a specific persona with specific expertise. When installed, it gives your AI coding assistant the operational mindset, tooling knowledge, and deliverable templates of a Salesforce Demo Engineer.

A Demo Engineer is:

> "The person who makes sure that when the DSE or SE walks into the room, everything clicks. Owns demo environments, curated data, reset procedures, and demo reliability. The unsung hero of every successful demo."

The DSE writes the story. The SE tailors it for the deal. The Demo Engineer makes sure the story can actually be told in the org — and told again, and again, reliably, on demand.

---

## Why a Demo Engineer Subagent?

Demo failures don't happen because the narrative was weak. They happen because:

- The data looks fake ("Test Account 1" with $0 revenue)
- A record was deleted during the last run and nobody reloaded it
- An integration token expired overnight
- The search index hasn't rebuilt since the data was refreshed
- A permission set wasn't assigned after the org was reset
- Nobody tested the demo flow since the last metadata deploy

These are all Demo Engineer problems. This subagent encodes the discipline to prevent them:

- **Treats demo data as a product.** Every record is intentional, realistic, and tells a story.
- **Enforces the 5-minute reset rule.** If you can't reset in 5 minutes, you can't recover from a bad run or handle back-to-back sessions.
- **Automates everything.** Setup scripts, not setup docs. CLI commands, not click paths.
- **Documents dependencies.** If it breaks at 8am before a 9am demo, someone can fix it fast.
- **Tests the demo before the demo.** Validation scripts catch broken automations, stale data, and expired tokens.

---

## What It Does

The Demo Engineer subagent produces six types of deliverables.

### Deliverables

| Deliverable | What You Get | When to Use It |
|---|---|---|
| **Demo Org Setup Script** | End-to-end setup from scratch: metadata deployment order, permission assignments, data load sequence, post-deploy config, validation checklist | Standing up a new demo environment or recreating one from scratch |
| **Sample Data Plan** | Persona definitions, record counts per object, relationship map, data generation approach, refresh cadence, validation queries | Planning what data needs to exist for a demo scenario |
| **Demo Reset Procedure** | Pre-reset checklist, ordered reset steps, data reload commands, cache refresh, validation, timing estimates | Making a demo repeatable between sessions |
| **Environment Runbook** | Org access details, installed packages, metadata dependencies, integration endpoints, known issues, escalation contacts | Documenting everything someone needs to operate the demo org |
| **Persona Data Package** | Detailed persona profiles with all associated records (Account, Contact, Case, Opportunity) that tell a coherent story, packaged as importable files | Creating demo data that feels real and narratively connected |
| **Environment Dependency Map** | Metadata, package, integration, and data dependencies with load sequence and failure impact matrix | Understanding what the demo depends on and what breaks if something is missing |

---

## How It Works

### The Skill System

Both Cursor and Claude Code support **skills** — markdown files that teach the AI assistant how to perform specific tasks. Skills are stored in a known directory, and the AI reads them automatically when it detects a matching scenario.

The Demo Engineer subagent is a skill. It consists of:

| File | Purpose |
|---|---|
| `SKILL.md` | Core instructions — identity, operating principles, deliverable workflows, data standards, scoring rubric, cross-skill delegation |
| `references/deliverables-guide.md` | Full templates for all six deliverable types (loaded on-demand) |
| `references/demo-data-patterns.md` | Realistic name generation, industry-specific data patterns, volume guidelines, anti-patterns, CLI reference (loaded on-demand) |

### When It Activates

The subagent activates automatically when your prompt matches its trigger patterns:

- Setting up a **demo org** from scratch or from a template
- Generating **sample data** or **persona-based test data**
- Creating a **demo reset procedure** or reset script
- Building an **environment runbook** for a demo org
- Mapping **environment dependencies** for a demo scenario
- Reviewing **demo reliability** or auditing an existing demo environment

It will **not** activate for:
- Demo narrative or strategic framing (handled by `sf-dse`)
- Deal strategy or account planning (handled by `sf-se`)
- Requirements gathering or user stories (handled by `sf-ba`)
- Production deployments (handled by `sf-deploy`)

---

## Deployment

### Prerequisites

- **Cursor** (any version with skills support) and/or **Claude Code** (any version with skills support)
- A terminal with `bash`, `curl`, and `git` available (macOS and Linux have these by default)

### Where It Installs

| Platform | Install Path |
|---|---|
| Cursor | `~/.cursor/skills/sf-demo-engineer/` |
| Claude Code | `~/.claude/skills/sf-demo-engineer/` |

---

### Option 1: One-Liner Install (Recommended)

No clone required. Run one command in your terminal.

**Install for both Cursor and Claude Code:**

```bash
curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/DemoEngineer/install.sh | bash -s -- --both
```

**Install for Cursor only:**

```bash
curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/DemoEngineer/install.sh | bash -s -- --cursor
```

**Install for Claude Code only:**

```bash
curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/DemoEngineer/install.sh | bash -s -- --claude
```

You should see output like:

```
╔════════════════════════════════════════════════════════╗
║  Salesforce Demo Engineer Subagent                    ║
║  Demo environments, data & reliability               ║
╚════════════════════════════════════════════════════════╝

  ✓ Installed to /Users/you/.cursor/skills/sf-demo-engineer (Cursor)
  ✓ Installed to /Users/you/.claude/skills/sf-demo-engineer (Claude Code)

Done! The Demo Engineer subagent will auto-activate when you:
  • Set up a demo org or generate sample data
  • Build demo reset procedures or environment runbooks
  • Create persona data packages or dependency maps
  • Ask for demo reliability review
```

---

### Option 2: Clone and Install

If you prefer to inspect the files first:

```bash
git clone https://github.com/sfdc-brendan/Demo-Lab.git
cd Demo-Lab/subagents/DemoEngineer
chmod +x install.sh
./install.sh --both
```

---

### Option 3: Manual Copy

**For Cursor:**

```bash
mkdir -p ~/.cursor/skills/sf-demo-engineer/references

curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/DemoEngineer/SKILL.md \
  -o ~/.cursor/skills/sf-demo-engineer/SKILL.md

curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/DemoEngineer/references/deliverables-guide.md \
  -o ~/.cursor/skills/sf-demo-engineer/references/deliverables-guide.md

curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/DemoEngineer/references/demo-data-patterns.md \
  -o ~/.cursor/skills/sf-demo-engineer/references/demo-data-patterns.md
```

**For Claude Code:**

```bash
mkdir -p ~/.claude/skills/sf-demo-engineer/references

curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/DemoEngineer/SKILL.md \
  -o ~/.claude/skills/sf-demo-engineer/SKILL.md

curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/DemoEngineer/references/deliverables-guide.md \
  -o ~/.claude/skills/sf-demo-engineer/references/deliverables-guide.md

curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/DemoEngineer/references/demo-data-patterns.md \
  -o ~/.claude/skills/sf-demo-engineer/references/demo-data-patterns.md
```

---

## Verifying the Install

After installing, verify the files are in place:

```bash
# For Cursor
ls -la ~/.cursor/skills/sf-demo-engineer/
ls -la ~/.cursor/skills/sf-demo-engineer/references/

# For Claude Code
ls -la ~/.claude/skills/sf-demo-engineer/
ls -la ~/.claude/skills/sf-demo-engineer/references/
```

You should see three files:

```
sf-demo-engineer/
├── SKILL.md
└── references/
    ├── deliverables-guide.md
    └── demo-data-patterns.md
```

To confirm the skill is loaded, open Cursor or Claude Code and try:

> "Set up a demo org for a telecom customer retention scenario with Service Cloud and Agentforce."

The agent should respond with a structured setup script (deployment order, data plan, permission assignments) rather than generic configuration instructions.

---

## Using the Demo Engineer Subagent

### 1. Demo Org Setup

**Example prompts:**

> "Set up a demo org for a telecom retention scenario with Service Cloud, Data Cloud, and Agentforce."

> "I need a scratch org for a financial services onboarding demo. Create the setup script with metadata deployment order and data loading."

**What you get:** A complete setup script with org provisioning, metadata deployment in dependency order, permission assignments for each demo user, data load sequence, post-deploy configuration, and a validation checklist.

---

### 2. Sample Data Generation

**Example prompts:**

> "Generate realistic persona data for a financial services demo with 3 personas: a wealth advisor, a compliance officer, and a high-net-worth client."

> "Create a sample data plan for a healthcare patient journey demo. I need patients, providers, encounters, and care plans."

**What you get:** A data plan with named personas, record counts per object, cross-object relationship maps, data generation scripts (Apex or CLI), refresh cadence, and validation queries.

---

### 3. Demo Reset Procedures

**Example prompts:**

> "Build a reset procedure for our telecom retention demo. It needs to reset in under 5 minutes."

> "The demo org keeps accumulating garbage data between runs. Create an automated reset that gets it back to a clean state."

**What you get:** A step-by-step reset procedure with pre-reset checklist, ordered reset steps (delete transient data, reload base data, clear caches), validation, timing estimates, and troubleshooting guide.

---

### 4. Environment Runbooks

**Example prompts:**

> "Document everything someone needs to know to operate our Data Cloud + Agentforce demo org. I want a full runbook."

> "We have a demo org that only one person knows how to fix. Create a runbook so anyone on the team can troubleshoot it."

**What you get:** A complete runbook with org access details, installed packages, metadata dependencies, integration endpoints, known issues with workarounds, and escalation contacts.

---

### 5. Persona Data Packages

**Example prompts:**

> "Create a persona data package for 'Maria Chen' — a frustrated VIP telecom customer considering switching providers. Include all related records that tell her story."

> "Build demo personas for a retail scenario: a loyal customer with a delayed holiday order, a new customer browsing for gifts, and a store manager tracking returns."

**What you get:** Detailed persona profiles with all associated records (Account, Contact, Case, Opportunity, custom objects) that form a coherent narrative, packaged as importable data files with cross-object relationship documentation.

---

### 6. Environment Dependency Maps

**Example prompts:**

> "Map all the dependencies for our Agentforce demo — what metadata, packages, integrations, and data need to exist, and in what order?"

> "The demo broke and I don't know why. Help me map all the dependencies so we can identify what's fragile."

**What you get:** A complete dependency inventory (metadata, packages, integrations, data) with load sequence, failure impact matrix, and a dependency diagram.

---

### 7. Scoring Demo Environments

After the agent produces any deliverable or audits an existing environment, you can ask it to score:

> "Score this demo environment against the Demo Engineer rubric."

It evaluates on a 100-point scale:

| Category | Points | What It Measures |
|---|---|---|
| Reliability | 25 | Demo works end-to-end without manual intervention |
| Reset Speed | 20 | Full reset in under 5 minutes, automated, validated |
| Data Realism | 20 | Persona-based data, industry-appropriate names, current dates |
| Automation Coverage | 20 | Setup and reset scripted, not manual click paths |
| Documentation Clarity | 15 | Runbook complete, dependencies mapped, escalation path defined |

| Score Range | Meaning |
|---|---|
| 85-100 | Demo-ready — hand it to anyone and it works |
| 70-84 | Solid foundation — minor gaps to close |
| 50-69 | Functional but fragile — needs automation or documentation |
| Below 50 | High risk of demo failure — significant rework needed |

---

## How It Relates to DSE and SE

The Demo Engineer sits between the strategic layer (DSE) and the delivery layer (SE/AE). It receives inputs from both and returns a working demo environment.

```
┌─────────────────────────────────────────┐
│               DSE                       │
│  Writes the demo narrative              │
│  Defines the strategic story arc        │
│  Hands demo script to Demo Engineer     │
└──────────────┬──────────────────────────┘
               │ demo script + scenario requirements
               ▼
┌─────────────────────────────────────────┐
│         DEMO ENGINEER                   │
│  Builds the org from the script         │
│  Curates realistic persona data         │
│  Automates setup and reset              │
│  Documents the environment              │
│  Validates everything works             │
└──────────────┬──────────────────────────┘
               │ working demo environment + runbook
               ▼
┌─────────────────────────────────────────┐
│             SE / AE                     │
│  Delivers the demo to the customer      │
│  May request customizations             │
│  Reports issues back to Demo Engineer   │
└─────────────────────────────────────────┘
```

**From the DSE:** The Demo Engineer receives demo scripts and scenario definitions. The DSE says "here's the story we want to tell" and the Demo Engineer builds the environment to support it.

**From the SE:** The Demo Engineer receives custom demo plans for specific deals. The SE says "I need this demo customized for Account X" and the Demo Engineer ensures the customizations work and are resettable.

**Back to both:** The Demo Engineer delivers a working environment with a runbook. If the DSE or SE hits an issue, they escalate back to the Demo Engineer, who diagnoses and fixes it.

---

## How It Integrates with Other Skills

The Demo Engineer delegates implementation work to specialized skills:

| When the Demo Engineer needs... | It delegates to... |
|---|---|
| Metadata deployed to an org | `sf-deploy` |
| Bulk data operations | `sf-data` |
| Apex automation scripts | `sf-apex` |
| Custom objects and fields created | `sf-metadata` |
| SOQL validation queries optimized | `sf-soql` |
| Architecture/dependency diagrams | `sf-diagram-mermaid` |
| Agentforce agent configured for demo | `sf-ai-agentforce` |
| Data Cloud pipeline set up for demo | `sf-datacloud` |

If those skills aren't installed, the Demo Engineer still produces all deliverables — it just won't auto-generate the implementation code for the handoff.

---

## File Reference

```
subagents/DemoEngineer/
├── README.md                                ← You are here
├── SKILL.md                                 ← Core skill (loaded into AI context)
├── install.sh                               ← Deployment script
└── references/
    ├── deliverables-guide.md                ← Full templates for all 6 deliverable types
    └── demo-data-patterns.md                ← Name generation, industry data, volume guidelines, CLI reference
```

| File | Lines | Purpose |
|---|---|---|
| `SKILL.md` | ~255 | Core identity, operating principles, deliverable workflows, data standards, scoring rubric, cross-skill delegation. Always loaded when the skill activates. |
| `references/deliverables-guide.md` | ~290 | Detailed templates for Demo Org Setup Script, Sample Data Plan, Demo Reset Procedure, Environment Runbook, Persona Data Package, and Environment Dependency Map. Loaded on-demand. |
| `references/demo-data-patterns.md` | ~330 | Realistic name banks, industry-specific data patterns (telecom, FSI, healthcare, retail), cross-object story building, volume guidelines, anti-patterns, and Salesforce CLI data command reference. Loaded on-demand. |

---

## Updating

To update to the latest version, re-run the install command:

```bash
curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/DemoEngineer/install.sh | bash -s -- --both
```

You'll see:

```
  Existing install found at /Users/you/.cursor/skills/sf-demo-engineer — updating...
  ✓ Installed to /Users/you/.cursor/skills/sf-demo-engineer (Cursor)
```

---

## Uninstalling

```bash
# Cursor
rm -rf ~/.cursor/skills/sf-demo-engineer

# Claude Code
rm -rf ~/.claude/skills/sf-demo-engineer
```

---

## FAQ

**Q: Do I need the DSE subagent installed for this to work?**
No. The Demo Engineer works standalone. If `sf-dse` is also installed, it can receive demo scripts from the DSE and build environments to support them. Without it, you provide the demo scenario directly and the Demo Engineer builds from there.

**Q: Will this conflict with other skills?**
No. The Demo Engineer has clear trigger boundaries. It only activates for demo environment setup, data generation, reset procedures, and related operational work. Strategic narrative (DSE), deal strategy (SE), requirements (BA), and production deployment (deploy) are handled by their respective skills.

**Q: Can I customize the templates?**
Yes. After installing, edit the files directly at `~/.cursor/skills/sf-demo-engineer/` or `~/.claude/skills/sf-demo-engineer/`. Changes persist until you re-run the installer (which overwrites).

**Q: What industries does it support?**
The data patterns reference file includes specific patterns for Telecommunications, Financial Services, Healthcare, and Retail/Consumer Goods. For other industries, the Demo Engineer applies the same principles (realistic naming, coherent relationships, appropriate volume) using the general framework.

**Q: Does it generate actual Apex scripts and data files?**
Yes. When it produces a Setup Script, Reset Procedure, or Persona Data Package, it generates executable `sf` CLI commands, anonymous Apex scripts, and sObject Tree JSON files. These are ready to run against a Salesforce org.

**Q: What's the difference between this and sf-data?**
`sf-data` is a general-purpose skill for Salesforce data operations (import, export, bulk operations). The Demo Engineer uses `sf-data` as a delegate but adds the demo-specific layer: persona curation, story-driven relationships, reset automation, and environment documentation.

**Q: Does it work on Windows?**
The skill files work on any platform. The `install.sh` script requires bash (available on macOS, Linux, and Windows via WSL or Git Bash). For native Windows without bash, use the [Manual Copy](#option-3-manual-copy) method with PowerShell equivalents.

**Q: How do I know it's active?**
When your prompt involves demo org setup, data generation, reset procedures, or environment documentation, the response will be structured around the Demo Engineer's deliverable templates. If unsure, ask: "Are you operating in Demo Engineer mode?" and it will confirm.
