---
name: sf-service-case-management
description: Service Cloud case lifecycle design and optimization. Use when designing case record models, status flows, assignment ownership, escalation paths, closure criteria, or backlog triage in Service Cloud.
disable-model-invocation: true
---
# Service Cloud Case Management

## Use This Skill When

- Building or reviewing case lifecycle states and transitions.
- Designing assignment rules, queue ownership, and escalation logic.
- Defining service processes, record types, and case page layouts.
- Improving triage quality, first-contact resolution, and closure hygiene.

## Core Workflow

1. **Map intake channels**
   - Capture origin (`Email`, `Web`, `Chat`, `Phone`, `API`) and required fields.
2. **Define lifecycle**
   - Standardize statuses and allowed transitions.
   - Add explicit entry and exit criteria for each status.
3. **Design ownership model**
   - Queue-first or direct assignment by product, severity, segment, or language.
4. **Add escalation controls**
   - Time-based and condition-based escalations with clear target teams.
5. **Close with quality gates**
   - Require resolution code, root cause category, and customer communication confirmation.

## Deliverables

- Case lifecycle table (status, owner, SLA timer behavior).
- Assignment and escalation rule summary.
- Data quality checklist for intake and closure.
- Top 3 operational risks and mitigations.
