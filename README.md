# Demo-Lab

LWCs, Apex, Flows, Agentforce topics, and GenAI assets to use in demos. **Do not use these in production environments.**

A collection of ready-to-deploy Salesforce metadata and code for service, agent, and analytics demos—contact cards, sentiment and coaching, RMA document generation, and AI agents that collect feedback and create Cases.

---

## What’s in the Repo

### [Agentforce](./Agentforce/)

AI agent demos and sample metadata for Salesforce **Agentforce**. Requires an org with Agentforce and Einstein Generative AI enabled (API 60.0+).

| Package | Description |
|--------|-------------|
| **[Product Feature Feedback](./Agentforce/Product%20Feature%20Feedback/)** | Agent that detects product feedback from natural language, analyzes it with a GenAI prompt (category, sentiment, topic, escalation, routing), creates a Case routed to the right product team, and escalates critical issues. Includes a GenAiPlugin topic, GenAiFunction, Flow, GenAiPromptTemplate, and Apex processor. |
| **[RMA Process](./Agentforce/RMA%20Process/)** | Return Merchandise Authorization: generates RMA PDFs from Case and contact data, attaches them to Cases as Files, and exposes an invocable Apex action for Flows and Agentforce (“create case and add documentation”). Flow, invocable `RMAGeneratorFlowAction`, Visualforce PDF template, and supporting Apex. |

---

### [LWCs](./LWCs/)

Lightning Web Components and related metadata for record pages, service, and analytics.

| Package | Description |
|--------|-------------|
| **[sdo_ContactCard](./LWCs/sdo_ContactCard/)** | Configurable **Contact Card** LWC: profile, key details, up to 5 custom metrics, and a dual-line CSAT-style chart. Works on Contact, Case, Messaging Session, and Voice Call record pages (resolves Contact from the record). Theme, header color, and metrics configurable in App Builder. |
| **[Sentiment and Coaching](./LWCs/Sentiment%20and%20Coaching/)** | **Sentiment analysis** and **agent performance coaching** for **Service Cloud Voice** (calls) and **Messaging** (chat). Flows run after call/chat, call Einstein Prompt Templates to analyze content, and write sentiment/coaching ratings and text to Voice Call and Messaging Session. LWCs (`callCoaching`, `sentimentTracker`, `messagingSessionAnalytics`) display results on record pages. Includes Apex extractors, GenAI prompt templates, and custom fields on Voice Call and Messaging Session. |

---

## Quick Reference

| Category | Components |
|----------|------------|
| **Agentforce** | Product Feature Feedback (topic + action + flow + prompt), RMA Process (flow + invocable + VF PDF) |
| **LWCs** | sdo_ContactCard, callCoaching, sentimentTracker, messagingSessionAnalytics |
| **Flows** | Product Feature Feedback Flow, Create_Case_and_add_Documentation (RMA), SCV/MSG sentiment & coaching flows |
| **GenAI** | Product Feature Feedback Analyzer, Call_Sentiment, Agent_Performance_Evaluation, MSG_Chat_Sentiment, MSG_Chat_Coaching |
| **Apex** | ProductFeatureFeedbackProcessor, RMAGeneratorController, RMAGeneratorFlowAction, RMATemplateController, ChatCoachingExtractor, ChatExtractor, TextExtractor |

---

## Deployment

- **Root [package.xml](./package.xml)** – Lists LWCs, Apex, Flows, GenAiPromptTemplates, and CustomObjects for the Sentiment and Coaching package. Use it with Salesforce CLI or your CI/CD tooling.
- **Per-package** – Each folder (e.g. `Agentforce/Product Feature Feedback`, `Agentforce/RMA Process`, `LWCs/Sentiment and Coaching`) contains metadata in standard SFDX layout. Deploy with:
  ```bash
  sf project deploy start --source-dir "Agentforce/RMA Process"
  ```
  or your preferred manifest.

See each package’s README for prerequisites, object/field requirements, and configuration.

---

## Requirements (by area)

- **Agentforce packages**: Org with Agentforce and Einstein GenAI; API 58.0–65.0 as noted in each package.
- **sdo_ContactCard**: Contact (and, for Voice Call, a `Contact__c` lookup on Voice Call if used there).
- **Sentiment and Coaching**: Service Cloud Voice and/or Messaging; Voice Call and/or Messaging Session; Einstein/GenAI; custom fields on those objects (included in the package metadata).

---

## Disclaimer

The files in this repo are **not** an official Salesforce product.  
These are all related as a demonstration accelerator. Use at your own risk; code is provided “as-is” without warranty. Review and test thoroughly before using in any production environment.

---

## License

Provided for educational and demonstration purposes. Feel free to use, modify, and adapt for your own Salesforce implementations.
