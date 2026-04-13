# Industry Advisor — Deliverables Guide

Templates and structure for the six core Industry Advisor deliverables.

---

## 1. Industry Process Map

An industry process map shows how the customer's real-world process works, annotated with regulatory touchpoints, compliance gates, and Salesforce capability mapping.

### Template Structure

```
# Industry Process Map: [Process Name]

## Metadata
- **Industry:** [e.g., Healthcare — Provider]
- **Process:** [e.g., Patient Referral Management]
- **Regulations:** [e.g., HIPAA, EMTALA, state referral laws]
- **Salesforce Cloud:** [e.g., Health Cloud]

## Process Overview
[1–2 paragraph summary of the industry-standard process, why it matters,
and what drives variation between organizations]

## Process Steps

### Step 1: [Industry Term for Step]
- **Description:** What happens in this step, described in the customer's language
- **Key Actors:** Who is involved (use industry roles, not Salesforce roles)
- **Regulatory Touchpoint:** [If applicable — which regulation and what it requires]
- **Compliance Gate:** [Yes/No — if Yes, what must be verified before proceeding]
- **Salesforce Mapping:**
  - Object: [e.g., Care Request]
  - Automation: [e.g., Flow triggers referral routing]
  - Integration: [e.g., HL7 ADT message from EHR]
- **Industry Terminology:**
  - [Customer term] → [Salesforce equivalent]

### Step 2: [Industry Term for Step]
[Repeat structure]

...

## Regulatory Touchpoint Summary
| Step | Regulation | Requirement | Salesforce Feature |
|---|---|---|---|
| [Step name] | [Regulation] | [What's required] | [How Salesforce addresses it] |

## Compliance Gates Summary
| Gate | Located After Step | Verification Required | Automated? |
|---|---|---|---|
| [Gate name] | [Step] | [What must be true] | [Yes/No — how] |

## Gaps and Risks
| Gap | Impact | Mitigation |
|---|---|---|
| [What Salesforce can't do natively] | [Business impact] | [Custom dev / ISV / process change] |
```

### Quality Criteria
- Steps use industry terminology, not Salesforce terminology
- Every regulatory touchpoint cites the specific regulation and section
- Compliance gates have clear pass/fail criteria
- Salesforce mapping is specific (object + field + automation), not hand-wavy
- Gaps are honest — don't pretend Salesforce covers everything

---

## 2. Regulatory Compliance Checklist

A structured inventory of all applicable regulations, their requirements, and how Salesforce addresses each one.

### Template Structure

```
# Regulatory Compliance Checklist: [Industry / Sub-Vertical]

## Metadata
- **Industry:** [e.g., Financial Services — Retail Banking]
- **Geography:** [e.g., United States, California]
- **Data Types:** [e.g., PII, financial records, credit data]
- **Salesforce Products:** [e.g., Financial Services Cloud, Shield, Data Cloud]

## Regulation: [Name — e.g., SOX (Sarbanes-Oxley Act)]

### Overview
[2–3 sentences: what the regulation covers, who it applies to, penalties for non-compliance]

### Requirements

#### Requirement 1: [Short Name]
- **Regulation Section:** [e.g., SOX Section 302]
- **Requirement:** [What is specifically required]
- **Risk Level:** [Critical / High / Medium / Low]
- **Salesforce Compliance Feature:**
  - Feature: [e.g., Field Audit Trail]
  - Configuration: [e.g., Enable on all financial record fields]
  - Shield Required: [Yes/No]
- **Gap:** [If Salesforce doesn't fully address — what's missing]
- **Mitigation:** [If there's a gap — how to address it]
- **Validation:** [How to prove compliance — audit approach]

#### Requirement 2: [Short Name]
[Repeat structure]

## Regulation: [Next Regulation]
[Repeat structure]

## Cross-Regulation Summary Matrix
| Requirement | SOX | KYC/AML | GDPR | PCI-DSS | Salesforce Feature |
|---|---|---|---|---|---|
| Data encryption at rest | | ✓ | ✓ | ✓ | Shield Platform Encryption |
| Audit trail | ✓ | ✓ | ✓ | | Field Audit Trail |
| Data retention policy | ✓ | ✓ | ✓ | ✓ | Data Retention policies |
| Access controls | ✓ | ✓ | ✓ | ✓ | Profiles, Permission Sets, FLS |

## Risk Summary
| Risk Level | Count | Top Risks |
|---|---|---|
| Critical | [n] | [List] |
| High | [n] | [List] |
| Medium | [n] | [List] |
| Low | [n] | [List] |
```

