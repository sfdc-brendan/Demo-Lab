# Agentforce Agent API Skills for Agentic Coding Tools

A suite of 8 Agent Skills for building integrations with the Salesforce **Agentforce Agent API** (`einstein/ai-agent/v1`) — authentication and setup, session lifecycle, synchronous and streaming messaging, context/custom variables, citations, integration architecture, troubleshooting, and integration review.

Compatible with Cursor, Claude Code, Windsurf, and any AI coding agent with a skills directory.

---

## Quick Install

Copy and paste into your terminal:

```bash
curl -sSL "https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/Agentforce/Agent%20API/skills/install.sh" | bash
```

The installer auto-detects your IDE and installs all `sf-agent-api-*` skills.

- Cursor: `~/.cursor/skills/`
- Claude Code: `~/.claude/skills/`
- Windsurf: `~/.windsurf/skills/`

Restart your IDE after installing.

### Manual install

```bash
git clone https://github.com/sfdc-brendan/Demo-Lab.git
cd "Demo-Lab/Agentforce/Agent API/skills"
bash install.sh
```

---

## Skills Included

- `sf-agent-api-setup`: External Client App (ECA), OAuth client credentials flow, scopes, token minting, base endpoints, and agent ID retrieval (Legacy URL + `BotDefinition`). *(hybrid — setup path + reference.md)*
- `sf-agent-api-session-lifecycle`: Start → message → end flow, `sessionId`/`sequenceId` management, end reasons, feedback submission, sync-vs-streaming decision.
- `sf-agent-api-messaging`: Synchronous and streaming (SSE) message sending, `sequenceId` ordering, and handling of ProgressIndicator / TextChunk / Inform / EndOfTurn / ValidationFailureChunk events. *(hybrid — code + reference.md)*
- `sf-agent-api-variables`: Context (`$Context.*`) and custom variables, editability rules, `__c` handling, and `ConversationVariable` / `ConversationContextVariable` metadata config. *(hybrid — code + reference.md)*
- `sf-agent-api-citations`: Parsing `citedReferences`, rendering source lists and inline citations via `inlineMetadata` (claim + location).
- `sf-agent-api-integration-patterns`: Website chat, headless automation, platform connectors, and agent-to-agent patterns; layered client architecture and resilience posture.
- `sf-agent-api-troubleshooting`: HTTP 400/401/404/423/500 diagnosis, timeout, media-type, `EngineConfigLookupException`, and Government Cloud endpoint issues.
- `sf-agent-api-review`: Pre-ship review rubric covering auth, session hygiene, concurrency, streaming resilience, variable safety, citations, error handling, and billing.

---

## Suggested Usage

Ask naturally, for example:

- "Set up an External Client App and mint a token for the Agent API."
- "Build a streaming chat client that consumes the Agent API SSE events."
- "Design the session lifecycle and sequenceId handling for a headless agent integration."
- "Pass EndUserLanguage and a custom variable when starting an agent session."
- "Render inline citations from the agent's citedReferences."
- "My Agent API call returns a 423 — what's wrong?"
- "Review this Agent API integration before we ship it."

---

## Notes

- Setup, messaging, and variables are **hybrid altitude** (Quick Start patterns in `SKILL.md` + deep reference in `reference.md`).
- Everything is grounded in the official [Agent API Developer Guide](https://developer.salesforce.com/docs/ai/agentforce/guide/agent-api.html) and [Agent API Reference](https://developer.salesforce.com/docs/einstein/genai/references/agent-api).
- Pair these with `sf-apex`, `sf-lwc`, and `sf-deploy` when implementing the integration inside a Salesforce org.
