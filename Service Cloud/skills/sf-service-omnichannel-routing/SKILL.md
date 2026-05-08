---
name: sf-service-omnichannel-routing
description: Omni-Channel routing strategy for Service Cloud. Use when configuring queues, routing rules, skills-based routing, presence statuses, and capacity planning across support channels.
disable-model-invocation: true
---
# Omni-Channel Routing

## Use This Skill When

- Designing queue strategy and routing priorities.
- Tuning capacity models for chat, voice, messaging, and cases.
- Implementing skill-based routing for specialized support teams.

## Routing Design Steps

1. Define work item taxonomy by channel and complexity.
2. Set routing priority and interruption policy by work type.
3. Configure presence statuses that match real staffing states.
4. Model agent capacity units and concurrency limits.
5. Add overflow and fallback routing for peak conditions.

## Validation Questions

- Does the model prevent VIP/SLA breaches during peak traffic?
- Are specialists protected from low-value work starvation?
- Is there a clear fallback path if required skills are unavailable?

## Deliverables

- Queue and skills matrix.
- Presence and capacity model.
- Routing rule summary with fallback paths.
- Monitoring dashboard spec for routing health.
