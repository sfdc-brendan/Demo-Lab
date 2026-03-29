# Service Coach

A Service Cloud Lightning Web Component that provides **real-time AI-powered coaching** for customer service representatives during voice calls and messaging sessions. Uses **Einstein Prompt Templates** (via `ConnectApi.EinsteinLLM`) and the **Service Cloud Voice Toolkit API** to deliver contextual coaching tips, suggested responses, sentiment analysis, and escalation risk assessment — all embedded directly on the record page.

**Do not use in production.** For demos and evaluation only.

## Features

- **Real-Time Coaching Tips**: AI-generated, contextual guidance based on the live conversation transcript and case details. Tips are categorized by type (empathy, resolution, process, upsell) and severity (info, warning, opportunity).
- **Suggested Responses**: Ready-to-use phrases the rep can say during the interaction, with accept/dismiss actions.
- **Conversation Signals**: Detected customer sentiment (positive/negative/neutral), intent detection, and escalation risk assessment (Low/Medium/High) displayed as signal cards.
- **Hybrid Trigger Model**: Auto-refreshes coaching on Voice Toolkit events (call started, call ended) with a configurable polling interval, plus a manual "Refresh Coaching" button for on-demand advice.
- **Multi-Channel Support**: Works on **VoiceCall**, **MessagingSession**, and **Case** record pages. Voice calls use the Toolkit API events; messaging sessions poll ConversationEntry records via Apex.
- **Configurable via Custom Metadata**: Runtime settings (refresh interval, max transcript length, prompt template name, sentiment toggle) stored in `Service_Coach_Config__mdt` — no code changes needed to tune behavior.

## What It Uses

| Capability | Description |
|------------|-------------|
| AI coaching | Einstein Prompt Templates via `ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate()` |
| Voice integration | `lightning-service-cloud-voice-toolkit-api` events (`callstarted`, `callended`) |
| Messaging integration | SOQL on `ConversationEntry` via `MessagingSession.ConversationId` |
| Conversation context | Case, Contact, Account data merged into prompt grounding |
| Configuration | `Service_Coach_Config__mdt` custom metadata for runtime tuning |

---

## How It Works

1. **Component loads on a record page**
   The rep opens a VoiceCall, MessagingSession, or Case record. The component detects the context via `objectApiName` and shows a "Ready to Coach" idle state.

2. **Coaching is triggered**
   - **Voice calls**: The Voice Toolkit fires a `callstarted` event, which automatically triggers the first coaching fetch and starts the auto-refresh timer.
   - **Messaging sessions**: The rep clicks "Get Coaching Advice" to start, then coaching auto-refreshes on a configurable interval (default 45 seconds).
   - **Cases**: The rep clicks the manual refresh button to get on-demand coaching for the case context.

3. **Apex fetches conversation context**
   `ServiceCoachController` calls `ServiceCoachService.buildConversationContext()`, which queries `ConversationEntry` records for the conversation transcript and loads related Case, Contact, and Account data.

4. **Einstein AI generates coaching**
   The service invokes `ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate()` with the prompt template API name (from custom metadata), the Case record, the conversation transcript, and the channel type. The AI responds with structured JSON.

5. **Response is parsed and rendered**
   The structured response is parsed into coaching tips, suggested responses, sentiment, intent, and escalation risk — and rendered in the `serviceCoachPanel` with collapsible sections.

6. **Auto-refresh continues**
   During an active voice call, coaching refreshes every N seconds (configurable). When the call ends, the timer stops. The rep can always click the refresh button for fresh advice.

---

## Installation

### Deploy via CLI

```bash
git clone https://github.com/sfdc-brendan/Demo-Lab.git
cd Demo-Lab/Service\ Cloud/Service\ Coach
sf org login web --alias my-org --set-default
sf project deploy start --source-dir force-app --target-org my-org
```

### Post-Installation

1. **Create the Einstein Prompt Template** in Prompt Builder (Setup > Prompt Builder). See [docs/PROMPT_TEMPLATE_SETUP.md](docs/PROMPT_TEMPLATE_SETUP.md) for the full template text, input parameters, and step-by-step instructions.
2. **Add the Service Coach component** to VoiceCall, MessagingSession, or Case record pages via Lightning App Builder.
3. Optionally adjust runtime settings in the **Service Coach Config** custom metadata record (Setup > Custom Metadata Types > Service Coach Config > Default).

