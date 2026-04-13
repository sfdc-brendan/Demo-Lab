# SA Deliverables Guide

Detailed templates for the six core SA deliverable types. Each template is designed for reuse — adapt to the specific project, org, and team context.

---

## Solution Design Document Template

```markdown
# Solution Design Document: [Project Name]

**Version:** [X.X]
**Author:** [SA name]
**Date:** [Date]
**Status:** Draft | In Review | Approved

## 1. Overview

### 1.1 Business Context
[2–3 sentences summarizing the business need. Reference the BA's requirements document.]

### 1.2 Solution Summary
[2–3 sentences describing the proposed solution at a high level. Which clouds, which patterns, what is new vs. extended.]

### 1.3 Key Stakeholders
| Name | Role | Involvement |
|---|---|---|
| [Name] | [Business sponsor] | Approves scope |
| [Name] | [Technical lead] | Reviews design |
| [Name] | [BA] | Validates requirements coverage |

## 2. Scope

### 2.1 In Scope
| # | Capability | Salesforce Cloud | Priority |
|---|---|---|---|
| 1 | [Capability] | [Cloud] | Must-have |
| 2 | [Capability] | [Cloud] | Should-have |

### 2.2 Out of Scope
| # | Capability | Reason | Deferred To |
|---|---|---|---|
| 1 | [Capability] | [Why excluded] | [Phase/Release] |

### 2.3 Assumptions
1. [Assumption about data, licensing, timeline, or team]
2. [Assumption]

### 2.4 Constraints
1. [Technical, regulatory, or organizational constraint]
2. [Constraint]

## 3. Data Model

### 3.1 Object Model
| Object | Type | Purpose | Record Volume (Est.) |
|---|---|---|---|
| [Object] | Standard / Custom | [Why it exists] | [Volume] |

### 3.2 Key Relationships
| Parent | Child | Relationship Type | Rationale |
|---|---|---|---|
| [Parent] | [Child] | Lookup / Master-Detail | [Why this type] |

### 3.3 Record Types
| Object | Record Type | Purpose | Page Layout |
|---|---|---|---|
| [Object] | [RT Name] | [Business meaning] | [Layout name] |

### 3.4 ERD
[Mermaid diagram — delegate to sf-diagram-mermaid]

## 4. Automation Design

### 4.1 Automation Inventory
| Process | Trigger | Approach | Rationale |
|---|---|---|---|
| [Process] | [Event] | Flow / Apex / Both | [Why this approach] |

### 4.2 Declarative vs. Custom Decisions
| Requirement | Declarative Option | Custom Option | Decision | Justification |
|---|---|---|---|---|
| [Requirement] | [Flow/Config] | [Apex/LWC] | [Choice] | [Why] |

## 5. Integration Design

### 5.1 Integration Inventory
| # | Source | Target | Direction | Pattern | Frequency |
|---|---|---|---|---|---|
| 1 | [System] | [System] | Inbound/Outbound/Bidirectional | [Pattern] | [Real-time/Batch/Event] |

### 5.2 Pattern Rationale
[For each integration, explain why the chosen pattern fits.]

### 5.3 Error Handling
| Integration | Error Scenario | Handling Strategy | Alerting |
|---|---|---|---|
| [Integration] | [Timeout/Failure/Bad Data] | [Retry/DLQ/Manual] | [Email/Custom Object/PagerDuty] |

## 6. Security Model

### 6.1 Org-Wide Defaults
| Object | OWD | Rationale |
|---|---|---|
| [Object] | Private / Public Read / Public Read-Write | [Why] |

### 6.2 Sharing Model
| Object | Sharing Mechanism | Criteria | Grants |
|---|---|---|---|
| [Object] | Sharing Rule / Manual / Apex | [Criteria] | [Read / Read-Write] |

### 6.3 Role Hierarchy
[Mermaid diagram or description of role hierarchy relevant to this solution.]

### 6.4 Field-Level Security
| Object.Field | Profile/Perm Set | Visible | Editable | Rationale |
|---|---|---|---|---|
| [Field] | [Profile] | Yes/No | Yes/No | [Why] |

## 7. Migration Strategy
[If data migration is in scope.]

### 7.1 Migration Scope
| Source System | Object | Record Count | Complexity |
|---|---|---|---|
| [System] | [Object] | [Count] | Low/Medium/High |

### 7.2 Approach
- Tool: [Data Loader / MuleSoft / Custom]
- Sequence: [Order of operations — parent before child, reference data first]
- Validation: [How to confirm migration success]

### 7.3 Rollback Plan
[What happens if migration fails. How to restore to pre-migration state.]

## 8. Technical Risks

| # | Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|---|
| 1 | [Risk] | High/Med/Low | High/Med/Low | [What we do about it] |
| 2 | [Risk] | High/Med/Low | High/Med/Low | [What we do about it] |

## 9. Sign-Off

| Stakeholder | Role | Approval | Date |
|---|---|---|---|
| [Name] | [Role] | Pending / Approved | [Date] |
```

