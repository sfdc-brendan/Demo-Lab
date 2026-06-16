---
name: sf-service-data-api-operations
description: Service Cloud data-only configuration strategy. Use when features are API-capable but not metadata-deployable and must be moved with data APIs, scripts, or seeded records.
disable-model-invocation: true
---
# Service Cloud Data API Operations

## Use This Skill When

- You are implementing features that cannot be deployed via Metadata API.
- You need an approach for `Macro`, `QuickText`, survey objects, swarming records, or similar setup records.
- You need repeatable data migration and idempotent upsert patterns for Service Cloud config data.

## Core Workflow

1. **Inventory data-only entities**
   - Confirm object-level support and required fields.
   - Identify reference dependencies (queues, users, skills, record types).
2. **Choose data movement strategy**
   - Prefer external ID driven upserts for idempotency.
   - Separate seed records from mutable operational records.
3. **Define CLI/data scripts**
   - Use `sf data query` for extraction and validation.
   - Use `sf data upsert bulk` or `sf data import tree` for load patterns.
4. **Harden sequence + retries**
   - Create load order for parent/child dependencies.
   - Add retry handling and dead-letter output for failed records.
5. **Validate behavior**
   - Verify object record counts, key field values, and activation states.
   - Document manual post-load checks in Setup where needed.

## Deliverables

- Data-only feature inventory with dependency graph.
- Idempotent load scripts and command sequence.
- Validation checklist and reconciliation queries.
- Cutover and rollback guidance for record operations.
