---
name: sf-agent-api-variables
description: Agent API context and custom variables — passing session context to an agent and configuring variable accessibility. Use when sending context variables ($Context.*) or custom variables through the Agent API, controlling editability across turns, or configuring ConversationVariable / ConversationContextVariable via Agentforce Builder or Metadata API.
disable-model-invocation: true
---
# Agent API Variables

## Use This Skill When

- Passing context variables (`$Context.*`) or custom variables in a start-session or send-message call.
- Deciding which variables can be set at start vs edited mid-conversation.
- Configuring variable API accessibility in Agentforce Builder or via Metadata API (`ConversationVariable`, `ConversationContextVariable`).

## Concept

You can pass two kinds of variables so the agent can use them on subsequent turns:

- **Context variables** — prefixed `$Context.` (for example `$Context.EndUserLanguage`). Predefined session context.
- **Custom variables** — your own named values (for example `team_descriptor`, `troubleshootingSteps`).

## Quick Start

Add a `variables` array to the start-session body (or a send-message body for editable variables):

```json
{
  "externalSessionKey": "{RANDOM_UUID}",
  "instanceConfig": { "endpoint": "https://{MY_DOMAIN_URL}" },
  "streamingCapabilities": { "chunkTypes": ["Text"] },
  "bypassUser": true,
  "variables": [
    { "name": "$Context.EndUserLanguage", "type": "Text", "value": "en_US" },
    { "name": "team_descriptor", "type": "Text", "value": "The Greatest Team" },
    { "name": "troubleshootingSteps", "type": "Text", "value": "Complete this list of troubleshooting steps: 1. Confirm username/password. 2. ..." }
  ]
}
```

Each variable has `name`, `type`, and `value`.

## Editability Rules

- Many variables are **read-only** and can only be set during the **start session** call.
- Context variables (`$Context` prefix) are **not editable after the session starts** — **except** `$Context.EndUserLanguage`.
- Only **editable** variables can be modified during a send-message call.
- When referencing variables derived from custom fields, **omit the `__c` suffix**. Example: `Conversation_Key__c` → `$Context.Conversation_Key`.

## Variable Types

`Text`, `Number`, `Boolean`, `Object`, `Date`, `DateTime`, `Currency`, `Id`.

## Configuring Accessibility

### Agentforce Builder
When creating an agent variable, check **Allow value to be set by API** so the API can populate it.

### Metadata API
Configure via `ConversationVariable` (in `BotVersion`/`BotTemplate`) and `ConversationContextVariable` (in `Bot`/`BotTemplate`).

Key fields:

| Field | Purpose |
|-------|---------|
| `dataType` | Text, Number, Boolean, Object, Date, DateTime, Currency, Id |
| `developerName` | Unique name; starts with a letter, no spaces, no trailing underscore, no double underscores |
| `label` | Human-readable label in the UI |
| `description` | Used by the Agentforce planner service |
| `includeInPrompt` | Whether the variable is included in the prompt sent to the model |
| `visibility` | `internal` = set only by action output; `external` = also settable by API (ConversationVariable only) |

Do not change `includeInPrompt` for the default `Id`, `EndUserId`, and `EndUserLanguage` variables — doing so can block the agent from key session data.

## Guardrails

- To set a variable via API it must be `external` visibility (ConversationVariable) and "Allow value to be set by API" enabled.
- Strip `__c` from custom-field-derived names, and use the `$Context.` prefix for context variables.
- Don't try to mutate read-only/context variables after start (except `$Context.EndUserLanguage`) — the change is ignored.
- Treat variable values as untrusted input downstream; validate before using in SOQL, HTML, or callouts.
- Keep prompt-injected variables (`includeInPrompt: true`) minimal and non-sensitive.

## Deliverables

- A variable contract: name, type, context-vs-custom, set-at-start-vs-editable, and API accessibility.
- Metadata definitions (`ConversationVariable` / `ConversationContextVariable`) for any API-settable variables.
- A validation plan for how variable values are consumed downstream.

## Additional Resources

- Where variables attach in the request flow: `sf-agent-api-session-lifecycle`, `sf-agent-api-messaging`
- Full metadata field list: [reference.md](reference.md)
- Official docs: [Send Agent Variables with the Agent API](https://developer.salesforce.com/docs/ai/agentforce/guide/agent-api-variables.html)