---

## Data Model Template

```markdown
# Data Model: [Project Name]

## Object Inventory

### Standard Objects (Extended)
| Object | Extensions | Purpose |
|---|---|---|
| [Account] | [Custom fields added] | [Why extended] |

### Custom Objects
| API Name | Label | Purpose | Estimated Records (Year 1) |
|---|---|---|---|
| [Object__c] | [Label] | [Business purpose] | [Volume] |

## Field Specifications

### [Object Name]
| Field API Name | Label | Type | Required | Default | Description |
|---|---|---|---|---|---|
| [Field__c] | [Label] | Text(80) / Picklist / Lookup / etc. | Yes/No | [Default] | [Purpose] |

## Relationships

| Parent Object | Child Object | Relationship | API Name | Cascade Delete | Rationale |
|---|---|---|---|---|---|
| [Parent] | [Child] | Master-Detail / Lookup | [API Name] | Yes/No | [Why this type] |

### Junction Objects
| Junction Object | Parent 1 | Parent 2 | Purpose |
|---|---|---|---|
| [Object__c] | [Object A] | [Object B] | [Many-to-many relationship for...] |

## Record Types

| Object | Record Type | Description | Processes Using It | Page Layout |
|---|---|---|---|---|
| [Object] | [RT Name] | [When to use] | [Flows, assignment rules] | [Layout] |

## Sharing Rules

| Object | OWD | Sharing Rule Name | Based On | Shared With | Access Level |
|---|---|---|---|---|---|
| [Object] | [OWD] | [Rule Name] | [Criteria/Owner] | [Role/Group] | [Read/Read-Write] |

## Storage Estimates

| Object | Year 1 Records | Year 3 Records | Avg Record Size | Storage Impact |
|---|---|---|---|---|
| [Object] | [Count] | [Count] | [KB] | [GB] |

**Total estimated storage:** [X GB Year 1, Y GB Year 3]
**File storage:** [If attachments/files are in scope]
**Big Object consideration:** [If any object exceeds threshold]

## ERD

[Mermaid erDiagram — delegate to sf-diagram-mermaid]
```

---

## Integration Architecture Template

```markdown
# Integration Architecture: [Project Name]

## Integration Landscape

### System Context
[High-level diagram showing Salesforce and all connected systems — delegate to sf-diagram-mermaid]

### Integration Inventory
| # | Name | Source | Target | Direction | Data | Pattern | Frequency | Volume | Priority |
|---|---|---|---|---|---|---|---|---|---|
| 1 | [Name] | [System] | [System] | In/Out/Bi | [Entity] | [Pattern] | [Schedule] | [Records/day] | [P1/P2/P3] |

## Pattern Selection

### Integration 1: [Name]
**Pattern:** [Request-Reply / Fire-and-Forget / Batch / Pub-Sub]
**Rationale:** [Why this pattern over alternatives]

**Alternatives considered:**
| Pattern | Pros | Cons | Why Not |
|---|---|---|---|
| [Alt 1] | [Pros] | [Cons] | [Reason rejected] |

**Technical details:**
- Protocol: [REST / SOAP / Platform Event / CDC / Bulk API / Streaming]
- Authentication: [OAuth 2.0 / JWT / Named Credential]
- Middleware: [Direct / MuleSoft / Other] — rationale: [Why]
- Rate limits: [Salesforce API limits, external system limits]

**Error handling:**
| Error Type | Detection | Response | Recovery |
|---|---|---|---|
| Timeout | [How detected] | [Retry with backoff] | [Manual review after N retries] |
| Validation failure | [How detected] | [Log to staging object] | [Fix and reprocess] |
| System unavailable | [How detected] | [Queue for retry] | [Alert and manual intervention] |

**Monitoring:**
- Success metric: [What "working" looks like]
- Alert trigger: [When to page someone]
- Dashboard: [Where to monitor]

### Integration 2: [Name]
[Same structure repeated]

## Cross-Cutting Concerns

### Authentication Strategy
| External System | Auth Method | Credential Storage | Rotation |
|---|---|---|---|
| [System] | [OAuth / API Key / JWT] | [Named Credential] | [Cadence] |

### API Limit Budget
| API Type | Daily Limit | Consumed by Integrations | Remaining Budget |
|---|---|---|---|
| REST API | [Limit] | [Estimated usage] | [Buffer] |
| Bulk API | [Limit] | [Estimated usage] | [Buffer] |
| Streaming API | [Limit] | [Estimated usage] | [Buffer] |

### Retry and Dead Letter Strategy
- Retry policy: [Exponential backoff, max N retries]
- Dead letter: [Custom object / Platform Event / External queue]
- Reprocessing: [Manual / Automated / Scheduled review]
```

