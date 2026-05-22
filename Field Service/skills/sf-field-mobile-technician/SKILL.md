# sf-field-mobile-technician

Technician mobile workflow design including offline-safe execution and completion quality.

Use when users need mobile app interaction patterns for job execution, data capture, checklists, signatures, and failure handling.

TRIGGER when:
- User asks for technician step-by-step execution flow.
- User asks about offline behavior or sync conflict patterns.
- User asks about proof-of-service capture and job closure.

DO NOT TRIGGER when:
- Task is focused on customer messaging channels (use `sf-field-customer-communications`).
- Task is dispatch-side scheduling strategy (use `sf-field-scheduling-dispatch`).

Primary outcomes:
- Mobile journey blueprint from accept to complete.
- Offline/online behavior contract with recovery paths.
- Data quality and compliance controls at completion.