---

## Package Contents

| Component | Type | Description |
|-----------|------|-------------|
| `serviceCoach` | LWC | Parent orchestrator — Voice Toolkit integration, state management, auto-refresh |
| `serviceCoachPanel` | LWC | Sectioned coaching panel (signals, tips, suggested responses) |
| `serviceCoachInsight` | LWC | Individual coaching tip card with severity indicator |
| `serviceCoachRecommendation` | LWC | Suggested response card with accept/dismiss actions |
| `ServiceCoachController` | Apex | `@AuraEnabled` controller exposing coaching methods to LWC |
| `ServiceCoachService` | Apex | Service class — conversation context building, AI invocation, response parsing |
| `ServiceCoachControllerTest` | Apex | Test class with positive, negative, bulk, and JSON parsing scenarios |
| `Service_Coach_Config__mdt` | Custom Metadata | Runtime configuration (template name, refresh interval, transcript limit, sentiment toggle) |

---

## File Structure

```
Service Coach/
├── README.md
├── sfdx-project.json
├── docs/
│   └── PROMPT_TEMPLATE_SETUP.md
└── force-app/
    └── main/
        └── default/
            ├── classes/
            │   ├── ServiceCoachController.cls
            │   ├── ServiceCoachController.cls-meta.xml
            │   ├── ServiceCoachService.cls
            │   ├── ServiceCoachService.cls-meta.xml
            │   ├── ServiceCoachControllerTest.cls
            │   └── ServiceCoachControllerTest.cls-meta.xml
            ├── customMetadata/
            │   └── Service_Coach_Config.Default.md-meta.xml
            ├── lwc/
            │   ├── serviceCoach/
            │   │   ├── serviceCoach.html
            │   │   ├── serviceCoach.js
            │   │   ├── serviceCoach.css
            │   │   └── serviceCoach.js-meta.xml
            │   ├── serviceCoachPanel/
            │   │   ├── serviceCoachPanel.html
            │   │   ├── serviceCoachPanel.js
            │   │   ├── serviceCoachPanel.css
            │   │   └── serviceCoachPanel.js-meta.xml
            │   ├── serviceCoachInsight/
            │   │   ├── serviceCoachInsight.html
            │   │   ├── serviceCoachInsight.js
            │   │   ├── serviceCoachInsight.css
            │   │   └── serviceCoachInsight.js-meta.xml
            │   └── serviceCoachRecommendation/
            │       ├── serviceCoachRecommendation.html
            │       ├── serviceCoachRecommendation.js
            │       ├── serviceCoachRecommendation.css
            │       └── serviceCoachRecommendation.js-meta.xml
            └── objects/
                └── Service_Coach_Config__mdt/
                    ├── Service_Coach_Config__mdt.object-meta.xml
                    └── fields/
                        ├── Auto_Refresh_Interval_Seconds__c.field-meta.xml
                        ├── Enable_Sentiment_Detection__c.field-meta.xml
                        ├── Max_Transcript_Length__c.field-meta.xml
                        └── Prompt_Template_API_Name__c.field-meta.xml
```

---

## Configuration

The `Service_Coach_Config__mdt` custom metadata type controls runtime behavior. Edit via Setup > Custom Metadata Types > Service Coach Config > Default.

| Field | Default | Description |
|-------|---------|-------------|
| Prompt Template API Name | `Service_Call_Coach` | API name of the Einstein Prompt Template |
| Auto Refresh Interval (Seconds) | `45` | How often coaching auto-refreshes during active conversations |
| Max Transcript Length | `2000` | Maximum characters of conversation transcript sent to the AI model |
| Enable Sentiment Detection | `true` | Show/hide the Conversation Signals section (sentiment, intent, escalation risk) |

---

## Requirements

- Salesforce org with Lightning Experience, API 66.0+
- **Service Cloud Voice** licensed and configured (for voice call coaching)
- **Messaging** enabled (for messaging session coaching)
- **Einstein Generative AI** / Prompt Builder enabled — the component uses `ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate()`
- **Einstein Prompt Template** created in Prompt Builder (see `docs/PROMPT_TEMPLATE_SETUP.md`)

---

## License

Provided as-is for demonstration purposes.
