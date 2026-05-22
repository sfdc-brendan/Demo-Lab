# sf-field-scheduling-dispatch

Dispatcher console operating model and scheduling-control design.

Use when users need patterns for appointment assignment, manual dispatch intervention, policy exceptions, and day-of-service adjustments.

TRIGGER when:
- User asks to design dispatcher workflows.
- User asks how to manage urgent jobs or conflict resolution.
- User asks about assignment rules and dispatch guardrails.

DO NOT TRIGGER when:
- Task is optimization algorithm/capacity strategy only (use `sf-field-optimization-capacity`).
- Task is technician mobile flow only (use `sf-field-mobile-technician`).

Primary outcomes:
- Dispatch decision framework (auto vs manual).
- Exception-routing playbook for urgent and failed appointments.
- Dispatcher KPI and operational governance model.
