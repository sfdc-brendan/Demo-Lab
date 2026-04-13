# Industry Advisor — Industry Patterns

Deep-dive patterns for each major vertical. Use these as a starting point — always validate against the specific customer's sub-vertical, geography, and organizational context.

---

## Healthcare / Life Sciences

### Sub-Vertical Distinctions

The healthcare industry is not monolithic. These sub-verticals have fundamentally different processes, buyers, and regulations:

| Sub-Vertical | Core Process | Primary Buyer | Key Regulation |
|---|---|---|---|
| Provider (Health System) | Patient care delivery | CIO, CMIO, VP of Operations | HIPAA, Meaningful Use |
| Provider (Physician Practice) | Patient scheduling + billing | Practice Manager, Office Manager | HIPAA, MIPS/MACRA |
| Payer (Health Insurance) | Claims adjudication + member services | VP of Member Experience, CTO | HIPAA, ACA, state insurance regs |
| Pharma | Drug development + commercialization | VP of Commercial, Medical Affairs | FDA 21 CFR Part 11, Sunshine Act |
| MedTech | Device sales + post-market surveillance | VP of Sales, Quality/Regulatory | FDA QSR, MDR (EU), UDI |
| Life Sciences (CRO) | Clinical trial management | VP of Clinical Operations | GCP, 21 CFR Part 11, GDPR |

### HIPAA Deep Dive

HIPAA is the foundational constraint for any healthcare Salesforce implementation:

**Privacy Rule (45 CFR Part 160, 164 Subpart E)**
- Minimum necessary principle: users should only see the PHI they need for their role
- Salesforce implication: field-level security, record-level sharing, role hierarchy must enforce minimum necessary
- Business Associate Agreement (BAA): Salesforce signs a BAA for Shield-protected orgs; confirm it's in place

**Security Rule (45 CFR Part 164 Subpart C)**
- Access controls: unique user IDs, automatic logoff, encryption
- Audit controls: track who accessed what PHI and when
- Transmission security: encrypt PHI in transit
- Salesforce implication: Shield Platform Encryption, Event Monitoring, Session Settings, TLS enforcement

**Breach Notification Rule**
- 60-day notification window for breaches affecting 500+ individuals
- Salesforce implication: Event Monitoring must be configured to detect unauthorized access; incident response plan must include Salesforce data

### Health Cloud Object Model

Key objects beyond standard Salesforce:

| Object | Purpose | Key Relationships |
|---|---|---|
| Care Plan | Tracks a patient's longitudinal care | Links to Patient, Care Team, Problems, Goals |
| Care Plan Template | Standardized care protocols | Used to create Care Plans |
| Care Team Member | Provider assigned to a patient's care | Links Care Plan to User/Contact |
| Clinical Encounter | A patient visit or interaction | Links to Patient, Provider, Facility |
| Patient | Person record (extends Contact) | Core entity — all clinical data relates here |
| Health Condition | Diagnosed condition (ICD-10) | Links to Patient, Care Plan |
| Medication | Prescribed medication | Links to Patient, Provider |
| Coverage | Insurance coverage details | Links to Patient, Payer |

### Integration Patterns

| System | Protocol | Direction | Key Data |
|---|---|---|---|
| EHR (Epic, Cerner) | HL7 FHIR / HL7 v2 ADT | Bidirectional | Patient demographics, encounters, results |
| Claims System | X12 837/835 or API | Inbound | Claims status, payment, EOB |
| Pharmacy | NCPDP SCRIPT | Outbound | e-Prescriptions |
| Lab Systems | HL7 ORU | Inbound | Lab results |
| HIE (Health Info Exchange) | FHIR, CCD/CDA | Bidirectional | Community health records |

### Common Healthcare Patterns

**Care Coordination Pattern**
- Problem: multiple providers treating the same patient don't communicate
- Solution: Health Cloud Care Plans with Care Team Members; automated notifications when care plan status changes
- KPI impact: reduces readmissions, improves care gap closure

