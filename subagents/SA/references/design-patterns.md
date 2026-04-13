# SA Design Patterns

Salesforce-specific architecture patterns for solution design. Use these as decision frameworks, not rigid rules — every pattern has a context where it's the right choice and a context where it isn't.

---

## Declarative-First Decision Tree

The SA's default stance: start declarative, escalate to custom only with documented justification.

### When to Use Flow

- Record-triggered automation (before-save, after-save)
- Screen-based guided processes for internal users
- Scheduled automation (batch operations under ~50K records)
- Simple integration callouts (single HTTP request, simple response parsing)
- Approval processes and email alerts
- Field updates, record creation, task assignment

### When to Use Apex

- Complex business logic that requires conditional branching across multiple objects in a single transaction
- Callouts with complex response parsing, retry logic, or multi-step orchestration
- Operations that must handle large volumes (>50K records) in batch
- Custom REST/SOAP API endpoints
- Platform Event subscribers with complex processing logic
- Operations requiring explicit transaction control (savepoints, partial rollbacks)
- Unit-testable logic that Flows cannot express cleanly

### When to Use Both

- Flow as the orchestrator, Apex as the worker — Flow handles the process sequence, invocable Apex handles the complex computation
- Record-triggered Flow for simple field updates + Apex trigger for cross-object validation
- Screen Flow for user-facing process, calling invocable Apex for backend logic

### Decision Framework

Ask these questions in order:

1. **Can a Flow do this entirely?** → Use Flow. Stop.
2. **Can a Flow do 80% with an Invocable Apex action for the complex part?** → Use Flow + Invocable Apex.
3. **Is the logic inherently code-level?** (complex algorithms, external system orchestration, bulk performance) → Use Apex. Document why Flow was insufficient.
4. **Is this a UI requirement?** → Screen Flow for simple forms. LWC for complex interactions, custom layouts, or real-time reactivity.

### Anti-Patterns to Flag

- **Flow that calls Apex that calls Flow** — circular delegation; pick one orchestrator
- **Apex trigger doing what a before-save Flow can do** — unnecessary code debt
- **Flow with 50+ elements** — consider refactoring into subflows or moving complex logic to invocable Apex
- **Apex written because "the developer prefers code"** — not a valid architectural justification

---

## Data Model Patterns

### Lookup vs. Master-Detail

| Factor | Lookup | Master-Detail |
|---|---|---|
| Parent required? | No — child can exist independently | Yes — child cannot exist without parent |
| Cascade delete? | No (optional by config) | Yes — deleting parent deletes children |
| Roll-up summaries? | Not natively (use Flow or DLRS) | Yes — native roll-up summary fields |
| Sharing model? | Independent — child has own OWD | Inherited — child inherits parent's sharing |
| Reparenting? | Yes — can change parent | Only if explicitly enabled |
| Multiple parents? | Can have up to 40 lookups | Max 2 master-detail per object |

**Decision guidance:**
- Use **Master-Detail** when the child has no meaning without the parent AND you need roll-up summaries or shared security
- Use **Lookup** when the child can exist independently OR you need independent sharing rules OR the parent-child relationship is optional
- If you need Master-Detail behavior but the child must sometimes exist without a parent, use a Lookup with a Flow-based roll-up (or DLRS)

### Junction Objects (Many-to-Many)

Use a junction object when:
- Two objects have a many-to-many relationship
- You need to store attributes of the relationship itself (e.g., role, start date, status)

**Pattern:**
```
Object A ←── Junction Object ──→ Object B
           (MD to A)     (MD to B)
```

- First master-detail determines the junction's primary sharing model
- Second master-detail is the secondary relationship
- Page layouts and related lists go on both parents

**Common junction patterns in Salesforce:**
- Contact Roles (Opportunity ↔ Contact)
- Account Team Members (Account ↔ User)
- Campaign Members (Campaign ↔ Lead/Contact)
- Custom: Project Assignments (Project ↔ Resource)

### Polymorphic Keys

When a child record needs to relate to multiple parent object types:
- **WhoId / WhatId pattern** (Task, Event) — platform-managed polymorphic lookup
- **Custom polymorphic lookup** — use a lookup to each possible parent + a "Type" field, with validation to ensure exactly one is populated
- **Name field (polymorphic standard lookup)** — available on select standard objects

**When to avoid:** Polymorphic relationships complicate queries, reports, and automation. Use only when the business genuinely needs a single child record to relate to different parent types.

### Big Object Considerations

Evaluate Big Objects when:
- Historical data exceeds **tens of millions of records** and doesn't need real-time querying
- Audit or compliance data must be retained but rarely accessed
- Archive strategy requires moving old records out of the transactional data store

