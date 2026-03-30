# Service Coach (Agentforce)

Real-time AI coaching for customer service representatives, powered by an **Agentforce Employee Agent**. This Lightning Web Component provides coaching tips, suggested responses, and conversation signals during live voice calls and messaging sessions.

---

## What It Does

The Service Coach LWC sits on VoiceCall, MessagingSession, and Case record pages. When a call starts or a rep clicks refresh, the component sends the conversation context to an Agentforce Employee Agent. The agent analyzes the situation -- drawing on Knowledge articles, past case resolutions, and service playbooks via RAG -- and returns structured coaching in real time.

Unlike a direct Prompt Template approach, the Agentforce version provides:

- **Knowledge Grounding (RAG)**: The agent searches Knowledge articles and SOPs to base coaching on your org's actual content
- **Multi-Turn Session Memory**: The agent remembers prior coaching within the same call, building on context instead of starting fresh each refresh
- **Topic-Based Routing**: A planner routes each request to the right specialist topic (Coaching, Escalation, Knowledge, or Upsell)
- **Declarative Action Orchestration**: The agent executes actions mid-conversation (search, query, assess) rather than relying on a single monolithic prompt

---

## How It Works -- Chronological Technical Walkthrough

### 1. Component Initialization

When the `serviceCoach` LWC mounts on a record page, it calls `ServiceCoachController.getServiceCoachConfig()` to load configuration from the `Service_Coach_Config__mdt` custom metadata type. This includes the agent API name, auto-refresh interval, max transcript length, and sentiment detection toggle.

### 2. Voice Toolkit Registration

The component's HTML includes `<lightning-service-cloud-voice-toolkit-api>`, which registers it to receive Service Cloud Voice events. The `js-meta.xml` declares the `lightning__ServiceCloudVoiceToolkitApi` capability. This is how the component auto-triggers on phone calls without user interaction.

### 3. Call Started / Manual Trigger

When the Voice Toolkit fires a `callstarted` event, or the rep clicks the refresh button, the component calls `_fetchCoaching()`. This transitions the state machine from `IDLE` to `LOADING`.

### 4. Apex Controller Layer

The LWC calls `ServiceCoachController.getCoachingAdvice(recordId, objectApiName, conversationSnippet)`. The controller delegates to `ServiceCoachService.buildConversationContext()` to gather case details, customer info, and transcript data, then passes the assembled context to `ServiceCoachService.getCoachingFromAgent()`.

### 5. Context Assembly

`ServiceCoachService` queries the appropriate object:
- **VoiceCall**: Looks up the related Case via `RelatedRecordId`, queries `ConversationEntry` records for the real-time transcript
- **MessagingSession**: Looks up the related Case via `CaseId`, queries `ConversationEntry` for the messaging transcript
- **Case**: Queries Case fields directly (Subject, Description, Contact Name, Account Rating)

The result is a `ConversationContext` wrapper containing the transcript, case subject, description, customer name, account tier, and channel type.

### 6. Agent Message Construction

`buildAgentMessage()` constructs a structured natural-language message from the `ConversationContext`. It tells the agent:
- What channel (VoiceCall, MessagingSession, Case)
- The case subject and description
- Customer name and account tier
- The recent conversation transcript
- The exact JSON schema the agent should respond with

### 7. Session Management

Before invoking the agent, the service checks `SessionManager` (a static map keyed by Case ID) for an existing session ID. On the first call, no session exists so the agent starts fresh. On subsequent refreshes, the stored session ID is passed so the agent continues the same conversation -- it remembers what it already coached.

### 8. Agentforce Invocation

The core invocation uses `Invocable.Action`:

```apex
Invocable.Action action = Invocable.Action.createCustomAction(
    'generateAiAgentResponse', agentApiName
);
action.setInvocationParameter('userMessage', userMessage);
if (String.isNotBlank(sessionId)) {
    action.setInvocationParameter('sessionId', sessionId);
}
List<Invocable.Action.Result> results = action.invoke();
```

The Employee Agent's planner receives the message and routes it to the appropriate topic (Coaching, Escalation, Knowledge, or Upsell) based on content analysis. The agent may execute multiple actions -- searching Knowledge, querying case history, assessing escalation risk -- before composing its response.

