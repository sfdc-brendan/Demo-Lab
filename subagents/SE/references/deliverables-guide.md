# SE Deliverables Guide

Detailed templates for the seven core SE deliverable types. Each template is designed as a starting point — tailor every section to the specific account, deal, and personas involved.

---

## Discovery Call Prep Template

```markdown
# Discovery Call Prep: [Account Name]
**Date:** [Date]
**SE:** [SE name]
**AE:** [AE name]
**Call duration:** [X minutes]
**Stage:** [Discovery / Qualification / Deep-dive]

## Account Research

### Company Overview
- **Industry:** [Vertical]
- **Revenue:** [$X / public or private]
- **Employees:** [Count]
- **HQ:** [Location]
- **Recent news:** [Key press releases, earnings, M&A, leadership changes]
- **Strategic priorities:** [From annual report, earnings calls, or public statements]

### Salesforce Footprint
- **Current clouds:** [Sales / Service / Marketing / etc.]
- **Edition:** [Enterprise / Unlimited / unknown]
- **Known integrations:** [ERP, data warehouse, marketing tools, etc.]
- **Contract renewal date:** [If known]

### Competitive Intel
| Competitor | Product Area | Status | Notes |
|---|---|---|---|
| [Competitor 1] | [Area] | [Incumbent / Evaluating / Shortlisted] | [Their likely pitch] |
| [Competitor 2] | [Area] | [Status] | [Notes] |

## Stakeholder Intel

| Name | Title | What They Care About | Communication Style | Hot Buttons |
|---|---|---|---|---|
| [Name] | [Title] | [Priorities] | [Detail-oriented / Big-picture / Data-driven] | [Topics to lean into or avoid] |

### Power Map
- **Economic buyer:** [Name — who signs the check]
- **Technical evaluator(s):** [Names — who will test the platform]
- **Champion:** [Name — who wants us to win]
- **Blocker:** [Name — who could derail, and why]
- **Coach:** [Name — internal ally giving us intel]

## Discovery Questions by Persona

### Executive Sponsor
| # | Question | What You're Listening For |
|---|---|---|
| 1 | What's driving this initiative now? What changed? | Urgency, trigger event, strategic priority |
| 2 | How does this fit into your broader transformation? | Scope, budget, organizational commitment |
| 3 | What does success look like in 12 months? | Measurable outcomes, KPIs they'll track |
| 4 | What happens if you do nothing? | Cost of inaction, urgency level |
| 5 | Who else is involved in this decision? | Decision process, stakeholder map |

### Business User / Line Manager
| # | Question | What You're Listening For |
|---|---|---|
| 1 | Walk me through a typical day. Where do you spend most of your time? | Process pain, manual steps, tool switching |
| 2 | What's your biggest frustration with the current process? | Demo narrative anchors |
| 3 | What workarounds have you built? | Hidden requirements, process gaps |
| 4 | If you could wave a magic wand, what would change? | Aspirational state for demo wow moments |
| 5 | How do you measure your team's performance today? | KPIs, reporting needs, data requirements |

### IT / Admin
| # | Question | What You're Listening For |
|---|---|---|
| 1 | What does your current architecture look like? | Integration complexity, data flow |
| 2 | What are your non-negotiable technical requirements? | Security, compliance, SSO, data residency |
| 3 | How do you handle integrations today? | Middleware, point-to-point, API maturity |
| 4 | What's your deployment and release process? | DevOps maturity, change management |
| 5 | What keeps you up at night about this project? | Hidden risks, past failures, political dynamics |

### Technical Evaluator
| # | Question | What You're Listening For |
|---|---|---|
| 1 | What evaluation criteria will you use to compare platforms? | POC rubric, weighted priorities |
| 2 | What's the most complex use case you need to validate? | POC scope, risk areas |
| 3 | How do you handle [specific technical area]? | Deep-dive opportunity, credibility moment |
| 4 | What's worked well (and not) in past platform evaluations? | Landmines, process preferences |
| 5 | What would make you say "this is the one"? | Technical win criteria |

## Current Tech Stack Assessment

| System | Purpose | Integration with SF? | Pain Points | Replacement Candidate? |
|---|---|---|---|---|
| [System] | [What it does] | [Yes/No/Partial] | [Known issues] | [Yes/No] |

## Talk Track

### Opening (2 min)
"[Name], thanks for making time today. We've done some homework on [Company] and
want to make sure we understand your world before we show you anything. The goal
today is to learn — about your priorities, your challenges, and what success looks
like for you. We'll share relevant perspectives where we can, but this is your meeting."

### Transition to Discovery
"Before we dive in, can you give us a 60-second overview of what prompted this
conversation?"

### Closing (5 min)
"Based on what we've heard today, here's what we think we can show you that's
directly relevant: [2–3 themes]. Does that resonate? What would you add?"

### Agreed Next Steps
| Action | Owner | Deadline |
|---|---|---|
| [Action] | [SF / Customer] | [Date] |
```

