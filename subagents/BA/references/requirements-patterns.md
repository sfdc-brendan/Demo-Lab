# BA Requirements & Process Patterns

Frameworks for requirements elicitation, story writing, process analysis, and stakeholder management.

---

## Requirements Elicitation Techniques

### Choosing the Right Technique

| Technique | Best For | Duration | Output |
|---|---|---|---|
| **Stakeholder Interview** | Deep-dive on one person's perspective, sensitive topics | 45–60 min | Interview notes, requirements draft |
| **Discovery Workshop** | Cross-functional alignment, surfacing disagreements | 2–4 hours | Shared understanding, prioritized requirements |
| **Process Walkthrough** | Understanding how work actually gets done today | 1–2 hours | Current-state process map |
| **Journey Mapping** | End-user experience, identifying pain points | 2–3 hours | Journey map with emotions, pain points, opportunities |
| **Observation / Shadowing** | Discovering unstated steps and workarounds | Half day | As-is process detail, hidden requirements |
| **Document Review** | Understanding existing systems, policies, SOPs | Async | Gap analysis, clarification questions |
| **Survey / Questionnaire** | Validating assumptions at scale, gathering preferences | Async | Quantified input for prioritization |

### Stakeholder Interview Guide

```
OPENING (5 min)
- Context: why we're here, what we'll do with the input
- Permission: recording, notes, follow-up

DISCOVERY (30–40 min)
1. Walk me through a typical [process/day/workflow].
2. Where do things slow down or break?
3. What workarounds have you built?
4. If you could change one thing, what would it be?
5. Who else is involved in this process?
6. What does "good" look like? How do you measure success?
7. What constraints do we need to respect?

CLOSING (5 min)
- Summarize what you heard (playback)
- Ask: "What didn't I ask that I should have?"
- Next steps and timeline
```

### Discovery Workshop Agenda

```
PRE-WORK (async)
- Distribute current-state process doc or questionnaire
- Ask participants to bring their top 3 pain points

WORKSHOP (3 hours)

1. Align (15 min)
   - Project context and goals
   - Workshop rules: all perspectives are valid, park technical solutioning

2. Current State (45 min)
   - Walk through the as-is process together
   - Mark pain points on sticky notes (or digital equivalent)
   - Group pain points into themes

3. Future State (60 min)
   - For each theme: "What should this look like?"
   - Capture requirements as "The system should..."
   - Flag decision points for follow-up

4. Prioritize (30 min)
   - MoSCoW: Must have / Should have / Could have / Won't have (this release)
   - Resolve conflicts between stakeholders in real-time

5. Wrap-Up (15 min)
   - Review captured requirements
   - Assign open items
   - Timeline for requirements doc delivery

FOLLOW-UP (within 48 hours)
- Distribute requirements draft for review
- Schedule follow-up for unresolved items
```

---

## User Story Patterns

### Common Salesforce Story Patterns

**Record creation with validation:**
```
As a [role],
I want to create a new [Object] with required fields validated,
So that data quality is maintained from the point of entry.
```

**Automated assignment:**
```
As a [manager role],
I want [Object] records to be automatically assigned based on [criteria],
So that my team doesn't spend time on manual routing.
```

**Approval process:**
```
As a [submitter role],
I want to submit [Object] for approval when [condition],
So that [business control] is enforced before [action].
```

**Report/Dashboard:**
```
As a [manager/exec role],
I want a dashboard showing [metrics] by [dimensions],
So that I can make data-driven decisions about [business area].
```

**Integration:**
```
As a [role],
I want [Object] data to sync with [external system] in [real-time/batch],
So that [business outcome — e.g., both systems show consistent data].
```

**Notification/Alert:**
```
As a [role],
I want to be notified when [condition occurs on Object],
So that I can [take timely action].
```

### Acceptance Criteria Patterns

**Positive path (must always have at least one):**
```
Given [valid precondition],
When [user performs action],
Then [expected successful outcome].
```

**Negative/Error path (must always have at least one):**
```
Given [invalid precondition or data],
When [user attempts action],
Then [system prevents action and shows meaningful error].
```

**Bulk/Scale path (include for data-heavy features):**
```
Given [large volume of records — specify count],
When [bulk action is performed],
Then [system completes within acceptable time without errors].
```

**Permission path (include when access control matters):**
```
Given [user without required permission],
When [user attempts action],
Then [system restricts access appropriately].
```

---

## Process Analysis Framework

### Current-State Analysis Checklist

For each business process, document:

- [ ] **Trigger**: What starts this process?
- [ ] **Input**: What data/information enters the process?
- [ ] **Steps**: What happens, in what order, by whom?
- [ ] **Decisions**: Where do paths diverge? What criteria?
- [ ] **Systems**: Which systems are involved at each step?
- [ ] **Handoffs**: Where does work move between people or teams?
- [ ] **Output**: What does the process produce?
- [ ] **End condition**: How do you know it's done?
- [ ] **Metrics**: How is success measured today?
- [ ] **Pain points**: Where does it break, slow down, or frustrate?
- [ ] **Workarounds**: What unofficial fixes exist?
- [ ] **Volume**: How often does this process run? How many records?

### Gap Analysis Matrix

| # | Gap | Current State | Desired State | Impact | Salesforce Solution | Complexity |
|---|---|---|---|---|---|---|
| 1 | [Name] | [How it works now] | [How it should work] | [Business impact] | [Declarative/Custom approach] | [Low/Med/High] |

### Process Optimization Questions

Before automating, challenge the process:

1. **Eliminate**: Can this step be removed entirely?
2. **Simplify**: Can this step be made simpler?
3. **Combine**: Can multiple steps be merged?
4. **Automate**: Should this step be automated? (Only after 1–3)
5. **Standardize**: Can variations of this step be consolidated?

---

## Stakeholder Management

### Stakeholder Map Template

| Stakeholder | Role | Interest | Influence | Engagement Strategy |
|---|---|---|---|---|
| [Name] | [Title] | [What they care about] | [High / Med / Low] | [Keep informed / Collaborate / Empower] |

### RACI for Requirements Activities

| Activity | BA | PO | Dev Lead | Architect | Business SME |
|---|---|---|---|---|---|
| Stakeholder interviews | R | A | I | C | C |
| Requirements drafting | R | A | I | C | C |
| Story writing | R | A | C | C | I |
| Process mapping | R | I | I | C | C |
| Acceptance criteria | R | A | C | I | C |
| UAT script creation | R | I | I | I | C |
| UAT execution | A | I | I | I | R |
| Training creation | R | I | I | I | C |
| Backlog prioritization | C | R | C | C | C |

R = Responsible, A = Accountable, C = Consulted, I = Informed

---

## Requirement Quality Checks

### The "Ready" Test

Before marking any requirement as ready, verify:

| Check | Question | Pass? |
|---|---|---|
| **Unambiguous** | Could two developers read this and build the same thing? | ☐ |
| **Testable** | Can QA write a test that proves this works? | ☐ |
| **Traceable** | Can you trace this back to a business need or stakeholder request? | ☐ |
| **Feasible** | Has the dev team confirmed this is buildable within constraints? | ☐ |
| **Prioritized** | Does the PO agree on the priority? | ☐ |
| **Sized** | Has the team estimated effort? | ☐ |
| **Independent** | Can this be built and delivered without waiting for other stories? | ☐ |

### Common Requirement Smells

| Smell | Example | Fix |
|---|---|---|
| **Vague subject** | "The system should be user-friendly" | Define specific usability criteria |
| **Hidden assumption** | "The manager approves" (which manager? always?) | Make the assumption explicit |
| **Solution masquerading as requirement** | "Add a picklist field for status" | Rewrite as the business need: "Track the lifecycle stage of each request" |
| **Missing edge case** | "Convert the lead to a contact" (what if the contact already exists?) | Add error/exception acceptance criteria |
| **No business value** | Story has "As a user, I want a field" with no "so that" | Ask why until you find the business reason |

---

## Salesforce-Specific BA Patterns

### Object-Process Mapping

When analyzing a business process, map each step to Salesforce:

| Process Step | SF Object | SF Feature | Configuration Type |
|---|---|---|---|
| Capture request | Case | Record type + page layout | Declarative |
| Route to team | Case | Assignment rules / Flow | Declarative |
| Escalate if SLA missed | Case | Escalation rules / Flow | Declarative |
| Send notification | — | Flow + Email template | Declarative |
| Generate document | Case | Apex + VF template | Custom |
| Close and survey | Case + Survey | Flow + Survey object | Declarative |

### Multi-Cloud Requirement Flags

When a requirement touches multiple clouds, flag it early:

```
⚠️ CROSS-CLOUD: This story requires:
- Service Cloud: Case object and assignment
- Data Cloud: Unified profile for customer context
- Agentforce: AI agent for initial triage

Dependencies: Data Cloud profile must be populated before
Agentforce can access customer context. Sequence: Data Cloud
story (US-012) must be complete before this story enters sprint.
```
