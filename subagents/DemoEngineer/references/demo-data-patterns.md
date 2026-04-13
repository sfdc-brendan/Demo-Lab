# Demo Data Patterns

Patterns, conventions, and anti-patterns for creating demo data that feels real and tells a coherent story. Reference this when building Sample Data Plans or Persona Data Packages.

---

## Realistic Name Generation

### Company Name Patterns

Good demo company names feel like they could be real. They should match the industry and region of the demo scenario.

| Industry | Pattern | Examples |
|---|---|---|
| Telecommunications | [Region/Direction] + [Telecom/Communications/Networks] | Pacific Telecom, NorthStar Communications, Meridian Networks, Atlas Wireless |
| Financial Services | [Surname/Place] + [Financial/Capital/Advisors/Bank] | Hargrove Financial, Lakeshore Capital, Pinnacle Advisors, Cornerstone Bank |
| Healthcare | [Nature/Place] + [Health/Medical/Healthcare] | Cedar Valley Health, Summit Medical Group, Horizon Healthcare, Bayside Medical |
| Retail | [Adjective/Nature] + [Market/Goods/Supply/Co] | Evergreen Market, Brightside Goods, Urban Supply Co, Coastal Living |
| Manufacturing | [Surname/Material] + [Industries/Manufacturing/Systems] | Thornton Industries, Precision Manufacturing, Alloy Systems, Bridgeport Engineering |
| Technology | [Abstract/Compound] + [Labs/Systems/Tech/Digital] | Lumina Labs, ClearPoint Systems, Nexus Digital, Arcadia Tech |

**Rules:**
- Never use "Acme," "Test Corp," "Sample Inc," or "Company A/B/C"
- Avoid trademarked names or names that match real public companies exactly
- Vary the naming pattern within a single data set (not all "[Place] + [Industry]")
- Include 2–3 "recognizable-feeling" names and a few unique ones per scenario

### Contact Name Patterns

Demo contacts should be diverse and plausible.

**Rules:**
- Vary gender, ethnicity, and cultural background across the persona set
- Match names to region if the demo is location-specific (e.g., Japan demo uses Japanese names)
- Use realistic titles that match the person's role in the demo story
- Avoid obviously fake names: "Test User," "John Doe," "Jane Smith," "User 1"

**Name Bank by Region:**

| Region | First Names | Last Names |
|---|---|---|
| US - General | Maria, James, Priya, Marcus, Aisha, David, Sarah, Wei, Jordan, Elena | Chen, Patel, Williams, Rodriguez, Kim, Okafor, Thompson, Nakamura, Rivera, Schmidt |
| US - West Coast | Kai, Skyler, Morgan, Alejandro, Mei, Tyler | Park, Nguyen, Garcia, Tanaka, Singh, Lopez |
| UK / Ireland | Oliver, Emma, Liam, Amara, Declan, Fiona | O'Brien, Singh, Patel, Campbell, Khan, Williams |
| DACH | Lukas, Anna, Maximilian, Leonie, Felix, Sophie | Müller, Schmidt, Weber, Fischer, Bauer, Hoffmann |
| ANZ | Lachlan, Charlotte, Mateo, Aroha, Jade, Finn | Mitchell, Kapoor, Taylor, Wong, O'Sullivan, Anderson |

**Title Bank by Level:**

| Level | Titles |
|---|---|
| C-Suite | CEO, CIO, CTO, CFO, CRO, Chief Customer Officer, Chief Digital Officer |
| VP | VP of Sales, VP of Customer Experience, VP of IT, VP of Marketing, VP of Operations |
| Director | Director of Customer Service, Director of Engineering, IT Director, Marketing Director |
| Manager | Service Manager, Account Manager, Operations Manager, Regional Manager |
| Individual Contributor | Account Executive, Service Agent, Business Analyst, Solutions Consultant |

---

## Industry-Specific Data Patterns

### Telecommunications