**Trade-offs:**
- Queryable only by the first fields in the composite index (no arbitrary WHERE clauses)
- No triggers, Flows, or process automation on Big Objects
- Async SOQL required for complex queries
- No standard UI — requires custom LWC for display

**Alternative:** External Objects via Salesforce Connect if the data lives in an external system and doesn't need to be stored in Salesforce.

### Record Type Strategy

Use record types when:
- Different business processes apply to the same object (e.g., Case types with different fields and page layouts)
- Different picklist values are needed per business context
- Page layout variations are required per user profile

**Avoid when:**
- The only difference is a single field value — use a picklist instead
- You're creating record types for reporting segmentation — use a formula or custom field
- You'd exceed 5-6 record types per object — consider whether you're overloading the object

---

## Integration Patterns

### Request-Reply (Synchronous)

**When to use:**
- User action requires immediate response from external system
- Data must be confirmed before proceeding (e.g., address validation, credit check)
- Low-latency, low-volume interactions

**Salesforce implementation:**
- Apex HTTP callout from trigger/Flow (respect callout limits)
- External Services (declarative, OAS-based)
- Named Credentials for authentication

**Constraints:**
- 120-second timeout for synchronous callouts
- Max 100 callouts per transaction
- No callouts from before-save triggers

### Fire-and-Forget (Asynchronous)

**When to use:**
- Salesforce sends data but doesn't need an immediate response
- Downstream processing can happen later
- Order of operations doesn't depend on external confirmation

**Salesforce implementation:**
- Outbound Messages (declarative, SOAP-based)
- Platform Events (publish from Flow/Apex, subscribe externally)
- Queueable/Future Apex with callout

**Constraints:**
- No guaranteed delivery order for Platform Events (ordering within a channel, but consumers must handle idempotency)
- Outbound Messages retry for 24 hours, then fail silently

### Batch Integration

**When to use:**
- Large data volumes (thousands to millions of records)
- Scheduled synchronization (nightly, hourly)
- Data warehouse loads or ETL processes

**Salesforce implementation:**
- Bulk API 2.0 (inbound/outbound)
- Scheduled Apex calling external APIs in batches
- MuleSoft with Salesforce Connector for orchestrated batch flows
- Data Loader for manual/scheduled batch operations

**Constraints:**
- Bulk API daily limits (varies by edition)
- Batch Apex: 50M records queried, 200 records per execute(), 5 concurrent batches

### Pub-Sub (Event-Driven)

**When to use:**
- Near-real-time notifications across systems
- Multiple consumers need the same event data
- Loose coupling between producer and consumer

**Salesforce implementation options:**

| Mechanism | Best For | Retention | Replay |
|---|---|---|---|
| Platform Events | Custom business events | 72 hours (standard) | Yes, from replay ID |
| Change Data Capture (CDC) | Reacting to record changes | 72 hours | Yes, from replay ID |
| Streaming API (PushTopic) | Legacy; prefer CDC/PE | — | Limited |

**Platform Events vs. CDC decision:**
- Use **Platform Events** when you're designing a custom event schema (e.g., "Order Fulfilled," "Payment Received")
- Use **CDC** when you need to react to any create/update/delete on a standard or custom object without custom code on the Salesforce side

### When to Use MuleSoft

MuleSoft is justified when:
- **Multiple systems** need to integrate (not just Salesforce ↔ one system)
- **Complex orchestration** — multi-step, conditional, or transactional flows across systems
- **API management** — versioning, rate limiting, security policies across consumers
- **Protocol translation** — connecting systems with incompatible protocols (SOAP ↔ REST, FTP ↔ API)
- **Reusable APIs** — building an API layer that multiple consumers (including non-Salesforce) can use

MuleSoft is likely overkill when:
- Single point-to-point integration between Salesforce and one system
- Simple webhook-style notifications
- Low volume, low complexity

---

## Security Model Patterns

### OWD + Sharing Rules + Role Hierarchy Decision Matrix

Start with the most restrictive OWD that works, then open access through sharing rules and role hierarchy.

| Scenario | OWD | Open Access Via |
|---|---|---|
| Reps should only see their own records | **Private** | Role hierarchy (managers see team) |
| Reps see their own + specific shared records | **Private** | Criteria-based sharing rules |
| Everyone reads all records, edits only their own | **Public Read Only** | — (default suffices) |
| Full open collaboration | **Public Read/Write** | — (default suffices) |
| External users (portal/community) | **Private** | Sharing sets, sharing groups |

### Role Hierarchy Design

- Mirror the **data access** needs, not the org chart
- Keep it as flat as possible — deep hierarchies slow sharing calculations
- Remember: role hierarchy grants READ access up. It does not restrict access down.