### Quality Criteria
- Every regulation section is cited specifically (not just "HIPAA" but "HIPAA § 164.312(a)(1)")
- Risk levels are justified, not arbitrary
- Gaps are called out honestly — never claim Salesforce is compliant when it isn't
- Mitigation strategies are actionable, not vague
- Cross-regulation matrix shows where one Salesforce feature satisfies multiple regulations

---

## 3. Industry Data Model Recommendation

A recommended data model that starts from the industry cloud (if applicable) and extends for the customer's specific needs.

### Template Structure

```
# Industry Data Model: [Industry / Sub-Vertical]

## Metadata
- **Industry:** [e.g., Healthcare — Provider (Health System)]
- **Salesforce Cloud:** [e.g., Health Cloud]
- **Key Entities:** [e.g., Patient, Provider, Facility, Care Plan, Encounter]

## Starting Point
[Which industry cloud data model to start from, and why.
If no industry cloud exists, which standard objects to repurpose.]

## Core Objects

### [Industry Entity Name] → [Salesforce Object]
- **Industry Definition:** [What this entity means in the vertical]
- **Salesforce Object:** [Standard / Industry Cloud / Custom]
- **Key Fields:**
  | Field (Industry Name) | Salesforce Field | Type | Sensitivity |
  |---|---|---|---|
  | [e.g., Medical Record Number] | [e.g., HealthCloudGA__MedicalRecordNumber__c] | Text | PHI |
- **Key Relationships:**
  | Related To | Relationship Type | Industry Meaning |
  |---|---|---|
  | [e.g., Provider] | Lookup | Attending physician |
- **Sharing Model:**
  - OWD: [e.g., Private]
  - Sharing Rules: [e.g., Care team members get read/write]
  - Regulatory Basis: [e.g., HIPAA minimum necessary principle]

### [Next Industry Entity]
[Repeat structure]

## Entity Relationship Diagram
[Mermaid diagram showing core relationships using industry terminology]

## Data Sensitivity Classification
| Object | Sensitivity Level | Regulation | Encryption Required | Audit Required |
|---|---|---|---|---|
| Patient | PHI | HIPAA | Yes (Shield) | Yes (Field Audit Trail) |
| Financial Account | PII + Financial | SOX, GLBA | Yes | Yes |

## Standard Object Repurposing Guide
| Standard Object | Industry Meaning | Renamed To (Label) | Key Customizations |
|---|---|---|---|
| Account | Healthcare Facility | Facility | Added NPI, bed count, specialties |
| Contact | Patient | Patient | Added MRN, DOB, insurance |
| Case | Care Coordination Task | Care Request | Added clinical priority, care plan link |

## Gaps: Objects to Build Custom
| Entity | Why Custom | Fields | Volume Estimate |
|---|---|---|---|
| [Entity not in standard or industry model] | [Why it can't map to existing] | [Key fields] | [Expected record count] |
```

### Quality Criteria
- Starts from the industry cloud model, not from scratch
- Every object is named using industry terminology (label changes documented)
- Data sensitivity is classified for every object with regulatory basis
- Sharing model is informed by regulation, not just business preference
- Entity relationships reflect how the industry actually works, not how Salesforce defaults

---

## 4. Vertical Terminology Glossary

A bridge between the customer's language and Salesforce's language.

### Template Structure

