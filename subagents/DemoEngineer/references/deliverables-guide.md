# Demo Engineer Deliverables Guide

Detailed templates for each Demo Engineer deliverable. These are loaded on-demand when the Demo Engineer skill needs to produce a specific artifact.

---

## 1. Demo Org Setup Script

A complete, executable guide to standing up a demo environment from zero.

### Template

```markdown
# Demo Org Setup: [Scenario Name]

## Prerequisites
- [ ] Org type: [Scratch org / Sandbox / Developer Edition / Trialforce]
- [ ] Edition: [Enterprise / Unlimited / other]
- [ ] Required licenses: [list — e.g., Service Cloud, Data Cloud, Einstein]
- [ ] Required features: [list — e.g., Knowledge, Omni-Channel, Agentforce]
- [ ] Source repo: [git URL or local path to SFDX project]
- [ ] Estimated setup time: [minutes]

## Step 1: Org Provisioning
[scratch org creation command or sandbox clone instructions]

sf org create scratch \
  --definition-file config/project-scratch-def.json \
  --alias [demo-alias] \
  --duration-days 30 \
  --set-default

## Step 2: Metadata Deployment Order
Deploy in this order to avoid dependency failures:

1. **Custom Objects & Fields** — schema must exist before anything references it
   sf project deploy start --source-dir force-app/main/default/objects

2. **Record Types & Page Layouts** — depend on objects/fields
   sf project deploy start --source-dir force-app/main/default/layouts

3. **Flows & Automation** — depend on schema, record types
   sf project deploy start --source-dir force-app/main/default/flows

4. **Apex Classes & Triggers** — depend on schema
   sf project deploy start --source-dir force-app/main/default/classes
   sf project deploy start --source-dir force-app/main/default/triggers

5. **LWC Components** — depend on Apex, schema
   sf project deploy start --source-dir force-app/main/default/lwc

6. **Permission Sets** — depend on all of the above
   sf project deploy start --source-dir force-app/main/default/permissionsets

## Step 3: Permission Assignments
Assign permission sets to demo users:

sf org assign permset --name [PermSetName] --target-org [demo-alias]

Demo user matrix:
| User | Profile | Permission Sets | Role |
|---|---|---|---|
| Demo Admin | System Administrator | [list] | CEO |
| Demo Agent | Custom: Service Agent | [list] | Service Rep |
| Demo Manager | Custom: Service Manager | [list] | Service Manager |

## Step 4: Data Load Sequence
Load in dependency order (parents before children):

1. Accounts (sf data import tree --files data/Account.json)
2. Contacts (sf data import tree --files data/Contact.json)
3. [Object 3, 4, 5...]

See the Sample Data Plan for record details.

## Step 5: Post-Deploy Configuration
Manual or scripted steps that can't be deployed as metadata:

- [ ] Enable [feature] in Setup → [path]
- [ ] Configure Connected App: [name]
- [ ] Set Custom Setting: [name] = [value]
- [ ] Activate Flow: [flow name]

sf apex run --file scripts/post-deploy-config.apex --target-org [demo-alias]

## Step 6: Validation Checklist
Run after setup to confirm everything works:

- [ ] Admin user can log in and see Home page
- [ ] Agent user can log in and see Service Console
- [ ] List views show expected record counts
- [ ] Demo Flow triggers correctly on [event]
- [ ] [Specific demo step 1] works end-to-end
- [ ] [Specific demo step 2] works end-to-end

Automated validation:
sf apex run --file scripts/validate-demo.apex --target-org [demo-alias]
```

---

## 2. Sample Data Plan

Defines what data exists in the demo org, who the personas are, and how data gets generated.

### Template

