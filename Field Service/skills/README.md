# Field Service Development Skills for Agentic Coding Tools

A suite of Agent Skills focused on Salesforce Field Service implementation patterns, scheduling and dispatch operations, mobile technician workflows, optimization, inventory, work orders, service appointments, and operational quality.

Compatible with Cursor, Claude Code, Windsurf, and any AI coding agent with a skills directory.

---

## Quick Install

Copy and paste into your terminal:

`curl -sSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/Field%20Service/skills/install.sh | bash`

Or with `wget`:

`wget -qO- https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/Field%20Service/skills/install.sh | bash`

The unified installer auto-detects your IDE and installs all `sf-field-*` skills.

- Cursor: `~/.cursor/skills/`
- Claude Code: `~/.claude/skills/`
- Windsurf: `~/.windsurf/skills/`

Restart your IDE after installing.

---

## Skills Included

- `sf-field-core-setup`: Field Service data model and baseline setup (service territories, operating hours, resources, work types).
- `sf-field-work-order-lifecycle`: Work order, line item, and service appointment lifecycle design.
- `sf-field-scheduling-dispatch`: Dispatcher console patterns, manual scheduling controls, and conflict handling.
- `sf-field-optimization-capacity`: Capacity, travel, and optimization strategy for assignment quality.
- `sf-field-mobile-technician`: Mobile app technician workflows, offline posture, and completion patterns.
- `sf-field-inventory-parts`: Product required, parts logistics, van stock, and replenishment strategy.
- `sf-field-sla-entitlements`: SLA and milestone patterns for onsite service commitments.
- `sf-field-customer-communications`: Appointment notifications, reminders, ETA updates, and post-visit messaging.
- `sf-field-service-reports`: Service report generation, signature capture, and closure controls.
- `sf-field-review`: Review rubric for Field Service architecture, dispatch operations, and adoption risks.

---

## Suggested Usage

Ask naturally, for example:

- "Design a scheduling and dispatch model for multi-region field teams."
- "Create a work order and service appointment lifecycle for break/fix operations."
- "Plan a mobile technician flow with offline-safe completion and signature capture."
- "Design parts logistics for van stock, transfers, and replenishment."
- "Review this Field Service setup for operational and scalability risk."

---

## Notes

- Most skills are planning altitude (frameworks, no code) and pair well with `sf-apex`, `sf-lwc`, `sf-flow`, and `sf-deploy` for implementation.
- Use `sf-field-review` as a quality gate before deployment to production.
