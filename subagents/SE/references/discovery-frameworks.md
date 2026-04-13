# SE Discovery & Qualification Frameworks

Frameworks for running effective discovery, qualifying deals technically, positioning against competitors, and handling the most common Salesforce objections.

---

## Discovery Question Bank by Persona

### Executive Sponsor

Questions for C-suite or VP-level leaders who own the budget and strategic direction.

| # | Question | What You're Listening For | Follow-Up If... |
|---|---|---|---|
| 1 | What's driving this initiative now? What changed? | Trigger event, urgency, strategic mandate | Vague → "Is there a specific event — a board directive, competitive pressure, a regulation — that created the timeline?" |
| 2 | How does this fit into your broader transformation roadmap? | Scope, adjacent initiatives, budget cycle | Isolated → "Are there other teams or projects that would benefit from the same platform?" |
| 3 | What does success look like in 12 months? What metrics will you track? | KPIs, measurable outcomes, executive reporting | Soft metrics → "How would you measure ROI for your board?" |
| 4 | What happens if you do nothing? | Cost of inaction, competitive risk, regulatory exposure | "We're fine for now" → "What changes in 18 months if you wait?" |
| 5 | Who else needs to be convinced for this to move forward? | Decision process, hidden stakeholders, political dynamics | "Just me" → unlikely; probe for procurement, legal, IT governance |
| 6 | What's been your experience with past technology investments like this? | Scar tissue, trust issues, expectations for the vendor relationship | Bad experience → dig deeper on what went wrong and what would be different |
| 7 | What's your biggest concern about this project? | Risks they see, fears you need to address proactively | "Nothing" → they haven't thought deeply yet, or they're not sharing |

### Business User / Line Manager

Questions for the people who will use the system every day.

| # | Question | What You're Listening For | Follow-Up If... |
|---|---|---|---|
| 1 | Walk me through a typical day. Where does most of your time go? | Process pain, tool switching, manual effort | Smooth story → "What about when things go wrong? Walk me through a bad day." |
| 2 | What's the most frustrating part of your current process? | Demo narrative anchors, emotional pain | "It's fine" → "If you could change one thing, what would it be?" |
| 3 | What workarounds has your team built? | Hidden requirements, process gaps, shadow IT | Spreadsheets → "How many hours a week does that take? What breaks when the person who maintains it is out?" |
| 4 | How do you hand off work to other teams? Where does the ball get dropped? | Cross-functional pain, integration needs | Clean handoff → "What about visibility — can your manager see where things stand across teams?" |
| 5 | What information do you wish you had at your fingertips that you don't today? | Data requirements, reporting gaps, 360-view needs | "Everything" → prioritize: "If you could only have one new piece of data, what would change your job the most?" |
| 6 | How do you handle [specific process] at volume? | Scalability pain, batch processing needs | Low volume → "What happens when volume doubles? What breaks first?" |
| 7 | What does your team measure, and how do they get those numbers today? | KPIs, manual reporting, data quality | Manual → demo opportunity for real-time dashboards |

### IT / Admin / Platform Team

Questions for the people responsible for infrastructure, security, and ongoing maintenance.

| # | Question | What You're Listening For | Follow-Up If... |
|---|---|---|---|
| 1 | What does your current architecture look like? Can you sketch the data flow? | Integration complexity, system of record, data quality | Simple → may have hidden complexity; complex → POC scoping intel |
| 2 | What are your non-negotiable requirements for any new platform? | Security, compliance, SSO, data residency, uptime SLA | Few → probe harder; "What does your security team require for cloud vendors?" |
| 3 | How do you handle identity management and single sign-on? | SSO provider, MFA, provisioning/deprovisioning | No SSO → integration work; existing SSO → standard connector |
| 4 | What's your data strategy? Where is customer data today? | Data warehouse, CDP, data lake, data quality programs | Fragmented → Data Cloud positioning opportunity |
| 5 | What's your API maturity? How do current systems communicate? | REST/SOAP/event-driven, middleware, point-to-point | Low maturity → integration risk; high maturity → faster POC |
| 6 | What's your deployment and release process? How do you handle change management? | DevOps maturity, CI/CD, sandbox strategy | Waterfall → set expectations; Agile → align processes |
| 7 | What has been your experience with Salesforce (or any CRM platform) historically? | Past implementations, admin skill level, technical debt | Bad experience → understand what went wrong; good → leverage momentum |