---

## Technical Decision Log Template

```markdown
# Technical Decision Log: [Project Name]

## Decision Record Format

Each entry follows the Architecture Decision Record (ADR) pattern.

---

### TDL-001: [Decision Title]

**Date:** [Date]
**Status:** Proposed | Accepted | Superseded by TDL-XXX
**Decider:** [SA name]
**Consulted:** [Names and roles]

#### Context
[What is the situation that requires a decision? What constraints exist?]

#### Options Evaluated

| Option | Description | Pros | Cons |
|---|---|---|---|
| A: [Name] | [Brief description] | [Advantages] | [Disadvantages] |
| B: [Name] | [Brief description] | [Advantages] | [Disadvantages] |
| C: [Name] | [Brief description] | [Advantages] | [Disadvantages] |

#### Decision
**Chosen:** Option [X] — [Name]

#### Rationale
[Why this option was selected. What criteria were most important. How trade-offs were weighed.]

#### Trade-Offs Accepted
- [Trade-off 1: what we give up and why it's acceptable]
- [Trade-off 2]

#### Consequences
- [Positive consequence]
- [Negative consequence and how it's mitigated]

#### Review Trigger
[When should this decision be revisited? E.g., "if data volume exceeds 10M records" or "when MuleSoft license is available."]

---

### TDL-002: [Next Decision]
[Same structure]
```

---

## Build vs Buy Analysis Template

```markdown
# Build vs Buy Analysis: [Capability Name]

**Date:** [Date]
**Analyst:** [SA name]

## Requirement Summary
[What the business needs, extracted from BA requirements. Be specific enough to evaluate options against.]

## Options Evaluated

### Option 1: Declarative (Salesforce Config)
- **Approach:** [Flows, validation rules, formulas, report types, etc.]
- **Effort:** [Person-days]
- **Ongoing cost:** [Admin maintenance hours/month]
- **Pros:** [Maintainable by admins, no code debt, upgradeable]
- **Cons:** [Limitations, what it can't do]
- **Gaps:** [Requirements not fully met]

### Option 2: Custom Build (Apex / LWC)
- **Approach:** [Custom classes, triggers, Lightning components]
- **Effort:** [Person-days]
- **Ongoing cost:** [Dev maintenance hours/month, test maintenance]
- **Pros:** [Full control, can handle complex logic]
- **Cons:** [Code debt, requires dev skills for changes, test coverage overhead]
- **Gaps:** [Requirements not fully met]

### Option 3: AppExchange Package
- **Package:** [Name, publisher, listing URL]
- **License cost:** [$X/user/month or $Y/org/month]
- **Approach:** [What it provides out of the box, what needs configuration]
- **Effort:** [Person-days for configuration and integration]
- **Ongoing cost:** [License + admin maintenance]
- **Pros:** [Faster time to value, vendor maintains code, community support]
- **Cons:** [Dependency on vendor, limited customization, data model impact]
- **Gaps:** [Requirements not fully met]

## Comparison Matrix

| Criterion | Weight | Declarative | Custom | AppExchange |
|---|---|---|---|---|
| Time to deliver | 20% | [Score 1-5] | [Score 1-5] | [Score 1-5] |
| Total cost (3 year) | 20% | [Score 1-5] | [Score 1-5] | [Score 1-5] |
| Maintainability | 20% | [Score 1-5] | [Score 1-5] | [Score 1-5] |
| Scalability | 15% | [Score 1-5] | [Score 1-5] | [Score 1-5] |
| Requirement coverage | 15% | [Score 1-5] | [Score 1-5] | [Score 1-5] |
| Risk | 10% | [Score 1-5] | [Score 1-5] | [Score 1-5] |
| **Weighted Total** | | [Total] | [Total] | [Total] |

## Recommendation
**Recommended option:** [Option X]

**Rationale:** [Why this option best balances the evaluation criteria. Address the top concern for each rejected option.]

**Conditions:** [Under what circumstances would this recommendation change?]
```