| Object | Key Fields | Realistic Values |
|---|---|---|
| Account | Industry, Type, AnnualRevenue, NumberOfEmployees | Telecommunications, Customer, $500K–$50M, 100–10000 |
| Contact | Title, Department, Phone | VP of Network Ops, Engineering, (area code) 555-XXXX |
| Case | Subject, Origin, Priority, Type | "5G coverage gap — downtown corridor", Phone/Chat/Web, High/Medium, Technical/Billing |
| Opportunity | Type, Amount, StageName | Renewal/Upsell/New Business, $200K–$5M, stages across pipeline |
| **Custom: Subscription__c** | Plan_Name__c, Monthly_Cost__c, Data_Limit_GB__c, Device__c | "Enterprise Unlimited", $89.99, 100, "iPhone 15 Pro" |
| **Custom: Usage__c** | Data_Used_GB__c, Period__c, Overage__c | 87.3, "March 2026", false |
| **Custom: Network_Ticket__c** | Location__c, Impact__c, Status__c | "Downtown SF - Tower 4", "200 users affected", "Investigating" |

**Telecom Story Data:** Create data that shows a customer with high usage approaching their plan limit, a billing dispute tied to an overage charge, and a retention opportunity where upgrading the plan would resolve the billing issue and increase revenue.

### Financial Services

| Object | Key Fields | Realistic Values |
|---|---|---|
| Account | Industry, Type, AnnualRevenue | Financial Services, Client, $1M–$500M |
| Contact | Title, Department | Wealth Advisor / Portfolio Manager / Compliance Officer, Advisory / Risk / Operations |
| Case | Subject, Type, Priority | "Wire transfer flagged for review", Compliance/Service/Onboarding, High/Medium |
| Opportunity | Type, Amount, StageName | New Account/Product Expansion/Rollover, $100K–$10M, pipeline stages |
| **Custom: Financial_Account__c** | Account_Type__c, Balance__c, Risk_Rating__c | "Managed Portfolio", $2,450,000, "Moderate" |
| **Custom: Transaction__c** | Type__c, Amount__c, Status__c, Date__c | "Wire Transfer", $150,000, "Pending Review", TODAY-2 |
| **Custom: KYC_Document__c** | Type__c, Status__c, Expiry__c | "Passport", "Verified", TODAY+365 |

**FSI Story Data:** Create a high-net-worth client onboarding scenario with KYC documents in various verification states, a flagged transaction that needs compliance review, and a cross-sell opportunity for a new investment product.

### Healthcare

| Object | Key Fields | Realistic Values |
|---|---|---|
| Account | Industry, Type | Healthcare, Patient Organization / Provider / Payer |
| Contact | Title, Department | Patient Coordinator / Dr. [Name] / Benefits Specialist, Patient Services / Cardiology / Claims |
| Case | Subject, Type, Priority | "Referral to specialist — cardiology", Referral/Prior Auth/Claims, High/Medium |
| **Custom: Patient__c** | DOB__c, MRN__c, PCP__c, Insurance__c | relative date, "MRN-2026-XXXX", Dr. reference, "BlueCross Premier" |
| **Custom: Encounter__c** | Type__c, Provider__c, Date__c, Notes__c | "Office Visit", Dr. reference, TODAY-14, "Follow-up on lab results" |
| **Custom: Care_Plan__c** | Condition__c, Status__c, Goals__c | "Type 2 Diabetes", "Active", "A1C below 7.0 by Q3" |

**Healthcare Story Data:** Create a patient journey from initial referral through specialist visit to care plan creation, showing how data unification across encounters improves care coordination.

### Retail / Consumer Goods

| Object | Key Fields | Realistic Values |
|---|---|---|
| Account | Industry, Type | Retail, B2C Customer / B2B Retailer |
| Contact | Title | Loyalty Member / Store Manager / Regional Buyer |
| Case | Subject, Origin, Type | "Order delayed — holiday shipment", Web/Chat/Social, Shipping/Return/Product Issue |
| Opportunity | Type, Amount | Seasonal Buy/Reorder/New Product Line, $50K–$2M |
| **Custom: Order__c** | Status__c, Total__c, Channel__c, Shipping__c | "Shipped", $342.50, "Online", "Express" |
| **Custom: Product_Interest__c** | Category__c, Score__c, Source__c | "Home & Garden", 85, "Browse History" |
| **Custom: Return__c** | Reason__c, Status__c, Refund_Amount__c | "Wrong size", "Approved", $89.99 |

**Retail Story Data:** Create a loyal customer who placed a large holiday order that was delayed, opened a support case, and is now at risk of churn — but their browsing history shows high interest in a new product line, creating a retention-through-personalization opportunity.

---

## Cross-Object Story Data

The power of demo data is in the connections between records. Isolated records don't tell a story.

