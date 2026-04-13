# Value Engineer — Deliverables Guide

Detailed templates for every Value Engineer deliverable type. Loaded on-demand when the agent generates a specific deliverable.

---

## 1. ROI Model

### Structure

```
# ROI Model: [Customer Name] — [Solution Scope]

## Executive Summary
- Total 3-year benefit: $X.XM
- Total investment: $X.XM
- Net present value (NPV): $X.XM
- Payback period: X months
- Risk-adjusted ROI: X%

## Investment Summary

### Year 1
| Category | Amount | Notes |
|---|---|---|
| Licensing (annual) | $XXX,XXX | [editions, user counts, add-ons] |
| Implementation services | $XXX,XXX | [partner, phases, duration] |
| Data migration | $XX,XXX | [scope, complexity] |
| Integration development | $XX,XXX | [systems, middleware] |
| Training & change management | $XX,XXX | [user count, delivery method] |
| Internal labor (backfill/oversight) | $XX,XXX | [FTE allocation] |
| **Year 1 Total** | **$X.XM** | |

### Years 2–3
| Category | Year 2 | Year 3 |
|---|---|---|
| Licensing | $XXX,XXX | $XXX,XXX |
| Ongoing administration (X FTE) | $XX,XXX | $XX,XXX |
| Enhancement budget | $XX,XXX | $XX,XXX |
| Training (new hires) | $XX,XXX | $XX,XXX |
| **Annual Total** | **$XXX,XXX** | **$XXX,XXX** |

### 3-Year Total Investment: $X.XM

## Benefits by Category

### Category 1: [e.g., Cost Reduction — Service Operations]
| Metric | Baseline | Target | Improvement | Annual Value |
|---|---|---|---|---|
| Avg handle time | X min | Y min | Z% reduction | $XXX,XXX |
| [next metric] | | | | |
| **Category subtotal** | | | | **$XXX,XXX** |

**Methodology**: [How each number was calculated. Source of improvement assumption.]

### Category 2: [e.g., Revenue Uplift — Sales Productivity]
[Same table structure]

### Category 3: [e.g., Risk Mitigation — Compliance]
[Same table structure]

## 3-Year Cash Flow

| Quarter/Year | Investment | Benefits | Net Cash Flow | Cumulative |
|---|---|---|---|---|
| Q1 Y1 | ($XXX,XXX) | $0 | ($XXX,XXX) | ($XXX,XXX) |
| Q2 Y1 | ($XX,XXX) | $XX,XXX | ($XX,XXX) | ($XXX,XXX) |
| Q3 Y1 | $0 | $XX,XXX | $XX,XXX | ($XX,XXX) |
| Q4 Y1 | $0 | $XX,XXX | $XX,XXX | $XX,XXX |
| Year 2 | ($XXX,XXX) | $XXX,XXX | $XXX,XXX | $XXX,XXX |
| Year 3 | ($XXX,XXX) | $XXX,XXX | $XXX,XXX | $X.XM |

**Payback period**: Quarter X, Year Y

## NPV Calculation
- Discount rate: X% (customer WACC / default 10%)
- 3-year NPV: $X.XM

## Sensitivity Analysis

| Assumption | Base Case | -20% | +20% | NPV Impact |
|---|---|---|---|---|
| [Top assumption 1] | X% | Y% | Z% | ±$XXX,XXX |
| [Top assumption 2] | | | | |
| [Top assumption 3] | | | | |

**Break-even**: [Top assumption] can decline to X% before NPV reaches zero.

## Scenarios
| Scenario | 3-Year Benefit | NPV | ROI | Payback |
|---|---|---|---|---|
| Conservative | $X.XM | $X.XM | X% | X mo |
| Expected | $X.XM | $X.XM | X% | X mo |
| Optimistic | $X.XM | $X.XM | X% | X mo |

## Methodology Appendix
[Source for each benchmark, formula for each calculation, risk adjustment rationale]
```

---

## 2. TCO Comparison

### Structure

