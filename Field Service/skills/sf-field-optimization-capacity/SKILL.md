# sf-field-optimization-capacity

Capacity, travel, and optimization strategy for scalable field operations.

Use when users need to tune assignment quality, reduce travel time, improve utilization, or define optimization policy.

TRIGGER when:
- User asks to improve schedule efficiency or SLA hit rate.
- User asks about capacity planning by territory/time window.
- User asks for travel-time and workload balancing strategy.

DO NOT TRIGGER when:
- Task is inventory logistics only (use `sf-field-inventory-parts`).
- Task is dispatcher UX process only (use `sf-field-scheduling-dispatch`).

Primary outcomes:
- Capacity model and utilization assumptions.
- Optimization policy matrix and tradeoff rationale.
- Measurement plan for outcomes and drift.
