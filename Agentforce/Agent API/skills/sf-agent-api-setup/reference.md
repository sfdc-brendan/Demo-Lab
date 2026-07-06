# Agent API Setup Reference

Deep reference for onboarding to the Agentforce Agent API. Quick Start lives in [SKILL.md](SKILL.md).

## External Client App (ECA) — Full Settings

Setup → Quick Find → **External Client Apps Manager** → **New External Client App**.

### Basic Information
- Name, API name, contact email.

### OAuth Settings → Enable OAuth
Add these OAuth scopes:

| Scope | Label |
|-------|-------|
| `api` | Manage user data via APIs |
| `refresh_token`, `offline_access` | Perform requests at any time |
| `chatbot_api` | Access chatbot services |
| `sfap_api` | Access the Salesforce API Platform |

### Additional OAuth settings — SELECT
- **Enable Client Credentials Flow** — exchange client credentials for an access token.
- **Issue JWT Web Token (JWT)-based access tokens for named users** — issue tokens for named users.

### Additional OAuth settings — DESELECT
- Require secret for Web Server Flow
- Require secret for Refresh Token Flow
- Require Proof Key for Code Exchange (PKCE) extension for Support Authorization Flows

### Policy tab (after creating the app)
1. Click **Edit**.
2. Under **OAuth Flows and External Client App Enhancements**, check **Enable Client Credentials Flow**.
3. Set **Run As (Username)** to a user with at least **API Only** access.
4. Save.

### Obtain credentials
Settings tab → **OAuth Settings** → **Consumer Key and Secret** → copy both values.

## Token Response Schema

The client credentials token call returns:

```json
{
  "access_token": "eyJ0bmsiOiJjb3JlL3Byb2QvM…",
  "signature": "HBb7Zf4aaOUlI1V…",
  "token_format": "jwt",
  "scope": "sfap_api chatbot_api api",
  "instance_url": "https://sample-org-eaa32a127e4a6b.my.salesforce.com",
  "id": "https://login.salesforce.com/id/00DW…/005W…",
  "token_type": "Bearer",
  "issued_at": "1736530186928",
  "api_instance_url": "https://api.salesforce.com"
}
```

- `access_token` → the bearer token for all Agent API calls.
- `instance_url` → your My Domain URL (use for `instanceConfig.endpoint`).
- `api_instance_url` → the API host base (`api.salesforce.com`).

## Required Values for a Call

| Value | Where to get it |
|-------|-----------------|
| `AGENT_ID` | See "Agent ID Retrieval" below |
| `ACCESS_TOKEN` | `access_token` from the token call |
| `RANDOM_UUID` | Any UUID you generate; represents the session key and traces the conversation in event logs |
| `MY_DOMAIN_URL` | Setup → My Domain → **Current My Domain URL** |

## Agent ID Retrieval

### Determine your builder
- **New Agentforce Builder**: Canvas/Script views, built-in AI assistance, Agent Script support. Accessed via Agentforce Studio in the App Launcher.
- **Legacy Agentforce Builder**: visual subagent editor, dialog-based config. Accessed via Setup → Agentforce Agents.

### Legacy Builder
The agent ID is the 18-character ID at the end of the Agent Overview page URL. Example:
`https://mydomain.salesforce-setup.com/lightning/setup/EinsteinCopilot/0XxSB000000IPCr0AO/edit` → `0XxSB000000IPCr0AO`.

### New Builder
The bot ID represents the agent ID. Retrieve from the `Bot` metadata type or `BotDefinition` standard object:

```sql
SELECT Id, DeveloperName FROM BotDefinition WHERE DeveloperName = 'Agentforce_Service_Agent'
```

The `Id` field is your agent ID.

CLI options:
```bash
sf data query --query "SELECT Id, AgentType, MasterLabel, DeveloperName FROM BotDefinition"
sf project retrieve start -m Bot -m GenAiPlannerBundle
```

## Government Cloud

Replace `api.salesforce.com` with `api.gov.salesforce.com` in every endpoint. Path and request format are otherwise identical. Example start session:
`https://api.gov.salesforce.com/einstein/ai-agent/v1/agents/{AGENT_ID}/sessions`

## Common Setup Failures

| Symptom | Cause | Fix |
|---------|-------|-----|
| HTTP 401 | Bad/expired token, wrong flow | Re-mint token; confirm client credentials flow enabled + Run As user set |
| HTTP 500 `EngineConfigLookupException` | Lightning URL used for endpoint | Use My Domain URL in `instanceConfig.endpoint` |
| HTTP 400 "not a valid agent ID" | Wrong agent ID | Re-fetch via BotDefinition / URL |
| HTTP 404 | Wrong host | Use `api.salesforce.com` (or gov host) |

## Sources
- [Get Started with the Agent API](https://developer.salesforce.com/docs/ai/agentforce/guide/agent-api-get-started.html)
- [Get the Agent ID for an Agent](https://developer.salesforce.com/docs/ai/agentforce/guide/agent-api-agent-id.html)
- [Agent API Considerations](https://developer.salesforce.com/docs/ai/agentforce/guide/agent-api-considerations.html)
