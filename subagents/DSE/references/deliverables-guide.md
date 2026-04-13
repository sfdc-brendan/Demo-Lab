# DSE Deliverables Guide

Detailed templates for the six core DSE deliverable types. Each template is designed for reuse — adapt to the specific customer, industry, or segment.

---

## POV / White Paper Template

```markdown
# [Title: Thesis as a Declarative Statement]

## Executive Summary
[2–3 sentences. State the thesis, the business impact, and the Salesforce platform response.]

## Industry Context
### The Pressure
[What macro trends, regulations, or competitive dynamics are forcing change?]

### The Opportunity
[What does the transformation look like for companies that act?]

## Current State Challenges
| Challenge | Business Impact | Affected Stakeholders |
|---|---|---|
| [Challenge 1] | [Revenue/cost/risk impact] | [C-suite, LOB, IT] |
| [Challenge 2] | [Revenue/cost/risk impact] | [C-suite, LOB, IT] |

## The Salesforce Platform Response

### Architecture Overview
[Insert Mermaid diagram — delegate to sf-diagram-mermaid]

### Capability Mapping
| Business Need | Salesforce Capability | Cloud/Product |
|---|---|---|
| [Need 1] | [Capability] | [Cloud] |
| [Need 2] | [Capability] | [Cloud] |

### Cross-Cloud Value
[Explain why the integrated platform delivers more value than point solutions.]

## Business Value Framework
| Metric | Current State | Target State | Value Driver |
|---|---|---|---|
| [KPI 1] | [Baseline] | [Target] | [How Salesforce enables it] |
| [KPI 2] | [Baseline] | [Target] | [How Salesforce enables it] |

## Customer Evidence
[Reference 1–2 similar customers or industry benchmarks. Use "a leading [industry] company" if specifics are confidential.]

## Recommended Next Steps
1. [Concrete action with timeline]
2. [Concrete action with timeline]
3. [Concrete action with timeline]

## Appendix: Technical Deep-Dive
[Optional. Architecture details, integration patterns, data model considerations.]
```

---

## Executive Briefing Template

```markdown
# Executive Briefing: [Customer Name]
**Date:** [Date]
**Attendees:** [Customer execs] | [Salesforce execs]
**Prepared by:** [SE name]

## Their World (2 min)
[Demonstrate understanding of the customer's strategic context. Reference their annual report, earnings call, or public strategy. Show you've done the homework.]

Key priorities we've identified:
1. [Priority 1 — in their language, not ours]
2. [Priority 2]
3. [Priority 3]

## Insights That Matter (5 min)
### Insight 1: [Title]
[Industry trend or data point directly relevant to their priorities. End with: "Here's what this means for [Customer]..."]

### Insight 2: [Title]
[Second insight. Same structure.]

## The Art of the Possible (10 min)
### Architecture Vision
[Mermaid diagram showing their future state on the Salesforce platform]

### Demo Narrative
**Persona:** [Role at the customer's company]
**Scenario:** [Day-in-the-life business scenario]

| Beat | What We Show | Why It Matters | Cloud/Product |
|---|---|---|---|
| 1 | [Action] | [Business outcome] | [Product] |
| 2 | [Action] | [Business outcome] | [Product] |
| 3 | [Action] | [Business outcome] | [Product] |

## Mutual Next Steps (3 min)
| Action | Owner | Timeline |
|---|---|---|
| [Action 1] | [Customer/Salesforce] | [Date] |
| [Action 2] | [Customer/Salesforce] | [Date] |

## Appendix: Pre-Brief Intel
- Account context: [deal stage, competitive landscape, blockers]
- Key stakeholder map: [who cares about what]
- Landmines to avoid: [sensitive topics, past failures, competitor relationships]
```

---

## Strategic Demo Script Template

```markdown
# Demo Script: [Scenario Name]
**Target audience:** [Buyer persona / role]
**Industry:** [Vertical]
**Duration:** [X minutes]
**Clouds/Products:** [List]

## Reusability Note
- Sections marked [REUSABLE] can be used across customers with minimal changes
- Sections marked [CUSTOMIZE] require customer-specific data or branding

## Setup Requirements
| Component | Configuration | Notes |
|---|---|---|
| [Org/Environment] | [Details] | [Setup steps] |
| [Data] | [Sample records needed] | [Data load instructions] |
| [Integrations] | [External systems] | [Mock or live] |

## Narrative Arc

### Opening: The Problem (2 min) [REUSABLE]
**Talk track:** "[Persona name] is a [role] at [company]. Every day, they face [specific challenge]..."

**What's on screen:** [Describe the starting state]

### Act 1: [First Capability Theme] (X min)
**Talk track:** [Exact words to say during this section]

**Demo steps:**
1. [Click/navigate to...]
2. [Show...]
3. [Highlight...]

**Transition:** [Bridge language to next section]

### Act 2: [Second Capability Theme] (X min)
[Same structure]

### Act 3: [Resolution & Business Impact] (X min)
**Talk track:** "What we've just seen is [summary]. For [customer], this means [quantified business outcome]..."

**What's on screen:** [Dashboard, report, or summary view]

## Closing
**Key takeaway:** [One sentence the audience should remember]

**Objection prep:**
| Likely Objection | Response |
|---|---|
| [Objection 1] | [Response] |
| [Objection 2] | [Response] |
```

