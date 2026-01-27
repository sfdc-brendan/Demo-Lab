# RMA Process

Return Merchandise Authorization (RMA) package for Salesforce. Generates professional RMA PDFs from Case data and attaches them to Cases. Designed for use with **Agentforce** flows and invocable actions—**for demos only; do not use in production**.

## What This Package Does

- **Creates RMA documents** from Case and contact data (customer, product, issue details, resolution).
- **Renders PDFs** via a Visualforce template and attaches them to the Case as Files.
- **Supports Flow/Agentforce** via an invocable Apex action that can be called from Screen Flows or from AI agents (e.g., “Create Case and add Documentation”).

## Contents

| Type | Name | Purpose |
|------|------|---------|
| **Flow** | `Create_Case_and_add_Documentation` | Record-triggered or screen flow that creates a Case and calls the RMA action to generate and attach the RMA PDF. |
| **Apex (Invocable)** | `RMAGeneratorFlowAction` | Invocable method “Generate RMA Document and Attach to Case” used by the flow and by Agentforce actions. |
| **Apex** | `RMAGeneratorController` | Server-side logic to build RMA JSON, render the Visualforce PDF, and create ContentVersion + ContentDocumentLink. |
| **Apex** | `RMATemplateController` | Controller for the RMA Visualforce page; parses RMA JSON and exposes getters for the template. |
| **Visualforce** | `RMATemplate` | PDF layout for the RMA (header, customer/product/issue/resolution sections, optional return shipping label). |

## Prerequisites

- Salesforce org with **Agentforce** (or at least Flows and Apex) enabled.
- **Case** object; flow and invocable assume standard Case fields plus any custom fields you map.
- API version 58.0 or later.

## Deployment

Deploy the metadata in this folder into your org (e.g., via Salesforce CLI or IDE):

- `classes/` — Apex classes and `-meta.xml`
- `flows/` — Flow definition
- `pages/` — Visualforce page and `-meta.xml`

Ensure the flow, invocable action, and RMA template are activated as needed for your demo.

## Usage (Demos)

1. **From a Flow**: Add an **Action** element and choose **Generate RMA Document and Attach to Case** (`RMAGeneratorFlowAction`). Pass Case Id, customer/product/issue fields from the flow.
2. **From Agentforce**: Expose the same invocable as an **agent action** so an AI agent can “create a case and add RMA documentation” when the user asks for a return.
3. **From Apex/LWC**: Call `RMAGeneratorController.generateRMA(rmaDataJson)` with a JSON string containing `caseId`, `rmaNumber`, and the same field set the flow uses.

RMA numbers follow the pattern `RMA-YYYYMMDD-XXXX`. The generated PDF is stored as a File and linked to the Case.

## 📄 Disclaimer
This project is NOT an official Salesforce product.

Created by Brendan Sheridan as a demonstration accelerator. Use at your own risk. This code is provided "as-is" without warranty of any kind. Always review and test thoroughly before using in any production environment.

## 📝 License
This project is provided for educational and demonstration purposes. Feel free to use, modify, and adapt for your own Salesforce implementations.
