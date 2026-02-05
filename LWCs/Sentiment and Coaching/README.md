# Sentiment & Coaching Analytics for Service Cloud

AI-powered sentiment analysis and agent coaching for **Voice Calls** (Service Cloud Voice) and **Messaging Sessions** (Digital Engagement). Uses Einstein GenAI to automatically extract sentiment ratings, call/chat summaries, and agent performance evaluations.

## Features

### Real-Time Analysis
- **Automatic sentiment extraction** when calls/chats end
- **Agent performance evaluation** with actionable coaching feedback
- **Sentiment ratings** (Positive, Neutral, Negative) with detailed summaries
- Works with both **Voice Calls** and **Messaging Sessions**

### Historical Look Back (New)
Analyze past records that weren't processed in real-time:
- Find Voice Calls and Messaging Sessions from the **last 7 or 14 days** that have no sentiment/coaching data
- **Bulk select** records to process
- Background flows process selected records asynchronously
- Results appear on record pages after flow completion

## Package Contents

### Apex Classes (4)
| Class | Purpose |
|-------|---------|
| `ChatCoachingExtractor` | Parses GenAI coaching response for Messaging Sessions |
| `ChatExtractor` | Parses GenAI sentiment response for Messaging Sessions |
| `HistoricalAnalysisController` | Finds candidates and triggers historical analysis |
| `TextExtractor` | Parses GenAI responses for Voice Calls |

### Custom Fields (10)

**Messaging Session:**
- `AgentPerformanceEvaluation__c` - Coaching feedback text
- `AgentPerformanceRating__c` - Performance score
- `ChatSentiment__c` - Sentiment summary
- `SentimentRating__c` - Positive/Neutral/Negative
- `Request_Historical_Analysis__c` - Triggers historical flows

**Voice Call:**
- `Agent_Performance_Evaluation__c` - Coaching feedback text
- `Agent_Performance_Rating__c` - Performance score
- `Call_Sentiment__c` - Sentiment summary
- `Sentiment_Rating__c` - Positive/Neutral/Negative
- `Request_Historical_Analysis__c` - Triggers historical flows

### Record-Triggered Flows (8)

| Flow | Object | Trigger |
|------|--------|---------|
| `MSG_Extract_Sentiment_After_Chat` | MessagingSession | Status = Ended |
| `MSG_Extract_Coaching_After_Chat` | MessagingSession | Status = Ended |
| `SCV_Extract_Sentiment_After_Call` | VoiceCall | CallDisposition = completed |
| `SCV_Extract_Agent_Performance_After_Call` | VoiceCall | CallDisposition = completed |
| `Historical_MSG_Extract_Sentiment_After_Chat` | MessagingSession | Request_Historical_Analysis__c = true |
| `Historical_MSG_Extract_Coaching_After_Chat` | MessagingSession | Request_Historical_Analysis__c = true |
| `Historical_SCV_Extract_Sentiment_After_Call` | VoiceCall | Request_Historical_Analysis__c = true |
| `Historical_SCV_Extract_Agent_Performance_After_Call` | VoiceCall | Request_Historical_Analysis__c = true |

### GenAI Prompt Templates (4)
| Template | Purpose |
|----------|---------|
| `MSG_Chat_Sentiment` | Extract sentiment from Messaging Session transcript |
| `MSG_Chat_Coaching` | Generate agent coaching for Messaging Session |
| `Call_Sentiment` | Extract sentiment from Voice Call transcript |
| `Agent_Performance_Evaluation` | Generate agent coaching for Voice Call |

### Lightning Web Components (4)
| Component | Use |
|-----------|-----|
| `messagingSessionAnalytics` | Record page component for Messaging Sessions |
| `voiceCallAnalytics` | Record page component for Voice Calls |
| `sentimentTracker` | Manual sentiment entry/override component |
| `historicalAnalysisLauncher` | App/Home page for bulk historical analysis |

### Permission Set (1)
- `Sentiment_Coaching_Fields` - Read/edit access to all custom fields

## Prerequisites

1. **Einstein GenAI** enabled with a supported model (e.g., GPT-4.1/5)
2. **Transcript flows** must exist in the org:
   - `conv_sum_ms__GetTscpForMsgSession` (Messaging Session)
   - `conv_sum_vc__GetTscpForVoiceCall` (Voice Call)
3. **Service Cloud Voice** and/or **Digital Engagement** configured
4. Standard `VoiceCall` and `MessagingSession` objects available

## Installation

### Deploy Full Package
```bash
sf project deploy start --manifest manifest/package-sentiment-coaching-full.xml --target-org "YourOrg" --wait 15
```

### Deploy Without Permission Set
Use this if your org already has Voice Call from another package:
```bash
sf project deploy start --manifest manifest/package-sentiment-coaching-without-permissionset.xml --target-org "YourOrg" --wait 15
```

Then manually create a permission set with access to the 10 custom fields.

## Post-Installation Setup

1. **Assign the permission set** `Sentiment_Coaching_Fields` to users who need the analytics
2. **Add LWCs to record pages:**
   - Add `voiceCallAnalytics` to Voice Call record page
   - Add `messagingSessionAnalytics` to Messaging Session record page
   - (Optional) Add `sentimentTracker` for manual sentiment entry
3. **Add Historical Analysis Launcher** to an App page, Home page, or Tab for admins who need to process historical records

## Using Historical Analysis

1. Navigate to the **Historical Analysis Launcher** component
2. Select the **object type** (Voice Calls, Messaging Sessions, or Both)
3. Choose the **time range** (Last 7 or 14 days)
4. Click **Find Records** to search for records without analysis
5. Select records from the list (use "Select All" for bulk selection)
6. Click **Run Analysis** to queue selected records
7. Background flows process records asynchronously
8. Use **Refresh** on record pages to see results

## Manifest Files

| File | Use Case |
|------|----------|
| `package-sentiment-coaching-full.xml` | Full deployment with all components |
| `package-sentiment-coaching-without-permissionset.xml` | Skip permission set (use when Voice Call object conflicts exist) |
| `package-messaging-fields.xml` | Messaging Session fields only |
| `package-media-package.xml` | Media package subset |

## Troubleshooting

### Permission Set Deployment Fails
If deploying the permission set fails because Voice Call already exists:
1. Deploy using `package-sentiment-coaching-without-permissionset.xml`
2. Manually create a permission set with access to the 10 custom fields
3. Or deploy `Sentiment_Coaching_Fields_Only.permissionset-meta.xml` separately

### Historical Analysis Not Working
- Ensure the `Request_Historical_Analysis__c` field is deployed on both objects
- Verify all 4 historical flows are active
- Check that the user has the permission set assigned

### No Sentiment Data After Chat/Call Ends
- Verify transcript flows exist (`conv_sum_ms__GetTscpForMsgSession`, `conv_sum_vc__GetTscpForVoiceCall`)
- Check that GenAI is enabled and the model is available
- Ensure the record-triggered flows are active

## Scripts

The `scripts/` folder contains helpful Apex scripts:
- `CreateAndAssignSentimentCoachingPermissionSet.apex` - Create and assign the permission set programmatically
- `AssignSentimentCoachingPermissionSetToAdmins.apex` - Assign to admin users

## License

This project is provided as-is for demonstration and POC purposes.
