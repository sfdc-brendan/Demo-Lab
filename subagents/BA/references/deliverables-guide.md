# BA Deliverables Guide

Detailed templates for the six core BA deliverable types. Each template is designed for reuse across projects, clouds, and industries.

---

## Requirements Document Template

```markdown
# Requirements Document: [Process / Feature Name]
**Project:** [Project name]
**Author:** [BA name]
**Version:** [X.X]
**Status:** [Draft / In Review / Approved]
**Last Updated:** [Date]

## 1. Overview
### Purpose
[One paragraph: what business capability this document covers and why it matters.]

### Scope
**In scope:**
- [Process/feature 1]
- [Process/feature 2]

**Out of scope:**
- [Explicitly excluded item 1]
- [Explicitly excluded item 2]

### Stakeholders
| Name | Role | Interest | Involvement |
|---|---|---|---|
| [Name] | [Business role] | [What they care about] | [Approver / Contributor / Informed] |

## 2. Current State (As-Is)
### Process Description
[Narrative description of how the process works today.]

### Process Flow
[Mermaid diagram or reference to Lucidchart — delegate to sf-diagram-mermaid]

### Pain Points
| # | Pain Point | Impact | Affected Users |
|---|---|---|---|
| 1 | [Description] | [Quantified impact if possible] | [User group] |
| 2 | [Description] | [Quantified impact] | [User group] |

## 3. Future State (To-Be)
### Process Description
[How the process will work after implementation.]

### Process Flow
[Future-state diagram]

### Key Changes
| Change | From (Current) | To (Future) | Benefit |
|---|---|---|---|
| [Change 1] | [Current behavior] | [New behavior] | [Business outcome] |

## 4. Functional Requirements
| ID | Requirement | Priority | Salesforce Capability | Type |
|---|---|---|---|---|
| FR-001 | [The system shall...] | Must have | [Object/Flow/Apex/LWC] | Declarative / Custom |
| FR-002 | [The system shall...] | Should have | [Capability] | Declarative / Custom |
| FR-003 | [The system shall...] | Nice to have | [Capability] | Declarative / Custom |

## 5. Non-Functional Requirements
| ID | Requirement | Category |
|---|---|---|
| NFR-001 | [Performance, security, or usability requirement] | [Performance / Security / Usability / Scalability] |

## 6. Data Requirements
### Objects & Fields
| Object | Key Fields | New / Existing | Notes |
|---|---|---|---|
| [Object] | [Field list] | [New / Existing] | [Relationships, validation rules] |

### Data Migration
| Source | Target Object | Volume | Transformation Notes |
|---|---|---|---|
| [Source system] | [SF Object] | [Record count] | [Mapping notes] |

## 7. Integration Requirements
| Integration | Direction | System | Frequency | Method |
|---|---|---|---|---|
| [Name] | Inbound / Outbound / Bidirectional | [External system] | Real-time / Batch | API / MuleSoft / File |

## 8. Assumptions & Dependencies
### Assumptions
1. [Assumption — e.g., "Users have Salesforce licenses assigned"]

### Dependencies
1. [Dependency — e.g., "Requires Account object customization from Sprint 2"]

## 9. Acceptance Criteria Summary
[Reference to user stories with detailed acceptance criteria, or summarize here.]

## 10. Sign-Off
| Name | Role | Date | Signature |
|---|---|---|---|
| [Name] | [Role] | [Date] | ☐ Approved |
```

---

## User Story Template

