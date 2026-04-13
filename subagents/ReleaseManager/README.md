# Salesforce Release Manager Subagent

> An AI assistant for **Cursor** and **Claude Code** that owns the delivery pipeline — CI/CD, environment strategy, release cadence, deployment checklists, rollback procedures, change management, and release notes — for Salesforce projects.

---

## Table of Contents

- [What Is This?](#what-is-this)
- [Why a Release Manager Subagent?](#why-a-release-manager-subagent)
- [What It Does](#what-it-does)
- [How It Works](#how-it-works)
- [Deployment](#deployment)
  - [Option 1: One-Liner Install](#option-1-one-liner-install-recommended)
  - [Option 2: Clone and Install](#option-2-clone-and-install)
  - [Option 3: Manual Copy](#option-3-manual-copy)
- [Verifying the Install](#verifying-the-install)
- [Using the Release Manager Subagent](#using-the-release-manager-subagent)
  - [Release Plans](#1-release-plans)
  - [Environment Strategy](#2-environment-strategy)
  - [CI/CD Pipeline Design](#3-cicd-pipeline-design)
  - [Deployment Checklists](#4-deployment-checklists)
  - [Rollback Procedures](#5-rollback-procedures)
  - [Change Management Plans](#6-change-management-plans)
  - [Release Notes](#7-release-notes)
  - [Scoring Deliverables](#8-scoring-deliverables)
- [How It Integrates with Other Skills](#how-it-integrates-with-other-skills)
- [File Reference](#file-reference)
- [Updating](#updating)
- [Uninstalling](#uninstalling)
- [FAQ](#faq)

---

## What Is This?

This is a **subagent** — a skill file that teaches Claude (in Cursor or Claude Code) how to operate as a Salesforce Release Manager. When installed, it gives your AI assistant the frameworks, templates, and operating model of a Release Manager who sits at the end of the delivery chain, receiving sprint output from BAs, SAs, and developers, and orchestrating the path to production.

The Release Manager owns:

> The process of getting things from development into production — safely, predictably, and repeatably. Not the code (that's developers), not the architecture (that's the SA), not the requirements (that's the BA) — the pipeline, the cadence, the change management.

This subagent encodes that delivery discipline.

---

## Why a Release Manager Subagent?

AI coding assistants are great at writing code and even deploying it, but they don't naturally think in release cadence, environment strategy, rollback planning, or stakeholder communication. They solve the "deploy this" problem but miss the "should we deploy this, when, in what order, with what safeguards, and who needs to know?" problem.

The Release Manager subagent fills that gap:

- **Automation over manual steps.** If it's not in the pipeline, it's not reliable. The RM designs processes that run the same way every time.
- **Rollback before go-forward.** Every deployment plan includes a rollback procedure. "We'll figure it out" is not a plan.
- **Environments as a product.** Sandbox strategy, refresh cadence, data seeding, and environment drift prevention are first-class concerns.
- **Change management is deployment.** Getting metadata into production is the easy part. Getting users to adopt the change is the hard part. Communication plans, training coordination, and hypercare are release activities.
- **Release notes are a deliverable.** Stakeholders deserve clarity on what changed, why, and what they need to do.
- **Hotfixes have their own lane.** Emergency fixes bypass the regular cadence but not the safeguards.

---

## What It Does

The Release Manager subagent produces seven types of deliverables and operates across the full release lifecycle.

### Deliverables

| Deliverable | What You Get | When to Use It |
|---|---|---|
| **Release Plan** | Sprint-to-release mapping, deployment sequence, dependencies, risk assessment, go/no-go criteria, communication plan | Planning any release to production |
| **Environment Strategy** | Sandbox inventory, promotion path, refresh cadence, data seeding approach, environment-specific configs | Setting up or improving your sandbox topology |
| **CI/CD Pipeline Design** | Branching strategy, pipeline stages, quality gates, test requirements, deployment targets, notification strategy | Building or redesigning your deployment pipeline |
| **Deployment Checklist** | Pre-deployment steps, deployment commands, post-deployment validation, smoke tests, monitoring period | Executing any deployment |
| **Rollback Procedure** | Rollback triggers, steps for metadata vs. data vs. both, validation after rollback, communication | Required companion to every deployment |
| **Change Management Plan** | Stakeholder analysis, communication plan, training plan, adoption metrics, hypercare model | Any release that affects user workflows |
| **Release Notes** | New features, enhancements, bug fixes, known issues, admin/user actions required | Every production release |

### Position in the Delivery Chain

```
BA (requirements) → SA (architecture) → Developers (code) → Release Manager (pipeline to production)
                                                                     ↓
                                                              sf-deploy (executes commands)
                                                              sf-testing (runs tests in pipeline)
```

The Release Manager receives sprint output and owns everything from "dev complete" to "live in production and users are supported."

### RACI Boundaries

The Release Manager knows what it leads and what it defers:

| Task | RM Role | Who Else Leads |
|---|---|---|
| Release planning & scheduling | **Leads** | BA provides scope, SA consulted |
| CI/CD pipeline design | **Leads** | DevOps/Admin supports |
| Environment strategy | **Leads** | SA consulted, Admin executes refreshes |
| Deployment execution | **Leads** | sf-deploy executes commands |
| Rollback decisions | **Leads** | SA consulted, Dev supports |
| Change management | **Leads** | BA provides training content |
| Release notes | **Leads** | Dev provides change details |
| Code development | Informed | Developer leads |
| Architecture decisions | Consulted | SA leads |
| Requirements gathering | Informed | BA leads |

---

## How It Works

### The Skill System

Both Cursor and Claude Code support **skills** — markdown files that teach the AI assistant how to perform specific tasks. The Release Manager subagent consists of:

| File | Purpose |
|---|---|
| `SKILL.md` | Core instructions — identity, operating principles, deliverable workflows, RACI, scoring rubric, cross-skill delegation |
| `references/deliverables-guide.md` | Full templates for all seven deliverable types (loaded on-demand) |
| `references/release-patterns.md` | Branching strategies, sandbox patterns, CI/CD with SF CLI, conflict resolution, hotfix process, org comparison (loaded on-demand) |

### When It Activates

The subagent activates automatically when your prompt matches its trigger patterns:

- Planning a **release** or setting **release cadence**
- Designing **environment strategy** or managing **sandboxes**
- Building **CI/CD pipelines** or configuring **quality gates**
- Creating **deployment checklists** or **rollback procedures**
- Writing **change management plans** or coordinating **hypercare**
- Drafting **release notes**
- Comparing **orgs** or detecting **metadata drift**
- Designing a **hotfix process**

It will **not** activate for implementation work (writing Apex, building LWCs, configuring Flows, gathering requirements) — those are handled by their respective specialized skills.

### What Changes When the Release Manager Is Active

| Without RM | With RM |
|---|---|
| "Here's the deploy command" | "Here's the release plan with deployment sequence, rollback procedure, and stakeholder communication" |
| Deploys happen when code is ready | Deploys happen on a predictable cadence with defined gates |
| Sandbox refresh is ad hoc | Sandbox strategy is documented with refresh cadence and data seeding |
| Rollback is "redeploy the old code" | Rollback is a documented procedure with triggers, steps, validation, and communication |
| Release notes are an afterthought | Release notes are a deliverable reviewed before deployment |

---

## Deployment

### Prerequisites

- **Cursor** (any version with skills support) and/or **Claude Code** (any version with skills support)
- A terminal with `bash`, `curl`, and `git` (macOS and Linux have these by default)

### Where It Installs

| Platform | Install Path |
|---|---|
| Cursor | `~/.cursor/skills/sf-release-manager/` |
| Claude Code | `~/.claude/skills/sf-release-manager/` |

---

### Option 1: One-Liner Install (Recommended)

No clone required. Run one command in your terminal.

**Both Cursor and Claude Code:**

```bash
curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/ReleaseManager/install.sh | bash -s -- --both
```

**Cursor only:**

```bash
curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/ReleaseManager/install.sh | bash -s -- --cursor
```

**Claude Code only:**

```bash
curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/ReleaseManager/install.sh | bash -s -- --claude
```

Expected output:

```
╔════════════════════════════════════════════════════════╗
║  Salesforce Release Manager Subagent                  ║
║  CI/CD, environments & change management             ║
╚════════════════════════════════════════════════════════╝

  ✓ Installed to /Users/you/.cursor/skills/sf-release-manager (Cursor)
  ✓ Installed to /Users/you/.claude/skills/sf-release-manager (Claude Code)

Done! The Release Manager subagent will auto-activate when you:
  • Plan releases or set release cadence
  • Design CI/CD pipelines or environment strategy
  • Create deployment checklists or rollback procedures
  • Write change management plans or release notes
  • Manage sandboxes or compare org metadata
```

---

### Option 2: Clone and Install

```bash
git clone https://github.com/sfdc-brendan/Demo-Lab.git
cd Demo-Lab/subagents/ReleaseManager
chmod +x install.sh
./install.sh --both
```

---

### Option 3: Manual Copy

**For Cursor:**

```bash
mkdir -p ~/.cursor/skills/sf-release-manager/references

curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/ReleaseManager/SKILL.md \
  -o ~/.cursor/skills/sf-release-manager/SKILL.md

curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/ReleaseManager/references/deliverables-guide.md \
  -o ~/.cursor/skills/sf-release-manager/references/deliverables-guide.md

curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/ReleaseManager/references/release-patterns.md \
  -o ~/.cursor/skills/sf-release-manager/references/release-patterns.md
```

**For Claude Code:**

```bash
mkdir -p ~/.claude/skills/sf-release-manager/references

curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/ReleaseManager/SKILL.md \
  -o ~/.claude/skills/sf-release-manager/SKILL.md

curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/ReleaseManager/references/deliverables-guide.md \
  -o ~/.claude/skills/sf-release-manager/references/deliverables-guide.md

curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/ReleaseManager/references/release-patterns.md \
  -o ~/.claude/skills/sf-release-manager/references/release-patterns.md
```

---

## Verifying the Install

```bash
# For Cursor
ls -la ~/.cursor/skills/sf-release-manager/
ls -la ~/.cursor/skills/sf-release-manager/references/

# For Claude Code
ls -la ~/.claude/skills/sf-release-manager/
ls -la ~/.claude/skills/sf-release-manager/references/
```

You should see:

```
sf-release-manager/
├── SKILL.md
└── references/
    ├── deliverables-guide.md
    └── release-patterns.md
```

To confirm the skill is loaded, try a prompt like:

> "Design a CI/CD pipeline for a team doing bi-weekly releases to a production org."

The agent should begin by asking about team size, current deployment method, source control, and environment topology — not by writing a GitHub Actions YAML file.

---

## Using the Release Manager Subagent

### 1. Release Plans

**Example prompts:**

> "Create a release plan for Sprint 8 output. We have 5 user stories, 2 bug fixes, and a Flow update going to production next Friday."

> "Plan a quarterly release that includes schema changes, new Apex classes, 3 Flows, and a data migration. We need to coordinate across two dev teams."

**What you get:** Sprint-to-release mapping, deployment sequence with dependency ordering, risk assessment, go/no-go criteria, and a communication plan.

---

### 2. Environment Strategy

**Example prompts:**

> "Design a sandbox strategy for a team of 8 developers working on Sales Cloud and Service Cloud. We have Enterprise Edition."

> "Our sandboxes are a mess — we don't know which ones are stale, who owns them, or when to refresh. Help us create an environment strategy."

**What you get:** Sandbox inventory template, promotion path diagram, refresh cadence, data seeding approach, and environment-specific configuration matrix.

---

### 3. CI/CD Pipeline Design

**Example prompts:**

> "Design a CI/CD pipeline for a team doing bi-weekly releases to a production org. We use GitHub and want automated validation on PRs."

> "We're moving from change sets to CLI-based deployments. Design the pipeline stages and quality gates."

**What you get:** Branching strategy, pipeline stage definitions, quality gates with enforcement mechanisms, test level recommendations per stage, notification strategy, and pipeline YAML skeleton.

---

### 4. Deployment Checklists

**Example prompts:**

> "Create a deployment checklist for Friday's release. It includes 3 Apex classes, a Flow, custom fields, and permission set updates."

> "We need a reusable deployment checklist template that works for any release."

**What you get:** Pre-deployment verification, step-by-step deployment commands, post-deployment validation including smoke tests, monitoring period definition, and stakeholder notification plan.

---

### 5. Rollback Procedures

**Example prompts:**

> "Create a rollback procedure for a metadata-only deployment that includes Apex classes, Flows, and page layouts."

> "We're deploying destructive changes (removing deprecated fields). What's the rollback plan if something goes wrong?"

**What you get:** Rollback triggers, steps specific to the deployment type (metadata vs. data vs. destructive), validation checklist after rollback, communication plan, and re-deployment strategy.

---

### 6. Change Management Plans

**Example prompts:**

> "We're rolling out a new case management process to 200 service agents. Create a change management plan."

> "Design a hypercare plan for the first two weeks after our major release."

**What you get:** Stakeholder analysis with impact levels, communication plan with timeline, training plan coordinated with BA, adoption metrics, resistance management strategy, and hypercare support model.

---

### 7. Release Notes

**Example prompts:**

> "Draft release notes for v2.5. We added automated case routing, fixed the duplicate contact bug, and enhanced the opportunity dashboard."

> "Create a release notes template we can reuse for every bi-weekly release."

**What you get:** Categorized changes (features, enhancements, fixes), user-facing descriptions, admin and user action items, known issues with workarounds, and technical deployment details.

---

### 8. Scoring Deliverables

After any deliverable is produced, you can request a quality score:

> "Score this release plan against the Release Manager rubric."

| Category | Points | What It Measures |
|---|---|---|
| Process Reliability | 25 | Deployments are predictable and repeatable |
| Automation Coverage | 20 | Pipeline steps are automated, manual steps are justified |
| Risk Mitigation | 20 | Rollback procedures exist, destructive changes flagged, go/no-go defined |
| Stakeholder Communication | 20 | Release notes complete, change management planned, users informed |
| Repeatability | 15 | Process works the same way every time, templates enforce consistency |

| Score Range | Meaning |
|---|---|
| 85–100 | Production-ready process — deploy with confidence |
| 70–84 | Solid foundation — minor gaps to address |
| 50–69 | Good direction — needs process hardening |
| Below 50 | Return to pipeline design fundamentals |

---

## How It Integrates with Other Skills

The Release Manager owns the pipeline and delegates implementation. If you have other Salesforce skills installed, delegation happens automatically:

| When the RM needs... | Delegation goes to... |
|---|---|
| Deployment commands executed | `sf-deploy` (runs `sf project deploy`, validation, quick deploy) |
| Sprint scope and user stories | `sf-ba` (provides what's in the release) |
| Architecture and environment input | `sf-sa` (informs sandbox topology, integration strategy) |
| Test execution in the pipeline | `sf-testing` (runs Apex tests, checks coverage) |
| Apex code being deployed | `sf-apex` (developers write the code) |
| LWC components being deployed | `sf-lwc` (developers build the components) |
| Flow automation in the release | `sf-flow` (declarative automation) |
| Metadata schema changes | `sf-metadata` (objects, fields, rules) |
| Pipeline and environment diagrams | `sf-diagram-mermaid` (visual process flows) |

The Release Manager pairs naturally with the **BA subagent** (receives sprint scope) and the **SA subagent** (receives environment and architecture guidance). Together they form the delivery chain: BA defines what to build, SA defines how to build it, developers build it, and the Release Manager gets it to production.

---

## File Reference

```
subagents/ReleaseManager/
├── README.md                              ← You are here
├── SKILL.md                               ← Core skill (loaded into AI context)
├── install.sh                             ← Deployment script
└── references/
    ├── deliverables-guide.md              ← Templates for all 7 deliverable types
    └── release-patterns.md                ← Branching, sandbox, CI/CD, hotfix patterns
```

| File | Lines | Purpose |
|---|---|---|
| `SKILL.md` | ~250 | Core identity, operating principles, RACI, deliverable workflows, release cadence patterns, scoring rubric, cross-skill delegation. Always loaded when the skill activates. |
| `references/deliverables-guide.md` | ~350 | Detailed templates for release plans, environment strategy, CI/CD pipeline design, deployment checklists, rollback procedures, change management plans, and release notes. Loaded on-demand. |
| `references/release-patterns.md` | ~380 | Branching strategies for Salesforce, sandbox strategy patterns, CI/CD with SF CLI, metadata conflict resolution, destructive changes, multi-package ordering, release cadence patterns, hotfix process, org comparison, change set vs CLI vs DevOps Center. Loaded on-demand. |

---

## Updating

Re-run the install command. It detects existing installations and replaces them:

```bash
curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/ReleaseManager/install.sh | bash -s -- --both
```

---

## Uninstalling

```bash
# Cursor
rm -rf ~/.cursor/skills/sf-release-manager

# Claude Code
rm -rf ~/.claude/skills/sf-release-manager
```

---

## FAQ

**Q: Do I need the BA or SA subagents installed too?**
No. The Release Manager works standalone. If you also have `sf-ba` and `sf-sa` installed, the RM will receive sprint scope from the BA and environment guidance from the SA. They complement each other but neither requires the other.

**Q: Will this conflict with the sf-deploy skill?**
No. The Release Manager designs the pipeline and process. `sf-deploy` executes the deployment commands. The RM delegates to `sf-deploy` for the actual `sf project deploy` operations. The RM thinks in "release plan," `sf-deploy` thinks in "deploy command."

**Q: Can I use this with third-party DevOps tools (Copado, Gearset, Flosum)?**
Yes. The Release Manager's deliverables (release plans, checklists, rollback procedures, change management) are tool-agnostic. The CI/CD pipeline design section focuses on Salesforce CLI + GitHub Actions as the reference pattern, but the principles apply to any pipeline tool.

**Q: What Salesforce editions does this cover?**
All of them, but sandbox limits vary by edition. The environment strategy accounts for this — Developer Edition gets developer sandboxes only, while Enterprise and above get partial and full copy sandboxes. The RM will ask about your edition when designing environment strategy.

**Q: How is this different from the SA subagent?**
The SA makes architecture decisions — what to build, how systems connect, which patterns to use. The Release Manager manages how that architecture gets safely from development into production. The SA asks "what's the right design?" The RM asks "how do we deploy it without breaking anything?"

**Q: How is this different from sf-deploy?**
`sf-deploy` is a skill for executing deployment commands — it knows `sf project deploy`, validation deploys, test levels, and CLI flags. The Release Manager is a skill for managing the entire release lifecycle — cadence, environment strategy, pipeline design, rollback planning, change management. The RM orchestrates; `sf-deploy` executes.

**Q: Does this work for ISV/managed package releases?**
The core patterns apply. Package versioning, subscriber org compatibility testing, and AppExchange review processes add ISV-specific steps that the RM can incorporate into the release plan and deployment checklist.
