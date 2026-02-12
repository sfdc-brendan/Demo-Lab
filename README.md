# Demo-Lab

LWCs, Apex, Flows, Agentforce topics, and GenAI assets to use in demos. **Do not use these in production environments.**

A collection of ready-to-deploy Salesforce metadata and code for service, agent, and analytics demos—contact cards, sentiment and coaching, RMA document generation, AI-powered case tagging, and AI agents that collect feedback and create Cases.

---

## What's in the Repo

### [Agentforce](./Agentforce/)

AI agent demos and sample metadata for Salesforce **Agentforce**. Requires an org with Agentforce and Einstein Generative AI enabled (API 60.0+).

| Package | Description |
|--------|-------------|
| **[Product Feature Feedback](./Agentforce/Product%20Feature%20Feedback/)** | Agent that detects product feedback from natural language, analyzes it with a GenAI prompt (category, sentiment, topic, escalation, routing), creates a Case routed to the right product team, and escalates critical issues. Includes a GenAiPlugin topic, GenAiFunction, Flow, GenAiPromptTemplate, and Apex processor. |
| **[RMA Process](./Agentforce/RMA%20Process/)** | Return Merchandise Authorization: generates RMA PDFs from Case and contact data, attaches them to Cases as Files, and exposes an invocable Apex action for Flows and Agentforce ("create case and add documentation"). Flow, invocable `RMAGeneratorFlowAction`, Visualforce PDF template, and supporting Apex. |

---

### [LWCs](./LWCs/)

Lightning Web Components and related metadata for record pages, service, and analytics.

| Package | Description |
|--------|-------------|
| **[Modern Contact Card](./LWCs/Modern%20Contact%20Card/)** | Configurable **Contact Card** LWC: profile with header background banner, health score pill (color-coded 0-100), contact tags, **brand affinities** (up to 4 brand logos/badges), up to 6 custom metrics, and a dual-line CSAT-style chart. Works on Contact, Case, Messaging Session, and Voice Call record pages (resolves Contact from the record). Light/dark theme, all sections toggleable and configurable in App Builder. *(Component API name: `modernContactCard`.)* |
| **[Incident Dashboard](./LWCs/Incident%20Dashboard/)** | **Active Incidents** dashboard LWC: grid of cards showing open Service Cloud Incidents and their related Cases (via CaseRelatedIssue). For Home and App pages. Includes Apex `IncidentDashboardController`. Works with [Incident Detection](./Service%20Cloud/Incident%20Detection/) data. *(Component API name: `incidentDashboard`.)* |
| **[Sentiment and Coaching](./LWCs/Sentiment%20and%20Coaching/)** | **Sentiment analysis** and **agent performance coaching** for **Service Cloud Voice** (calls) and **Messaging** (chat). Flows run after call/chat, call Einstein Prompt Templates to analyze content, and write sentiment/coaching ratings and text to Voice Call and Messaging Session. LWCs (`callCoaching`, `sentimentTracker`, `messagingSessionAnalytics`) display results on record pages. Includes Apex extractors, GenAI prompt templates, and custom fields on Voice Call and Messaging Session. |

---

### [Service Cloud](./Service%20Cloud/)

Service Cloud demos: incident detection, Case-related automation, case tagging, and GenAI.

| Package | Description |
|--------|-------------|
| **[Incident Detection](./Service%20Cloud/Incident%20Detection/)** | **Real-time incident detection** for Cases. Record-triggered flow on Case create: summarizes the Case with GenAI, then invokes Apex to compare against recent open Cases. When a pattern is found, creates or reuses an **Incident** and **CaseRelatedIssue** links. Includes Flow `SDO_Service_Case_RealTime_Incident`, Apex `CaseIncidentHandler`, and GenAI prompt templates `Case_Summarizer`, `Case_RealTime_Similarity`. **Prerequisite:** Create custom field `Case.AI_Summary__c` (Long Text Area) before deploying. |
| **[Email OTP](./Service%20Cloud/Email%20OTP/)** | **Email OTP**: one-time 6-digit verification codes sent to the contact's email. LWC on Contact page (send code + verify); Apex `CustomerVerificationCodeService` and custom object `Customer_Verification_Code__c`. Email-only; SMS not included. |
| **[Case Tagging](./Service%20Cloud/Case%20Tagging/)** | **AI-powered case tagging**: analyzes Case subject, description, type, priority, origin, and status with Einstein GenAI to produce comma-separated tags (e.g. criticality, category). Includes LWC on Case record page (`caseTags`), **Case Tag Trends** dashboard LWC (`caseTagTrends`), invocable and batch for historical backfill, autolaunched flows and GenAI prompt templates. Custom fields on Case and custom metadata for configuration. See package README for mermaid diagram and setup. |

---

## Quick Reference

