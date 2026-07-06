---
name: sf-agent-api-troubleshooting
description: Agent API troubleshooting — diagnose HTTP 400/401/404/423/500 responses, timeouts, media-type errors, and Government Cloud endpoint issues. Use when an Agentforce Agent API call fails, returns an error status, times out, or when diagnosing EngineConfigLookupException / HttpServerErrorException / Session Already Locked errors.
disable-model-invocation: true
---
# Agent API Troubleshooting

## Use This Skill When

- An Agent API call returns a non-2xx status and you need the likely cause and fix.
- A call times out or reports an unexpected media-type / config error.
- Diagnosing Government Cloud endpoint mismatches.

## Error Matrix

| Status | Meaning | Likely cause | Fix |
|--------|---------|--------------|-----|
| **400** Bad Request | Malformed request | Message contains "{VALUE} is not a valid agent ID" | Verify the agent ID (re-fetch via `BotDefinition` or Legacy URL) |
| **401** Unauthorized | Auth problem | Bad/expired token, flow not enabled | Re-mint token; confirm client credentials flow + Run As user |
| **404** Not Found | Wrong token or endpoint | Incorrect host/path; gov cloud on standard host | Verify endpoint; gov cloud must use `api.gov.salesforce.com` |
| **423** Locked | Session already locked | Concurrent request on the same session | Serialize turns; only one request in flight per session |
| **500** Internal Server Error | Server-side / config error | See sub-causes below | Match the message/error field below |

### HTTP 500 sub-causes

| Message/Error field contains | Cause | Fix |
|------------------------------|-------|-----|
| "Unsupported Media Type" | Wrong `Content-Type` | Set `Content-Type: application/json` |
| `EngineConfigLookupException` | Wrong domain in start session | Use the **Current My Domain URL** for `instanceConfig.endpoint` (not Lightning URL) |
| `HttpServerErrorException` | Wrong agent ID in endpoint | Use the correct agent ID (see `sf-agent-api-setup`) |
| (timeout) | Call exceeded 120s | The API times out at 120s and returns 500; add client timeout + retry/fallback |
| other | Setup incomplete | Re-verify Get Started setup steps |

## Diagnostic Workflow

1. **Capture** status code, response `message`/`error` fields, and `traceId` (from streaming events / logs).
2. **Classify** using the matrix above.
3. **Verify inputs** in order: token validity → base host (standard vs gov) → agent ID → `instanceConfig.endpoint` (My Domain) → headers (`Content-Type`, `Accept`).
4. **Check concurrency** if 423 — is another turn still in flight for this session?
5. **Re-test** the isolated call (curl / Postman) before changing client code.

## Guardrails

- Log `traceId`, `sessionId`, and the HTTP status on every failure — support cases need `traceId`.
- Never retry a 423 immediately in a tight loop; wait for the in-flight turn to complete.
- Distinguish transient 500 (timeout, server) from deterministic 500 (config, media type) before retrying.
- On Government Cloud, a 404 usually means the standard host was used — switch to `api.gov.salesforce.com`.
- Re-minting the token fixes most 401s; if not, the flow/Run As configuration is wrong.

## Deliverables

- A triage note per failure: status, cause, fix, and whether it's transient or deterministic.
- A retry/backoff policy that treats 423 and deterministic 500s as non-retryable-as-is.

## Additional Resources

- Setup and correct endpoints: `sf-agent-api-setup`
- Concurrency/session rules: `sf-agent-api-session-lifecycle`
- Resilience design: `sf-agent-api-integration-patterns`
- Official docs: [Agent API Troubleshooting](https://developer.salesforce.com/docs/ai/agentforce/guide/agent-api-troubleshooting.html), [Considerations](https://developer.salesforce.com/docs/ai/agentforce/guide/agent-api-considerations.html)