```
# TCO Comparison: [Customer Name]
# [Salesforce Solution] vs. [Incumbent/Competitor] vs. [Status Quo]

## Executive Summary
- 3-year TCO — Salesforce: $X.XM
- 3-year TCO — [Incumbent]: $X.XM
- 3-year TCO — Status quo: $X.XM
- Salesforce advantage: $X.XM savings over [comparison] (X%)

## Comparison Matrix

### Licensing & Subscription
| Cost Element | Salesforce | [Incumbent] | Status Quo |
|---|---|---|---|
| Core platform licenses | $XXX,XXX/yr | $XXX,XXX/yr | $XXX,XXX/yr |
| Add-on modules | $XX,XXX/yr | $XX,XXX/yr | N/A |
| API / integration fees | Included | $XX,XXX/yr | $XX,XXX/yr |
| Storage / compute | $XX,XXX/yr | $XX,XXX/yr | $XX,XXX/yr |
| **Annual licensing** | **$XXX,XXX** | **$XXX,XXX** | **$XXX,XXX** |

### Implementation
| Cost Element | Salesforce | [Incumbent] | Status Quo |
|---|---|---|---|
| Professional services | $XXX,XXX | $XXX,XXX | N/A |
| Data migration | $XX,XXX | $XX,XXX | N/A |
| Integration build | $XX,XXX | $XX,XXX | $XX,XXX |
| Training | $XX,XXX | $XX,XXX | N/A |
| **Implementation total** | **$XXX,XXX** | **$XXX,XXX** | **$XX,XXX** |

### Ongoing Operations
| Cost Element | Salesforce | [Incumbent] | Status Quo |
|---|---|---|---|
| Admin FTEs | X ($XXX,XXX) | X ($XXX,XXX) | X ($XXX,XXX) |
| Developer FTEs | X ($XXX,XXX) | X ($XXX,XXX) | X ($XXX,XXX) |
| Vendor support fees | $XX,XXX/yr | $XX,XXX/yr | $XX,XXX/yr |
| Upgrade/patch effort | Included | $XX,XXX/yr | $XX,XXX/yr |
| **Annual operations** | **$XXX,XXX** | **$XXX,XXX** | **$XXX,XXX** |

### Hidden Costs
| Cost Element | Salesforce | [Incumbent] | Status Quo |
|---|---|---|---|
| Technical debt accumulation | Low | Medium | High |
| Opportunity cost of delayed innovation | $XX,XXX/yr | $XX,XXX/yr | $XXX,XXX/yr |
| Talent acquisition premium (legacy skills) | N/A | $XX,XXX/yr | $XX,XXX/yr |
| End-of-life / forced migration risk | N/A | $XX,XXX | $XXX,XXX |

## 3-Year TCO Summary

| Year | Salesforce | [Incumbent] | Status Quo |
|---|---|---|---|
| Year 1 | $XXX,XXX | $XXX,XXX | $XXX,XXX |
| Year 2 | $XXX,XXX | $XXX,XXX | $XXX,XXX |
| Year 3 | $XXX,XXX | $XXX,XXX | $XXX,XXX |
| **3-Year Total** | **$X.XM** | **$X.XM** | **$X.XM** |

## Cost Per Unit Analysis
| Metric | Salesforce | [Incumbent] | Status Quo |
|---|---|---|---|
| Cost per user/month | $XXX | $XXX | $XXX |
| Cost per transaction | $X.XX | $X.XX | $X.XX |
| Cost per customer served | $X.XX | $X.XX | $X.XX |

## Platform Consolidation Opportunity
[List systems that Salesforce replaces or consolidates, with their current costs]

## Methodology Notes
[Assumptions for FTE costs, licensing terms, growth rates, hidden cost calculations]
```

---

## 3. Business Case Document

### Structure

