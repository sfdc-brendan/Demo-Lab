---
name: sf-agent-api-session-lifecycle
description: Agent API session lifecycle — start a session, maintain conversation context, end a session, and submit feedback. Use when designing or building the session flow for an Agentforce Agent API integration, managing session IDs and sequence IDs, choosing sync vs streaming messaging, or handling session end reasons and feedback submission.
disable-model-invocation: true
---
# Agent API Session Lifecycle

## Use This Skill When

- Designing the full session flow: start → send messages → end, plus feedback.
- Managing `sessionId`, `externalSessionKey`, and per-turn `sequenceId`.
- Deciding between synchronous and streaming message delivery.
- Handling session end reasons and submitting response feedback to Data 360.

## Lifecycle Overview

1. **Start a session** with an agent → receive `sessionId` and an initial greeting `Inform` message.
2. **Send messages** using the `sessionId`. The agent tracks context across turns. Choose sync or streaming.
3. **End the session** when finished (or let it time out).
4. Optionally **submit feedback** on any response.

The API supports **one request at a time** per session — a concurrent request returns HTTP 423 (Session Already Locked).

## Quick Start (curl)

### Start a session

```bash
curl --location -X POST https://api.salesforce.com/einstein/ai-agent/v1/agents/{AGENT_ID}/sessions \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer {ACCESS_TOKEN}' \
--data '{
  "externalSessionKey": "{RANDOM_UUID}",
  "instanceConfig": { "endpoint": "https://{MY_DOMAIN_URL}" },
  "streamingCapabilities": { "chunkTypes": ["Text"] },
  "bypassUser": true
}'
```

The response returns `sessionId` (required for all subsequent calls), an `_links` object with `messages`/`session`/`end` hrefs, and an initial `Inform` message (the agent greeting).

### End a session

```bash
curl --location --request DELETE 'https://api.salesforce.com/einstein/ai-agent/v1/sessions/{SESSION_ID}' \
--header 'x-session-end-reason: UserRequest' \
--header 'Authorization: Bearer {ACCESS_TOKEN}'
```

Returns a `SessionEnded` message with a `reason` (for example `ClientRequest`).

### Submit feedback

```bash
curl --location 'https://api.salesforce.com/einstein/ai-agent/v1/sessions/{SESSION_ID}/feedback' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer {ACCESS_TOKEN}' \
--data '{
  "feedbackId": "{FEEDBACK_ID}",
  "feedback": "GOOD",
  "text": "Email looks great"
}'
```

`feedbackId` comes from the response message you are rating. `feedback` is `GOOD` or `BAD`. A successful submission returns HTTP 201. Feedback is stored in Data 360.

## Key Session Parameters

| Parameter | Where | Purpose |
|-----------|-------|---------|
| `externalSessionKey` | Start session | Your UUID; traces the conversation in event logs |
| `instanceConfig.endpoint` | Start session | My Domain URL (`https://xxx.my.salesforce.com`) |
| `streamingCapabilities.chunkTypes` | Start session | e.g. `["Text"]` |
| `bypassUser` | Start session | `true` = run as agent user; `false` = run as token user |
| `sessionId` | Start response | Required for send/end/feedback |
| `sequenceId` | Each message | Monotonically increasing integer per session |
| `x-session-end-reason` | End session header | e.g. `UserRequest` |

## Sync vs Streaming (Decision)

- **Synchronous** (`/messages`): whole response in one shot. Best for automation, server-to-server, and simple request/response.
- **Streaming** (`/messages/stream`, SSE): incremental chunks. Best for real-time chat UIs where you render as text arrives.

For message payloads and streaming event handling, use `sf-agent-api-messaging`.

## Guardrails

- Serialize calls per session — never fire concurrent requests (HTTP 423). Queue turns client-side.
- Increment `sequenceId` for every message in a session; reusing or resetting it corrupts turn ordering.
- Always end sessions you no longer need (DELETE) to release resources; don't rely solely on timeout.
- Persist `sessionId` and `externalSessionKey` together for traceability and log correlation.
- Capture `feedbackId` from each response so feedback can be attributed to the correct turn.
- The Agent API has a 120-second timeout; a timed-out call returns HTTP 500.

## Deliverables

- A session state model (start → active turns → end) with `sessionId`/`sequenceId` tracking.
- A defined session end strategy (explicit end reason + timeout handling).
- A feedback capture plan mapping `feedbackId` to responses.
- Sync-vs-streaming decision recorded per integration surface.

## Additional Resources

- Message payloads, streaming SSE events, and citations: `sf-agent-api-messaging`, `sf-agent-api-citations`
- Passing context/custom variables at start and per turn: `sf-agent-api-variables`
- Setup and tokens: `sf-agent-api-setup`
- Official docs: [Session Lifecycle](https://developer.salesforce.com/docs/ai/agentforce/guide/agent-api-lifecycle.html), [Examples](https://developer.salesforce.com/docs/ai/agentforce/guide/agent-api-examples.html)
