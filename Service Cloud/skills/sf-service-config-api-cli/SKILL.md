---
name: sf-service-config-api-cli
description: Service Cloud feature-to-API/CLI mapping and deployment planning. Use when translating Service Cloud features into metadata deploys, data API operations, and repeatable sf CLI execution plans.
disable-model-invocation: true
---
# Service Cloud Feature Config APIs + CLI

## Use This Skill When

- You need to convert a Service Cloud requirement into exact API surface and `sf` CLI commands.
- You are building an implementation backlog that separates metadata, data-only, and UI-only configuration.
- You need deployment-safe packaging guidance for mixed Service Cloud features.

## Core Workflow

1. **Classify each feature**
   - Tag as `metadata-deployable`, `data API only`, or `setup UI only`.
   - Capture API type (`Metadata`, `REST`, `SOAP`, `Tooling`) and deploy path.
2. **Map to deploy units**
   - Group metadata by type for atomic deploys (for example: `CaseSettings`, `AssignmentRules`, `QueueRoutingConfig`).
   - Keep high-risk changes in isolated deploy batches.
3. **Map data-only operations**
   - Define seed/import/update strategy for records such as `Macro`, `QuickText`, survey records, and other non-metadata entities.
4. **Generate execution plan**
   - Produce ordered `sf project deploy start --metadata ...` commands.
   - Add post-deploy data operations and verification checks.
5. **Add rollback + validation**
   - Define validation commands and smoke tests by feature area.
   - Add rollback handling for metadata and data separately.

## Deliverables

- Feature-to-API/CLI matrix for requested scope.
- Ordered deployment runbook with `sf` commands.
- Data-only seeding and validation plan.
- Top dependency risks and mitigation actions.
