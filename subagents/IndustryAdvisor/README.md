# Salesforce Industry Advisor Subagent

> A **force multiplier** for Cursor and Claude Code that adds deep vertical expertise to every Salesforce conversation. The Industry Advisor knows that "case management" means something completely different in healthcare vs financial services vs telecom — and ensures your AI assistant does too.

---

## Table of Contents

- [What Is This?](#what-is-this)
- [Why an Industry Advisor?](#why-an-industry-advisor)
- [What It Does](#what-it-does)
- [How It Works](#how-it-works)
- [Deployment](#deployment)
  - [Option 1: One-Liner Install](#option-1-one-liner-install-recommended)
  - [Option 2: Clone and Install](#option-2-clone-and-install)
  - [Option 3: Manual Copy](#option-3-manual-copy)
- [Verifying the Install](#verifying-the-install)
- [Using the Industry Advisor](#using-the-industry-advisor)
  - [Industry Process Maps](#1-industry-process-maps)
  - [Regulatory Compliance](#2-regulatory-compliance)
  - [Industry Data Models](#3-industry-data-models)
  - [Terminology Translation](#4-terminology-translation)
  - [Industry Benchmarks](#5-industry-benchmarks)
  - [Compliance Matrices](#6-compliance-matrices)
  - [Scoring Deliverables](#7-scoring-deliverables)
- [How It Enriches Other Skills](#how-it-enriches-other-skills)
- [Industry Coverage](#industry-coverage)
- [File Reference](#file-reference)
- [Updating](#updating)
- [Uninstalling](#uninstalling)
- [FAQ](#faq)

---

## What Is This?

This is a **subagent** — a skill file that teaches Claude (in Cursor or Claude Code) how to operate as a specific persona with specific expertise. When installed, it gives your AI coding assistant deep vertical knowledge across nine industries, including regulations, terminology, KPIs, data models, and Salesforce industry cloud mappings.

The Industry Advisor is not a standalone role — it's a **force multiplier** that enriches every other subagent:

| When combined with... | The Industry Advisor adds... |
|---|---|
| **DSE** (Distinguished Solutions Engineer) | Industry metrics to executive briefings; vertical credibility to POVs |
| **BA** (Business Analyst) | Regulatory constraints to requirements; industry terminology to user stories |
| **SA** (Solution Architect) | Industry data models to architecture; compliance requirements to design decisions |
| **SE** (Solutions Engineer) | Vertical context to demos; industry-specific discovery questions |

---

## Why an Industry Advisor?

Generic Salesforce advice is dangerous in regulated industries. Consider:

- Recommending a data model without understanding HIPAA's minimum necessary principle
- Designing an integration without knowing that telecom orders must decompose across BSS/OSS
- Building a financial services solution without KYC/AML compliance gates
- Creating a public sector solution without FedRAMP authorization awareness

The Industry Advisor prevents these mistakes by injecting vertical context into every recommendation.

---

## What It Does

The Industry Advisor produces six core deliverables:

1. **Industry Process Maps** — Real-world processes with regulatory touchpoints and compliance gates
2. **Regulatory Compliance Checklists** — Regulation-by-regulation breakdown with Salesforce feature mapping
3. **Industry Data Model Recommendations** — Vertical-specific objects, fields, and sharing models
4. **Vertical Terminology Glossaries** — Bridge between customer language and Salesforce language
5. **Industry Benchmark Reports** — KPIs with benchmarks and Salesforce improvement pathways
6. **Compliance Requirement Matrices** — Granular regulation-to-configuration mapping

Every deliverable is self-scored on a 100-point rubric before presentation.

---

## How It Works

The skill file (`SKILL.md`) teaches the AI assistant to:

1. **Identify the vertical and sub-vertical** before making any recommendation
2. **Load the regulatory context** that constrains the solution
3. **Speak the customer's language** — translate Salesforce terms to industry terms
4. **Map to industry clouds** when they exist (Health Cloud, FSC, Communications Cloud, etc.)
5. **Connect capabilities to industry KPIs** — metrics the customer actually measures
6. **Cross-pollinate** — recognize patterns from one industry that solve problems in another

Reference files provide deep-dive templates and industry-specific patterns.

---

## Deployment

### Option 1: One-Liner Install (Recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/IndustryAdvisor/install.sh | bash -s -- --both
```

Flags:
- `--cursor` — Install for Cursor IDE only
- `--claude` — Install for Claude Code only
- `--both` — Install for both (recommended)

### Option 2: Clone and Install

```bash
git clone https://github.com/sfdc-brendan/Demo-Lab.git
cd Demo-Lab/subagents/IndustryAdvisor
chmod +x install.sh
./install.sh --both
```

### Option 3: Manual Copy

```bash
# For Cursor
mkdir -p ~/.cursor/skills/sf-industry-advisor/references
cp SKILL.md ~/.cursor/skills/sf-industry-advisor/
cp references/*.md ~/.cursor/skills/sf-industry-advisor/references/

# For Claude Code
mkdir -p ~/.claude/skills/sf-industry-advisor/references
cp SKILL.md ~/.claude/skills/sf-industry-advisor/
cp references/*.md ~/.claude/skills/sf-industry-advisor/references/
```

---

## Verifying the Install

After installation, test with a prompt that requires vertical knowledge:

> "What regulatory requirements affect a healthcare CRM implementation on Salesforce?"

The assistant should respond with HIPAA details (Privacy Rule, Security Rule, Breach Notification), Health Cloud recommendations, PHI handling requirements, and specific Salesforce Shield features — not generic CRM advice.

---

## Using the Industry Advisor

### 1. Industry Process Maps

**Example prompt:**
> "Map the telecom subscriber lifecycle to Salesforce objects — from acquisition through retention through win-back."

The assistant will produce a process map using telecom terminology (subscriber, ARPU, churn), identify regulatory touchpoints (CPNI consent), and map each step to Communications Cloud objects.

### 2. Regulatory Compliance

**Example prompt:**
> "What regulatory requirements affect a healthcare CRM implementation?"

The assistant will enumerate HIPAA requirements (Privacy Rule, Security Rule, Breach Notification), map each to Salesforce features (Shield, Event Monitoring, FLS), and identify gaps.

### 3. Industry Data Models

**Example prompt:**
> "Recommend a data model for a wealth management firm using Financial Services Cloud."

The assistant will start from the FSC data model (Households, Financial Accounts, Financial Holdings), add wealth-specific objects (Investment Preferences, Risk Profile), and address compliance requirements (fiduciary rules, SEC/FINRA).

### 4. Terminology Translation

**Example prompt:**
> "Create a terminology glossary for a payer (health insurance) Salesforce implementation."

The assistant will map industry terms (Member, Claim, EOB, Prior Authorization, Formulary) to Salesforce objects and flag common confusion points.

### 5. Industry Benchmarks

**Example prompt:**
> "What KPIs should we track for a telecom churn reduction initiative, and how does Salesforce improve them?"

The assistant will identify vertical-specific metrics (churn rate, ARPU, NPS, FCR), provide industry benchmarks, and map each to Salesforce capabilities with expected improvement ranges.

### 6. Compliance Matrices

**Example prompt:**
> "Build a HIPAA Security Rule compliance matrix for our Health Cloud implementation."

The assistant will list every Security Rule requirement, map each to specific Salesforce configuration (not just feature names), and include validation approaches for auditors.

### 7. Scoring Deliverables

**Example prompt:**
> "Score this industry process map against the 100-point rubric."

The assistant will evaluate against: Industry Accuracy (25 pts), Regulatory Awareness (20 pts), Terminology Precision (20 pts), KPI Relevance (20 pts), and Actionability (15 pts).

---

## How It Enriches Other Skills

The Industry Advisor is designed to work alongside other subagents:

### DSE + Industry Advisor
```
"Prepare an executive briefing for a hospital CIO about Salesforce Health Cloud."
```
The DSE structures the briefing; the Industry Advisor adds HIPAA context, care coordination KPIs, and EHR integration patterns.

### BA + Industry Advisor
```
"Write user stories for a bank's client onboarding process."
```
The BA structures the stories; the Industry Advisor adds KYC/AML requirements, compliance gates, and banking terminology.

### SA + Industry Advisor
```
"Design the data architecture for a telecom subscriber management platform."
```
The SA designs the architecture; the Industry Advisor adds Communications Cloud objects, BSS/OSS integration patterns, and CPNI data handling requirements.

### SE + Industry Advisor
```
"Prepare discovery questions for a manufacturing company evaluating Salesforce."
```
The SE structures the discovery; the Industry Advisor adds questions about ERP integration, dealer/distributor channels, and sales agreement complexity.

---

## Industry Coverage

| Industry | Sub-Verticals | Industry Cloud | Key Regulations |
|---|---|---|---|
| Healthcare | Provider, Payer, Pharma, MedTech, Life Sciences | Health Cloud | HIPAA, HITECH, FDA 21 CFR Part 11 |
| Financial Services | Banking, Insurance, Wealth, Mortgage | Financial Services Cloud | SOX, KYC/AML, GDPR, PCI-DSS |
| Telecom/Media | Mobile, Fixed-Line, Cable, OTT | Communications Cloud | FCC, CPNI |
| Manufacturing | Discrete, Process, Industrial, Automotive, A&D | Manufacturing Cloud | OSHA, EPA, ITAR/EAR |
| Retail/CPG | Brick-and-Mortar, E-Commerce, D2C, CPG | Commerce Cloud, Consumer Goods Cloud | PCI-DSS, CCPA/GDPR |
| Public Sector | Federal, State, Local, Tribal | Public Sector Solutions | FedRAMP, FISMA, Section 508 |
| Energy/Utilities | Electric, Gas, Water, Renewable, O&G | — | NERC CIP, FERC |
| Education | K-12, Higher Ed, Continuing Ed | Education Cloud | FERPA, Title IX |
| Nonprofit | Human Services, Foundations, Associations | Nonprofit Cloud | IRS 501(c), Form 990 |

---

## File Reference

```
subagents/IndustryAdvisor/
├── SKILL.md                              # Core skill (loaded by Cursor/Claude)
├── README.md                             # This file
├── install.sh                            # One-command installer
└── references/
    ├── deliverables-guide.md             # Templates for all 6 deliverables
    └── industry-patterns.md              # Deep-dive patterns per vertical
```

---

## Updating

Re-run the installer to update:

```bash
# From a clone
./install.sh --both

# One-liner
curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/IndustryAdvisor/install.sh | bash -s -- --both
```

---

## Uninstalling

```bash
# Cursor
rm -rf ~/.cursor/skills/sf-industry-advisor

# Claude Code
rm -rf ~/.claude/skills/sf-industry-advisor
```

---

## FAQ

**Q: Does this replace industry-specific Salesforce training?**
A: No. It provides a strong starting point for vertical conversations, but always validate against the customer's specific context. The Industry Advisor knows the patterns — the customer knows their organization.

**Q: What if my customer spans multiple industries?**
A: Many customers do (e.g., a health insurance company is both healthcare and financial services). Specify both verticals and the advisor will address the regulatory intersection.

**Q: How current are the regulatory references?**
A: The skill provides regulatory frameworks and patterns, not legal advice. Always verify current regulatory requirements with compliance teams and legal counsel.

**Q: Can I use this for industries not listed?**
A: The nine covered industries represent the most common Salesforce verticals. For unlisted industries, the cross-industry patterns and general frameworks still apply — just specify the vertical and the advisor will adapt.

**Q: How does this interact with the other subagents?**
A: The Industry Advisor auto-activates when industry context is relevant. It enriches the primary skill's output rather than replacing it. Think of it as a subject-matter expert who joins the conversation when vertical depth is needed.
