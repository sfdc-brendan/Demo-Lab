# Distinguished Solutions Engineer (DSE) Subagent

> A strategic AI advisor for **Cursor** and **Claude Code** that thinks and operates at the Distinguished Solutions Engineer level — the highest individual contributor role in the Salesforce SE organization.

---

## Table of Contents

- [What Is This?](#what-is-this)
- [Why a DSE Subagent?](#why-a-dse-subagent)
- [What It Does](#what-it-does)
- [How It Works](#how-it-works)
- [Deployment](#deployment)
  - [Option 1: One-Liner Install](#option-1-one-liner-install-recommended)
  - [Option 2: Clone and Install](#option-2-clone-and-install)
  - [Option 3: Manual Copy](#option-3-manual-copy)
- [Verifying the Install](#verifying-the-install)
- [Using the DSE Subagent](#using-the-dse-subagent)
  - [Executive Briefings](#1-executive-briefings)
  - [Strategic Demo Scripts](#2-strategic-demo-scripts)
  - [GTM Plays](#3-gtm-plays)
  - [Points of View (POVs)](#4-points-of-view-povs)
  - [SE Enablement Sessions](#5-se-enablement-sessions)
  - [Voice of the Customer Briefs](#6-voice-of-the-customer-briefs)
  - [Must-Win Deal Consultancy](#7-must-win-deal-consultancy)
  - [Scoring Deliverables](#8-scoring-deliverables)
- [How It Integrates with Other Skills](#how-it-integrates-with-other-skills)
- [File Reference](#file-reference)
- [Updating](#updating)
- [Uninstalling](#uninstalling)
- [FAQ](#faq)

---

## What Is This?

This is a **subagent** — a skill file that teaches Claude (in Cursor or Claude Code) how to operate as a specific persona with specific expertise. When installed, it gives your AI coding assistant the strategic mindset, frameworks, and deliverable templates of a Salesforce Distinguished Solutions Engineer.

A Distinguished Solutions Engineer is:

> "A luminary of strategic, industry and architectural knowledge who envisions and conveys next-generation solutions that provide exceptional business value to customers."

The DSE title is limited to roughly 3–5% of the SE org. These are individuals who have earned organizational trust and, if required, could sell and present alongside Salesforce's most senior executives.

This subagent encodes that operating model into an AI assistant.

---

## Why a DSE Subagent?

Most AI coding assistants default to implementation mode — they jump straight to writing code. That's perfect for building a component or fixing a bug, but it misses the strategic layer that separates good demos from great ones, and feature lists from executive conversations.

The DSE subagent fills that gap. It:

- **Thinks in business outcomes before features.** Instead of "here's how Data Cloud ingests data," it starts with "here's why your customer's CIO cares about unified customer data."
- **Architects across the full Salesforce platform.** When you ask about one cloud, it considers whether adjacent capabilities would strengthen the story.
- **Produces reusable strategic assets.** Every deliverable is designed as a template that scales across your team, territory, or business unit.
- **Communicates at executive register.** Crisp, outcome-oriented language structured as situation → complication → resolution.
- **Knows when to delegate.** It doesn't try to write Apex or LWC code itself — it hands that off to the right specialized skill and stays focused on strategy.

---

## What It Does

The DSE subagent produces six types of strategic deliverables and operates in three engagement patterns.

### Deliverables

| Deliverable | What You Get | When to Use It |
|---|---|---|
| **Executive Briefing** | Customer-specific C-suite presentation with insights, architecture vision, tailored demo narrative, and mutual next steps | Preparing for an exec meeting, SIC, or strategic account review |
| **Strategic Demo Script** | Narrative-arc demo with talk track, setup notes, reusable/customizable sections, and objection prep | Building a demo for a must-win deal or a repeatable industry demo |
| **GTM Play** | Segment-targeted play with discovery framework, competitive positioning, reference architecture, and success metrics | Scaling a winning approach across a territory or business unit |
| **POV / White Paper** | Strategic thesis with industry context, cross-cloud architecture, business value framework, and customer evidence | Positioning Salesforce for a strategic initiative or competitive situation |
| **SE Enablement Session** | Coaching content structured as concept → demo → practice → debrief, with annotations and self-assessment | Up-leveling your SE team on a product area, demo technique, or industry play |
| **Voice of the Customer Brief** | Aggregated field signals with quantified impact, current workarounds, proposed direction, and competitive context | Feeding product gaps or customer pain points back to PM teams |

### Engagement Patterns

| Pattern | What It Does |
|---|---|
| **Must-Win Deal** | Rapid account download → win theme development → demo & proof strategy → executive engagement → debrief. The "special forces" mode for Big Bet accounts. |
| **Territory Planning** | Landscape analysis → account tiering → GTM play mapping → resource allocation → quarterly review cadence. Co-planning with Sales leadership. |
| **Product Partnership** | Signal collection → theme aggregation → PM engagement → feedback loop. Being the Voice of the Customer back to Product. |

---

## How It Works

### The Skill System

Both Cursor and Claude Code support **skills** — markdown files that teach the AI assistant how to perform specific tasks. Skills are stored in a known directory, and the AI reads them automatically when it detects a matching scenario.

The DSE subagent is a skill. It consists of:

| File | Purpose |
|---|---|
| `SKILL.md` | Core instructions — identity, operating principles, deliverable workflows, scoring rubric, cross-skill delegation rules |
| `references/deliverables-guide.md` | Full templates for all six deliverable types (loaded on-demand, not always in context) |
| `references/engagement-patterns.md` | Detailed frameworks for must-win deals, territory planning, and product partnership (loaded on-demand) |

### When It Activates

The subagent activates automatically when your prompt matches its trigger patterns. You don't need to explicitly invoke it. It will engage when you:

- Ask for help with **cross-cloud architecture** or **multi-product solutions**
- Request **executive-facing deliverables** (briefings, POVs, demo scripts)
- Need **GTM play design** or **territory planning**
- Want **DSE-level review** of a solution or presentation
- Ask for **SE enablement** or **coaching content**
- Need to synthesize **product feedback** for PM teams

It will **not** activate for single-product implementation work (writing Apex, building an LWC, deploying metadata) — those are handled by their respective specialized skills.

### What "Strategic Altitude" Means in Practice

When the DSE subagent is active, it changes how the AI approaches your request:

| Without DSE | With DSE |
|---|---|
| "Here's how to configure Data Cloud" | "Here's why your customer's CRO cares about unified data, and here's the architecture that connects Data Cloud to their revenue goals" |
| Lists product features | Frames the business outcome first, then maps capabilities to customer priorities |
| Writes one-off content | Creates reusable templates with labeled customization points |
| Uses technical jargon | Uses executive register — situation, complication, resolution |

---

## Deployment

### Prerequisites

- **Cursor** (any version with skills support) and/or **Claude Code** (any version with skills support)
- A terminal with `bash`, `curl`, and `git` available (macOS and Linux have these by default)

### Where It Installs

| Platform | Install Path |
|---|---|
| Cursor | `~/.cursor/skills/sf-dse/` |
| Claude Code | `~/.claude/skills/sf-dse/` |

The skill content is identical for both platforms. Only the directory differs.

---

### Option 1: One-Liner Install (Recommended)

No clone required. Run one command in your terminal.

**Install for both Cursor and Claude Code:**

```bash
curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/DSE/install.sh | bash -s -- --both
```

**Install for Cursor only:**

```bash
curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/DSE/install.sh | bash -s -- --cursor
```

**Install for Claude Code only:**

```bash
curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/DSE/install.sh | bash -s -- --claude
```

You should see output like:

```
╔════════════════════════════════════════════════════════╗
║  Distinguished Solutions Engineer (DSE) Subagent      ║
║  Strategic advisor for Salesforce platform work       ║
╚════════════════════════════════════════════════════════╝

  ✓ Installed to /Users/you/.cursor/skills/sf-dse (Cursor)
  ✓ Installed to /Users/you/.claude/skills/sf-dse (Claude Code)

Done! The DSE subagent will auto-activate when you:
  • Ask for cross-cloud architecture or executive-facing deliverables
  • Need POVs, GTM plays, demo scripts, or exec briefings
  • Request DSE-level review of a solution
```

---

### Option 2: Clone and Install

If you prefer to inspect the files first or already have the repo cloned:

```bash
git clone https://github.com/sfdc-brendan/Demo-Lab.git
cd Demo-Lab/subagents/DSE
chmod +x install.sh
./install.sh --both
```

---

### Option 3: Manual Copy

If you'd rather handle it yourself:

**For Cursor:**

```bash
mkdir -p ~/.cursor/skills/sf-dse/references

curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/DSE/SKILL.md \
  -o ~/.cursor/skills/sf-dse/SKILL.md

curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/DSE/references/deliverables-guide.md \
  -o ~/.cursor/skills/sf-dse/references/deliverables-guide.md

curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/DSE/references/engagement-patterns.md \
  -o ~/.cursor/skills/sf-dse/references/engagement-patterns.md
```

**For Claude Code:**

```bash
mkdir -p ~/.claude/skills/sf-dse/references

curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/DSE/SKILL.md \
  -o ~/.claude/skills/sf-dse/SKILL.md

curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/DSE/references/deliverables-guide.md \
  -o ~/.claude/skills/sf-dse/references/deliverables-guide.md

curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/DSE/references/engagement-patterns.md \
  -o ~/.claude/skills/sf-dse/references/engagement-patterns.md
```

---

## Verifying the Install

After installing, verify the files are in place:

```bash
# For Cursor
ls -la ~/.cursor/skills/sf-dse/
ls -la ~/.cursor/skills/sf-dse/references/

# For Claude Code
ls -la ~/.claude/skills/sf-dse/
ls -la ~/.claude/skills/sf-dse/references/
```

You should see three files:

```
sf-dse/
├── SKILL.md
└── references/
    ├── deliverables-guide.md
    └── engagement-patterns.md
```

To confirm the skill is loaded, open Cursor or Claude Code and try a prompt like:

> "I need to prepare an executive briefing for a healthcare customer evaluating Service Cloud and Data Cloud."

The agent should respond with strategic framing (their business priorities, industry context) rather than jumping straight to product configuration.

---

## Using the DSE Subagent

Below are example prompts for each capability, along with what you can expect the agent to produce.

### 1. Executive Briefings

**Example prompts:**

> "Help me prepare an executive briefing for the CIO of a Tier 1 telecom company. They're evaluating Data Cloud and Agentforce for customer retention."

> "I have a CRO meeting at a financial services firm next week. They're currently on ServiceNow for case management and we need to position Service Cloud + AI."

**What you get:** A structured briefing document with:
- Their strategic context (demonstrates you've done the homework)
- 2–3 tailored insights mapped to their priorities
- Architecture vision with a cross-cloud diagram
- Demo narrative structured as business scenarios, not feature tours
- Mutual next steps with owners and timelines
- Pre-brief intel section (stakeholder map, landmines to avoid)

---

### 2. Strategic Demo Scripts

**Example prompts:**

> "Build a demo script for a 15-minute Service Cloud + Agentforce demo targeted at VP of Customer Service in retail."

> "I need a reusable demo narrative for Data Cloud + Marketing Cloud in financial services. It should work across multiple accounts with minimal customization."

**What you get:** A narrative-arc demo script with:
- Persona and business scenario (day-in-the-life framing)
- Setup requirements (org, data, integrations)
- Scripted talk track for each beat
- Sections marked as `[REUSABLE]` or `[CUSTOMIZE]`
- Transition language between sections
- Objection prep matrix

---

### 3. GTM Plays

**Example prompts:**

> "Design a GTM play for mid-market healthcare organizations looking to modernize patient engagement with Experience Cloud and Health Cloud."

> "Create a competitive displacement play for accounts currently on Zendesk moving to Service Cloud + Agentforce."

**What you get:** A complete play with:
- Target segment, industry, buyer persona, and trigger event
- Customer pain point in their language
- Solution narrative with reference architecture
- Discovery frameworks for both AEs and SEs
- Competitive positioning matrix
- Reusable asset inventory
- Measurable success metrics

---

### 4. Points of View (POVs)

**Example prompts:**

> "Write a POV on why telecom companies need a unified customer data strategy, positioning Data Cloud + Agentforce as the answer."

> "I need a white paper on AI-powered service transformation for manufacturing. It should be reusable across the territory."

**What you get:** A strategic document with:
- Executive summary (thesis, impact, platform response)
- Industry context (macro pressures, transformation opportunity)
- Current state challenges mapped to stakeholders
- Cross-cloud architecture with capability mapping
- Business value framework with quantified KPIs
- Customer evidence and recommended next steps

---

### 5. SE Enablement Sessions

**Example prompts:**

> "Create an enablement session teaching SEs how to demo Agentforce at C-suite altitude instead of doing a technical walkthrough."

> "Build a 45-minute workshop on presenting Data Cloud to non-technical executives."

**What you get:** A structured enablement plan with:
- Clear learning objective
- Concept section (strategic framing, mental models)
- Live demo with coaching annotations (common mistakes vs. better approaches)
- Practice exercise with scenarios and evaluation criteria
- Self-assessment questions
- Follow-up resources

---

### 6. Voice of the Customer Briefs

**Example prompts:**

> "I've been hearing from multiple accounts that Data Cloud's identity resolution is too complex to configure. Synthesize this into a VoC brief for PM."

> "Three Big Bet deals this quarter hit a wall because Agentforce can't do X. Help me write this up for the product team."

**What you get:** A PM-ready brief with:
- Signal summary
- Field evidence (deals, segments, revenue impact, verbatims)
- Current workaround and its limitations
- Proposed direction with options
- Competitive context
- Prioritization rationale

---

### 7. Must-Win Deal Consultancy

**Example prompts:**

> "I'm the overlay SE on a must-win deal at a Fortune 500 insurance company. They're evaluating us against Microsoft and ServiceNow. Walk me through how to approach this."

> "We have a CRO-priority account in telecom. The previous demo didn't land. Help me redesign the strategy."

**What you get:** A phased engagement plan:
1. Rapid account download (what to gather from the account team)
2. Win theme development (2–3 differentiated themes mapped to stakeholders)
3. Demo and proof strategy (narrative, deep-dive, POC scope)
4. Executive engagement guidance (how to present)
5. Debrief framework (capture what worked)

---

### 8. Scoring Deliverables

After the agent produces any deliverable, you can ask it to score the output:

> "Score this briefing against the DSE rubric."

It evaluates on a 100-point scale:

| Category | Points | What It Measures |
|---|---|---|
| Strategic Framing | 25 | Business outcome orientation, industry context, executive register |
| Architecture Breadth | 20 | Cross-cloud thinking, platform-wide lens, integration coherence |
| Reusability | 20 | Template-ready structure, labeled customization points, adaptable to other accounts |
| Executive Communication | 20 | Narrative clarity, situation-complication-resolution structure, "so what" factor |
| Actionability | 15 | Clear next steps, discovery questions, measurable success criteria |

| Score Range | Meaning |
|---|---|
| 85–100 | Executive-ready — ship it |
| 70–84 | Strong foundation — minor refinement needed |
| 50–69 | Good direction — needs strategic sharpening |
| Below 50 | Rethink framing and audience alignment |

---

## How It Integrates with Other Skills

The DSE subagent is an orchestrator. It handles strategy and delegates implementation to specialized skills. If you have other Salesforce skills installed, it will hand off automatically:

| When the DSE identifies... | It delegates to... |
|---|---|
| Apex code is needed | `sf-apex` |
| An LWC component is needed | `sf-lwc` |
| A Flow should be built | `sf-flow` |
| Data Cloud pipeline design | `sf-datacloud` |
| An Agentforce agent is needed | `sf-ai-agentforce` |
| An architecture diagram is needed | `sf-diagram-mermaid` |
| Integration patterns are needed | `sf-integration` |
| Metadata/schema work is needed | `sf-metadata` |
| SOQL is needed | `sf-soql` |
| Deployment is needed | `sf-deploy` |

If those skills aren't installed, the DSE will still produce the strategic deliverable — it just won't have specialized implementation support for the handoff.

---

## File Reference

```
subagents/DSE/
├── README.md                            ← You are here
├── SKILL.md                             ← Core skill (loaded into AI context)
├── install.sh                           ← Deployment script
└── references/
    ├── deliverables-guide.md            ← Full templates for all 6 deliverable types
    └── engagement-patterns.md           ← Must-win deal, territory planning, product partnership frameworks
```

| File | Lines | Purpose |
|---|---|---|
| `SKILL.md` | 231 | Core identity, operating principles, deliverable workflows, scoring rubric, cross-skill delegation. Always loaded when the skill activates. |
| `references/deliverables-guide.md` | 308 | Detailed markdown templates for POVs, executive briefings, demo scripts, GTM plays, enablement sessions, and VoC briefs. Loaded on-demand when the agent needs to generate a specific deliverable. |
| `references/engagement-patterns.md` | 191 | Phased frameworks for must-win deals (5 phases), territory planning (5 steps), product partnership (4 steps), plus executive engagement principles and coaching frameworks. Loaded on-demand. |

---

## Updating

To update to the latest version, re-run the install command. The installer detects an existing installation and replaces it:

```bash
curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/DSE/install.sh | bash -s -- --both
```

You'll see:

```
  Existing install found at /Users/you/.cursor/skills/sf-dse — updating...
  ✓ Installed to /Users/you/.cursor/skills/sf-dse (Cursor)
```

---

## Uninstalling

```bash
# Cursor
rm -rf ~/.cursor/skills/sf-dse

# Claude Code
rm -rf ~/.claude/skills/sf-dse
```

---

## FAQ

**Q: Do I need other Salesforce skills installed for this to work?**
No. The DSE subagent works standalone. If you also have `sf-apex`, `sf-lwc`, `sf-datacloud`, or other specialized skills installed, it will delegate implementation work to them. Without them, it still produces all strategic deliverables — it just won't auto-generate implementation code.

**Q: Will this conflict with my existing skills?**
No. The DSE subagent has clear trigger boundaries. It only activates for strategic, cross-cloud, executive-level work. Single-product tasks (writing Apex, building an LWC, deploying metadata) continue to be handled by their respective skills.

**Q: Can I customize the templates?**
Yes. After installing, edit the files directly at `~/.cursor/skills/sf-dse/` or `~/.claude/skills/sf-dse/`. Changes persist until you re-run the installer (which overwrites).

**Q: What Salesforce clouds/products does it cover?**
All of them. The DSE subagent thinks across Sales Cloud, Service Cloud, Marketing Cloud, Commerce Cloud, Data Cloud, MuleSoft, Tableau, Agentforce, Experience Cloud, Revenue Cloud, and Industries clouds. That's the point — it operates at the platform level, not the individual product level.

**Q: Does it work on Windows?**
The skill files work on any platform. The `install.sh` script requires bash (available on macOS, Linux, and Windows via WSL or Git Bash). For native Windows without bash, use the [Manual Copy](#option-3-manual-copy) method with PowerShell equivalents.

**Q: How do I know it's active?**
When you ask a question that matches its trigger patterns (cross-cloud architecture, executive deliverables, GTM plays, etc.), you'll notice the response starts with strategic framing rather than jumping to implementation. If you're unsure, ask: "Are you operating in DSE mode?" and it will confirm.
