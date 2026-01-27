# Product Feature Feedback

An **Agentforce** demo that lets an AI agent collect product feedback from users and automatically create Cases for Product teams to triage and act on. It uses sentiment analysis, categorization, escalation, and team routing so feedback is handled in the right place with the right priority.

**Use this in demos only. Do not use in production.**

---

## What It Does

When users share feedback about your product—complaints, bugs, or suggestions—the agent:

1. **Detects** product feedback from natural language (e.g., “The app is slow”, “Can you add dark mode?”, “I found a bug”).
2. **Analyzes** the feedback with a GenAI prompt to get:
   - **Category**: Complaint vs. Suggestion
   - **Sentiment**: Positive, Negative, or Neutral
   - **Feature topic**: e.g. User Interface, Mobile Experience, Performance, Security
   - **Escalation level**: Critical, High, Medium, or Low
   - **Routing**: Which team should own it (Engineering, Mobile, UX, Product, DevOps, Support)
3. **Creates a Case** with that analysis, routed to the right product team.
4. **Escalates** critical issues (e.g. system down, security) and tells the user their feedback was received and how it was routed.

---

## Components

| Component | Type | Purpose |
|-----------|------|---------|
| **Product Feature Feedback Agent** | GenAiPlugin (Topic) | Agentforce topic that defines when and how to collect feedback, when to call the action, and how to respond to the user. |
| **Process Product Feature Feedback** | GenAiFunction | Agent action that invokes the Flow to analyze feedback and create the Case. |
| **Product Feature Feedback Analyzer** | GenAiPromptTemplate | Prompt that takes raw feedback and returns structured JSON (category, sentiment, topic, escalation, routing, insights, actions). |
| **Product Feature Feedback Flow** | Flow | Orchestrates: calls the Analyzer prompt, parses the result, then invokes the Apex processor to create and route the Case. |
| **ProductFeatureFeedbackProcessor** | Apex Class | Invocable Apex that creates the Case, sets priority/routing, and handles escalation logic. |

---

## How They Work Together

```
User says: "The mobile app keeps crashing when I try to upload photos"
    ↓
Product Feature Feedback Agent (Topic) recognizes feedback
    ↓
Calls Process Product Feature Feedback (GenAiFunction)
    ↓
Product Feature Feedback Flow runs
    ↓
Product Feature Feedback Analyzer (Prompt) returns structured analysis
    ↓
ProductFeatureFeedbackProcessor (Apex) creates Case, sets routing & priority
    ↓
Agent confirms to user: "I've analyzed your feedback and routed it to Mobile Team with High priority..."
```

---

## Deploying to an Org

These components are **Salesforce metadata**. Deploy them with the Salesforce CLI or your CI/CD tooling:

1. **Copy** the `Agentforce/Product Feature Feedback` folder into your project’s `force-app` (or equivalent) source tree so paths match standard metadata layout (e.g. `classes/`, `flows/`, `genAiFunctions/`, etc.).
2. **Deploy** with:
   ```bash
   sf project deploy start --source-dir "path/to/Product Feature Feedback"
   ```
   Or add the metadata to your `package.xml` and run:
   ```bash
   sf project deploy start --manifest manifest/package.xml
   ```

Ensure your org has **Agentforce** and **Einstein Generative AI** enabled, and that the Agent is configured to use the Product Feature Feedback topic.

---

## Requirements

- Salesforce org with Agentforce and GenAI features enabled  
- API version 60.0+ (65.0 used in this metadata)  
- Contact and Case objects; standard Case fields for Subject, Description, Priority, Status  

---

## Repository

Part of [Demo-Lab](https://github.com/sfdc-brendan/Demo-Lab): LWCs, Apex, and Agentforce assets for demos. Not intended for production use.