**Patient Engagement Pattern**
- Problem: patients disengage between visits; preventive care gaps grow
- Solution: Marketing Cloud + Health Cloud integration; automated outreach based on care gaps
- KPI impact: improves HCAHPS scores, preventive screening rates

**Referral Management Pattern**
- Problem: referral leakage (patients referred to out-of-network providers)
- Solution: Health Cloud referral objects with in-network provider matching
- KPI impact: reduces referral leakage rate, improves network utilization

---

## Financial Services

### Sub-Vertical Distinctions

| Sub-Vertical | Core Process | Primary Buyer | Key Regulation |
|---|---|---|---|
| Retail Banking | Account opening + servicing | VP of Digital, Head of Branch | Dodd-Frank, CFPB, TILA |
| Commercial Banking | Relationship management + lending | Head of Commercial Banking | SOX, BSA/AML, CRA |
| Insurance (P&C) | Underwriting + claims | VP of Claims, CTO | State insurance regs, NAIC |
| Insurance (Life) | Policy administration + servicing | VP of Operations | State insurance regs, NAIC |
| Wealth Management | Client advisory + portfolio mgmt | Head of Wealth, Chief Compliance | SEC, FINRA, fiduciary rules |
| Mortgage/Lending | Loan origination + servicing | VP of Lending, CTO | TILA, RESPA, HMDA, ECOA |

### KYC/AML Deep Dive

Know Your Customer / Anti-Money Laundering is the critical compliance domain:

**Customer Due Diligence (CDD)**
- Verify identity at account opening (name, DOB, address, ID number)
- Beneficial ownership for entities (25%+ owners)
- Salesforce implication: identity verification workflows, document capture, beneficial ownership tracking on Account

**Enhanced Due Diligence (EDD)**
- Required for high-risk customers (PEPs, high-risk geographies, complex structures)
- Ongoing monitoring of transaction patterns
- Salesforce implication: risk scoring on Account, periodic review workflows, integration with screening services

**Suspicious Activity Reporting (SAR)**
- File SARs within 30 days of detection; 60 days if no suspect identified
- Cannot notify the customer that a SAR was filed ("tipping off")
- Salesforce implication: SAR workflow must be hidden from customer-facing users; separate permission set; audit trail

### Financial Services Cloud Object Model

| Object | Purpose | Key Relationships |
|---|---|---|
| Financial Account | Bank account, investment account, insurance policy | Links to Account (client/household) |
| Financial Account Role | Who has what access to which account | Links Financial Account to Contact |
| Financial Holding | Assets, liabilities, positions | Links to Financial Account |
| Financial Goal | Client's financial objectives | Links to Account/Household |
| Action Plan | Structured set of tasks for lifecycle events | Links to Account, uses Action Plan Template |
| Household | Group of related individuals | Parent of Account (person accounts) |
| Securities | Investment instruments | Referenced by Financial Holding |
| Claim | Insurance claim record | Links to Policy (Financial Account), Contact |

### Integration Patterns

| System | Protocol | Direction | Key Data |
|---|---|---|---|
| Core Banking (FIS, Fiserv, Jack Henry) | API / Batch | Bidirectional | Accounts, transactions, balances |
| Trading Platform (Bloomberg, Refinitiv) | FIX / API | Inbound | Market data, positions, trades |
| Credit Bureau (Equifax, Experian, TransUnion) | API | Inbound | Credit scores, reports |
| KYC/AML Screening (LexisNexis, Dow Jones) | API | Bidirectional | Screening results, risk scores |
| Document Management (DocuSign, Adobe Sign) | API | Bidirectional | Signed documents, compliance records |

### Common Financial Services Patterns

**Client Lifecycle Management Pattern**
- Problem: fragmented view of client across products (banking, insurance, investments)
- Solution: FSC Household model with Financial Account rollups; unified client dashboard
- KPI impact: increases wallet share, improves advisor productivity

**Compliant Data Sharing Pattern**
- Problem: advisors need to share client info with assistants, but compliance requires controls
- Solution: FSC compliant data sharing rules; sharing sets based on team membership
- KPI impact: reduces compliance violations, maintains advisor productivity