```
# Vertical Terminology Glossary: [Industry / Sub-Vertical]

## Metadata
- **Industry:** [e.g., Telecom — Mobile Operator]
- **Audience:** Implementation team, BAs, developers, solution architects
- **Purpose:** Ensure all project communication uses the customer's language

## Core Business Terms

| Industry Term | Definition | Salesforce Equivalent | Common Confusion |
|---|---|---|---|
| Subscriber | An individual with an active service plan | Contact (Communications Cloud: Subscriber) | Not the same as "User" — subscribers are customers, not employees |
| Service Location | Physical address where service is delivered | Address (with custom fields) | Don't confuse with Account billing address |
| Trouble Ticket | A customer-reported service issue | Case | Telecom trouble tickets have severity levels tied to SLAs different from standard Case priority |
| ARPU | Average Revenue Per User — monthly recurring revenue divided by subscriber count | Calculated field / Report | This is a KPI, not a field — calculate from billing data |

## Regulatory Terms

| Term | Definition | Relevance | Common Misuse |
|---|---|---|---|
| CPNI | Customer Proprietary Network Information — protected data about subscriber calling patterns | FCC-regulated; cannot share without consent | Often confused with general PII — CPNI is a specific, narrower category |
| [Additional regulatory terms] | | | |

## Process Terms

| Term | Definition | Salesforce Process | Notes |
|---|---|---|---|
| Order Decomposition | Breaking a complex multi-service order into individual fulfillment tasks | CPQ → Order Management → individual order items | This is unique to telecom — a single subscriber order may decompose into 10+ fulfillment items |
| [Additional process terms] | | | |

## Acronyms

| Acronym | Expansion | Context |
|---|---|---|
| BSS | Business Support Systems | Billing, CRM, order management — the "business" side |
| OSS | Operations Support Systems | Network management, provisioning — the "technical" side |
| [Additional acronyms] | | |

## Terms That Differ Between Sub-Verticals

| Term | Meaning in [Sub-Vertical A] | Meaning in [Sub-Vertical B] |
|---|---|---|
| Member | Insurance: a person covered by a policy | Association: a person who belongs to the organization |
| [Additional terms] | | |
```

### Quality Criteria
- Every core business term the customer uses is mapped
- "Common Confusion" column is populated — this is where the real value is
- Regulatory terms are included (the team must use these correctly)
- Sub-vertical distinctions are called out
- The glossary is usable as a project reference, not just a one-time read

---

## 5. Industry Benchmark Report

Connect Salesforce capabilities to the metrics the industry measures, with realistic benchmarks.

### Template Structure

```
# Industry Benchmark Report: [Industry / Sub-Vertical]

## Metadata
- **Industry:** [e.g., Healthcare — Health System]
- **Source Period:** [e.g., 2024–2025 benchmarks]
- **Sources:** [e.g., HCAHPS, CMS data, Becker's Hospital Review]

## Executive Summary
[2–3 paragraphs: the top KPIs, where the industry stands, and where
Salesforce can demonstrably move the needle]

## KPI Deep Dives

### KPI: [Name — e.g., 30-Day Readmission Rate]
- **Definition:** [Precise definition as the industry measures it]
- **Industry Average:** [e.g., 15.5% for Medicare patients (CMS 2024)]
- **Top Quartile:** [e.g., 11.2%]
- **Why It Matters:** [Regulatory penalties, revenue impact, patient outcomes]
- **Salesforce Impact:**
  - **Feature:** [e.g., Health Cloud Care Plans + automated follow-up]
  - **Mechanism:** [How the feature improves the metric — be specific]
  - **Expected Improvement:** [e.g., 2–4 percentage point reduction based on comparable implementations]
  - **Proof Points:** [Customer examples or research if available]
- **Measurement in Salesforce:**
  - **How to Track:** [Reports, dashboards, Data Cloud analytics]
  - **Data Required:** [What data must flow into Salesforce to measure this]

### KPI: [Next KPI]
[Repeat structure]

## KPI Summary Matrix
| KPI | Industry Avg | Top Quartile | SF Feature | Expected Δ | Confidence |
|---|---|---|---|---|---|
| Readmission Rate | 15.5% | 11.2% | Care Plans | -2–4 pp | High |
| Patient Satisfaction | 72% | 85% | Patient Engagement | +5–10 pp | Medium |

## Salesforce ROI Narrative
[Connect the KPI improvements to financial impact. Use the customer's
scale to estimate dollar values where possible.]

## Caveats
- [Benchmarks vary by sub-vertical, geography, and organization size]
- [Salesforce is one factor — process change and adoption matter more]
- [Expected improvements assume full adoption and integration]
```