```markdown
# Sample Data Plan: [Scenario Name]

## Persona Definitions

### Persona 1: [Name]
- **Full Name**: Maria Chen
- **Title**: VP of Customer Experience
- **Company**: Pacific Telecom (Account)
- **Industry**: Telecommunications
- **Location**: San Francisco, CA
- **Role in Demo**: Primary customer-facing persona; shows case escalation path
- **Associated Records**:
  - 1 Account (Pacific Telecom)
  - 3 Contacts (Maria + 2 colleagues)
  - 5 Cases (mix of open, escalated, resolved)
  - 2 Opportunities (renewal + upsell)

### Persona 2: [Name]
[Same structure]

### Persona 3: [Name]
[Same structure]

## Record Counts by Object

| Object | Record Count | Notes |
|---|---|---|
| Account | 25 | Mix of enterprise, mid-market, SMB |
| Contact | 75 | ~3 per Account, varied roles |
| Case | 120 | Mix of statuses, priorities, channels |
| Opportunity | 40 | Spread across stages |
| [Custom Object] | [count] | [purpose] |

## Relationship Map

Account (25)
├── Contact (75) — 3 per Account avg
│   └── Case (120) — linked to Contact and Account
├── Opportunity (40) — 1-2 per Account
│   └── OpportunityContactRole — links to primary Contact
└── [Custom Object] — [relationship description]

## Data Generation Approach

| Method | When to Use | Files |
|---|---|---|
| sf data import tree | Standard objects, < 200 records | data/*.json |
| Anonymous Apex | Complex relationships, calculated fields | scripts/generate-data.apex |
| CSV + DataLoader | Bulk loads, > 200 records | data/csv/*.csv |

## Data Refresh Cadence

| Scenario | Frequency | Method |
|---|---|---|
| Daily demo reset | Daily (automated) | Reset script + data reload |
| Weekly maintenance | Weekly | Full data refresh |
| Pre-customer demo | Ad-hoc | Reset script |

## Validation Queries

-- Confirm record counts
SELECT COUNT() FROM Account  -- expect 25
SELECT COUNT() FROM Contact  -- expect 75
SELECT COUNT() FROM Case     -- expect 120

-- Confirm relationships are intact
SELECT COUNT() FROM Contact WHERE AccountId = null  -- expect 0
SELECT COUNT() FROM Case WHERE ContactId = null     -- expect 0
```

---

## 3. Demo Reset Procedure

Step-by-step instructions to return the demo org to a known-good state.

### Template

```markdown
# Demo Reset Procedure: [Scenario Name]

**Target reset time**: < 5 minutes
**Method**: [Fully automated / Semi-automated / Manual]

## Pre-Reset Checklist
- [ ] No active demo sessions in progress
- [ ] Note any custom data created during the last demo (for teardown)
- [ ] Confirm org is accessible (login test)

## Reset Steps (execute in order)

### Step 1: Delete Transient Data
Remove records created during demo sessions (not base/seed data).

sf apex run --file scripts/reset/01-delete-transient.apex

-- 01-delete-transient.apex
-- Delete cases created after seed data timestamp
DELETE [SELECT Id FROM Case WHERE CreatedDate > :seedDataTimestamp];
DELETE [SELECT Id FROM Task WHERE CreatedDate > :seedDataTimestamp];
-- Add objects as needed

### Step 2: Reset Record States
Return seed records to their demo-ready state.

sf apex run --file scripts/reset/02-reset-states.apex

-- 02-reset-states.apex
-- Reset case statuses, opportunity stages, etc.
List<Case> cases = [SELECT Id, Status FROM Case WHERE Subject LIKE 'DEMO:%'];
for (Case c : cases) { c.Status = 'New'; }
update cases;

### Step 3: Reload Data
Re-import any records that were deleted or need refreshing.

sf data import tree \
  --files data/reset/Cases.json \
  --target-org [demo-alias]

### Step 4: Clear Caches and Indexes
- [ ] Rebuild search index (if demo uses global search)

sf apex run --file scripts/reset/04-rebuild-indexes.apex

- [ ] Clear report cache (if demo shows reports/dashboards)

### Step 5: Validate Reset

sf apex run --file scripts/reset/05-validate.apex

Expected output:
✓ Account count: 25
✓ Contact count: 75
✓ Case count: 120 (all in expected statuses)
✓ Opportunity count: 40
✓ No orphaned records
✓ Demo user access confirmed

## Estimated Time
| Step | Duration |
|---|---|
| Delete transient data | ~30 seconds |
| Reset record states | ~30 seconds |
| Reload data | ~2 minutes |
| Clear caches | ~30 seconds |
| Validate | ~30 seconds |
| **Total** | **~4 minutes** |

## Troubleshooting

| Symptom | Likely Cause | Fix |
|---|---|---|
| Delete fails with "entity is locked" | Active approval process | Reject/recall approvals first |
| Data import fails | Duplicate external IDs | Run delete step again, then retry |
| User can't see records | Sharing rules / OWD | Re-assign permission sets |
| Search returns stale results | Index not rebuilt | Wait 5 min or rebuild manually |
```