**Client Onboarding Pattern**
- Problem: onboarding takes too long; multiple forms, identity verification, regulatory checks
- Solution: FSC Action Plans with automated KYC/AML integration; digital document collection
- KPI impact: reduces time-to-onboard, improves client satisfaction

---

## Telecom / Media

### Sub-Vertical Distinctions

| Sub-Vertical | Core Process | Primary Buyer | Key Regulation |
|---|---|---|---|
| Mobile Operator | Subscriber acquisition + retention | VP of Consumer, CTO | FCC, CPNI |
| Fixed-Line / Broadband | Service provisioning + support | VP of Operations | FCC, local franchise |
| Cable / MSO | Video + broadband bundling | VP of Product | FCC, local franchise, retransmission |
| OTT / Streaming | Content delivery + subscription | VP of Growth | COPPA, CCPA/GDPR |
| Tower Company | Infrastructure leasing | VP of Operations | FCC, FAA, local zoning |

### Telecom-Specific Metrics

| Metric | Definition | Industry Benchmark | Why It Matters |
|---|---|---|---|
| Churn Rate | % subscribers who cancel per month | 1.5–2.5% (postpaid mobile) | Revenue erosion; acquiring new subscriber costs 5–7× retention |
| ARPU | Average Revenue Per User per month | $50–70 (US postpaid mobile) | Core revenue metric; drives valuation |
| NPS | Net Promoter Score | 20–40 (telecom industry avg) | Telecom historically has low NPS; improvement is differentiation |
| FCR | First-Call Resolution | 70–75% | Directly correlated with churn; every unresolved call increases churn risk |
| MRR | Monthly Recurring Revenue | N/A (varies) | Subscription business health metric |
| CPGA | Cost Per Gross Add | $300–500 (US postpaid) | Acquisition efficiency |

### Communications Cloud Object Model

| Object | Purpose | Key Relationships |
|---|---|---|
| Subscriber | Individual with active service(s) | Extends Contact |
| Service Account | Container for subscriber services at a location | Links to Account, Service Location |
| Product Offering | Bundled or individual service product | Catalog structure with components |
| Order | Service order (new, change, disconnect) | Links to Subscriber, Product Offering |
| Order Item | Individual line item within an order | Links to Order, decomposed for fulfillment |
| Asset | Provisioned service or device | Links to Subscriber, Service Account |
| Trouble Ticket | Service issue with SLA tracking | Links to Subscriber, Asset |

### Integration Patterns

| System | Protocol | Direction | Key Data |
|---|---|---|---|
| BSS (Amdocs, Netcracker) | TM Forum APIs | Bidirectional | Billing, product catalog, orders |
| OSS (Nokia, Ericsson) | TM Forum / SOAP | Outbound | Provisioning, activation, network config |
| Network Inventory | API | Inbound | Coverage, capacity, equipment |
| Billing (Convergys, CSG) | Batch / API | Inbound | Usage, invoices, payments |
| Number Portability DB | API | Bidirectional | Port-in/port-out requests |

### Common Telecom Patterns

**Churn Prediction and Retention Pattern**
- Problem: subscribers churn without warning; retention offers come too late
- Solution: Data Cloud ingests usage, billing, and support data; predictive model scores churn risk; triggers proactive retention campaigns
- KPI impact: reduces churn by 0.5–1.5 percentage points

**Order Decomposition Pattern**
- Problem: a single subscriber order (e.g., mobile + home internet + TV) must decompose into multiple fulfillment tasks across different systems
- Solution: Communications Cloud order management; order decomposition rules route each component to the right fulfillment system
- KPI impact: reduces order fallout, improves time-to-activate

**Trouble Ticket to Network Correlation Pattern**
- Problem: trouble tickets treated as individual cases; pattern (network outage) not detected
- Solution: correlate trouble tickets by service location and time; auto-detect network events; proactive notification to affected subscribers
- KPI impact: improves FCR, reduces call volume during outages

---

## Manufacturing

### Sub-Vertical Distinctions