---

## Technical Qualification Template

```markdown
# Technical Qualification: [Account Name]
**Deal stage:** [Stage]
**ACV:** [$X]
**Close date target:** [Date]
**SE:** [SE name]
**Last updated:** [Date]

## MEDDPICC Technical Overlay

### Metrics
- **Customer's success metrics:** [What they measure]
- **Our value hypothesis:** [How we move those metrics]
- **Quantified impact:** [$ or % improvement we can prove]

### Economic Buyer
- **Name / Title:** [Who signs]
- **Technical awareness:** [High / Medium / Low]
- **SE access:** [Direct / Through champion / None]
- **What they need to hear:** [Business outcome, not technical detail]

### Decision Criteria
| Criterion | Weight | Our Fit | Competitor Fit | Notes |
|---|---|---|---|---|
| [Criterion 1] | [High/Med/Low] | [Strong/Moderate/Weak] | [Strong/Moderate/Weak] | [Action to improve] |

### Decision Process
- **Evaluation steps:** [RFP → Demo → POC → Reference calls → Final presentation]
- **Timeline:** [Key dates]
- **Technical win required before:** [Date]
- **Paper process:** [Procurement, legal, security review timeline]

### Identify Pain
| Pain Point | Stated By | Severity | Our Solution | Demo Beat |
|---|---|---|---|---|
| [Pain 1] | [Name/Role] | [Critical/High/Medium] | [Capability] | [Demo section that addresses it] |

### Champion
- **Name / Title:** [Who]
- **Why they champion us:** [Personal win, political capital, genuine belief]
- **How we enable them:** [Internal materials, talking points, ROI data]
- **Risk level:** [Strong / At risk / Losing them]

### Competition
| Competitor | Their Pitch | Our Counter | Landmine Planted? |
|---|---|---|---|
| [Competitor] | [What they claim] | [Our differentiation] | [Yes/No — question asked] |

## Platform Fit Assessment

| Requirement | Salesforce Capability | Fit | Gap | Mitigation |
|---|---|---|---|---|
| [Requirement] | [Feature/Product] | [Native/Config/Custom/Partner] | [If any] | [Workaround or roadmap] |

### Build Complexity
- **Declarative %:** [Estimated percentage achievable with clicks]
- **Custom code %:** [Apex, LWC, or integration code needed]
- **Integration count:** [Number of external system connections]
- **Data migration scope:** [Volume, complexity, source systems]

## Integration Complexity

| Integration | Direction | System | Protocol | Complexity | Risk |
|---|---|---|---|---|---|
| [Name] | [In/Out/Bi] | [System] | [REST/SOAP/File/Event] | [Low/Med/High] | [Notes] |

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation | Owner |
|---|---|---|---|---|
| [Risk 1] | [High/Med/Low] | [High/Med/Low] | [Plan] | [SE/AE/Customer] |

## Technical Health Score
| Dimension | Score (1–5) | Notes |
|---|---|---|
| Platform fit | [X] | [Why] |
| Integration feasibility | [X] | [Why] |
| Stakeholder alignment | [X] | [Why] |
| Competitive position | [X] | [Why] |
| Timeline achievability | [X] | [Why] |
| **Overall** | **[Avg]** | **[Summary assessment]** |
```

---

## Custom Demo Plan Template

