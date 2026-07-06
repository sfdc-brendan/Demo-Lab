# Agent API Messaging Reference

Full request/response and SSE event shapes. Quick Start lives in [SKILL.md](SKILL.md).

## Message Request Body

Both endpoints take the same body:

```json
{
  "message": {
    "sequenceId": 1,
    "type": "Text",
    "text": "Show me the cases associated with Lauren Bailey."
  }
}
```

- `sequenceId` — integer, increases per message within a session.
- `type` — `Text` for user text input.
- `text` — the user utterance.
- `variables` — optional array of context/custom variables (see `sf-agent-api-variables`).

## Synchronous Response (Inform)

```json
{
  "messages": [
    {
      "type": "Inform",
      "id": "ceb6b5de-6063-4e39-bc02-91e9bf7da867",
      "metrics": {},
      "feedbackId": "0bc8720e-e010-4129-87bb-70caaa885ee4",
      "planId": "0bc8720e-e010-4129-87bb-70caaa885ee4",
      "isContentSafe": true,
      "message": "Here are two cases related to Lauren Bailey: ...",
      "result": [],
      "citedReferences": []
    }
  ],
  "_links": { "…": "…" }
}
```

## Streaming Events (SSE)

Each event arrives as an SSE frame. Representative payloads:

### ProgressIndicator
```json
{
  "timestamp": 1736902938827,
  "originEventId": "1736902935340-REQ",
  "traceId": "2fdb1d5e7eb48d35b9d1ba402eeb4b69",
  "offset": 0,
  "message": {
    "type": "ProgressIndicator",
    "id": "c4410599-8c0a-412d-910f-a60e4159d807",
    "indicatorType": "ACTION",
    "message": "Working on it"
  }
}
```

### TextChunk
```json
{
  "timestamp": 1736902952425,
  "originEventId": "1736902935340-REQ",
  "traceId": "2fdb1d5e7eb48d35b9d1ba402eeb4b69",
  "offset": 1,
  "message": {
    "type": "TextChunk",
    "id": "6fc64974-9c20-484e-8b8c-105e460d4a00",
    "offset": 1,
    "message": "Here",
    "formatType": "Text"
  }
}
```

### Inform (complete message in the stream)
```json
{
  "messages": [
    {
      "type": "Inform",
      "id": "f0313bcb-65a2-4abb-9d84-b872247b1420",
      "metrics": {},
      "feedbackId": "ab403163-b87f-4e4b-9fa6-18670a2be655",
      "planId": "ab403163-b87f-4e4b-9fa6-18670a2be655",
      "isContentSafe": true,
      "message": "Here are two cases related to Lauren Bailey: ...",
      "result": [],
      "citedReferences": []
    }
  ],
  "_links": {
    "self": null,
    "messages": { "href": ".../sessions/{id}/messages" },
    "messagesStream": { "href": ".../sessions/{id}/messages/stream" },
    "session": { "href": ".../agents/{agentId}/sessions" },
    "end": { "href": ".../sessions/{id}" }
  }
}
```

### EndOfTurn
```json
{
  "timestamp": 1736902953027,
  "originEventId": "1736902935340-REQ",
  "traceId": "2fdb1d5e7eb48d35b9d1ba402eeb4b69",
  "offset": 0,
  "message": {
    "type": "EndOfTurn",
    "id": "2a2be92b-f479-481a-9f22-1e5bf39e038e"
  }
}
```

### ValidationFailureChunk
Emitted when the agent's response fails validation. **Remove all previously rendered chunks and display only the new streamed content.**

## Common Envelope Fields

| Field | Meaning |
|-------|---------|
| `timestamp` | Epoch millis when event was produced |
| `originEventId` | Correlates events for a single request (`…-REQ`) |
| `traceId` | Trace id for the turn; log for support |
| `offset` | Ordering hint within the stream |
| `message.type` | Event/message discriminator |

## Inform Message Fields

| Field | Meaning |
|-------|---------|
| `id` | Message id |
| `feedbackId` | Use with the feedback endpoint to rate this response |
| `planId` | Planner execution id |
| `isContentSafe` | Trust Layer content-safety flag |
| `message` | The full text (may contain `\n` and markdown-ish formatting) |
| `result` | Structured results (action data), when present |
| `citedReferences` | Cited sources; see `sf-agent-api-citations` |

## Sources
- [Agent API Examples](https://developer.salesforce.com/docs/ai/agentforce/guide/agent-api-examples.html)
- [Agent API Reference (Summary)](https://developer.salesforce.com/docs/einstein/genai/references/agent-api)