### Technical Evaluator

Questions for the person running the evaluation, comparing platforms, and writing the recommendation.

| # | Question | What You're Listening For | Follow-Up If... |
|---|---|---|---|
| 1 | What evaluation criteria will you use to compare platforms? | Decision criteria, weighting, non-negotiables | Undefined → offer to help structure; defined → align demo to criteria |
| 2 | How will you score or compare the finalists? | Evaluation rubric, POC scope, reference call plan | No method → risk of subjective decision; method → align to it precisely |
| 3 | What's the most complex or risky use case you need to validate? | POC scope driver, potential deal-breaker | Simple → deal may be a demo-only close; complex → POC likely needed |
| 4 | What would make you recommend Salesforce over the alternatives? | Technical win criteria, personal priorities | "Nothing specific" → probe: "What would you need to see to be confident?" |
| 5 | What concerns do you have about Salesforce specifically? | Objections to address, misconceptions to correct | None stated → they're either early or not sharing; ask differently |
| 6 | How much customization do you expect to need versus using out-of-the-box? | Build vs. buy expectations, development resource assumptions | Heavy custom → set expectations on platform philosophy; light → emphasize configuration speed |
| 7 | What's worked well and not worked well in past platform evaluations? | Process landmines, vendor fatigue, decision blockers | Good experience → align to it; bad → differentiate from past vendors |

---

## MEDDPICC Technical Overlay

How each MEDDPICC element maps to the SE's role on the deal.

| Element | Definition | SE's Job | Key Questions | Artifacts |
|---|---|---|---|---|
| **Metrics** | Quantifiable measures of success | Help the customer define measurable success criteria tied to platform capabilities | "How will you measure ROI? What KPIs matter to your CFO?" | ROI framework, benchmark data |
| **Economic Buyer** | Person with budget authority | Tailor exec-level demo narrative; ensure technical story ladders up to business outcome | "What does [EB name] need to believe about the technology?" | Executive briefing, architecture summary |
| **Decision Criteria** | Formal or informal evaluation criteria | Align demo beats and POC scope to their exact criteria; influence criteria where possible | "Can you share your evaluation scorecard? How is it weighted?" | Feature comparison, POC rubric alignment |
| **Decision Process** | Steps from evaluation to purchase | Map the technical milestones within the process; identify where the SE must present | "What are the gates between now and a decision? Where does technical validation fit?" | Timeline, milestone plan |
| **Paper Process** | Procurement, legal, security review | Prepare security questionnaire responses, architecture docs for IT review | "What does your procurement team need from a technical standpoint?" | Security whitepaper, compliance docs |
| **Identify Pain** | Customer's acknowledged pain | Connect every demo moment and POC criterion to a stated pain; never demo capabilities without a pain anchor | "What's the business cost of this problem today? Who feels it most?" | Pain-to-demo mapping |
| **Champion** | Internal advocate with power and influence | Equip the champion with technical talking points, ROI data, and internal presentation materials | "What would help you sell this internally? What objections will you face?" | Champion enablement kit |
| **Competition** | Other vendors or status quo | Know the competitor's pitch, plant landmines, differentiate on capability and platform breadth | "Who else are you evaluating? What have you liked about what you've seen?" | Battle card, landmine questions |

---

## Competitive Discovery

Questions that surface competitor weaknesses without naming them directly.

### Platform Breadth
- "Are you evaluating this as a point solution, or do you need it to connect with your sales, service, and marketing processes?"
- "How important is having a single platform versus best-of-breed tools that you integrate?"
- "What's your plan if you need to add AI capabilities across multiple departments — can your current evaluation cover that?"

### Data & Integration
- "How will you get a unified view of the customer across channels? Is that something the platform needs to handle natively?"
- "How do you plan to handle real-time data access versus batch processing? Does the platform you're evaluating support both?"
- "What's your strategy for connecting this tool with your existing tech stack — native connectors, middleware, or custom code?"