```markdown
# Custom Demo Plan: [Account Name]
**Demo date:** [Date]
**Duration:** [X minutes]
**Audience:** [Names and roles]
**Clouds/Products:** [List]
**SE:** [SE name]

## Persona-Scenario Mapping

| Persona | Name | Their Pain | Demo Scenario | Wow Moment |
|---|---|---|---|---|
| [Role] | [Name] | [Stated problem] | [Day-in-the-life scenario] | [Moment designed to create emotional response] |

## Demo Flow

### Opening: Their World (2 min)
**Talk track:** "Let me start by playing back what we heard during our conversations.
[Customer name] is dealing with [pain 1], [pain 2], and [pain 3]. Today we're going
to show you how we address each of those — not with features, but with the actual
workflow your team would use every day."

**On screen:** [Starting point — e.g., home page, dashboard, or customer record]

### Beat 1: [Pain Point → Solution] (X min)
**Pain addressed:** [Specific customer pain from discovery]
**Persona:** [Who this resonates with]

**Talk track:**
"[Persona name] told us that [problem]. Let me show you what their morning
looks like on Salesforce..."

**Demo steps:**
1. [Navigate to...]
2. [Show...]
3. [Highlight...]
4. [Result that solves the pain]

**Wow moment:** [Specific moment designed to surprise and delight]

**Transition:** "[Bridge to next beat — connect the output of this scenario
to the input of the next]"

### Beat 2: [Pain Point → Solution] (X min)
[Same structure]

### Beat 3: [Pain Point → Solution] (X min)
[Same structure]

### Resolution: Business Impact (3 min)
**Talk track:** "What we've shown you today isn't a product tour — it's your team's
new reality. [Persona 1] goes from [old way] to [new way]. [Persona 2] gets
[capability they asked for]. And [Exec sponsor] sees [business outcome] reflected
in [dashboard/report]."

**On screen:** [Executive dashboard showing KPIs improved]

## Data & Configuration Requirements

| Component | What's Needed | Status | Owner |
|---|---|---|---|
| Demo org | [Specific org or scratch org] | [Ready / Needs setup] | [SE] |
| Sample data | [Records needed, volume] | [Loaded / Needs creation] | [SE] |
| Custom config | [Fields, flows, pages] | [Built / In progress] | [SE] |
| Integrations | [Mock or live connections] | [Status] | [SE] |
| Branding | [Customer logo, colors if used] | [Status] | [SE] |

## Objection Prep

| Likely Objection | When It May Come Up | Root Concern | Response | Proof Point |
|---|---|---|---|---|
| [Objection] | [During beat X] | [What they're really worried about] | [Acknowledge → Reframe → Prove] | [Reference / demo / data] |

## Dry-Run Checklist
- [ ] Demo org tested end-to-end
- [ ] Sample data loaded and verified
- [ ] All automation firing correctly
- [ ] Backup plan if [specific feature] fails
- [ ] Screen resolution and display tested
- [ ] Talk track rehearsed with AE
- [ ] Next steps slide or talking point ready
- [ ] Recording permissions confirmed (if applicable)

## Post-Demo Actions
| Action | Owner | Deadline |
|---|---|---|
| Send follow-up with [specific artifact] | [SE] | [Date] |
| Schedule deep-dive on [topic] | [AE] | [Date] |
| Provide [technical detail] customer requested | [SE] | [Date] |
```

---

## Competitive Battle Card Template

```markdown
# Battle Card: [Competitor Name]
**Last updated:** [Date]
**Author:** [SE name]
**Relevant when:** [Deal scenarios where this competitor appears]

## Competitor Profile

### Overview
- **Company:** [Name]
- **Primary products:** [Key offerings that compete with Salesforce]
- **Target market:** [Who they sell to, segments, industries]
- **Positioning:** [How they describe themselves in one sentence]
- **Recent moves:** [Acquisitions, product launches, pricing changes]

### Their Strengths (Be Honest)
1. [Strength 1 — acknowledge what they do well]
2. [Strength 2]
3. [Strength 3]

### Their Weaknesses
1. [Weakness 1 — factual, provable]
2. [Weakness 2]
3. [Weakness 3]

## Their Pitch vs. Our Story

| Their Claim | Reality Check | Our Counter-Narrative |
|---|---|---|
| "[Claim 1]" | [What's true, what's exaggerated] | [Our differentiation on this point] |
| "[Claim 2]" | [Reality] | [Our counter] |
| "[Claim 3]" | [Reality] | [Our counter] |

## Feature Comparison Matrix

| Capability | Salesforce | [Competitor] | Advantage | Notes |
|---|---|---|---|---|
| [Capability 1] | [How we do it] | [How they do it] | [SF / Them / Tie] | [Context] |
| [Capability 2] | [How we do it] | [How they do it] | [SF / Them / Tie] | [Context] |
| [Capability 3] | [How we do it] | [How they do it] | [SF / Them / Tie] | [Context] |

### Where We Win
[2–3 capability areas where Salesforce has clear, defensible differentiation]

### Where They Win
[Areas where they have a genuine advantage — knowing this prevents credibility damage]

### Where It Depends
[Areas where the winner depends on the customer's specific context]

## Landmine Questions

Questions to ask during discovery that expose competitor weaknesses without naming them:

| Question | What It Exposes | When to Ask |
|---|---|---|
| "How important is it that your [capability] integrates natively with your CRM data?" | [Competitor]'s integration limitations | Discovery, technical evaluation |
| "What's your plan for AI across service, sales, and marketing — unified or separate tools?" | [Competitor]'s lack of platform breadth | Exec meeting, discovery |
| "How do you handle [specific scenario] at scale?" | [Competitor]'s scalability or performance limits | Technical deep-dive |
| "What's your experience been with [competitor's known weakness area]?" | Known pain point if they're an incumbent | Customer reference stage |
| "How do you plan to unify data across channels for a single customer view?" | [Competitor]'s data silo problem | Architecture discussion |

## Proof Points

| Type | Description | When to Use |
|---|---|---|
| Customer reference | [Customer who switched from competitor to SF] | Late-stage validation |
| Analyst report | [Gartner/Forrester/IDC positioning] | Exec meetings, RFP responses |
| Benchmark | [Performance, TCO, or adoption metric] | Technical evaluation |
| Architecture proof | [Demo or POC showing capability competitor lacks] | Technical deep-dive |

## When the Customer Quotes the Competitor

| Customer Says | They Heard From Competitor | Your Response |
|---|---|---|
| "[Competitor claim 1]" | [Source of the claim] | [Factual counter with proof] |
| "[Competitor claim 2]" | [Source] | [Counter] |
```