### Quality Criteria
- KPIs are the ones the industry actually tracks, not generic CRM metrics
- Benchmarks cite sources and are current
- Expected improvements are realistic ranges, not promises
- The mechanism of improvement is explained (not just "use this feature")
- Caveats are honest — overpromising KPI improvement destroys credibility

---

## 6. Compliance Requirement Matrix

The most granular deliverable — every regulatory requirement mapped to a specific Salesforce configuration.

### Template Structure

```
# Compliance Requirement Matrix: [Regulation]

## Metadata
- **Regulation:** [e.g., HIPAA Security Rule]
- **Industry:** [e.g., Healthcare]
- **Salesforce Products:** [e.g., Health Cloud, Shield, Event Monitoring]
- **Last Updated:** [Date]

## Requirements

### [Regulation Section — e.g., § 164.312(a)(1) Access Control]

#### Requirement: [Short Name — e.g., Unique User Identification]
- **Regulation Text:** [Exact or paraphrased requirement]
- **Classification:** Required / Addressable
- **Salesforce Feature:** [e.g., Unique usernames, SSO via SAML/OIDC]
- **Configuration:**
  1. [Specific setting: e.g., Enable "Login must use SSO" in auth provider settings]
  2. [Specific setting: e.g., Disable local password for non-admin users]
  3. [Specific setting: e.g., Configure session timeout to ≤15 minutes]
- **Validation Approach:**
  - [How to test: e.g., Attempt login without SSO — should fail]
  - [Audit check: e.g., Run Login History report — no local logins]
- **Ongoing Monitoring:**
  - [e.g., Weekly review of Login History for anomalies]
  - [e.g., Event Monitoring alert for failed login attempts > threshold]
- **Evidence for Auditors:**
  - [e.g., Screenshot of SSO configuration]
  - [e.g., Login History report exported as PDF]

#### Requirement: [Next Requirement]
[Repeat structure]

### [Next Regulation Section]
[Repeat structure]

## Compliance Coverage Summary
| Section | Total Requirements | Fully Addressed | Partially Addressed | Gaps |
|---|---|---|---|---|
| Access Control | 5 | 4 | 1 | 0 |
| Audit Controls | 3 | 2 | 0 | 1 |
| Transmission Security | 2 | 2 | 0 | 0 |

## Gap Remediation Plan
| Gap | Regulation Section | Risk | Remediation | Timeline | Owner |
|---|---|---|---|---|---|
| [What's missing] | [Section] | [Critical/High/Med/Low] | [How to fix] | [When] | [Who] |
```

### Quality Criteria
- Every requirement from the regulation is listed — no cherry-picking
- Configuration is specific enough that an admin could implement it
- Validation approach proves compliance, not just configuration
- Ongoing monitoring is included — compliance is continuous, not one-time
- Evidence guidance helps prepare for actual audits

---

## General Deliverable Quality Standards

Across all six deliverables:

1. **Industry language first** — every deliverable uses the customer's terminology
2. **Regulation citations are specific** — section numbers, not just regulation names
3. **Gaps are honest** — never claim Salesforce covers something it doesn't
4. **Actionable over impressive** — the deliverable should be usable, not just readable
5. **Scored before delivery** — use the 100-point rubric; don't ship below 75
