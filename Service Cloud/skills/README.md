# Service Cloud Development Skills for Agentic Coding Tools

A suite of 11 Agent Skills focused on Service Cloud implementation patterns, case operations, omni-channel routing, digital engagement, messaging APIs, and support operations quality.

Compatible with Cursor, Claude Code, Windsurf, and any AI coding agent with a skills directory.

---

## Quick Install

Copy and paste into your terminal:

```bash
curl -sSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/Service%20Cloud/skills/install.sh | bash
```

Or with `wget`:

```bash
wget -qO- https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/Service%20Cloud/skills/install.sh | bash
```

The unified installer auto-detects your IDE and installs all `sf-service-*` skills.

- Cursor: `~/.cursor/skills/`
- Claude Code: `~/.claude/skills/`
- Windsurf: `~/.windsurf/skills/`

Restart your IDE after installing.

---

## Skills Included

- `sf-service-case-management`: Case lifecycle design, status flow, ownership models, escalation controls.
- `sf-service-console-productivity`: Service Console page patterns, utility bar, macros, quick text, split view.
- `sf-service-omnichannel-routing`: Presence, routing configs, capacity models, queue and skill-based routing.
- `sf-service-knowledge`: Knowledge article model, channel strategy, search relevance, deflection flow.
- `sf-service-entitlements`: Entitlements, milestones, SLA design, violation handling, business hours strategy.
- `sf-service-voice-digital`: Voice/chat/messaging channel patterns and agent workflow harmonization.
- `sf-service-messaging-conversation-toolkit`: Messaging API and Conversation Toolkit API design, implementation, and guardrails.
- `sf-service-field-service-handoff`: Service Cloud to Field Service handoff patterns and feedback loops.
- `sf-service-email-to-case`: Email-to-Case threading, auto-response, assignment, and triage hardening.
- `sf-service-incident-management`: Major incident intake, comms rhythm, swarm operations, closure workflow.
- `sf-service-review`: Review rubric for Service Cloud architecture, data, routing, and adoption risks.

---

## Suggested Usage

Ask naturally, for example:

- "Design an Omni-Channel routing model for tiered support."
- "Create SLA milestone patterns for premium and standard support plans."
- "Review this Service Cloud setup for operational risk."
- "Plan a case-to-field-service dispatch handoff model."
- "Design a Messaging API + Conversation Toolkit integration for agent handoff."

---

## Notes

- These skills are designed for design/review/planning and implementation guidance.
- Use your existing `sf-apex`, `sf-lwc`, `sf-flow`, and `sf-deploy` skills for code and deployment execution.