### 9. Response Parsing

The agent returns a text response containing JSON. `parseCoachingResponse()` extracts the JSON (handling cases where the agent wraps it in conversational text), then deserializes it into `CoachingTip` and `SuggestedResponse` wrapper objects. If the JSON is malformed, the raw text becomes a single coaching tip as a fallback.

### 10. LWC Rendering

The parsed `CoachingResponse` flows through the component hierarchy:
- **serviceCoachPanel** renders three sections: Conversation Signals (intent, sentiment, escalation risk chips), Coaching Tips, and Suggested Responses
- **serviceCoachInsight** renders each coaching tip with severity-colored left border (blue=info, orange=warning, green=opportunity) and collapsible detail
- **serviceCoachRecommendation** renders each suggested response with "Use" and "Dismiss" action buttons

### 11. Auto-Refresh Cycle

After the initial fetch, a `setInterval` timer fires every N seconds (configurable, default 45). Each refresh sends the latest transcript to the agent with the existing session ID. Because the agent has session memory, it can notice changes -- like rising frustration -- and update its coaching accordingly. The timer clears when a `callended` event fires.

---

## Package Contents

| Type | Component | Description |
|------|-----------|-------------|
| Apex | `ServiceCoachService` | Agent invocation, session management, context building, response parsing |
| Apex | `ServiceCoachController` | `@AuraEnabled` methods exposed to the LWC |
| Apex | `ServiceCoachControllerTest` | Test class with PNB coverage |
| LWC | `serviceCoach` | Parent orchestrator with Voice Toolkit integration |
| LWC | `serviceCoachPanel` | Sectioned layout for signals, tips, and responses |
| LWC | `serviceCoachInsight` | Coaching tip card with severity indicator |
| LWC | `serviceCoachRecommendation` | Suggested response card with accept/dismiss |
| Custom Metadata | `Service_Coach_Config__mdt` | Agent name, refresh interval, transcript length, sentiment toggle |

---

## File Structure

```
Service Coach - Agentforce/
├── README.md
├── sfdx-project.json
├── config/
│   └── project-scratch-def.json
├── docs/
│   └── AGENT_SETUP.md
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
            │   ├── serviceCoachPanel/
            │   ├── serviceCoachInsight/
            │   └── serviceCoachRecommendation/
            └── objects/
                └── Service_Coach_Config__mdt/
                    ├── Service_Coach_Config__mdt.object-meta.xml
                    └── fields/
                        ├── Agent_API_Name__c.field-meta.xml
                        ├── Auto_Refresh_Interval_Seconds__c.field-meta.xml
                        ├── Max_Transcript_Length__c.field-meta.xml
                        └── Enable_Sentiment_Detection__c.field-meta.xml
```

---

## Installation

### Deploy to Org

```bash
sf project deploy start --source-dir force-app --target-org your-org-alias
```

### Prerequisites

- Salesforce org with Lightning Experience, API v66.0+
- **Agentforce** licensed (Employee Agent capability)
- **Service Cloud Voice** (for voice call coaching)
- **Messaging** (for messaging session coaching)
- **Einstein Search** configured with Knowledge article index
- The Employee Agent created and activated (see `docs/AGENT_SETUP.md`)

### Post-Deploy Configuration

1. Create the Employee Agent in Setup following `docs/AGENT_SETUP.md`
2. Verify the `Service_Coach_Config__mdt.Default` record has the correct agent API name
3. Add the **Service Coach (Agentforce)** component to VoiceCall, MessagingSession, and/or Case record pages via App Builder
4. Test by opening a Case and clicking refresh, or by initiating a voice call

---

## Configuration

All settings are managed via the `Service_Coach_Config__mdt` custom metadata type:

| Field | Default | Description |
|-------|---------|-------------|
| `Agent_API_Name__c` | `Service_Coach_Agent` | API name of the Agentforce Employee Agent |
| `Auto_Refresh_Interval_Seconds__c` | `45` | Seconds between automatic coaching refreshes during active calls |
| `Max_Transcript_Length__c` | `2000` | Maximum character length of transcript sent to the agent |
| `Enable_Sentiment_Detection__c` | `true` | Show/hide the sentiment signal chip in the UI |
