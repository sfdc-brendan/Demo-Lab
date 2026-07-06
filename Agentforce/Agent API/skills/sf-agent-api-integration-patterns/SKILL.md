---
name: sf-agent-api-integration-patterns
description: Agent API integration architecture — website chat, headless automation, platform connectors, and agent-to-agent patterns. Use when designing where and how to embed the Agentforce Agent API, structuring a client (token service, session manager, message loop, streaming handler), and setting the security and resilience posture for a production integration.
disable-model-invocation: true
---
# Agent API Integration Patterns

## Use This Skill When

- Choosing an integration pattern for the Agent API (website, headless, connector, agent-to-agent).
- Structuring a reusable client: token management, session lifecycle, message loop, streaming, retries.
- Setting the security and resilience posture before building.

## Integration Patterns

| Pattern | Description | Delivery | Notes |
|---------|-------------|----------|-------|
| **Website chat** | Embed agent chat on a site/app | Streaming | Token brokered server-side; browser never sees the secret |
| **Headless automation** | Automate functionality without UI | Sync | Server-to-server; ideal for jobs/workflows |
| **Platform connector** | Connect to Slack, Teams, custom workflows | Sync or streaming | Standardized REST calls per platform SDK |
| **Agent-to-agent** | One agent invokes another | Sync | Build an agentic ecosystem; watch credit consumption |

## Reference Client Architecture

Structure any integration around four layers:

1. **Token service** — mints and caches the client-credentials token, refreshes before expiry, and keeps the secret server-side.
2. **Session manager** — starts sessions (`externalSessionKey` per conversation), tracks `sessionId` + `sequenceId`, and ends sessions.
3. **Message loop** — serializes turns per session (one request in flight), builds the message body, attaches variables.
4. **Response handler** — parses sync `Inform` or consumes the SSE stream; renders citations; captures `feedbackId`.

```
[Client UI / Job] → [Message loop] → [Session manager] → [Token service] → Agent API
                         ↑                                   (cache token)
                   [Response handler] ← SSE / JSON ←─────────────┘
```

### Browser-safe pattern (website)
- Never expose the consumer secret or token to the browser.
- Front-end talks to **your** backend; backend brokers the token and proxies Agent API calls.
- Stream from backend to browser (SSE/WebSocket) if real-time rendering is needed.

## Resilience Checklist

- **Token refresh**: refresh on `401` and proactively before expiry.
- **Concurrency**: queue turns per session; a concurrent request returns `423`.
- **Timeout**: the API times out at 120s → surfaced as `500`; set client timeouts and a user-facing fallback.
- **Retries**: retry idempotent failures (network, `500` transient) with backoff; do **not** blindly resend a message that may have partially processed.
- **Session cleanup**: DELETE sessions on conversation end; reap abandoned sessions.
- **Government Cloud**: switch base host to `api.gov.salesforce.com`.

## Guardrails

- Server-side secret/token custody only — treat the browser as hostile.
- One in-flight request per session; serialize turns.
- Use the My Domain URL for `instanceConfig.endpoint`, not the Lightning URL.
- Agent API usage consumes credits (see Generative AI Usage and Billing) — budget agent-to-agent chains carefully.
- Not supported for "Agentforce (Default)" agents — confirm agent type before integrating.
- Log `traceId`, `sessionId`, and `externalSessionKey` for every turn to support debugging and audit.

## Deliverables

- Chosen integration pattern with rationale (surface, sync vs streaming, credit impact).
- A layered client design (token / session / message / response) with concurrency and retry policy.
- A security posture doc (secret custody, token brokering, PII handling).
- A resilience matrix covering 401 / 423 / 500 / timeout / session cleanup.

## Additional Resources

- Setup and tokens: `sf-agent-api-setup`
- Session and messaging mechanics: `sf-agent-api-session-lifecycle`, `sf-agent-api-messaging`
- Context passing: `sf-agent-api-variables`
- Error handling: `sf-agent-api-troubleshooting`
- Pre-ship review: `sf-agent-api-review`
- Official docs: [Agent API Developer Guide](https://developer.salesforce.com/docs/ai/agentforce/guide/agent-api.html), [Considerations](https://developer.salesforce.com/docs/ai/agentforce/guide/agent-api-considerations.html)