---

## 4. Environment Runbook

Everything someone needs to know to operate, troubleshoot, and maintain the demo org.

### Template

```markdown
# Environment Runbook: [Scenario Name]

## Org Access

| Item | Value |
|---|---|
| Login URL | https://[domain].my.salesforce.com |
| Org ID | 00D... |
| Admin Username | [admin@demo.org] |
| Admin Password | [stored in password manager / vault reference] |
| MFA | [method — e.g., Salesforce Authenticator, TOTP] |
| Connected Org Alias | [sf CLI alias] |

## Demo Users

| Username | Profile | Password | Persona |
|---|---|---|---|
| agent@demo.org | Service Agent | [vault ref] | Alex Rivera — Tier 1 Agent |
| manager@demo.org | Service Manager | [vault ref] | Jordan Lee — Service Manager |
| exec@demo.org | Custom Executive | [vault ref] | Chris Park — VP CX |

## Installed Packages

| Package | Namespace | Version | License Required | Purpose |
|---|---|---|---|---|
| [Package Name] | [ns] | [ver] | [Yes/No] | [what it does in the demo] |

## Custom Metadata Dependencies

| Type | API Name | Purpose | Demo Impact if Missing |
|---|---|---|---|
| Custom Object | [API name] | [purpose] | [what breaks] |
| Custom Field | [Object.Field] | [purpose] | [what breaks] |
| Record Type | [Object.RecordType] | [purpose] | [what breaks] |
| Custom Setting | [API name] | [purpose] | [what breaks] |
| Custom Metadata Type | [API name] | [purpose] | [what breaks] |

## Integration Endpoints

| Integration | Type | Endpoint | Auth Method | Status |
|---|---|---|---|---|
| [Name] | Named Credential | [URL] | [OAuth / API Key] | [Active / Mock] |
| [Name] | Connected App | [consumer key ref] | [JWT / Web Server] | [Active] |

## Known Issues and Workarounds

| Issue | Symptoms | Workaround | Permanent Fix |
|---|---|---|---|
| [Issue 1] | [what you see] | [quick fix] | [real fix, if known] |
| [Issue 2] | [what you see] | [quick fix] | [real fix, if known] |

## Escalation Contacts

| Scenario | Contact | Method |
|---|---|---|
| Org locked / inaccessible | [Name] | [Slack / phone] |
| Package upgrade needed | [Name] | [Slack / phone] |
| Integration endpoint down | [Name] | [Slack / phone] |
| "Everything is broken, demo in 1 hour" | [Name] | [phone — call, don't text] |
```

---

## 5. Persona Data Package

A self-contained data set that represents one or more demo personas with all their associated records.

### Template

