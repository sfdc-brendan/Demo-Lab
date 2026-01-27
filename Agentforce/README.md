# Agentforce

Agentforce demos and sample metadata for Salesforce AI agents. Use these in demos only—**do not use in production**.

## Contents

| Folder | Description |
|--------|-------------|
| [Product Feature Feedback](./Product%20Feature%20Feedback/) | Agent that collects product feedback, analyzes it with GenAI, and creates Cases routed to the right product team with escalation. |
| [RMA Process](./RMA%20Process/) | RMA (Return Merchandise Authorization) package: generates RMA PDFs from Case data, attaches them to Cases, and exposes an invocable action for Flows and Agentforce (create case + add documentation). |

## Requirements

- Salesforce org with **Agentforce** and **Einstein Generative AI** enabled  
- API version 60.0 or later  

See each subfolder’s README for deployment and usage details.