---

## Technical Objection Responses Template

```markdown
# Technical Objection Responses: [Account Name]
**Deal:** [Account / opportunity name]
**SE:** [SE name]
**Last updated:** [Date]

## Objection Response Framework

For every objection, use the **ARPA** model:
1. **Acknowledge** — validate the concern ("That's a fair question...")
2. **Reframe** — put it in context ("The real question is...")
3. **Prove** — provide evidence (demo, reference, architecture, data)
4. **Advance** — move toward next step ("Let me show you / set up a call with...")

---

### Objection 1: [Exact words the customer used]

**Raised by:** [Name, role]
**Context:** [When and where this came up]

**Root concern:** [What they're actually worried about — often different from the stated objection]

**Response:**
- **Acknowledge:** "[Acknowledgment that validates their concern]"
- **Reframe:** "[Put the concern in proper context]"
- **Prove:** "[Specific evidence — demo, reference call, documentation, architecture diagram]"
- **Advance:** "[Next step to resolve this concern definitively]"

**Proof point:** [Reference customer, benchmark, live demo, or documentation link]

**Follow-up action:** [What you committed to, by when]
**Status:** [Open / Addressed / Resolved]

---

### Objection 2: [Exact words]
[Same structure]

---

## Objection Tracking Summary

| # | Objection | Raised By | Root Concern | Status | Resolution Date |
|---|---|---|---|---|---|
| 1 | [Short description] | [Name] | [Root cause] | [Open/Addressed/Resolved] | [Date] |
| 2 | [Short description] | [Name] | [Root cause] | [Status] | [Date] |
```

---

## POC Scope Document Template

```markdown
# POC Scope: [Account Name]
**Version:** [X.X]
**SE:** [SE name]
**Customer sponsor:** [Name, title]
**POC duration:** [X weeks]
**Start date:** [Date]
**Decision date:** [Date]

## Success Criteria

| # | Criterion | Measurement | Target | Weight |
|---|---|---|---|---|
| 1 | [What must be proven] | [How it's measured] | [Specific threshold] | [% of total] |
| 2 | [Criterion] | [Measurement] | [Target] | [Weight] |
| 3 | [Criterion] | [Measurement] | [Target] | [Weight] |

**Agreement:** Success criteria must be mutually agreed before POC begins. Changes
require written agreement from both parties.

## Scope

### In Scope
| # | Use Case | Description | Salesforce Capability | Complexity |
|---|---|---|---|---|
| 1 | [Use case] | [What we'll prove] | [Product/feature] | [Low/Med/High] |

### Explicitly Out of Scope
| # | Item | Reason | When It Would Be Addressed |
|---|---|---|---|
| 1 | [Item] | [Why excluded] | [Phase 2 / Implementation / Not planned] |

### Scope Control
Any additions to scope require:
1. Written request from customer sponsor
2. Impact assessment from SE (timeline, resource, risk)
3. Mutual agreement before work begins

## Timeline

| Week | Milestone | Deliverable | Owner |
|---|---|---|---|
| 0 | Kickoff | Scope agreement, environment access | Both |
| 1 | [Milestone] | [Deliverable] | [Owner] |
| 2 | [Milestone] | [Deliverable] | [Owner] |
| X | Final review | POC evaluation session | Both |
| X+1 | Decision | Go/no-go recommendation | Customer |

## Resource Requirements

### Salesforce Side
| Role | Person | Time Commitment | Responsibilities |
|---|---|---|---|
| SE | [Name] | [X hrs/week] | Build, configure, present |
| AE | [Name] | [X hrs/week] | Stakeholder management, scheduling |
| Specialist | [If needed] | [X hrs/week] | [Specific expertise] |

### Customer Side
| Role | Person | Time Commitment | Responsibilities |
|---|---|---|---|
| Technical sponsor | [Name] | [X hrs/week] | Access, feedback, evaluation |
| Business SME | [Name] | [X hrs/week] | Use case validation, data |
| IT admin | [Name] | [X hrs/week] | Environment, integrations, security |

## Evaluation Rubric

| Category | Weight | 1 (Does Not Meet) | 3 (Meets) | 5 (Exceeds) |
|---|---|---|---|---|
| [Category 1] | [X%] | [Definition] | [Definition] | [Definition] |
| [Category 2] | [X%] | [Definition] | [Definition] | [Definition] |

**Scoring:** Weighted average ≥ 3.0 = Pass | 2.0–2.9 = Conditional | < 2.0 = Fail

## Exit Criteria

### Pass
- All success criteria met at target threshold
- Weighted evaluation score ≥ 3.0
- Customer sponsor confirms technical validation

### Conditional Pass
- Most success criteria met, gaps have documented remediation plan
- Weighted evaluation score 2.0–2.9
- Customer agrees to proceed with conditions

### Fail
- Critical success criteria not met, no viable remediation
- Weighted evaluation score < 2.0
- Documented as lessons learned for both teams

## Risks

| Risk | Likelihood | Impact | Mitigation | Owner |
|---|---|---|---|---|
| [Risk] | [H/M/L] | [H/M/L] | [Plan] | [Who] |
```

