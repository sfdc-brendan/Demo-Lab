---
name: sf-service-messaging-conversation-toolkit
description: Salesforce Messaging API and Conversation Toolkit API implementation guidance. Use when building custom messaging clients, orchestrating agent handoff, sending/receiving messages, or managing conversation sessions and participant context in Service Cloud.
disable-model-invocation: true
---
# Messaging API and Conversation Toolkit API

## Use This Skill When

- Building or reviewing custom messaging experiences on Salesforce.
- Integrating Messaging API flows for session setup, message exchange, and lifecycle handling.
- Designing Conversation Toolkit API usage for agent context, transcript continuity, and handoff logic.
- Hardening asynchronous messaging operations for retries, idempotency, and sequencing.

## Core Workflow

1. **Define interaction model**
   - Clarify actors, channels, and transitions between bot, queue, and live agent.
2. **Design Messaging API contract**
   - Map conversation start, send/receive events, delivery state, and closure semantics.
3. **Design Conversation Toolkit usage**
   - Standardize context payloads, participant updates, and conversation metadata access patterns.
4. **Enforce operational controls**
   - Add idempotency keys, replay handling, timeout rules, and dead-letter strategy.
5. **Instrument and audit**
   - Track latency, handoff success rate, dropped sessions, and unresolved conversations.

## Guardrails

- Keep channel event handling deterministic and sequence-aware.
- Normalize message payloads before enrichment or routing.
- Persist correlation IDs across messaging, case, and incident records.
- Define fallback behavior when conversation state cannot be resolved.

## Deliverables

- End-to-end sequence diagram for messaging and handoff.
- API contract checklist (request/response/event expectations).
- Failure mode matrix with recovery actions.
- KPI plan for reliability and customer experience outcomes.
