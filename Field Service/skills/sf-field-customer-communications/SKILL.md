# sf-field-customer-communications

Customer communication model for pre-visit, en route, onsite, and post-visit interactions.

Use when users need notification strategy, channel mix, consent boundaries, and event-triggered outreach for appointments.

TRIGGER when:
- User asks for reminders, ETA notifications, or arrival updates.
- User asks for post-visit follow-up or closure messaging.
- User asks about communications tied to reschedule/cancel events.

DO NOT TRIGGER when:
- Task is dispatch optimization logic (use `sf-field-optimization-capacity`).
- Task is service report generation only (use `sf-field-service-reports`).

Primary outcomes:
- Event-to-message orchestration map.
- Channel policy by persona and urgency.
- Messaging governance and quality controls.
