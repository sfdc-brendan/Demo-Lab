# Sentiment and Coaching

A demo package that adds **sentiment analysis** and **agent performance coaching** for **Voice** (Service Cloud Voice) and **Messaging** (chat) interactions. It uses Einstein generative AI prompt templates, flows, Apex, and Lightning Web Components to evaluate calls and chats and store results on Voice Call and Messaging Session records.

## What It Does

- **Voice (SCV)** – After a call, flows extract **call sentiment** and **agent performance** from transcript/content, then store ratings and evaluations on the **Voice Call** record. LWCs display coaching and sentiment on the call record.
- **Messaging** – After a chat, flows extract **chat sentiment** and **coaching** from the conversation, then store ratings and evaluations on the **Messaging Session** record. An LWC shows analytics on the session record.

All of this is powered by **Einstein Prompt Templates** (GenAI) and is intended for demo or pilot use in Service Cloud Voice and Messaging/Omni-Channel setups.

## What’s in This Package

| Category | Components | Purpose |
|----------|------------|---------|
| **Lightning Web Components** | `callCoaching`, `sentimentTracker`, `messagingSessionAnalytics` | Show coaching and sentiment on Voice Call and Messaging Session record pages |
| **Flows** | `SCV_Extract_Sentiment_After_Call`, `SCV_Extract_Agent_Performance_After_Call`, `MSG_Extract_Sentiment_After_Chat`, `MSG_Extract_Coaching_After_Chat` | Run after call/chat to call prompt templates and write results to the record |
| **GenAI Prompt Templates** | `Call_Sentiment`, `Agent_Performance_Evaluation`, `MSG_Chat_Sentiment`, `MSG_Chat_Coaching` | Used by the flows to analyze content and return sentiment/coaching text and ratings |
| **Apex** | `ChatCoachingExtractor`, `ChatExtractor`, `TextExtractor` | Support chat/messaging extraction and text processing used by the messaging flows |
| **Custom Fields** | On **Voice Call**: `Call_Sentiment__c`, `Sentiment_Rating__c`, `Agent_Performance_Evaluation__c`, `Agent_Performance_Rating__c`<br>On **Messaging Session**: `ChatSentiment__c`, `SentimentRating__c`, `AgentPerformanceEvaluation__c`, `AgentPerformanceRating__c` | Store sentiment and coaching output from the flows |

## Voice vs Messaging

| Capability | Voice (SCV) | Messaging |
|------------|-------------|-----------|
| **Sentiment** | Call sentiment and rating | Chat sentiment and rating |
| **Coaching** | Agent performance evaluation and rating | Agent performance evaluation and rating |
| **Trigger** | SCV post-call flows | MSG post-chat flows |
| **Record** | **Voice Call** | **Messaging Session** |
| **LWCs** | `callCoaching`, `sentimentTracker` | `messagingSessionAnalytics` |

## Where You Can Use It

- **Voice** – Orgs with **Service Cloud Voice** and **Voice Call** records. Add the LWCs to Voice Call record pages and run the SCV flows from your post-call automation.
- **Messaging** – Orgs with **Messaging** or **Omni-Channel** and **Messaging Session** records. Add the LWC to Messaging Session record pages and run the MSG flows from your post-chat automation.

Deploy the metadata (LWCs, Flows, Apex, GenAI Prompt Templates, and object/field metadata) into a sandbox or demo org, then configure the flows to run when calls or chats close.

## Prerequisites

- **Einstein** (e.g. prompt template / GenAI) features enabled.
- **Service Cloud Voice** (for voice) and/or **Messaging** (for chat) with Voice Call and/or Messaging Session in use.
- The custom fields above created on **Voice Call** and **Messaging Session** (included in this package’s object metadata).

## Package Layout

```
Sentiment and Coaching/
├── README.md (this file)
├── lwc/           # callCoaching, sentimentTracker, messagingSessionAnalytics
├── classes/       # ChatCoachingExtractor, ChatExtractor, TextExtractor
├── flows/         # SCV_*, MSG_* flows
├── genAiPromptTemplates/  # Agent_Performance_Evaluation, Call_Sentiment, MSG_Chat_*
└── objects/       # VoiceCall & MessagingSession fields (and related metadata)
```

To deploy only this package, point your Salesforce CLI or IDE at this folder (or at a `package.xml`/manifest that lists these components) and deploy to the target org.

## 📄 Disclaimer
This project is NOT an official Salesforce product.

Created by Brendan Sheridan as a demonstration accelerator. Use at your own risk. This code is provided "as-is" without warranty of any kind. Always review and test thoroughly before using in any production environment.

## 📝 License
This project is provided for educational and demonstration purposes. Feel free to use, modify, and adapt for your own Salesforce implementations.


