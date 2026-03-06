# RMA Process

An **Agentforce** demo that lets an AI agent handle Return Merchandise Authorization (RMA) requests from customers. It collects product and issue details, creates a Case, generates a professional RMA PDF document, and routes the case to a support agent. **For demos only; do not use in production.**

## What It Does

When a customer contacts support to return a product, report a defect, or request a replacement, the agent:

1. **Detects** an RMA-related request from natural language (e.g., "I need to return this product", "My device is broken", "I want a replacement").
2. **Collects** the required details: product name, serial number, issue description, symptoms, and any troubleshooting steps already tried.
3. **Creates a Case** and generates a professional RMA PDF document attached to the Case as a File.
4. **Routes** the case to a support agent and notifies via Slack.
5. **Confirms** the RMA number and case details back to the customer.

---

## Components

| Component | Type | Purpose |
|-----------|------|---------|
| **RMA Process Agent** | GenAiPlugin (Topic) | Agentforce topic that defines when and how to handle RMA requests, when to call the action, and how to respond to the customer. |
| **Create RMA Case and Documentation** | GenAiFunction | Agent action that invokes the Flow to create a Case and generate the RMA document. |
| **Create Case and add Documentation** | Flow | Orchestrates: creates the Case, looks up Contact, calls the Apex RMA generator, routes work, and sends a Slack notification. |
| **RMAGeneratorFlowAction** | Apex (Invocable) | Invocable method "Generate RMA Document and Attach to Case" used by the flow. |
| **RMAGeneratorController** | Apex | Server-side logic to build RMA JSON, render the Visualforce PDF, and create ContentVersion + ContentDocumentLink. |
| **RMATemplateController** | Apex | Controller for the RMA Visualforce page; parses RMA JSON and exposes getters for the template. |
| **RMATemplate** | Visualforce | PDF layout for the RMA (header, customer/product/issue/resolution sections, optional return shipping label). |

---

## How They Work Together

```
Customer says: "My Toast Go 3 is broken, I need to return it"
    |
RMA Process Agent (Topic) recognizes RMA request
    |
Collects: product name, serial number, issue, symptoms
    |
Calls Create RMA Case and Documentation (GenAiFunction)
    |
Create Case and add Documentation (Flow) runs
    |
RMAGeneratorFlowAction (Apex) generates RMA PDF and attaches to Case
    |
Case is routed to support agent, Slack notification sent
    |
Agent confirms to customer: "Your RMA number is RMA-20260306-1234..."
```

---

## Prerequisites

- Salesforce org with **Agentforce** and **Einstein Generative AI** enabled.
- **Case** and **Contact** objects; flow assumes standard fields plus any custom fields you map.
- API version 58.0 or later.

## Deployment

Deploy the metadata in this folder into your org (e.g., via Salesforce CLI or IDE):

- `classes/` -- Apex classes and `-meta.xml`
- `flows/` -- Flow definition
- `pages/` -- Visualforce page and `-meta.xml`
- `genAiFunctions/` -- Agent action definition with input/output schemas
- `genAiPlugins/` -- Agent topic definition with instructions

```bash
sf project deploy start --source-dir "path/to/RMA Process"
```

Ensure your org has Agentforce enabled and that the Agent is configured to use the RMA Process Agent topic.

---

## Usage (Demos)

1. **From Agentforce**: The **RMA Process Agent** topic is automatically available when assigned to your agent. The agent will detect RMA requests and handle the full flow.
2. **From a Flow**: Add an **Action** element and choose **Generate RMA Document and Attach to Case** (`RMAGeneratorFlowAction`). Pass Case Id, customer/product/issue fields from the flow.
3. **From Apex/LWC**: Call `RMAGeneratorController.generateRMA(rmaDataJson)` with a JSON string containing `caseId`, `rmaNumber`, and the same field set the flow uses.

RMA numbers follow the pattern `RMA-YYYYMMDD-XXXX`. The generated PDF is stored as a File and linked to the Case.

---

## Requirements

* Salesforce org with Agentforce and GenAI features enabled
* API version 58.0+ (64.0 used in this metadata)
* Contact and Case objects; standard Case fields for Subject, Description, Priority, Status

---

## Repository

Part of Demo-Lab: LWCs, Apex, and Agentforce assets for demos. Not intended for production use.

## Disclaimer

This project is NOT an official Salesforce product.

Created by Brendan Sheridan as a demonstration accelerator. Use at your own risk. This code is provided "as-is" without warranty of any kind. Always review and test thoroughly before using in any production environment.

## License

This project is provided for educational and demonstration purposes. Feel free to use, modify, and adapt for your own Salesforce implementations.