| Sub-Vertical | Core Process | Primary Buyer | Key Regulation |
|---|---|---|---|
| Discrete | Build-to-order / configure-to-order | VP of Sales, VP of Operations | OSHA, EPA, export controls |
| Process | Continuous production (chemical, food) | Plant Manager, VP Supply Chain | FDA (food), EPA, OSHA |
| Industrial Equipment | Capital equipment sales + service | VP of Service, VP of Sales | OSHA, product liability |
| Automotive | OEM + dealer management | VP of Sales, VP of Dealer Ops | NHTSA, EPA, TREAD Act |
| Aerospace & Defense | Long-cycle contracts | Program Manager, VP of Contracts | ITAR, FAR/DFARS, CMMC |

### Manufacturing Cloud Object Model

| Object | Purpose | Key Relationships |
|---|---|---|
| Sales Agreement | Long-running contract with volume commitments | Links to Account, Products |
| Sales Agreement Product | Individual product line within agreement | Links to Sales Agreement |
| Account-Based Forecast | Forecast at the account level (not opp level) | Links to Account, Sales Agreement |
| Rebate Program | Volume-based incentive program | Links to Account, Products |
| Partner | Dealer/distributor in the channel | Extends Account with partner fields |
| Asset | Installed equipment at customer site | Links to Account, Product, Service Contract |
| Service Contract | Maintenance/warranty agreement | Links to Account, Asset |

### Integration Patterns

| System | Protocol | Direction | Key Data |
|---|---|---|---|
| ERP (SAP, Oracle, Infor) | MuleSoft / Batch | Bidirectional | Orders, inventory, shipments, invoices |
| PLM (PTC, Siemens) | API | Inbound | Product configurations, BOM |
| MES (Rockwell, Siemens) | API / OPC-UA | Inbound | Production data, quality metrics |
| Supply Chain (Blue Yonder, Kinaxis) | API | Bidirectional | Demand signals, supply commits |
| Field Service (Salesforce FSL) | Native | Bidirectional | Work orders, technician dispatch |

### Common Manufacturing Patterns

**Sales Agreement Forecasting Pattern**
- Problem: traditional opportunity-based forecasting doesn't work for long-running contracts with recurring orders
- Solution: Manufacturing Cloud Sales Agreements with account-based forecasting; actuals vs. committed volumes tracked over contract life
- KPI impact: improves forecast accuracy (target: ±5% at 90 days)

**Dealer/Distributor Visibility Pattern**
- Problem: manufacturers have no visibility into end-customer demand through the dealer channel
- Solution: Experience Cloud partner portal with demand signals flowing back; Data Cloud aggregates channel data
- KPI impact: improves demand sensing, reduces bullwhip effect

**Asset Lifecycle Management Pattern**
- Problem: no connected view from equipment sale through warranty through service contract through replacement
- Solution: Asset object tracks full lifecycle; Service Contracts auto-created from warranty; IoT signals trigger predictive maintenance
- KPI impact: increases service contract attach rate, reduces unplanned downtime

---

## Retail / Consumer Goods

### Sub-Vertical Distinctions

| Sub-Vertical | Core Process | Primary Buyer | Key Regulation |
|---|---|---|---|
| Brick-and-Mortar Retail | In-store experience + operations | VP of Stores, CTO | PCI-DSS, ADA, local labor laws |
| E-Commerce / D2C | Digital commerce + fulfillment | VP of Digital, CMO | PCI-DSS, CCPA/GDPR, FTC |
| Consumer Packaged Goods | Trade promotion + retail execution | VP of Sales, VP of Trade | FTC, FDA (food/cosmetics) |
| Grocery | Supply chain + fresh management | VP of Operations | FDA, FSMA, state weights & measures |
| Luxury | Clienteling + exclusivity | VP of Retail, Client Advisors | Anti-counterfeiting, import duties |

### Key Retail Metrics