```markdown
# User Stories: [Feature / Epic Name]
**Epic:** [Parent epic if applicable]
**Sprint Target:** [Sprint number or "Backlog"]
**Author:** [BA name]

---

### Story: [SHORT-ID] [Title]

**As a** [persona — specific role, not "user"],
**I want to** [goal — what they need to do],
**So that** [business value — why it matters to the business].

**Acceptance Criteria:**

**Given** [precondition / starting context],
**When** [action the user takes],
**Then** [observable outcome].

**Given** [alternate precondition],
**When** [action],
**Then** [alternate outcome].

**Given** [error / edge case condition],
**When** [action],
**Then** [error handling behavior].

**Details:**
- **Salesforce object(s):** [Objects involved]
- **Automation:** [Flow / Apex / None]
- **Dependencies:** [Other stories, integrations, data]
- **Data requirements:** [Test data needs]
- **Cross-cloud:** [Yes/No — if yes, which clouds]

**Size estimate:** [S / M / L]

**Notes:**
[Anything the dev or QA team needs to know that doesn't fit above.]

---

### Story: [SHORT-ID] [Title]
[Repeat structure for each story]
```

### Story Writing Checklist

Use this to validate every story before sprint:

- [ ] Persona is a real role, not "user" or "admin"
- [ ] Goal is specific and actionable
- [ ] Business value answers "why does the business care?"
- [ ] At least one happy-path acceptance criterion
- [ ] At least one error/edge-case criterion
- [ ] Salesforce objects identified
- [ ] Declarative vs. custom flagged
- [ ] Dependencies listed
- [ ] PO has reviewed and approved

---

## Process Map Template

```markdown
# Process Map: [Process Name]
**Scope:** [Start event] → [End event]
**Version:** [Current / Future]
**Author:** [BA name]

## Actors
| Actor | System/Role | Responsibilities |
|---|---|---|
| [Actor 1] | [Salesforce / External / Manual] | [What they do in this process] |

## Process Flow

[Mermaid diagram — use flowchart TD or LR]

## Step Detail
| Step | Actor | Action | System | Object/Screen | Decision? | Automation? |
|---|---|---|---|---|---|---|
| 1 | [Role] | [What they do] | [SF / External / Manual] | [Object or screen] | No | No |
| 2 | [Role] | [Evaluate X] | [SF] | [Object] | Yes → Step 3a / 3b | No |
| 3a | [System] | [Auto-assign] | [SF] | [Flow name] | No | Yes — Flow |
| 3b | [Role] | [Manual review] | [SF] | [Object page] | No | No |

## Exception Paths
| Exception | Trigger | Handling | Resolution |
|---|---|---|---|
| [Exception 1] | [What causes it] | [How it's handled] | [End state] |

## Automation Opportunities
| Step | Current | Proposed | Benefit | Complexity |
|---|---|---|---|---|
| [Step #] | [Manual action] | [Flow / Apex / Agentforce] | [Time saved / errors reduced] | [Low / Med / High] |
```

---

## UAT Plan Template

```markdown
# UAT Plan: [Feature / Release Name]
**Release:** [Release name or sprint]
**UAT Lead:** [BA name]
**UAT Window:** [Start date] – [End date]

## 1. Scope
### In Scope
| Feature | User Stories | Requirements |
|---|---|---|
| [Feature 1] | [US-001, US-002] | [FR-001, FR-003] |

### Out of Scope
- [Items not being tested in this cycle]

## 2. Entry Criteria
- [ ] All in-scope stories are deployed to UAT environment
- [ ] Test data is loaded and verified
- [ ] UAT users have credentials and permissions
- [ ] Known defects from SIT are documented

## 3. Test Scenarios
| ID | Scenario | User Story | Steps | Expected Result | Priority |
|---|---|---|---|---|---|
| TC-001 | [Scenario name] | [US-XXX] | See detailed script below | [Expected outcome] | Critical |
| TC-002 | [Scenario name] | [US-XXX] | See detailed script below | [Expected outcome] | High |

### TC-001: [Scenario Name] (Detailed Script)
**Preconditions:** [Setup required before testing]
**Test data:** [Specific records needed]

| Step | Action | Expected Result | Pass/Fail | Notes |
|---|---|---|---|---|
| 1 | [Navigate to...] | [Page loads showing...] | ☐ | |
| 2 | [Click / Enter...] | [System responds with...] | ☐ | |
| 3 | [Verify...] | [Record shows...] | ☐ | |

## 4. Exit Criteria
- [ ] All critical test scenarios pass
- [ ] All high-priority test scenarios pass
- [ ] No open Severity 1 or 2 defects
- [ ] Business stakeholder sign-off received

## 5. Defect Management
| Severity | Definition | Response |
|---|---|---|
| Sev 1 — Blocker | Process cannot continue, no workaround | Fix before UAT can proceed |
| Sev 2 — Critical | Major function broken, workaround exists | Fix before go-live |
| Sev 3 — Major | Function impaired but usable | Fix in next release |
| Sev 4 — Minor | Cosmetic or low-impact | Backlog |

## 6. Sign-Off
| Name | Role | Date | Result |
|---|---|---|---|
| [Name] | [Business owner] | [Date] | ☐ Approved / ☐ Approved with conditions / ☐ Rejected |
```

