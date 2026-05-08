---
name: sf-service-field-service-handoff
description: Service Cloud to Field Service handoff patterns. Use when orchestrating escalation from contact center resolution attempts into onsite dispatch, work orders, and technician feedback loops.
disable-model-invocation: true
---
# Field Service Handoff

## Use This Skill When

- Defining when cases should convert to field work.
- Designing work order creation and dispatch criteria.
- Improving loop closure between technicians and case teams.

## Handoff Model

- Trigger conditions: failed remote fix, hardware dependency, safety constraints.
- Required data package: asset, location, entitlement state, fault details, customer availability.
- Ownership transition: case agent to dispatch/field ops with clear acknowledgement.
- Return loop: technician notes, parts used, resolution proof, follow-up actions.

## Deliverables

- Case-to-work-order decision tree.
- Required field payload checklist for dispatch quality.
- Cross-team SLA and communication protocol.
