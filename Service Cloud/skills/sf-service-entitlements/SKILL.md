---
name: sf-service-entitlements
description: Entitlements and milestone design for Service Cloud SLA management. Use when configuring entitlement processes, milestone timers, violation handling, and business-hours-aware support commitments.
disable-model-invocation: true
---
# Service Entitlements and SLAs

## Use This Skill When

- Designing SLA tiers and response/resolution commitments.
- Configuring entitlements, milestones, and business hours.
- Auditing milestone breaches and escalation effectiveness.

## Design Sequence

1. Define support plans and contract-linked entitlement scope.
2. Map milestones for first response, update cadence, and resolution.
3. Configure timer behavior for pauses, status transitions, and waiting states.
4. Create warning/violation actions (alerts, escalations, swarm triggers).
5. Align reporting to customer-facing SLA definitions.

## Common Failure Modes

- Ambiguous pause conditions that hide true breach risk.
- Milestones not aligned with channel-specific expectations.
- Missing ownership for violation response.

## Deliverables

- Entitlement and milestone matrix.
- Timer control policy (start, pause, resume, complete).
- SLA risk dashboard spec.