```markdown
# Persona Data Package: [Scenario Name]

## Persona Profiles

### Persona: Maria Chen — The Frustrated VIP Customer
- **Account**: Pacific Telecom (Enterprise, $2.4M ARR)
- **Title**: VP of Customer Experience
- **Location**: San Francisco, CA
- **Phone**: (415) 555-0142
- **Email**: maria.chen@pacifictelecom.demo
- **Demographic**: 20+ years in telecom, tech-savvy, expects premium service
- **Story**: Long-time customer experiencing repeated billing issues; considering switch to competitor. Key retention target.

### Associated Data

#### Accounts
| Name | Industry | Type | AnnualRevenue | BillingCity |
|---|---|---|---|---|
| Pacific Telecom | Telecommunications | Customer | 2400000 | San Francisco |

#### Contacts
| Name | Title | Account | Phone | Email |
|---|---|---|---|---|
| Maria Chen | VP of Customer Experience | Pacific Telecom | (415) 555-0142 | maria.chen@pacifictelecom.demo |
| David Park | IT Director | Pacific Telecom | (415) 555-0198 | david.park@pacifictelecom.demo |
| Sarah Okafor | Billing Manager | Pacific Telecom | (415) 555-0215 | sarah.okafor@pacifictelecom.demo |

#### Cases
| Subject | Status | Priority | Contact | Description |
|---|---|---|---|---|
| Incorrect charge on enterprise plan | Escalated | High | Maria Chen | Monthly invoice shows $12K overage... |
| Network outage - downtown office | Resolved | Critical | David Park | 4-hour outage affecting 200 users... |
| Contract renewal pricing request | New | Medium | Maria Chen | Requesting updated pricing for 3-year... |

#### Opportunities
| Name | Stage | Amount | CloseDate | Contact Role |
|---|---|---|---|---|
| Pacific Telecom - Renewal FY26 | Negotiation | 2400000 | [NEXT_QUARTER] | Maria Chen (Decision Maker) |
| Pacific Telecom - 5G Upsell | Discovery | 800000 | [NEXT_QUARTER+1] | David Park (Evaluator) |

### Cross-Object Story
Maria is frustrated because of Case #1 (billing error). She's in renewal negotiations
(Opportunity #1) and the billing issue is putting the renewal at risk. Meanwhile, David
had a network outage (Case #2, now resolved) that further strained the relationship.
The agent's job in the demo is to resolve Maria's billing issue AND identify the 5G
upsell opportunity based on David's infrastructure needs.

## File Manifest
| File | Format | Records | Object |
|---|---|---|---|
| data/persona/Account.json | sObject Tree | 1 | Account |
| data/persona/Contact.json | sObject Tree | 3 | Contact |
| data/persona/Case.json | sObject Tree | 3 | Case |
| data/persona/Opportunity.json | sObject Tree | 2 | Opportunity |

## Import Command
sf data import tree \
  --files data/persona/Account.json,data/persona/Contact.json,data/persona/Case.json,data/persona/Opportunity.json \
  --target-org [demo-alias]
```

---

## 6. Environment Dependency Map

A complete inventory of what the demo depends on, in what order things must be deployed, and what breaks if something is missing.

### Template

```markdown
# Environment Dependency Map: [Scenario Name]

## Metadata Dependencies

| Layer | Components | Depends On | Deploy Order |
|---|---|---|---|
| Schema | Custom Objects, Fields, Record Types | Nothing (base layer) | 1 |
| Layouts | Page Layouts, Compact Layouts, Lightning Pages | Schema | 2 |
| Automation | Flows, Process Builder, Apex Triggers | Schema, Layouts | 3 |
| Code | Apex Classes, LWC Components | Schema, Automation | 4 |
| Security | Permission Sets, Sharing Rules, Profiles | All above | 5 |
| Configuration | Custom Settings, Custom Metadata, Named Credentials | All above | 6 |

## Package Dependencies

| Package | Namespace | Min Version | Required By | License Impact |
|---|---|---|---|---|
| [Package 1] | [ns] | [version] | [what uses it] | [license count needed] |
| [Package 2] | [ns] | [version] | [what uses it] | [license count needed] |

## Integration Dependencies

| Integration | Type | Required For | Fallback if Unavailable |
|---|---|---|---|
| [API/Service] | REST callout | [demo step] | [mock response / skip step] |
| [External system] | Named Credential | [demo step] | [static data fallback] |

## Data Dependencies

| Data Set | Object(s) | Required By | Load Method |
|---|---|---|---|
| Reference data | [object list] | Schema, Automation | sf data import tree |
| Persona data | [object list] | Demo execution | sf data import tree |
| Configuration records | [object list] | Automation, Flows | Anonymous Apex |

## Load Sequence Diagram

Deploy metadata → Install packages → Configure integrations
    → Load reference data → Load persona data → Assign permissions
    → Validate

Detailed sequence (delegate to sf-diagram-mermaid for visual):

1. Create/verify org
2. Deploy schema (objects, fields, record types)
3. Install managed packages
4. Deploy layouts and Lightning pages
5. Deploy automation (Flows, Apex)
6. Deploy LWC components
7. Deploy permission sets
8. Configure named credentials and connected apps
9. Load reference/configuration data
10. Load persona data
11. Assign permission sets to users
12. Run validation script

## Failure Impact Matrix

| If This Is Missing... | These Demo Steps Break... | Recovery Time |
|---|---|---|
| [Component] | [affected steps] | [time estimate] |
| [Package] | [affected steps] | [time estimate] |
| [Integration] | [affected steps] | [time estimate] |
| [Data set] | [affected steps] | [time estimate] |
```