---

## Environment Strategy Template

```markdown
# Environment Strategy: [Project / Org Name]

## Org Strategy

### Topology
- **Model:** Single org | Multi-org | Hybrid
- **Rationale:** [Why this model fits the business structure]
- **Org list:**
  | Org | Edition | Purpose | Clouds Enabled |
  |---|---|---|---|
  | [Org name] | Enterprise / Unlimited | [Production / Dev] | [List] |

## Sandbox Plan

| Sandbox Name | Type | Purpose | Refresh Cadence | Data Strategy |
|---|---|---|---|---|
| DEV | Developer | Individual feature development | On demand | Seed scripts only |
| DEV-INT | Developer Pro | Integration development and testing | Bi-weekly | Seed scripts + mock services |
| QA | Partial Copy | QA and regression testing | Per sprint | Subset of production data |
| STAGING | Full Copy | UAT and pre-deployment validation | Per release | Full production copy |

### Sandbox Naming Convention
`[OrgPrefix]-[Type]-[Purpose]` — e.g., `ACME-DEV-FeatureX`, `ACME-QA-Sprint12`

## CI/CD Pipeline

### Source Control
- **Repository:** [GitHub / Bitbucket / etc.]
- **Branching strategy:** [Trunk-based / GitFlow / Feature branches]
- **Branch naming:** `feature/[ticket]-[description]`, `release/[version]`

### Deployment Model
- **Approach:** Source-driven (sf project deploy) | Org-driven | Hybrid
- **Package strategy:** Unlocked packages / Unpackaged metadata / Both
- **Rationale:** [Why this model]

### Pipeline Stages
| Stage | Environment | Trigger | Validations | Approvals |
|---|---|---|---|---|
| Build | — | PR created | Compile, lint, PMD | — |
| Test | DEV-INT | PR merge to develop | Apex tests, integration tests | Auto |
| QA | QA | Sprint complete | Regression suite | QA lead |
| UAT | STAGING | Release candidate | UAT scripts | Business sponsor |
| Production | PROD | Release window | Smoke tests | Release manager |

### Rollback Strategy
- **Approach:** [Metadata rollback / Feature flags / Quick deploy of previous version]
- **RTO:** [Recovery time objective]
- **Responsible:** [Role]

## Data Seeding

### Approach by Environment
| Environment | Data Source | Volume | Refresh Method |
|---|---|---|---|
| DEV | Seed scripts (Apex / sf data import) | Minimal | On sandbox create |
| QA | Partial copy + anonymization | Medium | Sandbox refresh + script |
| STAGING | Full copy + anonymization | Full | Sandbox refresh |

### Sensitive Data Handling
- PII fields: [Anonymized / Masked / Excluded]
- Method: [Sandbox post-copy script / Data Mask / Custom Apex]

## Release Cadence

| Release Type | Frequency | Contents | Approval |
|---|---|---|---|
| Sprint release | Bi-weekly | Sprint deliverables | PO + QA sign-off |
| Hotfix | As needed | Critical bug fixes | Tech lead + PO |
| Major release | Quarterly | Multi-sprint features | Steering committee |

### Salesforce Release Alignment
- **Approach to Salesforce releases:** [Preview sandbox testing / Sandbox preview org / Release notes review]
- **Testing cadence:** [Test in preview sandbox 4 weeks before release]
```
