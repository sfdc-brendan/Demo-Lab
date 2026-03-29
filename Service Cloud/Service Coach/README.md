# Service Coach

A Service Cloud Lightning Web Component that acts as a **real-time AI coaching assistant** for customer service representatives. During a phone call or messaging conversation, Service Coach analyzes the live transcript alongside case, contact, and account context, then uses Salesforce on-platform generative AI to surface coaching tips, suggested responses, sentiment signals, and escalation risk — all in a panel embedded directly on the record page.

The component serves a dual purpose: it is both a **next best action** engine (recommending specific things the rep should say or do) and a **service coach** (guiding the rep through the conversation with contextual advice). It works across voice calls via the **Service Cloud Voice Toolkit API** and messaging sessions via **ConversationEntry** polling, providing a single coaching experience regardless of channel.

**Do not use in production.** For demos and evaluation only.

## What the Rep Sees

When a service representative opens a VoiceCall, MessagingSession, or Case record page, the Service Coach component appears in a card with three sections:

- **Conversation Signals** — a three-column summary showing detected customer sentiment (positive / negative / neutral), the customer's intent, and escalation risk (Low / Medium / High). Color-coded for quick scanning.
- **Coaching Tips** — a list of expandable insight cards, each with a category badge (empathy, resolution, process, upsell, coaching) and severity indicator (info, warning, opportunity). These are tactical pieces of advice for how to handle the conversation.
- **Suggested Responses** — recommended phrases the rep can say next, with "Accept" and "Dismiss" buttons. Accepting a response removes it from the list and shows a confirmation toast. Categories indicate the conversation stage (opening, empathy, resolution, closing).

A pulsing "Live" badge appears during active voice calls. The footer shows the channel type (Voice Call, Messaging Session, or Case) and a spinning sync icon when auto-refresh is active. A manual refresh button is always available in the card header.

---

## What Happens Technically — Chronological Walkthrough

### 1. Component initialization

When the `serviceCoach` LWC renders on a record page, it receives `recordId` and `objectApiName` from the Lightning page context. In `connectedCallback`, it makes an imperative Apex call to `ServiceCoachController.getServiceCoachConfig()`, which queries the `Service_Coach_Config__mdt` custom metadata type for the `Default` record. This returns four settings: the Prompt Template API name, the auto-refresh interval in seconds, the maximum transcript length, and whether sentiment detection is enabled. If no custom metadata record exists, hardcoded defaults are used (template: `Service_Call_Coach`, interval: 45s, transcript: 2000 chars, sentiment: on).

The component starts in the **idle** state and shows a "Ready to Coach" message with a "Get Coaching Advice" button.

### 2. Coaching is triggered

How coaching starts depends on the channel:

- **Voice call** (`objectApiName === 'VoiceCall'`): The component renders the `<lightning-service-cloud-voice-toolkit-api>` element, which is the Service Cloud Voice Toolkit API. When the telephony system signals a call has begun, the toolkit fires a `callstarted` event. The component's `handleCallStarted` handler sets the call-active flag, clears any accumulated transcript, calls `fetchCoaching()`, and starts the auto-refresh timer via `setInterval`.

- **Messaging session** (`objectApiName === 'MessagingSession'`): The Voice Toolkit is not rendered. The rep clicks "Get Coaching Advice" to trigger the first `fetchCoaching()` call. After the first successful response, the component starts the auto-refresh timer so that coaching updates as new messages arrive.

- **Case** (`objectApiName === 'Case'`): The rep clicks the manual refresh button. No auto-refresh is started since there is no live conversation.

### 3. LWC calls Apex (`fetchCoaching`)

The `fetchCoaching` method in `serviceCoach.js` guards against concurrent requests (if already loading, it returns immediately), sets the state to `loading`, and makes an imperative call to `ServiceCoachController.getCoachingAdvice()` with three parameters: the `recordId`, the `objectApiName`, and any accumulated transcript from the client side.

### 4. Apex builds conversation context (`ServiceCoachController` → `ServiceCoachService`)

`ServiceCoachController.getCoachingAdvice()` delegates to `ServiceCoachService.buildConversationContext()`. This method inspects the `objectApiName` to determine which path to take:

- **VoiceCall path**: Queries the `VoiceCall` record to get its `RelatedRecordId`. If the related record is a Case, it queries the Case along with the parent Contact and Account (Subject, Description, Contact.Name, Account.Name, Account.Rating, Priority, Status, Origin). Then it queries `ConversationEntry` records: it reads the VoiceCall's `ConversationId`, queries up to 50 `ConversationEntry` records ordered by `EntryTime ASC`, and formats them into a transcript string with lines like `"Agent: ..."` and `"Customer: ..."` based on the `ActorType` field.

- **MessagingSession path**: Queries the `MessagingSession` record for its `CaseId`. If a Case is linked, loads the same Case/Contact/Account context. Then queries `ConversationEntry` records using the MessagingSession's `ConversationId`, building the same formatted transcript.

- **Case path**: Directly queries the Case, Contact, and Account fields. No transcript is queried since Cases don't have a `ConversationId`.

All SOQL queries use `WITH USER_MODE` for CRUD/FLS enforcement.

The result is a `ConversationContext` wrapper containing: `transcript`, `caseSubject`, `caseDescription`, `customerName`, `accountTier`, `channelType`, and `caseId`.

