---
name: sf-service-voice-toolkit
description: Real-time voice transcript integration patterns for custom LWCs on the VoiceCall record page. Use when designing agent assist, coaching, sentiment, form-fill, or compliance components that consume the live transcript via Service Cloud Voice Toolkit API or ConversationEntry fallback.
disable-model-invocation: true
---
# Voice Toolkit and Live Transcript Integration

## Use This Skill When

- Designing custom LWC experiences that react to a live call transcript on the VoiceCall record page.
- Choosing between the Service Cloud Voice Toolkit API and ConversationEntry polling for transcript access.
- Planning real-time agent assist, coaching, sentiment, compliance, or form-fill that depends on what is being said during the call.
- Standardizing how transcript fragments are sequenced, deduplicated, and surfaced to downstream consumers (UI, AI prompts, automation).

## Toolkit Selection Framework

1. **Profile the contact center**
 - Confirm whether the org runs Native Voice (Service Cloud Voice with Amazon Connect or partner-managed) or Partner Telephony (BYOT).
 - Confirm whether real-time transcription is enabled on the VoiceCall channel.
2. **Pick the primary transcript source**
 - Prefer the `lightning-service-cloud-voice-toolkit-api` event stream when the LWC sits on a live VoiceCall record.
 - Fall back to polling `ConversationEntry` when the toolkit is not available, when the call has already ended, or when the consumer is not on the agent desktop.
3. **Decide who emits and who consumes**
 - Identify which utterances matter: customer only, agent only, or both. Filter at the source, not in the consumer.
 - Define how transcript events fan out (single LWC, LMS broadcast to multiple components, persisted for later analysis).

## Core Workflow

1. **Define the transcript contract**
 - Standardize the shape every consumer receives: speaker role, text, sequence number, timestamp, and finality (interim vs final).
 - Keep ordering authoritative: always sort by sequence, never by arrival time.
2. **Subscribe and normalize**
 - Subscribe to toolkit transcript events on connect; tear down on call end and on component disconnect.
 - Normalize partner payload variants into the shared transcript contract before downstream use.
3. **Add a polling fallback**
 - Define poll cadence, page size, and high-water mark per VoiceCall to avoid duplicate or missed entries.
 - Stop polling on call wrap and on user navigation away from the record.
4. **Debounce downstream work**
 - Coalesce transcript updates with a quiet-window debounce before triggering expensive consumers (AI calls, server actions).
 - Cap maximum debounce delay so consumers still react during long monologues.

## Guardrails

- Treat transcript text as untrusted input — never echo into Apex, prompts, or rendered HTML without sanitization.
- Persist correlation IDs (`VoiceCallId`, `ConversationEntryId`) on every downstream artifact for audit and replay.
- Respect compliance scope: redact or block transcript routes when the call is on a recording-prohibited line.
- Fail closed: when the transcript source is unavailable, surface a clear empty state rather than stale or partial data.

## Deliverables

- Transcript source decision (toolkit primary, ConversationEntry fallback, or both) with rationale.
- Transcript contract definition shared across consuming components.
- Debounce and polling cadence plan with maximum latency targets.
- Failure-mode matrix covering toolkit unavailable, partial transcripts, late-arriving finals, and call drop.
