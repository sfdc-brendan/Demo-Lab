# sf-service-voice-toolkit — Reference

Deep reference material loaded only when the agent needs specific API shapes, edge case handling, or migration notes. The primary patterns live in `SKILL.md`.

---

## Voice Toolkit API Event Reference

### Element

```html
<lightning-service-cloud-voice-toolkit-api></lightning-service-cloud-voice-toolkit-api>
```

Place once per LWC. The element only exists after first render — wire listeners in `renderedCallback`, not `connectedCallback`.

### Events

| Event | Fires when | `event.detail` shape |
|---|---|---|
| `transcript` | A new transcript fragment arrives (interim or final) | `{ id, conversationId, content: { text, isFinal }, sender: { role, callParticipantId }, clientSentTimestamp }` |
| `callstarted` | Call leg connects | `{ conversationId, callId, fromNumber, toNumber }` |
| `callended` | Call wraps | `{ conversationId, callId, endReason }` |
| `participantadded` | Conference / transfer adds a leg | `{ participant: { role, callParticipantId, displayName } }` |
| `participantremoved` | Leg drops | `{ participantId }` |
| `mute` / `unmute` | Agent mic state changes | `{ muted: boolean }` |

### `sender.role` values

- `Customer` — external party
- `Agent` — primary CSR
- `Supervisor` — barge-in or whisper coach
- `IVR` / `Bot` — pre-routing system
- `Unknown` — partner telephony with unmapped role; treat as `Customer` defensively

### Interim vs final fragments

- `content.isFinal === false` → interim partial (ASR still updating). Show in UI for responsiveness; do not feed to AI extractors.
- `content.isFinal === true` → settled final. Safe to send to downstream consumers.

If you see flicker in UI, you are rendering interim fragments without distinguishing them from finals.

---

## ConversationEntry Reference

### Key fields

| Field | Type | Purpose |
|---|---|---|
| `ConversationId` | Reference | Joins to `VoiceCall.ConversationId` |
| `Seq` | Number | Monotonic sequence — authoritative ordering |
| `Message` | LongText | The utterance text |
| `EntryType` | Picklist | `Voice`, `Message`, `TranscriptionEnded`, `ParticipantChanged`, `RoutingResult` |
| `ActorType` | Picklist | `EndUser`, `Agent`, `Bot`, `System`, `Supervisor` |
| `ActorName` | Text | Display name of the speaker |
| `EntryTime` | DateTime | Server-side timestamp |
| `RelatedRecordId` | Reference | Often the `VoiceCall.Id` |

### Filtering

Restrict to actual utterances:

```sql
WHERE EntryType IN ('TranscriptionEnded', 'Voice', 'Message')
  AND Message != null
```

`ParticipantChanged` and `RoutingResult` are housekeeping rows — useful for audit, noisy for transcript display.

### Customer vs Agent test

```apex
Boolean isCustomer = 'EndUser'.equals(ce.ActorType);
```

Don't trust `ActorName` for routing decisions; some partner stacks set it inconsistently.

---

## Toolkit vs ConversationEntry — When to Use Which

| Scenario | Source | Why |
|---|---|---|
| LWC on live VoiceCall page, agent desktop | Toolkit | Lowest latency, real-time push |
| LWC on VoiceCall page after call ended | ConversationEntry | Toolkit fires nothing post-wrap |
| Background Apex (Flow, Queueable, scheduled) | ConversationEntry | No DOM available |
| LWC on a non-VoiceCall page (Case, Account) | ConversationEntry | Toolkit only works on VoiceCall record context |
| Cross-component LMS broadcast | Toolkit primary, fan out via LMS | One subscriber, many consumers |
| Compliance / archival pipeline | ConversationEntry via Platform Events | Toolkit is desktop-only |

### Hybrid pattern (recommended for production)

Run both. Toolkit is the live source; ConversationEntry polling is the catch-up after page load and the safety net when toolkit drops events.

```javascript
async connectedCallback() {
    await this.loadVoiceCallContext();
    await this.loadHistoricalEntries();   // ConversationEntry catch-up
    this.startPolling();                   // safety net
    // Toolkit subscription happens in renderedCallback
}
```

Use a shared `_knownEntryIds` set + `_lastSeenSeq` water mark across both sources to dedupe.

---

## Native Voice vs Partner Telephony Differences

| Aspect | Native (SCV + Amazon Connect) | Partner Telephony (BYOT) |
|---|---|---|
| Toolkit transcript events | Yes | Vendor-dependent |
| ConversationEntry rows | Yes | Yes (created by partner adapter) |
| Interim fragments (`isFinal: false`) | Yes | Often only finals |
| `sender.role` accuracy | High | Medium — fall back to ActorType |
| Conference/transfer events | Reliable | Vendor-dependent |
| Recording controls | Toolkit-supported | Partner UI only |

When you can't tell which the org runs, assume BYOT and code defensively: filter on `isFinal`, cross-reference `ActorType`, treat unknown roles as `Customer`.

---

## Edge Cases and Failure Modes

### Late-arriving final after `callended`

Toolkit can deliver one or two final fragments after the `callended` event, especially when ASR is finishing the last utterance. Recommended:

```javascript
handleCallEnded = () => {
    if (this._pollTimer) clearTimeout(this._pollTimer);
    setTimeout(() => this.runDownstreamFinal(), 1500);
};
```

### Transcript drops mid-call

If the ASR service hiccups, the toolkit goes silent without an error event. The polling fallback catches this — keep polling even when toolkit-subscribed, just lower the cadence (10–15s).

### Long utterance over the column limit

`ConversationEntry.Message` is a LongTextArea (32,768). Single ASR utterances rarely exceed 4KB, but coached calls with monologues can. Don't assume any specific upper bound; defensively truncate when feeding to prompts.

### Replay after page navigation

User navigates away and back. Always re-query `ConversationEntry` from `_lastSeenSeq` on reconnect. The toolkit does not replay missed events.

### Concurrent components on the same page

Two LWCs both subscribing to the same toolkit element causes double-handling. Either:
- Use one parent component that subscribes and rebroadcasts via Lightning Message Service, or
- Make each component idempotent on `event.detail.id`.

---

## Debounce and Polling Cadence Tuning

| Consumer | Recommended debounce | Recommended poll cadence |
|---|---|---|
| AI extraction (LLM call) | 3000ms | 5000ms |
| UI badge update | 250ms | 5000ms |
| Sentiment scoring | 1500ms | 5000ms |
| Compliance keyword scan | 0ms (per-utterance) | 3000ms |
| Persisted analytics | 10000ms | 10000ms |

Cap maximum debounce delay so consumers still react during long monologues. Pattern:

```javascript
scheduleDownstreamWork() {
    if (this._workTimer) clearTimeout(this._workTimer);
    if (!this._maxLatencyTimer) {
        this._maxLatencyTimer = setTimeout(() => {
            this._maxLatencyTimer = null;
            this.runDownstream();
        }, 8000);
    }
    this._workTimer = setTimeout(() => {
        if (this._maxLatencyTimer) {
            clearTimeout(this._maxLatencyTimer);
            this._maxLatencyTimer = null;
        }
        this.runDownstream();
    }, 3000);
}
```

---

## Permissions and Setup

- LWC consumer must be on a Lightning page with the VoiceCall record context.
- Running user needs `Service Cloud Voice User` permission set (or equivalent custom set with Voice access).
- For ConversationEntry queries: `View All` on Conversation, or row-level access via the related VoiceCall.
- For partner adapters: confirm the adapter writes ConversationEntry rows (some only emit toolkit events).