---

## Training Material Template

```markdown
# Training Guide: [Feature / Process Name]
**Audience:** [Role(s)]
**Salesforce proficiency:** [Beginner / Intermediate / Advanced]
**Last updated:** [Date]

## Overview
[1–2 sentences: what this guide covers and why the audience needs it.]

## Before You Start
- [ ] You have a Salesforce login
- [ ] You have the [Permission Set Name] assigned
- [ ] You can access the [App Name] app in the App Launcher

## Task 1: [Task Name]
**When to do this:** [Trigger — e.g., "When a new lead comes in from the website"]

### Steps
1. Navigate to **[Tab/Object]** in the App Launcher
2. Click **[Button]**
3. Fill in the following fields:
   | Field | What to Enter | Example |
   |---|---|---|
   | [Field 1] | [Description] | [Example value] |
   | [Field 2] | [Description] | [Example value] |
4. Click **Save**

### What Happens Next
[Describe any automation that fires — e.g., "A Flow automatically assigns the record to the queue based on region."]

### Common Issues
| Problem | Cause | Fix |
|---|---|---|
| [Error message or symptom] | [Why it happens] | [What to do] |

## Task 2: [Task Name]
[Repeat structure]

## Quick Reference Card
| I want to... | Go to... | Click... |
|---|---|---|
| [Create a new X] | [Tab] | [New button] |
| [Update an existing X] | [Record page] | [Edit button] |
| [Run a report on X] | [Reports tab] | [Report name] |

## FAQ
**Q: [Common question from stakeholders during the project]**
A: [Answer]

**Q: [Another common question]**
A: [Answer]
```

---

## Backlog Item Template

```markdown
# Backlog Item: [Request Title]
**Requested by:** [Name, role]
**Date submitted:** [Date]
**BA assigned:** [BA name]

## Request
[2–3 sentences: what the stakeholder is asking for, in their words.]

## Classification
- **Type:** Bug fix / Enhancement / New feature / Process change
- **Process area:** [e.g., Lead management, Case handling, Quoting]
- **Cloud(s):** [Sales / Service / Marketing / etc.]
- **Urgency:** [Immediate / This quarter / Next quarter / Someday]

## Business Justification
**Problem:** [What's broken or missing]
**Impact:** [Who is affected and how — quantify if possible]
**Desired outcome:** [What success looks like]

## Assessment
### Value vs. Complexity
| Dimension | Rating | Rationale |
|---|---|---|
| Business value | [High / Med / Low] | [Why] |
| Technical complexity | [High / Med / Low] | [Why] |
| Dependencies | [None / Some / Many] | [List them] |

### CoE Charter Alignment
- [ ] Aligns with charter goal: [Goal name]
- [ ] Does not conflict with in-flight work
- [ ] Has stakeholder sponsorship

## Recommendation
**Priority:** [P1 / P2 / P3 / P4]
**Target release:** [Sprint X / Release Y / Backlog]
**Rationale:** [Why this priority and timeline]

## Decision
| Decision | Made by | Date |
|---|---|---|
| [Approved / Deferred / Rejected] | [PO / Steering committee] | [Date] |
```
