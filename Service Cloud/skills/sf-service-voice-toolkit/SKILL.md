---
name: sf-service-voice-toolkit
description: Real-time voice transcript integration patterns for custom LWCs on the VoiceCall record page. Use when designing or building agent assist, coaching, sentiment, form-fill, or compliance components that consume the live transcript via Service Cloud Voice Toolkit API or ConversationEntry fallback.
disable-model-invocation: true
---
# Voice Toolkit and Live Transcript Integration

## Use This Skill When

- Designing custom LWC experiences that react to a live call transcript on the VoiceCall record page.
- Choosing between the Service Cloud Voice Toolkit API and ConversationEntry polling for transcript access.
- Building real-time agent assist, coaching, sentiment, compliance, or form-fill that depends on what is being said during the call.
- Standardizing how transcript fragments are sequenced, deduplicated, and surfaced to downstream consumers (UI, AI prompts, automation).

## Quick Start (Code Patterns)

These four patterns cover ~90% of voice transcript integrations. Copy, adapt, ship. For full event payload shapes and edge cases, see [reference.md](reference.md).

### 1. Subscribe to the Voice Toolkit (LWC)

Drop a `<lightning-service-cloud-voice-toolkit-api>` element in the template, then wire it in `renderedCallback` and tear down in `disconnectedCallback`. Use `renderedCallback` (not `connectedCallback`) — the toolkit element doesn't exist until first render.

```html
<template>
    <lightning-service-cloud-voice-toolkit-api></lightning-service-cloud-voice-toolkit-api>
    <!-- your UI -->
</template>
```

```javascript
_toolkitSubscribed = false;

renderedCallback() {
    if (this._toolkitSubscribed) return;
    const toolkit = this.template.querySelector('lightning-service-cloud-voice-toolkit-api');
    if (toolkit) {
        toolkit.addEventListener('transcript', this.handleTranscriptEvent);
        toolkit.addEventListener('callended', this.handleCallEnded);
        this._toolkitSubscribed = true;
    }
}

disconnectedCallback() {
    const toolkit = this.template.querySelector('lightning-service-cloud-voice-toolkit-api');
    if (toolkit) {
        toolkit.removeEventListener('transcript', this.handleTranscriptEvent);
        toolkit.removeEventListener('callended', this.handleCallEnded);
    }
    this._toolkitSubscribed = false;
}

handleTranscriptEvent = (event) => {
    const { content, sender } = event.detail;
    if (!content?.text) return;
    const role = sender?.role === 'Agent' || sender?.role === 'Supervisor' ? sender.role : 'Customer';
    this.utterances = [...this.utterances, {
        id: event.detail.id,
        text: content.text,
        role,
        timestamp: event.detail.clientSentTimestamp
    }];
    this.scheduleDownstreamWork();
};

handleCallEnded = () => {
    if (this._pollTimer) clearTimeout(this._pollTimer);
    // Fire any final downstream work here if needed.
};
```

### 2. Poll ConversationEntry as the fallback (Apex)

Use this when the toolkit is unavailable, the call already ended, or the consumer is not on the agent desktop. Always sort by `Seq`, always use a high-water mark to avoid replays.

```apex
@AuraEnabled
public static List<TranscriptEntry> getTranscriptEntries(Id voiceCallId, Integer lastSeenSeq) {
    if (voiceCallId == null) return new List<TranscriptEntry>();

    List<VoiceCall> calls = [
        SELECT ConversationId FROM VoiceCall WHERE Id = :voiceCallId LIMIT 1
    ];
    if (calls.isEmpty() || calls[0].ConversationId == null) {
        return new List<TranscriptEntry>();
    }

    Integer minSeq = lastSeenSeq != null ? lastSeenSeq : -1;

    List<ConversationEntry> entries = [
        SELECT Message, EntryType, ActorType, ActorName, EntryTime, Seq
        FROM ConversationEntry
        WHERE ConversationId = :calls[0].ConversationId
          AND Seq > :minSeq
          AND EntryType IN ('TranscriptionEnded', 'Voice', 'Message')
        ORDER BY Seq ASC
        LIMIT 200
    ];

    List<TranscriptEntry> result = new List<TranscriptEntry>();
    for (ConversationEntry ce : entries) {
        if (String.isNotBlank(ce.Message)) result.add(new TranscriptEntry(ce));
    }
    return result;
}
```

### 3. Poll loop with high-water mark (LWC)

Self-rescheduling poll, deduped by entry id, stops cleanly on call wrap or component unmount.

```javascript
_lastSeenSeq = -1;
_knownEntryIds = new Set();
_pollTimer;

startPolling() {
    if (!this.recordId || this.isFinished) return;
    this._pollTimer = setTimeout(async () => {
        if (this.isFinished) return;
        await this.fetchEntries();
        this.startPolling();
    }, 5000); // 5s cadence
}

async fetchEntries() {
    const entries = await getTranscriptEntries({
        voiceCallId: this.recordId,
        lastSeenSeq: this._lastSeenSeq
    });
    if (!entries?.length) return;
    const fresh = [];
    for (const e of entries) {
        const id = `native-${e.seq}`;
        if (!this._knownEntryIds.has(id)) {
            this._knownEntryIds.add(id);
            fresh.push({ id, text: e.message, role: e.isCustomer ? 'Customer' : 'Agent', timestamp: e.entryTime });
        }
        if (e.seq > this._lastSeenSeq) this._lastSeenSeq = e.seq;
    }
    if (fresh.length) {
        this.utterances = [...this.utterances, ...fresh];
        this.scheduleDownstreamWork();
    }
}
```

### 4. Debounce downstream work

Coalesce transcript events with a quiet-window debounce before triggering expensive consumers (AI calls, server actions). Tune the window: 3s is a good default for AI extraction; 500ms for UI-only updates.

```javascript
const DEBOUNCE_MS = 3000;
_workTimer;

scheduleDownstreamWork() {
    if (this._workTimer) clearTimeout(this._workTimer);
    this._workTimer = setTimeout(() => this.runDownstream(), DEBOUNCE_MS);
}
```

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

## Guardrails

- Treat transcript text as untrusted input — never echo into Apex, prompts, or rendered HTML without sanitization.
- Persist correlation IDs (`VoiceCallId`, `ConversationEntryId`) on every downstream artifact for audit and replay.
- Respect compliance scope: redact or block transcript routes when the call is on a recording-prohibited line.
- Fail closed: when the transcript source is unavailable, surface a clear empty state rather than stale or partial data.
- Always sort by `Seq`, never by arrival time. Networks reorder; sequence is authoritative.
- Stop polling on call wrap and on user navigation away from the record. Leaked timers cost real money and burn governor limits.

## Deliverables

- Transcript source decision (toolkit primary, ConversationEntry fallback, or both) with rationale.
- Transcript contract definition shared across consuming components.
- Debounce and polling cadence plan with maximum latency targets.
- Failure-mode matrix covering toolkit unavailable, partial transcripts, late-arriving finals, and call drop.

## Additional Resources

- Full event payload shapes, partner-vs-native differences, edge cases, and ConversationEntry field reference: [reference.md](reference.md)
- Companion skill for building the AI extractor that consumes the transcript: `sf-service-models-api`
- Companion skill for the composite intake pattern: `sf-service-ai-intake`
