# sf-field-work-order-lifecycle

Design and governance for Work Order, Work Order Line Item, and Service Appointment lifecycle.

Use when users need lifecycle states, transitions, ownership patterns, or close-out controls for field execution.

TRIGGER when:
- User asks for work order status model or handoff flow.
- User asks how line items and appointments should progress.
- User needs cancellation, reschedule, or completion controls.

DO NOT TRIGGER when:
- Focus is dispatch console operations only (use `sf-field-scheduling-dispatch`).
- Focus is SLA milestone policy only (use `sf-field-sla-entitlements`).

Primary outcomes:
- Status-transition matrix with guardrails.
- Ownership model across dispatch, technician, and back office.
- Closure quality checklist and auditability controls.