### Scalability & Enterprise Readiness
- "What's your expected data volume in 3 years? Can the platforms you're looking at scale to that?"
- "How many concurrent users do you anticipate? Have you validated performance at that scale?"
- "What's your disaster recovery and business continuity requirement? How does each vendor handle that?"

### AI & Innovation
- "Are you evaluating AI capabilities as part of this? If so, is it AI built into the platform, or an add-on?"
- "How important is it that your AI runs on your customer data natively, versus sending data to a third-party model?"
- "What's your roadmap for AI? Do you need a platform that innovates on AI quarterly, or is today's capability sufficient?"

### Ecosystem & Long-Term Value
- "How do you think about the vendor ecosystem? Is it important that there's a market of developers, partners, and apps?"
- "What's your plan for customization that the vendor doesn't offer out of the box? Is there an app marketplace or partner network?"
- "How do you evaluate the long-term health and investment of the vendor?"

---

## Demo-to-Discovery Bridge

Every demo is also a discovery session. Use these patterns to turn demo reactions into deeper insight.

### Reading the Room

| Signal | What It Means | What to Do |
|---|---|---|
| Leaning in, nodding, taking notes | This resonates | Slow down, go deeper, ask: "Is this the workflow your team would use?" |
| "Can it also do X?" | Unstated requirement | Capture it: "Great question — let me note that. Tell me more about why X matters." |
| Silence or blank expressions | Lost them, or it doesn't resonate | Pause and ask: "Is this relevant to your workflow, or should we focus elsewhere?" |
| Arms crossed, checking phone | Disengaged or skeptical | Shift to a question: "I want to make sure we're covering what matters to you. What would you most like to see?" |
| "Our current tool does that" | Not a differentiator | Acknowledge and pivot: "Good — let me show you something your current tool can't do." |
| Pushback or objection | Buying signal | Engage: "That's a fair concern. Tell me more about what's behind that." |
| "When can we start?" | Strong buy signal | Shift to next steps: "Let's talk about what a pilot would look like." |

### Turning Demo Moments into Discovery

After showing a capability, always bridge back to their world:

1. **"How does your team handle this today?"** — reveals the current-state gap
2. **"Who on your team would use this most?"** — identifies the champion or power user
3. **"What would this change about your team's day-to-day?"** — quantifies value in their terms
4. **"What would you need to see to be confident this works for you?"** — surfaces POC criteria
5. **"What other teams or processes would benefit from this?"** — expands deal scope

---

## Technical Qualification Scoring Model

Score each dimension 1–5 after discovery to assess deal technical health.

| Dimension | 1 (Red) | 3 (Yellow) | 5 (Green) | Weight |
|---|---|---|---|---|
| **Platform fit** | Major gaps, heavy custom | Some custom needed, manageable | Strong native fit, mostly declarative | 25% |
| **Integration feasibility** | Complex, many systems, no middleware | Moderate integrations, some middleware | Few integrations, standard connectors | 20% |
| **Stakeholder alignment** | Key stakeholders opposed or disengaged | Mixed signals, some alignment | Champion + evaluator + sponsor aligned | 20% |
| **Competitive position** | Behind, competitor is incumbent with momentum | Neck and neck, differentiation unclear | Ahead, clear differentiation on key criteria | 20% |
| **Timeline achievability** | Unrealistic timeline for scope | Tight but doable with scope control | Comfortable timeline, clear milestones | 15% |

**Scoring:**
- **4.0–5.0**: Green — pursue aggressively, invest resources
- **3.0–3.9**: Yellow — winnable with focused effort on weak dimensions
- **2.0–2.9**: Orange — significant risks; qualify hard before investing further
- **< 2.0**: Red — high risk of loss; have a candid conversation with AE about deal viability

---

## Common Salesforce Objections & Response Patterns

### Security & Compliance

**Objection:** "We're concerned about putting our data in the cloud / meeting compliance requirements."

**Root concern:** Data sovereignty, regulatory risk, audit exposure.

**Response framework:**
- **Acknowledge:** "Data security is non-negotiable — we agree completely."
- **Reframe:** "The question isn't cloud vs. on-prem. It's which environment invests more in security. Salesforce processes over 200 billion transactions per day with trust.salesforce.com providing real-time transparency."
- **Prove:** Salesforce Shield (encryption, event monitoring, audit trail), compliance certifications (SOC 2, ISO 27001, HIPAA, FedRAMP, GDPR), data residency options (Hyperforce).
- **Advance:** "Let me connect you with our security team for a deep-dive on your specific compliance requirements."

