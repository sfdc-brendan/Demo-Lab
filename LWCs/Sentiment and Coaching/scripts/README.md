# Scripts

## Option 1: Create AND Assign (recommended)

**File:** `CreateAndAssignSentimentCoachingPermissionSet.apex`

This script does everything in one go:

1. **Creates** the permission set `Sentiment_Coaching_Fields` (if it doesn't exist).
2. **Adds field permissions** for all 10 Sentiment Coaching custom fields (5 on Voice Call, 5 on Messaging Session) with Read and Edit.
3. **Assigns** the permission set to all active System Administrator users.

### How to run

1. In your org (e.g. Winter 25), open **Developer Console**.
2. **Debug → Open Execute Anonymous Window**.
3. Paste the entire contents of `CreateAndAssignSentimentCoachingPermissionSet.apex`.
4. Check **Open Log** to see progress messages.
5. Click **Execute**.

That's it. The permission set is created, configured, and assigned to all admins.

---

## Option 2: Assign Only (if permission set already exists)

**File:** `AssignSentimentCoachingPermissionSetToAdmins.apex`

Use this if you've already deployed or created the permission set and just want to assign it to System Administrators.

### Prerequisite

The permission set must exist. Create it via:

- **CLI:** `sf project deploy start --metadata PermissionSet:Sentiment_Coaching_Fields_Only --target-org "Winter 25" --wait 10`
- **Setup:** Create manually in Setup → Permission Sets.

### How to run

1. **Developer Console → Debug → Open Execute Anonymous Window**.
2. Paste `AssignSentimentCoachingPermissionSetToAdmins.apex`.
3. **Execute**.

---

## Fields included

Both scripts grant Read and Edit on these 10 custom fields:

**Voice Call**
- Agent_Performance_Evaluation__c
- Agent_Performance_Rating__c
- Call_Sentiment__c
- Sentiment_Rating__c
- Request_Historical_Analysis__c

**Messaging Session**
- AgentPerformanceEvaluation__c
- AgentPerformanceRating__c
- ChatSentiment__c
- SentimentRating__c
- Request_Historical_Analysis__c