| Metric | Definition | Benchmark | Salesforce Lever |
|---|---|---|---|
| Conversion Rate | Visitors who purchase / total visitors | 2–3% (e-commerce), 20–30% (in-store) | Personalization via Data Cloud + Marketing Cloud |
| Average Order Value | Revenue / number of orders | Varies by vertical | Recommendations, upsell via Commerce Cloud |
| Customer Acquisition Cost | Marketing spend / new customers | Varies; LTV:CAC ratio target ≥3:1 | Attribution via Data Cloud, Marketing Cloud optimization |
| Return Rate | Returns / total orders | 20–30% (e-commerce), 8–10% (in-store) | Accurate product info, sizing tools |
| Basket Size | Items per transaction | Varies | Cross-sell recommendations |
| NPS | Net Promoter Score | 30–50 (retail avg) | Service recovery, personalized experiences |

### Common Retail/CPG Patterns

**Unified Customer Profile Pattern**
- Problem: customer data fragmented across POS, e-commerce, loyalty, email, social
- Solution: Data Cloud unifies all customer touchpoints into a single profile; segments drive personalized marketing and service
- KPI impact: increases LTV, reduces acquisition cost through better targeting

**Retail Execution Pattern (CPG)**
- Problem: CPG field reps visit stores but don't have real-time data on compliance, inventory, or competitor activity
- Solution: Consumer Goods Cloud with visit planning, store audits (photo recognition), and real-time dashboards
- KPI impact: improves shelf compliance, increases share of shelf

**Omnichannel Order Management Pattern**
- Problem: customer expects buy-online-pickup-in-store, buy-in-store-ship-to-home, and seamless returns across channels
- Solution: Commerce Cloud + Order Management with unified inventory visibility
- KPI impact: increases conversion, reduces fulfillment cost

---

## Public Sector

### Sub-Vertical Distinctions

| Sub-Vertical | Core Process | Primary Buyer | Key Regulation |
|---|---|---|---|
| Federal (Civilian) | Citizen services + grants | CIO, Program Director | FedRAMP, FISMA, Section 508 |
| Federal (Defense) | Mission support + logistics | CIO, Program Manager | FedRAMP High, CMMC, ITAR |
| State Government | Benefits + licensing | CIO, Agency Director | State-specific, Section 508 |
| Local Government | Permits + inspections | City Manager, IT Director | Local codes, ADA |
| Tribal | Sovereignty-specific services | Tribal Council, IT Director | Tribal sovereignty + applicable federal |

### FedRAMP Considerations

FedRAMP authorization determines which Salesforce features are available:

| FedRAMP Level | Use Case | Salesforce Offering |
|---|---|---|
| Moderate | Most civilian federal agencies | Salesforce Government Cloud |
| High | DoD, intelligence, high-impact systems | Salesforce Government Cloud Plus |
| Not Required | State/local (usually) | Commercial Salesforce with security hardening |

Implications for solution design:
- Government Cloud has feature parity delays (new features arrive later)
- Some AppExchange packages are not FedRAMP authorized
- Data residency must be within authorized boundaries
- Integration with other government systems often requires PIV/CAC authentication

### Common Public Sector Patterns

**Citizen Service Request Pattern**
- Problem: citizens have no visibility into permit, license, or benefit application status
- Solution: Public Sector Solutions with Experience Cloud portal; automated status updates; digital document submission
- KPI impact: reduces call center volume, improves citizen satisfaction

**Grants Management Pattern**
- Problem: grant lifecycle (application → review → award → monitoring → closeout) managed in spreadsheets
- Solution: Public Sector Solutions or custom objects for grant lifecycle; automated compliance checks; outcome reporting
- KPI impact: reduces grant processing time, improves compliance audit scores

**Inter-Agency Data Sharing Pattern**
- Problem: agencies need to share citizen data for coordinated services but face privacy/security constraints
- Solution: MuleSoft integration layer with consent management; data sharing agreements codified in sharing rules
- KPI impact: improves service coordination, reduces duplicate data entry

---

## Energy / Utilities

### Common Patterns

**Meter-to-Cash Pattern**
- Problem: complex billing based on time-of-use rates, demand charges, and renewable credits
- Solution: integration between AMI (metering), billing system, and Salesforce for customer-facing rate analysis and billing inquiries
- KPI impact: reduces billing-related calls, improves first-call resolution