### Building a Coherent Narrative

**Step 1: Start with the persona's problem.**
What is the customer experiencing? A billing error? A service outage? A delayed order?

**Step 2: Create the Account and Contact first.**
These anchor everything else. The Account should feel like a real company. The Contact should have a name, title, and role that make sense for the story.

**Step 3: Create Cases that represent the problem.**
At least one open/escalated case that the demo will resolve, and 1–2 historical cases that show context (previous interactions, resolved issues).

**Step 4: Create Opportunities that show business impact.**
A renewal at risk because of the problem, or an upsell opportunity that resolves the problem. Connect the Opportunity to the Contact via OpportunityContactRole.

**Step 5: Create supporting records that add depth.**
Activities (Tasks, Events), notes, custom object records that make the data feel lived-in. A case with no prior activities looks fake. An account with no closed opportunities looks new.

**Step 6: Validate the story end-to-end.**
Log in as the demo persona. Navigate Account → Contact → Cases → Opportunity. Does the data tell the story you intended? Can the presenter narrate it smoothly?

### Relationship Integrity Checklist

- [ ] Every Contact has an AccountId (no orphaned contacts)
- [ ] Every Case has a ContactId and AccountId
- [ ] Every Opportunity has an AccountId and at least one OpportunityContactRole
- [ ] Custom object children reference their parent via lookup/master-detail
- [ ] Activities (Tasks/Events) are associated with both WhoId (Contact) and WhatId (Account/Opportunity/Case)
- [ ] No circular dependencies that prevent data deletion during reset

---

## Data Volume Guidelines

### Minimum for Realism

| Object | Minimum Records | Why |
|---|---|---|
| Account | 15 | List views need enough rows to scroll; fewer than 10 looks empty |
| Contact | 30 | ~2 per Account minimum; demonstrates relationship depth |
| Case | 50 | Need variety in status, priority, channel for dashboards |
| Opportunity | 20 | Need records in multiple stages for pipeline views |
| Custom Objects | 10+ | Enough to populate related lists and list views |

### Sweet Spot for Demos

| Object | Recommended | Rationale |
|---|---|---|
| Account | 25–50 | Enough for search, filtering, and list view variation |
| Contact | 75–150 | Rich enough for agent console and relationship views |
| Case | 100–200 | Good distribution across statuses for reports and dashboards |
| Opportunity | 40–80 | Full pipeline with realistic stage distribution |
| Activities | 200–500 | Makes record timelines feel alive |

### Performance Ceiling (Scratch Orgs)

| Object | Max Recommended | Notes |
|---|---|---|
| Any standard object | 1,000 | Beyond this, list views and reports slow down in scratch orgs |
| Custom objects | 500 | Depends on field count and automation complexity |
| Files/Attachments | 50 | File storage limits in scratch orgs are tight |
| Total data records | 5,000 | Aggregate guideline across all objects |

---

## Common Demo Data Anti-Patterns

### Anti-Pattern 1: Test Data Naming
**Problem:** Records named "Test Account 1," "Sample Contact," "foo@bar.com"
**Impact:** Destroys credibility immediately. Audience mentally checks out.
**Fix:** Use the name banks and industry patterns in this document. Every record should feel like it belongs to a real company.

### Anti-Pattern 2: Broken Relationships
**Problem:** Contacts without Accounts, Cases without Contacts, Opportunities referencing deleted Accounts.
**Impact:** Related lists are empty, lookups show errors, demo clicks lead to dead ends.
**Fix:** Always load parent records before children. Validate with SOQL after load. Include relationship checks in reset validation.

### Anti-Pattern 3: Missing Required Fields
**Problem:** Records created with only the minimum fields, everything else blank.
**Impact:** Record detail pages look sparse. Dashboards have empty charts. AI features have nothing to work with.
**Fix:** Populate all fields that appear on demo page layouts. If a field is visible, it should have a value.

### Anti-Pattern 4: Stale Dates
**Problem:** Cases from 2022, Opportunities closing last year, Activities from 18 months ago.
**Impact:** Timelines look abandoned. "Last Modified" columns expose stale data. Audience notices.
**Fix:** Use relative dates in data generation scripts. Calculate dates from TODAY, not hardcoded values. Refresh dates as part of reset procedure.