---

## Technical Close Plan Template

```markdown
# Technical Close Plan: [Account Name]
**Deal:** [Opportunity name]
**Target close date:** [Date]
**Current stage:** [Stage]
**Technical win status:** [Not started / In progress / Achieved / At risk]
**SE:** [SE name]
**Last updated:** [Date]

## Remaining Technical Concerns

| # | Concern | Raised By | Severity | Status | Resolution Plan |
|---|---|---|---|---|---|
| 1 | [Concern] | [Name, role] | [Blocker / Major / Minor] | [Open / In progress / Resolved] | See below |
| 2 | [Concern] | [Name, role] | [Severity] | [Status] | See below |

### Concern 1: [Title]
**Stated concern:** [Exact words]
**Root cause:** [What's really behind it]
**Resolution plan:**
| Action | Owner | Deadline | Status |
|---|---|---|---|
| [Action 1] | [SE/AE/Specialist] | [Date] | [Done / In progress / Not started] |
| [Action 2] | [Owner] | [Date] | [Status] |

**Proof required:** [Demo, reference call, documentation, architecture review]
**Stakeholder to confirm resolution:** [Name]

### Concern 2: [Title]
[Same structure]

## Timeline to Technical Win

| Date | Milestone | What Happens | Owner | Dependencies |
|---|---|---|---|---|
| [Date] | [Milestone] | [Description] | [Who] | [What must be done first] |
| [Date] | Technical win declaration | SE + Champion confirm all criteria met | SE + Champion | All concerns resolved |
| [Date] | Handoff to procurement | Technical sign-off delivered to AE | SE | Technical win |

## Stakeholder Alignment

| Stakeholder | Role | Position | Confidence | Actions Needed |
|---|---|---|---|---|
| [Name] | Economic buyer | [Champion / Supportive / Neutral / Skeptical / Blocker] | [Green / Yellow / Red] | [What we need to do] |
| [Name] | Technical evaluator | [Position] | [Color] | [Actions] |
| [Name] | Champion | [Position] | [Color] | [Actions] |

## Risk Register

| Risk | Impact | Likelihood | Mitigation | Trigger | Owner |
|---|---|---|---|---|---|
| [Risk 1] | [High/Med/Low] | [High/Med/Low] | [Plan] | [What signals this risk is materializing] | [Who] |

## Technical Win Communication

Once all concerns are resolved and all stakeholders are aligned:

**Internal (account team):**
"Technical win achieved on [Account]. All [X] evaluation criteria met. [Champion name]
confirmed via [email/meeting] on [date]. Key differentiators: [2–3 bullets]. Handing
off to AE for commercial close. Outstanding items: [if any]."

**External (customer sponsor):**
"[Name], thanks for the thorough evaluation. Based on our work together, we've
addressed [concerns] and demonstrated [capabilities]. We're confident Salesforce
is the right platform for [their initiative]. Next step: [commercial discussion / 
executive alignment / procurement kickoff]."
```