---

## GTM Play Template

```markdown
# GTM Play: [Play Name]

## Play Identity
- **Target segment:** [Enterprise / Commercial / SMB]
- **Industry:** [Vertical or cross-industry]
- **Buyer persona:** [Primary decision-maker]
- **Trigger event:** [What causes the customer to act now?]

## Customer Pain Point
[2–3 sentences describing the problem in the customer's language.]

## Solution Narrative
[How Salesforce solves this. Cross-cloud lens. Business outcome focus.]

### Reference Architecture
[Mermaid diagram]

## Discovery Framework
### For the AE
| Question | What You're Listening For |
|---|---|
| [Question 1] | [Signal / qualifier] |
| [Question 2] | [Signal / qualifier] |

### For the SE
| Technical Question | Architecture Implication |
|---|---|
| [Question 1] | [Design decision it informs] |
| [Question 2] | [Design decision it informs] |

## Competitive Positioning
| Competitor | Their Pitch | Our Differentiation |
|---|---|---|
| [Competitor 1] | [Their angle] | [Why we win] |
| [Competitor 2] | [Their angle] | [Why we win] |

## Reusable Assets
| Asset | Location | Last Updated |
|---|---|---|
| Demo script | [path] | [date] |
| POV | [path] | [date] |
| Customer story | [reference] | [date] |

## Success Metrics
| Metric | Definition | Target |
|---|---|---|
| [Metric 1] | [How measured] | [Goal] |
| [Metric 2] | [How measured] | [Goal] |
```

---

## SE Enablement Session Template

```markdown
# Enablement: [Topic]
**Duration:** [X minutes]
**Audience:** [SE level / segment]
**Learning objective:** After this session, SEs will be able to [specific outcome].

## Concept (X min)
[Teach the strategic framing. Why this matters. Industry context.]

### Key Mental Models
1. [Model 1 — e.g., "Think platform, not product"]
2. [Model 2]

## Live Demo (X min)
[Walk through the demo using the strategic demo script format above. Annotate with coaching notes.]

### Coaching Annotations
| Demo Beat | Common Mistake | Better Approach |
|---|---|---|
| [Beat 1] | [What SEs typically do wrong] | [What great looks like] |
| [Beat 2] | [Common mistake] | [Better approach] |

## Practice (X min)
[Pair exercise or role-play. Provide a scenario and have SEs practice.]

**Scenario:** [Brief customer scenario]
**Your role:** [SE]
**Evaluate on:** [2–3 criteria]

## Debrief (X min)
### Self-Assessment
1. Could I explain why this matters to a CIO in 60 seconds?
2. Could I adapt this demo to a different industry?
3. Do I know when NOT to show this capability?

## Follow-Up Resources
- [Link to demo environment]
- [Link to POV template]
- [Link to recording of this session]
```

---

## Voice of the Customer Brief Template

```markdown
# VoC Brief: [Topic / Capability Gap]
**Date:** [Date]
**Submitted by:** [DSE name]
**Priority:** [Critical / High / Medium]

## Signal Summary
[1–2 sentences: what customers are asking for and why.]

## Field Evidence
| Customer / Deal | Segment | Revenue Impact | Verbatim |
|---|---|---|---|
| [Customer 1] | [Segment] | [$X pipeline] | "[Quote]" |
| [Customer 2] | [Segment] | [$X pipeline] | "[Quote]" |

**Aggregate impact:** [X deals, $Y pipeline, Z% of segment]

## Current Workaround
[How customers or SEs are solving this today. What breaks.]

## Proposed Direction
[Not a PRD — a directional suggestion for PM to evaluate.]

### Option A: [Approach]
- Pros: [...]
- Cons: [...]

### Option B: [Approach]
- Pros: [...]
- Cons: [...]

## Competitive Context
[Do competitors already have this? Is it a differentiator or table stakes?]

## Recommended Priority
[Why this should be prioritized relative to other asks. Tie to strategic themes.]
```