**Demand Response Pattern**
- Problem: utilities need customers to reduce usage during peak events
- Solution: Marketing Cloud + Data Cloud for targeted demand response notifications; tracking participation and incentive payouts
- KPI impact: reduces peak demand, improves program participation rates

**Renewable Energy Program Pattern**
- Problem: community solar, green tariff, and EV programs require complex enrollment and billing
- Solution: Experience Cloud enrollment portal + custom program management objects + billing system integration
- KPI impact: increases program enrollment, reduces manual processing

---

## Education

### Common Patterns

**Student Recruitment-to-Enrollment Pattern**
- Problem: prospective students interact across web, events, email, and campus visits with no unified view
- Solution: Education Cloud recruitment + admissions modules; Marketing Cloud journey for nurture; Experience Cloud applicant portal
- KPI impact: improves yield rate, reduces melt (students who commit but don't enroll)

**Student Success / Early Alert Pattern**
- Problem: at-risk students not identified until it's too late to intervene
- Solution: Education Cloud student success hub; early alert triggers based on grades, attendance, and engagement; advisor case management
- KPI impact: improves retention rate, reduces time-to-degree

**Advancement / Fundraising Pattern**
- Problem: alumni engagement and fundraising managed in disconnected systems
- Solution: Education Cloud advancement module; Data Cloud for unified alumni profile across giving, events, and engagement
- KPI impact: increases alumni giving rate, improves donor retention

---

## Nonprofit

### Common Patterns

**Fundraising Pipeline Pattern**
- Problem: major gift officers manage prospects in spreadsheets; no pipeline visibility
- Solution: Nonprofit Cloud fundraising module with gift pipeline, cultivation stages, and ask tracking
- KPI impact: increases major gift revenue, improves moves management efficiency

**Program Outcome Tracking Pattern**
- Problem: funders require outcome data but programs track outputs (activities) not outcomes (impact)
- Solution: custom program management objects linking activities → outputs → outcomes; Tableau dashboards for funder reporting
- KPI impact: improves funder retention, strengthens grant applications with outcome data

**Volunteer Management Pattern**
- Problem: volunteer coordination happens in email and spreadsheets; no matching of skills to needs
- Solution: Experience Cloud volunteer portal; custom objects for skills, availability, and assignments; automated matching
- KPI impact: increases volunteer engagement, reduces coordinator workload

---

## Cross-Industry Pattern Transfer

These patterns emerge across multiple verticals. When you see one, name the cross-industry connection explicitly:

| Pattern | Origin Industry | Transfer To | Adaptation Required |
|---|---|---|---|
| Care Coordination | Healthcare | Financial Services (client lifecycle), Nonprofit (case management) | Replace care plan with financial plan or service plan; adjust compliance requirements |
| Churn Prediction | Telecom | SaaS, Subscription Retail, Insurance (policy lapse) | Adjust features (usage patterns → engagement patterns); retrain models |
| Channel Visibility | Manufacturing (dealer) | Insurance (agent), Automotive (dealer) | Adjust partner portal for vertical-specific data |
| Outcome Tracking | Nonprofit | Healthcare (population health), Education (student success) | Adjust outcome definitions; different measurement frameworks |
| Digital Self-Service | Public Sector (citizen portal) | Utilities (customer portal), Insurance (policyholder portal) | Adjust authentication, forms, and status tracking |
| Compliance Workflow | Financial Services (KYC) | Healthcare (HIPAA), Government (clearance) | Different regulations but same pattern: verify → document → monitor |
| Lifecycle Management | Manufacturing (asset) | Healthcare (device), Energy (meter) | Adjust lifecycle stages; different maintenance triggers |
| Retail Execution | Consumer Goods (store visits) | Pharma (HCP visits), Insurance (agent audits) | Adjust visit templates and compliance checks |

When advising a customer in one vertical, actively look for proven patterns from other verticals that can accelerate the solution.