### Scalability

**Objection:** "Can Salesforce handle our volume? We have millions of records and thousands of users."

**Root concern:** Performance degradation, governor limits, enterprise readiness.

**Response framework:**
- **Acknowledge:** "Scale is a valid concern — it should be part of any evaluation."
- **Reframe:** "Salesforce runs the world's largest CRM deployments. The platform processes 12+ trillion transactions per year across 150,000+ customers."
- **Prove:** Governor limits are design guardrails, not hard ceilings. Big Object for large data volumes, Async processing, Data Cloud for analytical scale. Reference customers at their scale.
- **Advance:** "Let's include a scale test in the POC to validate performance with your expected volumes."

### Customization Limits

**Objection:** "Salesforce is too rigid / we need more flexibility / it's a walled garden."

**Root concern:** Platform lock-in, inability to build what they need, past experience with limited customization.

**Response framework:**
- **Acknowledge:** "Flexibility is crucial — you need a platform that adapts to your business, not the other way around."
- **Reframe:** "Salesforce offers a spectrum: declarative configuration for common patterns, and full programmatic extensibility (Apex, LWC, APIs, Heroku, Functions) when you need custom behavior."
- **Prove:** Demo a custom LWC. Show the metadata API. Reference AppExchange (7,000+ apps). Demonstrate that standard + custom coexist.
- **Advance:** "Let me build a proof-of-concept of your most complex use case to show the flexibility firsthand."

### Pricing & Licensing

**Objection:** "Salesforce is too expensive / the licensing model is confusing / we're concerned about total cost."

**Root concern:** Budget constraints, sticker shock, hidden costs, TCO uncertainty.

**Response framework:**
- **Acknowledge:** "Investment matters. Let's make sure you're evaluating total value, not just license cost."
- **Reframe:** "The real question is total cost of ownership and time-to-value. Factor in: implementation speed (declarative vs. custom build), maintenance cost (managed platform vs. self-hosted), and productivity gains."
- **Prove:** TCO comparison (include infrastructure, maintenance, developer productivity, time-to-market). Customer ROI studies. Faster deployment timelines vs. build-from-scratch alternatives.
- **Advance:** "Let me work with your AE on a licensing model that fits your rollout plan — we can phase adoption to manage cost."

### Integration Complexity

**Objection:** "We have a complex integration landscape. Getting Salesforce to talk to everything is going to be a nightmare."

**Root concern:** Past integration failures, middleware cost, data consistency, timeline risk.

**Response framework:**
- **Acknowledge:** "Integration is often the hardest part of any platform decision — you're right to focus on it."
- **Reframe:** "Salesforce is an integration-first platform. Native APIs (REST, SOAP, Bulk, Streaming), MuleSoft for enterprise integration, platform events for event-driven architecture, and pre-built connectors for common systems."
- **Prove:** Demo a MuleSoft integration. Show Change Data Capture. Reference customers with similar integration complexity. Draw the architecture together.
- **Advance:** "Let's map your integration landscape together and identify which connections are standard, which need MuleSoft, and which we should include in the POC."

### AI Readiness

**Objection:** "We're not ready for AI / AI sounds great but we don't trust it with customer interactions / our data isn't clean enough."

**Root concern:** AI hype fatigue, trust in AI outputs, data quality awareness, unclear ROI.

**Response framework:**
- **Acknowledge:** "That's a mature perspective. AI should be implemented thoughtfully, not just because it's trendy."
- **Reframe:** "Agentforce isn't autonomous AI replacing humans — it's AI grounded in your data, governed by your rules, with human oversight built in. And you can start with AI assist (copilot mode) before moving to AI agents."
- **Prove:** Demo Agentforce with trust layer (grounding, guardrails, audit trail). Show the Einstein Trust Layer. Demonstrate the human-in-the-loop pattern.
- **Advance:** "Let's start with one use case where AI would save your team measurable time, and we'll build it into the POC with your data."