**Common mistake:** Building a 10-level role hierarchy that mirrors HR org chart. Access requirements usually map to 3-4 levels.

### Permission Set Strategy

- **Permission Sets** for individual permissions that vary by user function
- **Permission Set Groups** to bundle permission sets by job role
- Avoid using Profiles for anything beyond login/OWD — prefer permission sets for all object and field access
- Muting permission sets within groups to subtract permissions for specific users

### Field-Level Security Patterns

- Default fields to **visible, editable** — restrict only sensitive fields
- PII fields (SSN, DOB, salary): permission set with explicit FLS grant
- Encrypted fields: consider Shield Platform Encryption for data-at-rest protection
- Formula fields: visible to anyone who can see the source fields (no independent FLS)

---

## Multi-Cloud Architecture Patterns

### Sales Cloud + Service Cloud

**Shared foundation:** Account, Contact, Activity
**Key integration points:**
- Case created from Opportunity (post-sale support)
- Service data visible on Account/Contact for sales context (installed products, open cases)
- Entitlements tied to Opportunities or Assets

**Data model consideration:** Shared Account/Contact model. Define who "owns" the Account (Sales or Service) and how handoff works.

### Service Cloud + Data Cloud

**Value proposition:** Unified customer profile powering intelligent service
**Key integration points:**
- Data Cloud unified profile surfaced on Case page via Data Cloud Related List or custom LWC
- Calculated insights (churn score, LTV) available to agents
- Segment membership visible for routing or prioritization

**Data model consideration:** Data Cloud DMOs map to Service Cloud objects. Identity resolution links external data to the CRM Contact.

### Data Cloud + Agentforce

**Value proposition:** AI agents grounded in unified customer data
**Key integration points:**
- Agentforce retrieves context from Data Cloud unified profiles
- Data Cloud segments trigger Agentforce actions
- Agentforce actions write back to Data Cloud for closed-loop analytics

**Design consideration:** Define the retrieval pattern — does the agent query Data Cloud per-conversation, or does pre-computed context get pushed to the CRM record?

### Marketing Cloud + Commerce Cloud

**Value proposition:** Personalized marketing driven by commerce behavior
**Key integration points:**
- Commerce order/cart data feeds Marketing Cloud for abandoned cart, post-purchase journeys
- Marketing Cloud segments used for personalized storefronts
- Shared identity between marketing contacts and commerce accounts

**Design consideration:** Event-driven architecture preferred. Commerce events published to Marketing Cloud via API or connector, not batch sync.

---

## Governor Limit Awareness

### Query and DML Budgets

| Governor Limit | Per-Transaction Limit | Design Response |
|---|---|---|
| SOQL queries | 100 (sync) / 200 (async) | Bulkify queries, use collections, avoid queries in loops |
| SOQL rows returned | 50,000 | Use selective filters, indexed fields, LIMIT clause |
| DML statements | 150 | Bulkify DML, collect records then do one insert/update |
| DML rows | 10,000 | Batch processing for large volumes |
| Callouts | 100 per transaction | Batch callouts, use async patterns for high volume |
| CPU time | 10,000ms (sync) / 60,000ms (async) | Optimize algorithms, move heavy processing to async |
| Heap size | 6MB (sync) / 12MB (async) | Stream large data sets, avoid loading full collections |

### Async Patterns

| Pattern | Max Records | Use When | Constraints |
|---|---|---|---|
| Future method | — | Simple async callout or processing | No chaining, limited parameters |
| Queueable Apex | — | Chained async jobs, complex processing | Max 50 chained jobs, 1 callout per execute |
| Batch Apex | 50M (query) | Bulk processing of large datasets | 5 concurrent batches, 200 records per execute |
| Scheduled Apex | — | Time-based recurring jobs | 100 scheduled jobs per org |
| Platform Events | — | Event-driven async processing | 150K events/hour (standard), high-volume option |

### Large Data Volume (LDV) Strategies

When an object will exceed **1 million records**:

1. **Indexing:** Ensure query filters use indexed fields (Id, Name, RecordType, foreign keys, custom indexed fields)
2. **Selective queries:** WHERE clause must filter to <30% of total records (100K for non-indexed) to use index
3. **Skinny tables:** Request Salesforce Support to create skinny tables for frequently queried objects with many fields
4. **Archiving:** Move historical records to Big Objects, external storage, or Data Cloud
5. **Mashup vs. replication:** For external data, evaluate Salesforce Connect (query on demand) vs. replication (copy into Salesforce)
6. **Query optimization:** Use relationship queries to reduce SOQL count, avoid wildcard searches, use date ranges to bound queries
7. **Data skew:** Avoid >10K child records per parent (account data skew) — distribute ownership, use separate lookup objects if needed