```
# Business Case: [Solution Name]
# Prepared for: [Customer Name]

## Executive Summary (1 page max)
**Problem**: [One sentence — the quantified business pain]
**Solution**: [One sentence — what Salesforce delivers]
**Impact**: [3-year NPV of $X.XM, payback in X months, X% risk-adjusted ROI]
**Recommendation**: [Approve / proceed to next phase / request additional data]

## Current State Assessment

### Quantified Pain Points
| Pain Point | Metric | Current Value | Annual Cost |
|---|---|---|---|
| [e.g., Manual case routing] | Hours/week | XX hrs | $XXX,XXX |
| [e.g., Customer churn] | Annual rate | X.X% | $X.XM |
| [e.g., Missed upsell] | Revenue/quarter | $XXX,XXX | $X.XM |

### Root Causes
[Why these problems exist — process, technology, organizational factors]

### Cost of Current State
- Direct costs: $X.XM/yr
- Indirect costs (productivity, opportunity): $X.XM/yr
- Risk exposure: $X.XM potential impact

## Proposed Solution

### Solution Overview
[What Salesforce capabilities address each pain point]

### Implementation Approach
| Phase | Duration | Scope | Investment |
|---|---|---|---|
| Phase 1 — Foundation | X months | [scope] | $XXX,XXX |
| Phase 2 — Optimization | X months | [scope] | $XXX,XXX |
| Phase 3 — Innovation | X months | [scope] | $XXX,XXX |

### Total Investment
[Summarized from ROI model — licensing + implementation + operations]

## Benefit Categories

### Hard Savings (high confidence — 80–95% probability)
| Benefit | Annual Value | Methodology |
|---|---|---|
| [e.g., Reduced agent headcount need] | $XXX,XXX | [calculation] |
| [e.g., License consolidation] | $XXX,XXX | [calculation] |

### Productivity Gains (medium-high confidence — 70–85%)
| Benefit | Annual Value | Methodology |
|---|---|---|
| [e.g., Rep time savings] | $XXX,XXX | [calculation] |

### Revenue Uplift (medium confidence — 50–70%)
| Benefit | Annual Value | Methodology |
|---|---|---|
| [e.g., Improved win rate] | $XXX,XXX | [calculation] |

### Risk Mitigation (variable confidence)
| Benefit | Potential Avoidance | Probability | Expected Value |
|---|---|---|---|
| [e.g., Compliance penalty] | $X.XM | X% | $XXX,XXX |

## Financial Summary
| Metric | Conservative | Expected | Optimistic |
|---|---|---|---|
| 3-Year NPV | $X.XM | $X.XM | $X.XM |
| Risk-Adjusted ROI | X% | X% | X% |
| Payback Period | X months | X months | X months |
| IRR | X% | X% | X% |

## Risk Assessment
| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| Adoption below target | Medium | $XXX,XXX NPV impact | Change management plan, executive sponsorship |
| Integration complexity | Low | $XX,XXX cost overrun | Phased approach, middleware layer |
| [additional risks] | | | |

## Implementation Timeline
[Gantt-style milestones with value realization markers]

## Recommendation
[Clear recommendation with decision criteria and next steps]

## Appendix: Methodology
[Complete calculation details, benchmark sources, assumption log]
```

---

## 4. Value Realization Dashboard Spec

### Structure

