# sf-field-inventory-parts

Field inventory and parts logistics strategy across depot, van stock, and consumption flows.

Use when users need to model required parts, reservations, transfers, replenishment, and consumption reconciliation.

TRIGGER when:
- User asks how to avoid truck rolls due to missing parts.
- User asks for van stock governance or replenishment thresholds.
- User asks about linking parts to work orders and appointments.

DO NOT TRIGGER when:
- Task is general SLA design (use `sf-field-sla-entitlements`).
- Task is appointment communications only (use `sf-field-customer-communications`).

Primary outcomes:
- Inventory operating model and ownership.
- Reservation and replenishment policy framework.
- Exception handling for shortages and substitutions.
