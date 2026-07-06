---
name: sf-agent-api-messaging
description: Agent API messaging — synchronous and streaming (SSE) message sending, sequenceId management, and streaming event handling. Use when building the send-message loop for an Agentforce Agent API client, consuming server-sent events (ProgressIndicator, TextChunk, Inform, EndOfTurn, ValidationFailureChunk), or choosing between the sync and stream endpoints.
disable-model-invocation: true
---
# Agent API Messaging (Sync and Streaming)

## Use This Skill When

- Building the send-message request/response loop against an active session.
- Consuming the streaming (SSE) endpoint and rendering chunks in real time.
- Handling streaming event types and the `ValidationFailureChunk` reset case.
- Managing `sequenceId` ordering across turns.

## Two Endpoints

| | Synchronous | Streaming |
|---|---|---|
| Path | `POST /sessions/{SESSION_ID}/messages` | `POST /sessions/{SESSION_ID}/messages/stream` |
| `Accept` header | `application/json` | `text/event-stream` |
| Response | Full `Inform` in one payload | SSE event stream |
| Best for | Automation, server-to-server | Real-time chat UI |

Both require an active session (see `sf-agent-api-session-lifecycle`).

## Quick Start

### Send a synchronous message

```bash
curl --location 'https://api.salesforce.com/einstein/ai-agent/v1/sessions/{SESSION_ID}/messages' \
--header 'Accept: application/json' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer {ACCESS_TOKEN}' \
--data '{
  "message": {
    "sequenceId": {SEQUENCE_ID},
    "type": "Text",
    "text": "Show me the cases associated with Lauren Bailey."
  }
}'
```

The response contains a `messages` array with an `Inform` message holding the full `message` text, plus `feedbackId`, `planId`, `isContentSafe`, `result`, and `citedReferences`.

### Send a streaming message

```bash
curl --location 'https://api.salesforce.com/einstein/ai-agent/v1/sessions/{SESSION_ID}/messages/stream' \
--header 'Accept: text/event-stream' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer {ACCESS_TOKEN}' \
--data '{
  "message": {
    "sequenceId": {SEQUENCE_ID},
    "type": "Text",
    "text": "Show me the cases associated with Lauren Bailey."
  }
}'
```

### Consume the SSE stream (Node)

Order the incoming events by `offset` and only treat `Inform` as the authoritative full answer. Full event payload shapes are in [reference.md](reference.md).

```javascript
const res = await fetch(`${BASE}/einstein/ai-agent/v1/sessions/${sessionId}/messages/stream`, {
  method: 'POST',
  headers: {
    Accept: 'text/event-stream',
    'Content-Type': 'application/json',
    Authorization: `Bearer ${accessToken}`
  },
  body: JSON.stringify({ message: { sequenceId, type: 'Text', text } })
});

let buffer = '';
let rendered = '';
for await (const chunk of res.body) {
  buffer += chunk.toString();
  const events = buffer.split('\n\n');
  buffer = events.pop() ?? '';
  for (const raw of events) {
    const line = raw.split('\n').find((l) => l.startsWith('data:'));
    if (!line) continue;
    const evt = JSON.parse(line.slice(5).trim());
    switch (evt.message?.type) {
      case 'ProgressIndicator':
        // optional: show a "Working on it" indicator
        break;
      case 'TextChunk':
        rendered += evt.message.message;
        renderPartial(rendered);
        break;
      case 'Inform':
        rendered = evt.messages[0].message; // authoritative full text
        renderFinal(rendered);
        break;
      case 'ValidationFailureChunk':
        rendered = '';           // discard everything streamed so far
        clearRenderedOutput();   // show only new streamed content after this
        break;
      case 'EndOfTurn':
        finishTurn();
        break;
      default:
        break;
    }
  }
}
```

## Streaming Event Types

| Event | Meaning | Client action |
|-------|---------|---------------|
| `ProgressIndicator` | Response in progress (`indicatorType`, e.g. `ACTION`) | Show typing/working indicator |
| `TextChunk` | Incremental text (`offset`, `formatType`) | Append to rendered text |
| `Inform` | Complete message | Replace partial with authoritative full text |
| `EndOfTurn` | Turn complete | Stop indicator, allow next input |
| `ValidationFailureChunk` | Response validation failed | Remove all rendered chunks; display only new streamed content |

## Guardrails

- Increment `sequenceId` on every turn within a session; ordering depends on it.
- Treat `Inform` as the source of truth — reconcile any streamed `TextChunk` text against it.
- On `ValidationFailureChunk`, clear previously rendered chunks; do not leave partial/unsafe text on screen.
- Parse SSE by event boundaries (`\n\n`) and buffer partial frames; never assume one chunk = one event.
- One in-flight request per session — a second concurrent call returns HTTP 423.
- Streaming still respects the 120-second API timeout.
- Escape/sanitize agent text before injecting into HTML; treat it as untrusted output.

## Deliverables

- A send-message function keyed to session + sequence with sync and/or streaming variants.
- An SSE consumer that handles all five event types and the validation-failure reset.
- A rendering contract (partial vs final) documented for the UI.

## Additional Resources

- Full SSE event payloads and sample responses: [reference.md](reference.md)
- Rendering cited sources / inline citations: `sf-agent-api-citations`
- Session start/end/feedback: `sf-agent-api-session-lifecycle`
- Official docs: [Agent API Examples](https://developer.salesforce.com/docs/ai/agentforce/guide/agent-api-examples.html)
