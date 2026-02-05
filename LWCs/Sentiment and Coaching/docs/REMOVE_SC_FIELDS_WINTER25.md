# Removing _Sc Messaging Session Fields in Winter 25

The org has the old **\_Sc** custom fields (e.g. `AgentPerformanceEvaluation_Sc__c`) and flow versions that still reference them, so Salesforce blocks deleting those fields until the references are removed.

**Source is already correct:** All flows and LWCs in this project use only the **original** Messaging Session field names (no _Sc). After you clear the references and _Sc fields in the org, a normal deploy will keep everything using the original fields.

## Steps in Winter 25

### 1. Delete the four flows that reference _Sc

In **Setup → Flows**, delete these flows (they will be recreated when you deploy the project):

- **MSG_Extract_Coaching_After_Chat**
- **MSG_Extract_Sentiment_After_Chat**
- **Historical_MSG_Extract_Coaching_After_Chat**
- **Historical_MSG_Extract_Sentiment_After_Chat**

(Use the dropdown on each flow → **Delete**.)

### 2. Delete the five _Sc custom fields

In **Setup → Object Manager → Messaging Session → Fields & Relationships**, delete:

- Agent Performance Evaluation Sc (`AgentPerformanceEvaluation_Sc__c`)
- Agent Performance Rating Sc (`AgentPerformanceRating_Sc__c`)
- Chat Sentiment Sc (`ChatSentiment_Sc__c`)
- Request Historical Analysis Sc (`Request_Historical_Analysis_Sc__c`)
- Sentiment Rating Sc (`SentimentRating_Sc__c`)

### 3. Deploy the project

From the project root:

```bash
sf project deploy start --source-dir force-app/main/default --target-org "Winter 25" --wait 15
```

This redeploys the four flows (using the **original** field names only) and the rest of the app. After this, only the original Messaging Session fields are used and the _Sc fields are gone.