```
# Value Realization Dashboard Spec
# [Customer Name] — [Solution Name]

## Purpose
Track actual business value delivered against the approved business case
projections. Two views: Executive (strategic KPIs) and Operational (detailed
metrics with drill-down).

## KPI Definitions

### Executive View (5–7 headline KPIs)

| KPI | Business Case Target | Baseline | 6-Mo Target | 12-Mo Target | 24-Mo Target |
|---|---|---|---|---|---|
| [e.g., Cost per case] | -30% | $XX.XX | $XX.XX | $XX.XX | $XX.XX |
| [e.g., Agent productivity] | +25% | XX cases/day | XX | XX | XX |
| [e.g., Customer satisfaction] | +15 pts | XX NPS | XX | XX | XX |
| [e.g., Case deflection rate] | +20% | XX% | XX% | XX% | XX% |
| [e.g., Revenue per rep] | +18% | $XXX,XXX | $XXX,XXX | $XXX,XXX | $XXX,XXX |

### Operational View (detailed metrics per KPI)

#### [KPI 1: Cost per Case]
| Sub-metric | Data Source | Calculation | Refresh |
|---|---|---|---|
| Total case volume | Service Cloud — Case object | COUNT(Cases) by period | Daily |
| Agent labor cost | HR system / Named Credential | Total agent salary ÷ cases handled | Monthly |
| Technology cost per case | Finance system | Platform cost ÷ case volume | Monthly |
| Average handle time | Service Cloud — CaseHistory | AVG(ClosedDate - CreatedDate) | Daily |

[Repeat for each KPI]

## Data Sources

| Source | Connection Method | Owner | Refresh Cadence |
|---|---|---|---|
| Service Cloud | Native (SOQL) | SF Admin | Real-time / Daily |
| HR / Payroll | Named Credential / API | HR Ops | Monthly |
| Finance / ERP | MuleSoft integration | Finance | Monthly |
| Customer survey | Data Cloud ingestion | CX Team | Weekly |

## Value Scorecard

| Benefit Category | Business Case Projection (Annual) | Actual (YTD) | Variance | Status |
|---|---|---|---|---|
| Cost reduction | $XXX,XXX | $XXX,XXX | +/- $XX,XXX | 🟢/🟡/🔴 |
| Productivity gain | $XXX,XXX | $XXX,XXX | | |
| Revenue uplift | $XXX,XXX | $XXX,XXX | | |
| **Total** | **$X.XM** | **$X.XM** | | |

## Dashboard Layout Recommendations
- Executive view: single page, 5–7 KPI cards with sparkline trends, traffic-light status
- Operational view: tabbed by benefit category, with drill-down to sub-metrics
- Value scorecard: business case vs. actual comparison with variance analysis
- Time filters: MTD, QTD, YTD, since go-live

## Alerting Rules
| Condition | Alert | Recipient |
|---|---|---|
| KPI trending >10% below target for 2 consecutive months | Email + Slack | Project sponsor, SF Admin |
| Value scorecard variance >15% negative | Executive escalation | VP sponsor |
| Data source refresh failure | Admin alert | SF Admin |
```

---

## 5. Benchmark Comparison

### Structure

```
# Benchmark Comparison: [Customer Name]
# Industry: [Industry Vertical]

## Executive Summary
[Customer] currently performs [above/at/below] industry median across
[X of Y] key metrics. The largest improvement opportunities represent
$X.XM in annual value.

## Benchmark Sources
| Source | Scope | Year | Confidence |
|---|---|---|---|
| [e.g., Gartner CX Benchmark] | [industry, sample size] | 20XX | High |
| [e.g., Salesforce State of Service] | [global, N respondents] | 20XX | Medium |
| [e.g., Industry association report] | [vertical, N companies] | 20XX | High |

## Performance Comparison

### [Category 1: Customer Service]
| KPI | Industry Bottom Quartile | Industry Median | Industry Top Quartile | [Customer] Current | Gap to Median |
|---|---|---|---|---|---|
| First contact resolution | XX% | XX% | XX% | XX% | X pp |
| Average handle time | XX min | XX min | XX min | XX min | X min |
| Customer satisfaction (CSAT) | XX% | XX% | XX% | XX% | X pp |
| Agent utilization | XX% | XX% | XX% | XX% | X pp |

### [Category 2: Sales Performance]
[Same table structure]

### [Category 3: Marketing Efficiency]
[Same table structure]

## Gap Analysis & Financial Impact

| KPI | Current Gap (vs. Median) | Financial Impact of Gap | Salesforce Capability | Expected Improvement |
|---|---|---|---|---|
| First contact resolution | -X pp | $XXX,XXX/yr (repeat contacts) | Service Cloud + Knowledge | +X–X pp |
| Average handle time | +X min | $XXX,XXX/yr (labor) | Agentforce + case automation | -X–X min |
| [continued] | | | | |

## Maturity Model

| Level | Description | [Customer] Status |
|---|---|---|
| **1 — Reactive** | Manual processes, no analytics, siloed data | |
| **2 — Managed** | Basic automation, departmental reporting | ← Current |
| **3 — Optimized** | Cross-functional workflows, predictive analytics | ← 12-month target |
| **4 — Adaptive** | AI-driven, real-time personalization, proactive engagement | ← 24-month target |
| **5 — Leading** | Industry-defining CX, continuous innovation | |

## Prioritized Improvement Roadmap
| Priority | KPI | Financial Impact | Effort | Salesforce Solution |
|---|---|---|---|---|
| 1 | [highest-value gap] | $XXX,XXX/yr | [T-shirt size] | [capability] |
| 2 | | | | |
| 3 | | | | |

## Methodology Notes
[How benchmarks were selected, normalization approach, confidence levels]
```

