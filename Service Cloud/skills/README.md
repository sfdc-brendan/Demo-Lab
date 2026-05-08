# Service Cloud Development Skills for Agentic Coding Tools

A suite of 14 Agent Skills focused on Service Cloud implementation patterns, case operations, omni-channel routing, digital engagement, messaging APIs, voice transcript integration, AI-assisted intake, and support operations quality.

Compatible with Cursor and Claude Code skill folders.

---

## Quick Install

```bash
bash "Service Cloud/skills/install.sh"
```

The installer copies all `sf-service-*` skills into `~/.cursor/skills/`.

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
- `sf-service-voice-toolkit`: Real-time transcript integration patterns — Voice Toolkit API, ConversationEntry fallback, transcript contracts, debounce strategy.
- `sf-service-models-api`: Trust Layer GenAI integration via `aiplatform.ModelsAPI` — model selection, prompt contracts, structured output, operational controls.
- `sf-service-ai-intake`: Live-call AI form-fill experiences — configurable intake templates, non-destructive merge, agent override, dynamic SObject dispatch.
- `sf-service-review`: Review rubric for Service Cloud architecture, data, routing, and adoption risks.

---

## Suggested Usage

Ask naturally, for example:

- "Design an Omni-Channel routing model for tiered support."
- "Create SLA milestone patterns for premium and standard support plans."
- "Review this Service Cloud setup for operational risk."
- "Plan a case-to-field-service dispatch handoff model."
- "Design a Messaging API + Conversation Toolkit integration for agent handoff."
- "Design a real-time transcript contract for an LWC on the VoiceCall page."
- "Plan a Trust Layer GenAI prompt contract for case classification."
- "Design a configurable AI-assisted intake template for roadside assistance calls."

---

## Notes

- These skills are designed for design/review/planning and implementation guidance.
- Use your existing `sf-apex`, `sf-lwc`, `sf-flow`, and `sf-deploy` skills for code and deployment execution.
