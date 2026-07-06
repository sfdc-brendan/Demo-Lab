# Agent API Variables Reference

Deep reference for configuring and passing Agent API variables. Quick Start lives in [SKILL.md](SKILL.md).

## Request Placement

The `variables` array can appear in:
- **Start Session** body — for read-only and initial values.
- **Send Message** body — for editable variables only.

Each entry:
```json
{ "name": "<variable name>", "type": "<data type>", "value": "<value>" }
```

## Naming Rules

- Context variables use the `$Context.` prefix (for example `$Context.EndUserLanguage`).
- Custom variables use the developer name you defined.
- For variables derived from custom fields, drop the `__c` suffix:
  `Conversation_Key__c` → `$Context.Conversation_Key`.

## Editability Matrix

| Variable kind | Settable at start | Editable mid-session |
|---------------|-------------------|----------------------|
| `$Context.EndUserLanguage` | Yes | Yes |
| Other `$Context.*` | Yes | No |
| Custom, `external`, editable | Yes | Yes |
| Read-only custom | Yes | No |

## ConversationVariable (BotVersion, BotTemplate)

| Field | Description |
|-------|-------------|
| `dataType` | Text, Number, Boolean, Object, Date, DateTime, Currency, Id |
| `description` | Description; used by the Agentforce planner service |
| `developerName` | Unique name. Begins with a letter, no spaces, no trailing underscore, no consecutive underscores |
| `includeInPrompt` | If `true`, variable is sent in the prompt (appears in Included Fields) |
| `label` | Human-readable label across the UI |
| `visibility` | `internal` = only action output can set; `external` = action output **and** API (e.g. Agent API) can set |

## ConversationContextVariable (Bot, BotTemplate)

| Field | Description |
|-------|-------------|
| `dataType` | Text, Number, Boolean, Object, Date, DateTime, Currency, Id |
| `description` | Description; used by the Agentforce planner service |
| `developerName` | Unique name; same naming constraints as above |
| `includeInPrompt` | Whether included in the prompt sent to the model |
| `label` | Human-readable label |

### Default variables
`Id`, `EndUserId`, and `EndUserLanguage` always appear in the Included Fields section regardless of `includeInPrompt`. Do not change `includeInPrompt` for these — it can prevent the agent from accessing important session data.

## Full Start-Session Example with Variables

```json
{
  "externalSessionKey": "{RANDOM_UUID}",
  "instanceConfig": { "endpoint": "https://{MY_DOMAIN_URL}" },
  "streamingCapabilities": { "chunkTypes": ["Text"] },
  "bypassUser": true,
  "variables": [
    { "name": "$Context.EndUserLanguage", "type": "Text", "value": "en_US" },
    { "name": "team_descriptor", "type": "Text", "value": "The Greatest Team" },
    { "name": "troubleshootingSteps", "type": "Text", "value": "Complete this list of troubleshooting steps: 1. Confirm that you've entered your username and password correctly. 2. Do all those other important troubleshooting steps." }
  ]
}
```

## Sources
- [Send Agent Variables with the Agent API](https://developer.salesforce.com/docs/ai/agentforce/guide/agent-api-variables.html)
- Metadata API Developer Guide: `ConversationVariable`, `ConversationContextVariable`
- Salesforce Help: Agent Variables