### 5. Apex invokes the Einstein Prompt Template (`ServiceCoachService.getCoachingFromAI`)

With the context built, the service reads the prompt template API name and max transcript length from `Service_Coach_Config__mdt`. It combines the server-side transcript (from ConversationEntry) with any additional client-side transcript, truncating from the front if the combined string exceeds the max length (keeping the most recent conversation).

It then constructs a `ConnectApi.EinsteinPromptTemplateGenerationsInput` with three input parameters wrapped in `ConnectApi.WrappedValue` objects:
- `Input:Case` — a map with the Case record ID (so the prompt template can resolve merge fields like `{!$Input:Case.Subject}`)
- `Input:conversationSnippet` — the transcript string
- `Input:channelType` — `"VoiceCall"`, `"MessagingSession"`, or `"Case"`

The `isPreview` flag is set to `false` so the model returns a real AI-generated response rather than preview/test data. The `applicationName` is set to `"ServiceCoach"` for tracking.

The service calls `ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate()` with the template API name and the input object. This sends the prompt through the **Einstein Trust Layer**, which handles toxicity detection, PII masking, and audit logging before routing to the foundation model.

### 6. AI generates structured coaching advice

The Einstein Prompt Template (created in Prompt Builder, not deployed as code) resolves the merge fields against the Case record and injects the conversation transcript. The system prompt instructs the model to respond with a JSON object containing:

```json
{
  "coachingTips": [{ "text": "...", "category": "empathy|resolution|process|upsell|coaching", "severity": "info|warning|opportunity" }],
  "suggestedResponses": [{ "text": "...", "context": "opening|empathy|resolution|closing" }],
  "detectedIntent": "What the customer wants",
  "sentiment": "positive|negative|neutral",
  "escalationRisk": "Low|Medium|High"
}
```

### 7. Apex parses the response

`ServiceCoachService.parseCoachingResponse()` receives the raw text from `output.generations[0].text`. It attempts to deserialize it as JSON using `JSON.deserializeUntyped()`. If successful, it maps the parsed arrays into `CoachingTip` and `SuggestedResponse` wrapper objects (each assigned a unique client-side ID) and extracts the scalar fields (intent, sentiment, escalation risk).

If the AI returns non-JSON text (malformed or plain-text advice), the catch block wraps the entire raw string as a single coaching tip with category `"coaching"` and severity `"info"`, so the rep always sees something useful.

If the `ConnectApi` call itself fails (model unavailable, token limits, etc.), the service returns a fallback response with a warning tip advising the rep to use standard procedures.

### 8. Response travels back to the LWC

The `CoachingResponse` wrapper (with `@AuraEnabled` properties) is serialized and returned through the Apex controller to the LWC. The `fetchCoaching` method receives the result, sets `coachingResponse`, transitions the state to `active`, records the last refresh timestamp, and — for messaging sessions — starts the auto-refresh timer if it's not already running.

### 9. Panel renders the coaching content

The parent `serviceCoach` component passes `coachingResponse` and `enableSentiment` down to `c-service-coach-panel`. The panel component renders three collapsible sections:

- **Conversation Signals**: A 3-column CSS grid showing sentiment, intent, and escalation risk with color-coded badges (green for positive/low, yellow for medium/warning, red for negative/high).
- **Coaching Tips**: Iterates over `coachingResponse.coachingTips` rendering a `c-service-coach-insight` card for each. Each card shows a category badge, the tip text, and an expandable detail section with the severity label.
- **Suggested Responses**: Iterates over `coachingResponse.suggestedResponses` rendering a `c-service-coach-recommendation` card for each. Each card shows a category badge, the response text, and Accept/Dismiss buttons.

### 10. Auto-refresh cycle continues

If a voice call is active or a messaging session has been activated, the `setInterval` timer fires every N seconds (default 45). Each tick calls `fetchCoaching()` again, which re-queries the latest `ConversationEntry` records (capturing new messages since the last refresh), re-invokes the prompt template with updated transcript context, and re-renders the panel with fresh coaching.

For voice calls, the `callended` event from the Voice Toolkit stops the timer and triggers one final coaching fetch (which may now reflect the full conversation). The "Live" badge disappears and the auto-refresh sync icon stops.

### 11. Rep interacts with recommendations

When the rep clicks "Accept" on a suggested response, the `serviceCoachRecommendation` component dispatches a bubbling `accept` custom event. The parent `serviceCoach` component handles it by showing a success toast ("Recommendation Accepted") and filtering that response out of the `suggestedResponses` array via immutable state update (spread + filter). Clicking "Dismiss" removes the card without a toast. The coaching tips section's insight cards can be expanded/collapsed via click or keyboard (Enter/Space), with `aria-expanded` tracking for accessibility.

---

## What It Uses

| Capability | Description |
|------------|-------------|
| AI coaching | Einstein Prompt Templates via `ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate()` |
| Voice integration | `lightning-service-cloud-voice-toolkit-api` events (`callstarted`, `callended`) |
| Messaging integration | SOQL on `ConversationEntry` via `MessagingSession.ConversationId` |
| Conversation context | Case, Contact, Account data merged into prompt grounding |
| Configuration | `Service_Coach_Config__mdt` custom metadata for runtime tuning |

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