---

## 6. Cost of Inaction Analysis

### Structure

```
# Cost of Inaction: [Customer Name]
# What Happens If Nothing Changes

## Executive Summary
Maintaining the current trajectory will cost [Customer] an estimated
$X.XM over the next 36 months in compounding operational costs,
competitive erosion, and deferred opportunity. This represents X% of
the proposed Salesforce investment's 3-year benefit.

## Current Trajectory (Status Quo Forward)

### Year 1 — Manageable but Mounting
| Cost Category | Annual Impact | Basis |
|---|---|---|
| Labor cost inflation (X% annual) | +$XX,XXX | Current headcount × inflation rate |
| Legacy system maintenance | +$XX,XXX | Vendor support increases, EOL risk |
| Manual process inefficiency | $XXX,XXX | Current waste, no improvement |
| Customer churn (current rate) | $XXX,XXX | Churn × LTV |
| **Year 1 inaction cost** | **$XXX,XXX** | |

### Year 2 — Accelerating
| Cost Category | Annual Impact | Basis |
|---|---|---|
| Compounding labor costs | +$XX,XXX | Cumulative inflation + new hires for growth |
| Technical debt servicing | +$XX,XXX | More patches, workarounds, fragility |
| Competitive win-rate erosion | -$XXX,XXX | Competitors investing in CX/AI |
| Customer expectations gap | +$XX,XXX | Rising expectations, stagnant capability |
| **Year 2 inaction cost** | **$XXX,XXX** | |

### Year 3 — Critical
| Cost Category | Annual Impact | Basis |
|---|---|---|
| Forced migration / EOL event | $XXX,XXX | Legacy platform end-of-support |
| Talent attrition risk | $XX,XXX | Difficulty retaining talent on old systems |
| Regulatory compliance gap | $XX,XXX | New requirements legacy can't meet |
| Market share erosion | $XXX,XXX | Cumulative competitive impact |
| **Year 3 inaction cost** | **$XXX,XXX** | |

## Cumulative Cost of Inaction

| Time Horizon | Cumulative Cost | Comparison to Salesforce Investment |
|---|---|---|
| 12 months | $XXX,XXX | X% of proposed investment |
| 24 months | $X.XM | X% of proposed investment |
| 36 months | $X.XM | X× the proposed investment |

## Competitive Risk Assessment

| Competitor Move | Probability | Impact on [Customer] | Timeline |
|---|---|---|---|
| [Competitor A] deploys AI-powered service | High | Loss of X% service differentiation | 6–12 months |
| [Competitor B] launches personalized digital experience | Medium | X% customer attrition risk | 12–18 months |
| Industry-wide CX standard rises | Certain | Below-average perception | Ongoing |

## Opportunity Cost

| Deferred Capability | Annual Revenue / Savings Impact | Cumulative (36 mo) |
|---|---|---|
| AI-powered case deflection | $XXX,XXX | $XXX,XXX |
| Predictive sales forecasting | $XXX,XXX | $XXX,XXX |
| Unified customer data | $XXX,XXX | $X.XM |
| **Total opportunity cost** | **$XXX,XXX/yr** | **$X.XM** |

## The "Doing Nothing Tax"
[Visualization description: cumulative cost curve showing how inaction
compounds over 36 months, plotted against the Salesforce investment +
return curve. The crossover point where inaction becomes more expensive
than acting is highlighted.]

## Recommendation
The cost of waiting X months to decide is approximately $XXX,XXX in
compounding costs and deferred value. Each quarter of delay increases
total 3-year cost of inaction by approximately $XX,XXX.

## Methodology Notes
[Inflation rates, churn assumptions, competitive intelligence sources,
opportunity cost calculation approach]
```