### Anti-Pattern 5: Timezone Mismatches
**Problem:** Datetime fields in UTC when demo is presented in CET, or activities at 3am local time.
**Impact:** Subtle but breaks immersion. "Why did the agent log a call at 3am?"
**Fix:** Set demo user timezone to the presentation timezone. Generate datetimes in business hours (8am–6pm) relative to the demo timezone.

### Anti-Pattern 6: Uniform Data Distribution
**Problem:** All Cases are "New," all Opportunities are "Prospecting," all Accounts have the same revenue.
**Impact:** Dashboards show flat charts. Filtering produces no interesting results.
**Fix:** Distribute records across statuses, stages, and value ranges. Use realistic distributions: more closed cases than open, pipeline weighted toward early stages, revenue following a power law.

### Anti-Pattern 7: No Record History
**Problem:** Records have no Activities, no Case Comments, no Chatter posts, no field history.
**Impact:** Record pages look freshly created, not lived-in. Agent console shows empty timelines.
**Fix:** Generate 2–5 Activities per record (Tasks, logged calls, emails). Add Case Comments showing conversation progression. Create Chatter posts on key records.

---

## Salesforce CLI Data Commands Reference

### Import Records (sObject Tree)

```bash
# Import a single file
sf data import tree --files data/Account.json --target-org demo-alias

# Import multiple files (respects relationships via references)
sf data import tree \
  --files data/Account.json,data/Contact.json,data/Case.json \
  --target-org demo-alias

# Import using a plan file (defines order and relationships)
sf data import tree --plan data/data-plan.json --target-org demo-alias
```

### Export Records

```bash
# Export with query
sf data export tree \
  --query "SELECT Id, Name, Industry FROM Account WHERE Industry = 'Telecommunications'" \
  --output-dir data/export/ \
  --target-org demo-alias

# Export with plan (preserves relationships)
sf data export tree \
  --query "SELECT Id, Name, (SELECT Id, FirstName, LastName FROM Contacts) FROM Account" \
  --plan \
  --output-dir data/export/ \
  --target-org demo-alias
```

### Anonymous Apex for Data Generation

```bash
# Run an Apex script
sf apex run --file scripts/generate-data.apex --target-org demo-alias
```

Example data generation script:

```java
// Generate Accounts with realistic telecom names
List<String> companyNames = new List<String>{
    'Pacific Telecom', 'NorthStar Communications', 'Meridian Networks',
    'Atlas Wireless', 'Summit Broadband', 'Coastal Connect'
};
List<Account> accounts = new List<Account>();
for (String name : companyNames) {
    accounts.add(new Account(
        Name = name,
        Industry = 'Telecommunications',
        Type = 'Customer',
        AnnualRevenue = Math.round(Math.random() * 5000000) + 500000,
        NumberOfEmployees = (Integer)(Math.random() * 5000) + 100,
        BillingCity = 'San Francisco',
        BillingState = 'CA'
    ));
}
insert accounts;
```

### Bulk Operations with DataLoader

For data sets exceeding 200 records or requiring complex field mappings:

```bash
# DataLoader via command line (requires DataLoader CLI installed)
# Use for CSV-based bulk imports with field mapping files

# Alternative: sf data bulk for large volumes
sf data bulk upsert \
  --sobject Account \
  --file data/csv/accounts.csv \
  --external-id External_Id__c \
  --target-org demo-alias \
  --wait 10
```

### Useful Data Validation Queries

```bash
# Count records per object
sf data query --query "SELECT COUNT() FROM Account" --target-org demo-alias
sf data query --query "SELECT COUNT() FROM Contact" --target-org demo-alias

# Check for orphaned records
sf data query \
  --query "SELECT COUNT() FROM Contact WHERE AccountId = null" \
  --target-org demo-alias

# Check date freshness
sf data query \
  --query "SELECT Id, Subject, CreatedDate FROM Case ORDER BY CreatedDate DESC LIMIT 5" \
  --target-org demo-alias

# Verify distribution
sf data query \
  --query "SELECT Status, COUNT(Id) cnt FROM Case GROUP BY Status" \
  --target-org demo-alias
```

### Data Delete for Reset

```bash
# Delete all records of a type (careful — use in demo orgs only)
sf apex run --file scripts/delete-transient.apex --target-org demo-alias

# Selective delete via query
sf data delete bulk \
  --sobject Case \
  --file data/csv/cases-to-delete.csv \
  --target-org demo-alias \
  --wait 10
```
