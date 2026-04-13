# Salesforce Business Analyst (BA) Subagent

> An AI assistant for **Cursor** and **Claude Code** that owns the full requirements lifecycle — elicitation, documentation, process analysis, user stories, UAT planning, training materials, and backlog management — for Salesforce projects.

---

## Table of Contents

- [What Is This?](#what-is-this)
- [Why a BA Subagent?](#why-a-ba-subagent)
- [What It Does](#what-it-does)
- [How It Works](#how-it-works)
- [Deployment](#deployment)
  - [Option 1: One-Liner Install](#option-1-one-liner-install-recommended)
  - [Option 2: Clone and Install](#option-2-clone-and-install)
  - [Option 3: Manual Copy](#option-3-manual-copy)
- [Verifying the Install](#verifying-the-install)
- [Using the BA Subagent](#using-the-ba-subagent)
  - [Requirements Documents](#1-requirements-documents)
  - [User Stories](#2-user-stories)
  - [Process Maps](#3-process-maps)
  - [UAT Plans](#4-uat-plans)
  - [Training Materials](#5-training-materials)
  - [Backlog Triage](#6-backlog-triage)
  - [Scoring Deliverables](#7-scoring-deliverables)
- [How It Integrates with Other Skills](#how-it-integrates-with-other-skills)
- [File Reference](#file-reference)
- [Updating](#updating)
- [Uninstalling](#uninstalling)
- [FAQ](#faq)

---

## What Is This?

This is a **subagent** — a skill file that teaches Claude (in Cursor or Claude Code) how to operate as a Salesforce Business Analyst. When installed, it gives your AI assistant the frameworks, templates, and operating model of a BA who sits at the intersection of business process and platform capability.

A Salesforce Business Analyst:

> Has "similar responsibilities, experience and skillset requirements as the Solution Architect — however [with] deep understanding of specific business processes."

The BA is not an admin, not a developer, and not an architect — but must understand all three well enough to translate between them and the business. This subagent encodes that translation layer.

---

## Why a BA Subagent?

AI coding assistants are great at writing code, but they don't naturally think in requirements, acceptance criteria, or process optimization. They jump to solutions before the problem is fully defined.

The BA subagent fills that gap:

- **Requirements before solutions.** It captures what the business needs before mapping to how Salesforce does it.
- **Translates in both directions.** Complex business needs become clear developer specs. Technical constraints become non-technical business language.
- **Challenges, doesn't just document.** It asks why, identifies redundancies, and recommends process simplification before automation.
- **Writes for the sprint team.** User stories and acceptance criteria are clear enough that a developer can build from them and a tester can validate against them without a follow-up meeting.
- **Owns the validation loop.** It follows through from requirements to UAT, confirming what was built matches what was asked for.
- **Thinks in adoption.** Training materials, job aids, and change management are built into the plan from the start.

---

## What It Does

The BA subagent produces six types of deliverables and operates within an Agile/Scrum context.

### Deliverables

| Deliverable | What You Get | When to Use It |
|---|---|---|
| **Requirements Document** | Current-state/future-state analysis, functional and non-functional requirements, data and integration requirements, stakeholder sign-off | Starting a new project or feature area |
| **User Stories** | Persona-based stories with given/when/then acceptance criteria, dependencies, size estimates, cross-cloud flags | Sprint planning and backlog refinement |
| **Process Map** | Step-by-step process flows with actors, systems, decisions, exception paths, and automation opportunities | Understanding how work gets done and where to improve |
| **UAT Plan** | Test scenarios traced to requirements, step-by-step scripts, entry/exit criteria, defect management, sign-off | Validating that what was built matches what was asked for |
| **Training Material** | Step-by-step user guides, quick reference cards, common errors, FAQ | Supporting adoption after delivery |
| **Backlog Item** | Request classification, value vs. complexity assessment, CoE alignment check, priority recommendation | Triaging incoming requests in a CoE |

### Agile/Scrum Role

The BA operates as an extension of the Product Owner:

| Ceremony | BA Contribution |
|---|---|
| Sprint Planning | Presents refined stories, clarifies acceptance criteria, flags dependencies |
| Backlog Refinement | Writes and refines stories with PO and dev team, breaks epics into stories |
| Daily Standup | Shares blockers on requirements clarity, stakeholder availability |
| Sprint Review | Reviews completed work against acceptance criteria before stakeholder demo |
| Retrospective | Identifies requirements-related process improvements |

### RACI Boundaries

The BA knows what it leads and what it defers:

| Task | BA Role | Who Else Leads |
|---|---|---|
| Requirements gathering | **Leads** | Admin supports, Architect consulted |
| Process documentation | **Leads** | Admin supports |
| UAT | **Leads** | Dev fixes defects |
| Training | **Leads** | Admin supports |
| Configuration/automation | Consulted | Admin leads |
| Custom development | Informed | Developer leads |
| Architecture decisions | Consulted | Architect leads |

---

## How It Works

### The Skill System

Both Cursor and Claude Code support **skills** — markdown files that teach the AI assistant how to perform specific tasks. The BA subagent consists of:

| File | Purpose |
|---|---|
| `SKILL.md` | Core instructions — identity, operating principles, deliverable workflows, RACI, scoring rubric, cross-skill delegation |
| `references/deliverables-guide.md` | Full templates for all six deliverable types (loaded on-demand) |
| `references/requirements-patterns.md` | Elicitation techniques, story writing patterns, process analysis frameworks, stakeholder management (loaded on-demand) |

### When It Activates

The subagent activates automatically when your prompt matches its trigger patterns:

- Writing or reviewing **user stories** or **acceptance criteria**
- Mapping **business processes** (current-state or future-state)
- Creating **requirements documents** or running **gap analysis**
- Planning or scripting **UAT**
- Creating **training materials** or user guides
- Triaging **backlog items** or prioritizing requests
- Defining **reporting requirements** or KPIs

It will **not** activate for implementation work (writing Apex, building LWCs, configuring Flows, deploying metadata) — those are handled by their respective specialized skills.

### What Changes When the BA Is Active

| Without BA | With BA |
|---|---|
| "Here's how to build a case assignment Flow" | "First, let's document the assignment criteria as requirements, then write stories the dev team can build from" |
| Jumps to Salesforce configuration | Captures the business intent first, maps to platform capabilities second |
| Produces code | Produces requirements, stories, process maps, and test scripts |
| Assumes the happy path | Writes acceptance criteria for happy path, error path, bulk path, and permission path |

---

## Deployment

### Prerequisites

- **Cursor** (any version with skills support) and/or **Claude Code** (any version with skills support)
- A terminal with `bash`, `curl`, and `git` (macOS and Linux have these by default)

### Where It Installs

| Platform | Install Path |
|---|---|
| Cursor | `~/.cursor/skills/sf-ba/` |
| Claude Code | `~/.claude/skills/sf-ba/` |

---

### Option 1: One-Liner Install (Recommended)

No clone required. Run one command in your terminal.

**Both Cursor and Claude Code:**

```bash
curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/BA/install.sh | bash -s -- --both
```

**Cursor only:**

```bash
curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/BA/install.sh | bash -s -- --cursor
```

**Claude Code only:**

```bash
curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/BA/install.sh | bash -s -- --claude
```

Expected output:

```
╔════════════════════════════════════════════════════════╗
║  Salesforce Business Analyst (BA) Subagent            ║
║  Requirements, process analysis & adoption            ║
╚════════════════════════════════════════════════════════╝

  ✓ Installed to /Users/you/.cursor/skills/sf-ba (Cursor)
  ✓ Installed to /Users/you/.claude/skills/sf-ba (Claude Code)

Done! The BA subagent will auto-activate when you:
  • Write user stories or acceptance criteria
  • Map business processes or run gap analysis
  • Plan UAT or create training materials
  • Triage backlog items or define requirements
```

---

### Option 2: Clone and Install

```bash
git clone https://github.com/sfdc-brendan/Demo-Lab.git
cd Demo-Lab/subagents/BA
chmod +x install.sh
./install.sh --both
```

---

### Option 3: Manual Copy

**For Cursor:**

```bash
mkdir -p ~/.cursor/skills/sf-ba/references

curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/BA/SKILL.md \
  -o ~/.cursor/skills/sf-ba/SKILL.md

curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/BA/references/deliverables-guide.md \
  -o ~/.cursor/skills/sf-ba/references/deliverables-guide.md

curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/BA/references/requirements-patterns.md \
  -o ~/.cursor/skills/sf-ba/references/requirements-patterns.md
```

**For Claude Code:**

```bash
mkdir -p ~/.claude/skills/sf-ba/references

curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/BA/SKILL.md \
  -o ~/.claude/skills/sf-ba/SKILL.md

curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/BA/references/deliverables-guide.md \
  -o ~/.claude/skills/sf-ba/references/deliverables-guide.md

curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/BA/references/requirements-patterns.md \
  -o ~/.claude/skills/sf-ba/references/requirements-patterns.md
```

---

## Verifying the Install

```bash
# For Cursor
ls -la ~/.cursor/skills/sf-ba/
ls -la ~/.cursor/skills/sf-ba/references/

# For Claude Code
ls -la ~/.claude/skills/sf-ba/
ls -la ~/.claude/skills/sf-ba/references/
```

You should see:

```
sf-ba/
├── SKILL.md
└── references/
    ├── deliverables-guide.md
    └── requirements-patterns.md
```

To confirm the skill is loaded, try a prompt like:

> "I need to document requirements for a new case management process in Service Cloud."

The agent should begin by asking about stakeholders, current-state process, and pain points — not by jumping to Flow configuration.

---

## Using the BA Subagent

### 1. Requirements Documents

**Example prompts:**

> "Document the requirements for automating lead assignment in Sales Cloud. We have three regions with different routing rules."

> "I need a requirements doc for a customer onboarding process that spans Service Cloud and Experience Cloud."

**What you get:** A structured document with current-state analysis, pain points, future-state design, functional and non-functional requirements, data model, integration needs, assumptions, and sign-off section.

---

### 2. User Stories

**Example prompts:**

> "Write user stories for a case escalation process. Cases should auto-escalate after 4 hours if unresolved, and managers need visibility into escalated cases."

> "Break this epic into sprint-ready user stories: 'As a service rep, I need a 360-degree view of the customer on the Case page.'"

**What you get:** Persona-based stories with given/when/then acceptance criteria covering happy path, error path, and edge cases. Each story includes Salesforce objects, automation type (declarative vs. custom), dependencies, and size estimate.

---

### 3. Process Maps

**Example prompts:**

> "Map the current-state lead-to-opportunity process. Today it involves manual handoff from marketing to sales with a spreadsheet tracker."

> "Create a future-state process map for automated case routing with Agentforce triage, human escalation, and SLA tracking."

**What you get:** Step-by-step process flow with actors, systems, decision points, exception paths, and annotations showing which Salesforce objects and automations apply at each step. Includes an automation opportunities table.

---

### 4. UAT Plans

**Example prompts:**

> "Create a UAT plan for the case management features we're deploying in Sprint 4. It covers case creation, assignment, escalation, and closure."

> "Write UAT test scripts for the new quoting approval process. I need step-by-step scripts the business users can follow."

**What you get:** Test scenarios traced back to user stories, step-by-step scripts with expected results and pass/fail checkboxes, entry/exit criteria, defect severity definitions, and stakeholder sign-off section.

---

### 5. Training Materials

**Example prompts:**

> "Create a training guide for service reps on the new case management process. They're Salesforce beginners."

> "Write a quick reference card for managers on how to use the new escalation dashboard."

**What you get:** Step-by-step task guides with field descriptions, quick reference cards for daily tasks, common errors and fixes, and FAQ built from stakeholder questions.

---

### 6. Backlog Triage

**Example prompts:**

> "A stakeholder wants to add a 'reason for hold' field to the Case object. Help me triage this against our CoE backlog."

> "We have 12 enhancement requests for the quoting process. Help me prioritize them using value vs. complexity."

**What you get:** Request classification, value/complexity assessment, CoE charter alignment check, priority recommendation with rationale, and decision-ready format for the PO or steering committee.

---

### 7. Scoring Deliverables

After any deliverable is produced, you can request a quality score:

> "Score these user stories against the BA rubric."

| Category | Points | What It Measures |
|---|---|---|
| Completeness | 25 | All requirements captured, edge cases addressed, no gaps |
| Clarity | 25 | Unambiguous, buildable, testable without follow-up |
| Business Alignment | 20 | Tied to business outcomes, stakeholder priorities reflected |
| Platform Awareness | 15 | Mapped to Salesforce capabilities, declarative vs. custom identified |
| Testability | 15 | Acceptance criteria are verifiable, UAT scenarios trace to requirements |

| Score Range | Meaning |
|---|---|
| 85–100 | Sprint-ready — proceed to build |
| 70–84 | Strong foundation — minor clarification needed |
| 50–69 | Good direction — needs refinement before sprint |
| Below 50 | Return to stakeholder discovery |

---

## How It Integrates with Other Skills

The BA subagent owns requirements and hands off implementation. If you have other Salesforce skills installed, delegation happens automatically:

| When the BA produces... | Implementation goes to... |
|---|---|
| Process maps with automation opportunities | `sf-flow` (declarative) or `sf-apex` (custom) |
| Data model requirements | `sf-metadata` |
| Reporting/dashboard requirements | `sf-soql` |
| Integration requirements | `sf-integration` |
| Architecture decisions needed | `sf-dse` |
| UI requirements | `sf-lwc` |
| Agentforce requirements | `sf-ai-agentforce` |
| Data Cloud requirements | `sf-datacloud` |
| Deployment needs | `sf-deploy` |
| Process diagrams | `sf-diagram-mermaid` |
| Test execution (after UAT design) | `sf-testing` |

The BA also pairs well with the **DSE subagent** — the DSE handles strategic architecture and executive engagement, while the BA handles the detailed requirements that feed the delivery team.

---

## File Reference

```
subagents/BA/
├── README.md                              ← You are here
├── SKILL.md                               ← Core skill (loaded into AI context)
├── install.sh                             ← Deployment script
└── references/
    ├── deliverables-guide.md              ← Templates for all 6 deliverable types
    └── requirements-patterns.md           ← Elicitation, story writing, process analysis frameworks
```

| File | Lines | Purpose |
|---|---|---|
| `SKILL.md` | ~230 | Core identity, operating principles, RACI, deliverable workflows, Agile context, scoring rubric, cross-skill delegation. Always loaded when the skill activates. |
| `references/deliverables-guide.md` | ~310 | Detailed templates for requirements docs, user stories (with writing checklist), process maps, UAT plans, training materials, and backlog items. Loaded on-demand. |
| `references/requirements-patterns.md` | ~250 | Elicitation techniques (interview guide, workshop agenda), user story patterns for common Salesforce scenarios, process analysis checklist, gap analysis matrix, stakeholder management, requirement quality checks, and Salesforce-specific BA patterns. Loaded on-demand. |

---

## Updating

Re-run the install command. It detects existing installations and replaces them:

```bash
curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/BA/install.sh | bash -s -- --both
```

---

## Uninstalling

```bash
# Cursor
rm -rf ~/.cursor/skills/sf-ba

# Claude Code
rm -rf ~/.claude/skills/sf-ba
```

---

## FAQ

**Q: Do I need the DSE subagent installed too?**
No. The BA works standalone. If you also have `sf-dse` installed, the BA will delegate architecture-level questions to the DSE, and the DSE will delegate requirements work to the BA. They complement each other but neither requires the other.

**Q: Will this conflict with my other Salesforce skills?**
No. The BA has clear RACI boundaries. It only activates for requirements, process analysis, UAT, training, and backlog work. Implementation tasks (Apex, LWC, Flows, metadata) are handled by their respective skills.

**Q: Can I customize the templates?**
Yes. Edit the files at `~/.cursor/skills/sf-ba/` or `~/.claude/skills/sf-ba/`. Changes persist until you re-run the installer.

**Q: What Salesforce clouds does it cover?**
All of them. The BA writes requirements across Sales, Service, Marketing, Commerce, Data Cloud, Experience Cloud, Revenue Cloud, and Industries. It maps requirements to platform capabilities regardless of cloud.

**Q: Does it work in waterfall projects too?**
Yes. The deliverable templates work in any methodology. The Agile/Scrum context (sprint ceremonies, story readiness checklist) is additive — it's included for teams using scrum but doesn't prevent use in waterfall or hybrid projects.

**Q: How is this different from the DSE subagent?**
The DSE thinks at strategic altitude — executive briefings, GTM plays, cross-cloud architecture narratives. The BA thinks at delivery altitude — user stories, acceptance criteria, process maps, UAT scripts. The DSE asks "why should the CIO care?" The BA asks "can a developer build from this and a tester validate it?"