| Category | Components |
|----------|------------|
| **Agentforce** | Product Feature Feedback (topic + action + flow + prompt), RMA Process (flow + invocable + VF PDF) |
| **Service Cloud** | Incident Detection (flow + Apex + GenAI prompts), Email OTP (LWC + Apex, email verification), **Case Tagging** (LWCs + flows + GenAI + invocable + batch) |
| **LWCs** | Modern Contact Card (modernContactCard), Incident Dashboard (incidentDashboard), customerVerification (Email OTP), **caseTags**, **caseTagTrends**, callCoaching, sentimentTracker, messagingSessionAnalytics |
| **Flows** | Product Feature Feedback Flow, Create_Case_and_add_Documentation (RMA), SDO_Service_Case_RealTime_Incident (Incident Detection), **Case_Tagging_Analysis_Flow**, **Case_Tagging_Trends_Summary_Flow**, SCV/MSG sentiment & coaching flows |
| **GenAI** | Product Feature Feedback Analyzer, Case_Summarizer, Case_RealTime_Similarity, **Case_Tagging_Analysis**, **Case_Tagging_Trends_Summary**, Call_Sentiment, Agent_Performance_Evaluation, MSG_Chat_Sentiment, MSG_Chat_Coaching |
| **Apex** | ProductFeatureFeedbackProcessor, CaseIncidentHandler, CaseIncidentQueueable, CaseBacklogBatch, IncidentDashboardController, CustomerVerificationCodeService, **CaseTaggingService**, **CaseTaggingController**, **CaseTaggingInvocable**, **CaseTaggingBatch**, **CaseTaggingTrendsController**, RMAGeneratorController, RMAGeneratorFlowAction, RMATemplateController, ChatCoachingExtractor, ChatExtractor, TextExtractor |

---

## Deployment

- **Root [package.xml](./package.xml)** – Lists LWCs, Apex, Flows, GenAiPromptTemplates, and CustomObjects for the Sentiment and Coaching package. Use it with Salesforce CLI or your CI/CD tooling.
- **Per-package** – Each folder (e.g. `Agentforce/Product Feature Feedback`, `Agentforce/RMA Process`, `Service Cloud/Incident Detection`, `Service Cloud/Email OTP`, `Service Cloud/Case Tagging`, `LWCs/Incident Dashboard`, `LWCs/Modern Contact Card`, `LWCs/Sentiment and Coaching`) contains metadata in standard SFDX layout. Deploy with:
 ```bash
 sf project deploy start --source-dir "Agentforce/RMA Process"
 sf project deploy start --source-dir "Service Cloud/Incident Detection"
 sf project deploy start --source-dir "Service Cloud/Email OTP"
 sf project deploy start --source-dir "Service Cloud/Case Tagging"
 sf project deploy start --source-dir "LWCs/Incident Dashboard"
 sf project deploy start --source-dir "LWCs/Modern Contact Card"
 ```
 or your preferred manifest.

See each package's README for prerequisites, object/field requirements, and configuration.

---

## Requirements (by area)

- **Agentforce packages**: Org with Agentforce and Einstein GenAI; API 58.0–65.0 as noted in each package.
- **Incident Detection**: Service Cloud (Case, Incident, CaseRelatedIssue); Einstein GenAI; create custom field **Case.AI_Summary__c** (Long Text Area) before deploying. See [Service Cloud/Incident Detection](./Service%20Cloud/Incident%20Detection/) README.
- **Email OTP** (folder: [Service Cloud/Email OTP](./Service%20Cloud/Email%20OTP/)): Contact with Email; assign **OTP Verification** permission set; add **Customer Verification (OTP)** LWC to Contact page. See package README.
- **Case Tagging** (folder: [Service Cloud/Case Tagging](./Service%20Cloud/Case%20Tagging/)): Service Cloud (Case); Einstein GenAI; API 65.0+. Custom fields and custom metadata are included. Assign **Case Tagging** permission set; add **Case Tags** LWC to Case record page and **Case Tag Trends** to a tab or app page. See package README and SETUP.md.
- **Modern Contact Card** (folder: [LWCs/Modern Contact Card](./LWCs/Modern%20Contact%20Card/)): Contact; custom fields included (health score, tags, brand affinities); assign **Modern Contact Card Access** permission set. For Voice Call, configure the Contact lookup field name in App Builder.
- **Incident Dashboard** (folder: [LWCs/Incident Dashboard](./LWCs/Incident%20Dashboard/)): Service Cloud (Incident, CaseRelatedIssue, Case). Optional companion to Incident Detection for displaying active incidents on Home/App pages.
- **Sentiment and Coaching**: Service Cloud Voice and/or Messaging; Voice Call and/or Messaging Session; Einstein/GenAI; custom fields on those objects (included in the package metadata).

---

## Disclaimer

The files in this repo are **not** an official Salesforce product. 
These are all related as a demonstration accelerator. Use at your own risk; code is provided "as-is" without warranty. Review and test thoroughly before using in any production environment.

---

## License

Provided for educational and demonstration purposes. Feel free to use, modify, and adapt for your own Salesforce implementations.
