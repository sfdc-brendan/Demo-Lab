---
name: sf-service-models-api
description: Trust Layer GenAI integration via aiplatform.ModelsAPI from Apex. Use when designing model selection, prompt strategy, structured output, response parsing, and operational controls for LLM calls embedded in Service Cloud workflows (case summarization, classification, extraction, drafting, agent assist).
disable-model-invocation: true
---
# Models API and Trust Layer Integration

## Use This Skill When

- Designing Apex-side GenAI calls through `aiplatform.ModelsAPI` (Models REST API behind the Einstein Trust Layer).
- Selecting which foundation model to route to for a given Service Cloud workflow.
- Defining prompt structure, structured-output contracts, and response-parsing strategy.
- Planning operational controls: PII handling, retries, latency budgets, governor-limit safety, and audit.

## Model Selection Framework

1. **Classify the task**
 - Generation, classification, extraction, summarization, embedding, or chained reasoning.
2. **Match task to model class**
 - Default to the org-provided GPT-class model for general extraction and summarization.
 - Choose a long-context or reasoning-tier model only when justified by transcript length, multi-doc context, or chain-of-reasoning needs.
 - Reserve embeddings models for retrieval and similarity, not for generation.
3. **Confirm availability and entitlement**
 - Verify the chosen model is enabled for the org and the running user's permission set.
 - Check Trust Layer policies for the data the prompt will carry (PII masking, retention, zero-data-retention routing).

## Core Workflow

1. **Define the prompt contract**
 - Separate the persona, the task instruction, the data payload, and the output specification.
 - State the output shape explicitly (strict JSON object with named keys, enum-constrained values, or plain text length cap).
2. **Constrain the output**
 - Enumerate every allowed value for picklist-style fields directly in the prompt.
 - Forbid free-text restating of inputs; require keys to be omitted when unknown rather than hallucinated.
3. **Call the Models API**
 - Centralize the request through one Apex service class so prompt versioning, model swaps, and telemetry happen in one place.
 - Set explicit timeouts and retries with backoff; never block the UI on a single synchronous call.
4. **Parse defensively**
 - Strip code fences and whitespace before deserialization.
 - Validate every returned key against the prompt contract; drop unknown keys, coerce or reject invalid values.
5. **Observe and iterate**
 - Log prompt version, model, latency, token usage, and validation outcome for every call.
 - Sample failures into a regression set and tune the prompt; never tune the consumer to absorb prompt drift.

## Guardrails

- Send only the minimum data needed; rely on Trust Layer masking, never on prompt-side instruction, to protect PII.
- Treat model output as untrusted: validate before writing to records, never `eval`, never inject into SOQL or HTML.
- Cap context size deterministically (truncate by speaker turn or by token budget) — do not let user input determine call cost.
- Fail closed on validation errors: surface the unparsed answer to a human, never silently write a malformed value.
- Version every prompt; treat prompt changes as code changes with review and changelog.

## Deliverables

- Model selection rationale with task class, model tier, and Trust Layer policy notes.
- Prompt contract document (persona, instruction, data envelope, output schema, examples).
- Apex service class boundary that encapsulates the API call, retries, telemetry, and parsing.
- Operational plan: latency budget, timeout, retry policy, failure routing, and prompt-version changelog.
