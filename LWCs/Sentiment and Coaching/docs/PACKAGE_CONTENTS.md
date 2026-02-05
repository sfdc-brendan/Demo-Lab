# Sentiment Coaching – Package Contents

Use this list when building a **managed** or **unlocked** package, or when documenting what to deploy.

---

## 1. Apex classes (4)

| Member | Purpose |
|--------|--------|
| `ChatCoachingExtractor` | Parses Gen AI coaching response for Messaging Session; used by MSG flows |
| `ChatExtractor` | Parses Gen AI sentiment response for Messaging Session; used by MSG flows |
| `HistoricalAnalysisController` | Finds Voice Call / Messaging Session candidates and sets Request Historical Analysis flag |
| `TextExtractor` | Parses Gen AI responses for Voice Call (coaching + sentiment); used by SCV flows |

---

## 2. Custom fields (10)

**Messaging Session (5)**  
- `AgentPerformanceEvaluation__c`  
- `AgentPerformanceRating__c`  
- `ChatSentiment__c`  
- `Request_Historical_Analysis__c`  
- `SentimentRating__c`  

**Voice Call (5)**  
- `Agent_Performance_Evaluation__c`  
- `Agent_Performance_Rating__c`  
- `Call_Sentiment__c`  
- `Request_Historical_Analysis__c`  
- `Sentiment_Rating__c`  

*(Do **not** package standard object definitions for `MessagingSession` or `VoiceCall`; only these custom fields.)*

---

## 3. Flows (8)

| Flow | Object | Trigger |
|------|--------|--------|
| `MSG_Extract_Coaching_After_Chat` | MessagingSession | Record-triggered (After Save, Status = Ended) |
| `MSG_Extract_Sentiment_After_Chat` | MessagingSession | Record-triggered (After Save, Status = Ended) |
| `Historical_MSG_Extract_Coaching_After_Chat` | MessagingSession | Record-triggered when `Request_Historical_Analysis__c` = true |
| `Historical_MSG_Extract_Sentiment_After_Chat` | MessagingSession | Record-triggered when `Request_Historical_Analysis__c` = true |
| `SCV_Extract_Agent_Performance_After_Call` | VoiceCall | Record-triggered (After Save, call ended) |
| `SCV_Extract_Sentiment_After_Call` | VoiceCall | Record-triggered (After Save, call ended) |
| `Historical_SCV_Extract_Agent_Performance_After_Call` | VoiceCall | Record-triggered when `Request_Historical_Analysis__c` = true |
| `Historical_SCV_Extract_Sentiment_After_Call` | VoiceCall | Record-triggered when `Request_Historical_Analysis__c` = true |

---

## 4. Gen AI prompt templates (4)

| Member | Used by |
|--------|--------|
| `Agent_Performance_Evaluation` | Voice Call coaching (SCV flows) |
| `Call_Sentiment` | Voice Call sentiment (SCV flows) |
| `MSG_Chat_Coaching` | Messaging Session coaching (MSG flows) |
| `MSG_Chat_Sentiment` | Messaging Session sentiment (MSG flows) |

**Dependencies:**  
- MSG prompts use **Flow: conv_sum_ms__GetTscpForMsgSession** (Messaging Session transcript).  
- Voice Call prompts use **Flow: conv_sum_vc__GetTscpForVoiceCall** (Voice Call transcript).  
These flows are **not** in this package; they must exist in the subscriber org (e.g. from Digital Engagement / Conversation Summary or equivalent).

---

## 5. Lightning Web Components (4)

| Component | Use |
|-----------|-----|
| `messagingSessionAnalytics` | Messaging Session record page – Agent Performance + Chat Sentiment |
| `voiceCallAnalytics` | Voice Call record page – Agent Performance + Call Sentiment |
| `sentimentTracker` | Optional tracker UI (Voice Call / Messaging Session) |
| `historicalAnalysisLauncher` | App/Home/Tab – find and run historical analysis on past records |

---

## 6. Permission set (1)

| Member | Purpose |
|--------|--------|
| `Sentiment_Coaching_Fields` | Read/edit access to all 10 custom fields on Voice Call and Messaging Session. Assign to users who need the analytics. |

---

## Optional (usually not packaged)

- **Compact layouts / list views** on Voice Call (e.g. `SDO_Service_Default`, list views) – often org-specific; include only if you want to ship a specific layout.
- **Page layouts / record pages** – add LWCs to record pages in the subscriber org after install.

---

## Manifest files in this repo

| File | Contents |
|------|----------|
| `manifest/package-sentiment-coaching-full.xml` | **Full package** – all of the above (Apex, CustomField, Flow, GenAiPromptTemplate, LightningComponentBundle, PermissionSet). Use for deploy or as the source for a package. |
| `manifest/package-sentiment-coaching-without-permissionset.xml` | Same as full but **no PermissionSet**. Use when the target org already has Voice Call (or Messaging Session) and deploying the permission set causes conflicts. After deploy, add permissions in the target org (see below). |
| `manifest/package-media-package.xml` | Subset used for a media package (no PermissionSet). |
| `manifest/package-messaging-fields.xml` | Messaging Session custom fields only. |

---

## When the target org already has Voice Call

If deployment fails because of the permission set (e.g. target org already has the Voice Call object from another package or SKU):

1. **Deploy without the permission set**  
   Use `manifest/package-sentiment-coaching-without-permissionset.xml`:
   ```bash
   sf project deploy start --manifest manifest/package-sentiment-coaching-without-permissionset.xml --target-org "YourOrg" --wait 15
   ```

2. **Add permissions in the target org** (pick one):
   - **Option A:** Deploy only the **Sentiment_Coaching_Fields_Only** permission set (grants access to the 10 Sentiment Coaching fields only; no other Voice Call fields). If that deploy still fails, use Option B.
   - **Option B:** In the target org, create a new permission set (e.g. “Sentiment Coaching Fields”), add read/edit for the 10 custom fields on Voice Call and Messaging Session, then assign it to the right users.

---

## Deploy with the full manifest

```bash
sf project deploy start --manifest manifest/package-sentiment-coaching-full.xml --target-org "YourOrgAlias" --wait 15
```

## Prerequisites in subscriber org

1. **Transcript flows** (or equivalent):  
   - `conv_sum_ms__GetTscpForMsgSession` for Messaging Session.  
   - `conv_sum_vc__GetTscpForVoiceCall` for Voice Call.  
   Without these, Gen AI prompts cannot get transcript text.

2. **Einstein GPT / Gen AI** enabled and model (e.g. GPT 4.1/5) available for the prompt templates.

3. **Objects**: Standard objects `VoiceCall` and `MessagingSession` exist (Salesforce Digital Engagement / Service Cloud Voice, etc.).

4. After install: **assign** the permission set **Sentiment Coaching Fields** to users and add the LWCs to the desired record pages and app/home/tab.
