# Historical Analysis – Flow Setup

The **Historical Analysis Launcher** LWC finds Voice Calls and Messaging Sessions (up to 2 weeks old) that have no sentiment or coaching data and sets **Request Historical Analysis** on them. Four **historical** flows are included in this package and run when that checkbox is true.

## Included flows (deployed with the package)

| Flow API Name | Object | Trigger | What it does |
|---------------|--------|---------|--------------|
| **Historical_SCV_Extract_Sentiment_After_Call** | VoiceCall | Request_Historical_Analysis__c = true | Same as SCV Extract Sentiment; then clears the checkbox. |
| **Historical_SCV_Extract_Agent_Performance_After_Call** | VoiceCall | Request_Historical_Analysis__c = true | Same as SCV Extract Agent Performance; then clears the checkbox. |
| **Historical_MSG_Extract_Sentiment_After_Chat** | MessagingSession | Request_Historical_Analysis__c = true | Same as MSG Extract Sentiment; then clears the checkbox. |
| **Historical_MSG_Extract_Coaching_After_Chat** | MessagingSession | Request_Historical_Analysis__c = true | Same as MSG Extract Coaching; then clears the checkbox. |

Each historical flow:

1. Starts when the record is **updated** and **Request_Historical_Analysis__c** equals **true**.
2. Runs the same prompt + extract + update logic as the corresponding “after call/chat” flow.
3. Ends with a **Clear Historical Flag** step that sets **Request_Historical_Analysis__c = false** so the flow doesn’t re-trigger.

## Why separate flows?

- The **original** flows run when **CallDisposition = completed** or **Status = Ended** (future-facing).
- The **historical** flows run only when **Request_Historical_Analysis__c = true** (launcher sets this).
- Clearing the checkbox after each run prevents the same record from being processed again.

## After deploy

1. Deploy the package (includes **Request_Historical_Analysis__c** on VoiceCall and MessagingSession, the four historical flows, and the launcher LWC).
2. Add the **Historical Analysis Launcher** LWC to an App or Home page.
3. Use it to find records (last 7 or 14 days), select them, and run analysis. The historical flows process them in the background; users can use **Refresh** on the record page to see results.
