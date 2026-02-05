# Create Unmanaged Package in Winter 25

Create the Sentiment Coaching **unmanaged package** in your Winter 25 org so you can upload it and install the app into other orgs. The package is “logged” and managed in Winter 25.

**Prerequisite:** The Sentiment Coaching metadata must already be deployed to Winter 25 (Apex, custom fields, flows, Gen AI prompts, LWCs). If not, run:

```bash
sf project deploy start --manifest manifest/package-sentiment-coaching-without-permissionset.xml --target-org "Winter 25" --wait 15
```

---

## Steps in Winter 25

### 1. Open Packaging

1. Log into **Winter 25**.
2. **Setup** (gear) → in Quick Find type **Packaging** → **Packaging** (or **Create** → **Packages**).
3. Click **New** (for an unmanaged package).

### 2. Define the package

- **Package Name:** e.g. `Sentiment Coaching`
- **Description:** e.g. `Agent performance and sentiment analytics for Voice Call and Messaging Session.`
- **Organization-Wide Sharing:** choose **Unrestricted** (or as required).
- **Language:** your default.
- Click **Save**.

### 3. Add components

Use **Add Components** and add everything below. You can add by type or search by name.

**Apex Classes (4)**  
- ChatCoachingExtractor  
- ChatExtractor  
- HistoricalAnalysisController  
- TextExtractor  

**Custom Fields (10)**  
- **Messaging Session:** Agent Performance Evaluation, Agent Performance Rating, Chat Sentiment, Request Historical Analysis, Sentiment Rating  
- **Voice Call:** Agent Performance Evaluation, Agent Performance Rating, Call Sentiment, Request Historical Analysis, Sentiment Rating  

**Flows (8)**  
- Historical MSG Extract Coaching After Chat  
- Historical MSG Extract Sentiment After Chat  
- Historical SCV Extract Agent Performance After Call  
- Historical SCV Extract Sentiment After Call  
- MSG Extract Coaching After Chat  
- MSG Extract Sentiment After Chat  
- SCV Extract Agent Performance After Call  
- SCV Extract Sentiment After Call  

**Lightning Web Components (4)**  
- historicalAnalysisLauncher  
- messagingSessionAnalytics  
- sentimentTracker  
- voiceCallAnalytics  

**Gen AI Prompt Templates (4)**  
- Agent Performance Evaluation  
- Call Sentiment  
- MSG Chat Coaching  
- MSG Chat Sentiment  

**Permission set (optional)**  
- If you want the package to include a permission set and it deploys successfully in your org, add **Sentiment Coaching Fields** or **Sentiment Coaching Fields Only**. If adding it causes install issues in target orgs (e.g. they already have Voice Call), omit it and have admins create field permissions in the target org.

### 4. Upload the package

1. On the package detail page, click **Upload**.
2. Accept the checklist (e.g. no Apex that isn’t in the package, etc.).
3. Complete upload. Winter 25 will generate a **Package ID** and (for unmanaged) an **Install Link** or **Install URL**.

### 5. Log / save the package info

- Note the **Package ID** and **Install URL** from the package record in Winter 25.
- You can paste the Install URL into a browser (logged in as the target org user) to install into another org.
- The package is now “logged” and managed in Winter 25; re-upload after making changes to refresh the installable version.

---

## Quick reference – component list

| Type            | Count | Names |
|-----------------|-------|--------|
| Apex Class      | 4     | ChatCoachingExtractor, ChatExtractor, HistoricalAnalysisController, TextExtractor |
| Custom Field    | 10    | 5 on Messaging Session, 5 on Voice Call (see above) |
| Flow            | 8     | All MSG_* and SCV_* / Historical_* flows listed above |
| LWC             | 4     | historicalAnalysisLauncher, messagingSessionAnalytics, sentimentTracker, voiceCallAnalytics |
| GenAiPromptTemplate | 4  | Agent_Performance_Evaluation, Call_Sentiment, MSG_Chat_Coaching, MSG_Chat_Sentiment |
| Permission Set  | 0 or 1 | Optional: Sentiment_Coaching_Fields or Sentiment_Coaching_Fields_Only |
