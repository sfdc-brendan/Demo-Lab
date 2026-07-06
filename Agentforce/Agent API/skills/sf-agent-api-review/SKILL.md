---
name: sf-agent-api-review
description: Review rubric for Agentforce Agent API integrations. Use when auditing or reviewing an Agent API client/integration for auth and secret handling, session hygiene, sequence and concurrency correctness, streaming resilience, variable safety, citation rendering, error handling, billing awareness, and Government Cloud readiness.
disable-model-invocation: true
---
# Agent API Integration Review

## Use This Skill When

- Reviewing an Agent API integration before it ships.
- Auditing an existing client for security, correctness, and resilience gaps.
- Producing a prioritized risk list for an Agentforce headless/chat integration.

## Review Checklist

### Authentication and secrets
- [ ] Consumer secret and token are server-side only; not in the browser or source control.
- [ ] Token refresh handled (proactive + on 401); no static/pasted tokens.
- [ ] ECA uses client credentials flow with the required scopes (`api`, `refresh_token`/`offline_access`, `chatbot_api`, `sfap_api`).
- [ ] Run As user has appropriate (least-privilege) access; `bypassUser` chosen deliberately.

### Endpoints and environment
- [ ] `instanceConfig.endpoint` uses the My Domain URL, not the Lightning URL.
- [ ] Correct base host (`api.salesforce.com`, or `api.gov.salesforce.com` for Government Cloud).
- [ ] Agent is not type "Agentforce (Default)".

### Session hygiene
- [ ] `externalSessionKey` is unique per conversation and logged for tracing.
- [ ] `sessionId` tracked; sessions explicitly ended (DELETE) with a sensible `x-session-end-reason`.
- [ ] Abandoned sessions are reaped; not relying solely on timeout.

### Turn correctness and concurrency
- [ ] `sequenceId` increments monotonically per session.
- [ ] Exactly one request in flight per session (guards against 423).
- [ ] Turns serialized/queued client-side.

### Messaging and streaming
- [ ] Sync vs streaming choice matches the surface.
- [ ] SSE parser buffers partial frames and splits on event boundaries.
- [ ] All streaming events handled: ProgressIndicator, TextChunk, Inform, EndOfTurn, ValidationFailureChunk.
- [ ] On ValidationFailureChunk, rendered chunks are cleared.
- [ ] `Inform` treated as authoritative full text.

### Variables
- [ ] API-settable variables are `external` + "Allow value to be set by API".
- [ ] `__c` suffix stripped; `$Context.` prefix used correctly.
- [ ] Read-only/context variables not mutated post-start (except `$Context.EndUserLanguage`).
- [ ] Variable values validated before downstream use (SOQL/HTML/callouts).

### Citations
- [ ] `citedReferences` empty-guarded; `inlineMetadata` optional-handled.
- [ ] Inline markers inserted by `location` from highest offset backward.
- [ ] Cited URLs validated; internal records navigated via `recordId`.

### Error handling and resilience
- [ ] 400/401/404/423/500 mapped to specific handling.
- [ ] 120s timeout handled with client timeout + user-facing fallback.
- [ ] Transient vs deterministic failures distinguished for retry.
- [ ] `traceId`, `sessionId`, status logged on every failure.

### Trust, safety, and billing
- [ ] Agent text treated as untrusted output (sanitized before render).
- [ ] `isContentSafe` respected.
- [ ] Credit/billing impact understood; agent-to-agent chains budgeted.
- [ ] Feedback capture wired (`feedbackId` → feedback endpoint) where useful.

## Output Format

Report findings as:
- 🔴 **Critical**: security/correctness must-fix before ship (e.g., secret in browser, no concurrency guard).
- 🟡 **Suggestion**: resilience/quality improvement (e.g., add token pre-refresh).
- 🟢 **Nice to have**: polish (e.g., inline citation rendering).

Close with the **top 3 risks** and concrete mitigations.

## Deliverables

- Completed checklist with pass/fail per item.
- Prioritized findings (Critical / Suggestion / Nice to have).
- Top 3 risks and mitigations.

## Additional Resources

- Domain skills for each area: `sf-agent-api-setup`, `sf-agent-api-session-lifecycle`, `sf-agent-api-messaging`, `sf-agent-api-variables`, `sf-agent-api-citations`, `sf-agent-api-integration-patterns`, `sf-agent-api-troubleshooting`
- Official docs: [Agent API Developer Guide](https://developer.salesforce.com/docs/ai/agentforce/guide/agent-api.html)
