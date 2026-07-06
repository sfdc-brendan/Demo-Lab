---
name: sf-agent-api-setup
description: Agent API onboarding — External Client App (ECA), OAuth client credentials flow, token minting, and agent ID retrieval. Use when setting up access to the Salesforce Agentforce Agent API, configuring the ECA/OAuth scopes, generating a bearer token, resolving My Domain and base endpoints, or finding an agent's ID for use in API calls.
disable-model-invocation: true
---
# Agent API Setup and Authentication

## Use This Skill When

- Standing up access to the Agentforce Agent API (`einstein/ai-agent/v1`) for the first time.
- Creating the External Client App (ECA) and choosing OAuth scopes and flow settings.
- Minting a bearer token via the client credentials flow.
- Resolving the correct base endpoint (`api.salesforce.com` vs `api.gov.salesforce.com`) and My Domain URL.
- Finding the agent ID from the Legacy or new Agentforce Builder.

## Prerequisites

- Agentforce enabled with at least one **activated** agent.
- Agent API is **not** supported for agents of type "Agentforce (Default)".
- A Run As user with at least **API Only** access for the client credentials flow.

## Quick Start (Setup Path)

Follow these steps in order. For screen-by-screen ECA settings and the full token/response reference, see [reference.md](reference.md).

### 1. Create the External Client App

Setup → **External Client Apps Manager** → **New External Client App**. Set name + contact email, enable OAuth, and add these scopes:

- `api` — Manage user data via APIs
- `refresh_token`, `offline_access` — Perform requests at any time
- `chatbot_api` — Access chatbot services
- `sfap_api` — Access the Salesforce API Platform

Enable **Client Credentials Flow** and **Issue JWT-based access tokens for named users**. Deselect the three "Require secret / Require PKCE" options. Then on the **Policy** tab, enable Client Credentials Flow and set **Run As** to an API-only user.

### 2. Get the consumer key and secret

App **Settings** tab → **OAuth Settings** → **Consumer Key and Secret**. Copy both. Never commit these.

### 3. Mint a token (client credentials)

```bash
curl https://{MY_DOMAIN_URL}/services/oauth2/token \
--header 'Content-Type: application/x-www-form-urlencoded' \
--data-urlencode 'grant_type=client_credentials' \
--data-urlencode 'client_id={CONSUMER_KEY}' \
--data-urlencode 'client_secret={CONSUMER_SECRET}'
```

Copy `access_token` from the JSON response. This bearer token is required on every Agent API call.

### 4. Get the agent ID

- **Legacy Agentforce Builder**: open the Agent Overview page in Setup; copy the 18-character ID at the end of the URL (for example `0XxSB000000IPCr0AO`).
- **New Agentforce Builder**: the bot ID is the agent ID. Query `BotDefinition`:

```sql
SELECT Id, DeveloperName FROM BotDefinition WHERE DeveloperName = 'Agentforce_Service_Agent'
```

Or via CLI: `sf data query --query "SELECT Id, DeveloperName, AgentType FROM BotDefinition"`

### 5. Make your first call

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

## Endpoint Reference

| Purpose | Base URL |
|---------|----------|
| Standard | `https://api.salesforce.com/einstein/ai-agent/v1` |
| Government Cloud | `https://api.gov.salesforce.com/einstein/ai-agent/v1` |

`instanceConfig.endpoint` must be your **My Domain URL** (`https://xxx.my.salesforce.com`), not the Lightning URL (`*.lightning.force.com`).

## Guardrails

- Store the consumer secret and access token server-side only; never ship them to a browser or commit them to source control.
- Use the My Domain URL for `instanceConfig.endpoint` — using the Lightning URL causes `EngineConfigLookupException` (HTTP 500).
- `bypassUser: true` runs as the agent-assigned user; `false` runs as the token user. Pick deliberately based on data-access requirements.
- Government Cloud orgs must use `api.gov.salesforce.com` everywhere — the standard host returns 404.
- Tokens are short-lived; build refresh into the client rather than pasting a static token.

## Deliverables

- Configured ECA with the four required scopes and client credentials flow enabled.
- A documented token-minting command/secret-storage plan.
- The resolved agent ID and My Domain URL captured for the target org.
- A verified first `Start Session` response.

## Additional Resources

- Full ECA settings walkthrough, token response schema, and agent-ID edge cases: [reference.md](reference.md)
- Session, message, and feedback flow: `sf-agent-api-session-lifecycle`
- Error diagnosis: `sf-agent-api-troubleshooting`
- Official docs: [Get Started with the Agent API](https://developer.salesforce.com/docs/ai/agentforce/guide/agent-api-get-started.html), [Get the Agent ID](https://developer.salesforce.com/docs/ai/agentforce/guide/agent-api-agent-id.html)
