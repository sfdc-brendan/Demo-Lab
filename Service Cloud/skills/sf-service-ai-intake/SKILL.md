---
name: sf-service-ai-intake
description: Live-call AI form-fill experiences for Service Cloud Voice. Use when designing configurable intake templates that listen to the live transcript, extract structured answers via the Models API, suggest non-destructive answers in the UI, and dispatch results to a target SObject. Composes sf-service-voice-toolkit and sf-service-models-api.
disable-model-invocation: true
---
# AI-Assisted Intake on Voice and Digital

## Use This Skill When

- Designing CSR-facing intake forms (roadside, claims, complaints, service requests) that fill themselves while the customer talks.
- Replacing scenario-specific intake LWCs with a configurable, template-driven intake platform.
- Defining how AI suggestions, agent overrides, and final submissions interact safely on a regulated channel.
- Planning extension to digital channels (chat, messaging) using the same template + extractor pattern.

## Pattern Overview

1. **Intake template as data, not code**
 - Model the scenario as records: a template record, ordered question records, picklist values, visibility rules, translations, and an optional target SObject API name.
 - Treat developer-name as the stable contract between the AI extractor and the writeback target field.
2. **Runtime LWC stays generic**
 - One runtime renders any active template; it never knows the scenario.
 - The LWC composes the voice-toolkit transcript source and the Models API extractor, both as injected dependencies.
3. **Non-destructive merge is the rule**
 - AI suggestions populate empty answers and never overwrite a value the agent typed.
 - Agent edits always win over later AI passes for the same field.

## Core Workflow

1. **Design the template**
 - Define questions, types, picklist sources (static or live from a real picklist field), validation, visibility rules, and per-locale translations.
 - Decide writeback target: a real SObject (standard or custom) or a generic submission fallback for prototyping.
2. **Define the extraction contract**
 - Map every question's developer name into the prompt schema with answer type and constraints.
 - Add per-question extraction hints only when the surface text is ambiguous.
3. **Wire the runtime loop**
 - Subscribe to transcript events; debounce; send the rolling transcript plus the question schema to the extractor.
 - Apply returned answers via non-destructive merge; reflect status in the UI (answered, AI-suggested, empty).
4. **Submit**
 - Validate required fields; dispatch by template configuration to either the target SObject or the submission fallback.
 - Generate a transcript-anchored audit artifact (PDF, file, or record) at submit time.

## Guardrails

- The agent always controls submit. AI never auto-submits, even at full coverage.
- Surface confidence visibly: clearly distinguish agent-confirmed answers from AI-suggested answers in the UI.
- Never round-trip free text into a strict picklist field without enum validation against the live field metadata.
- Honor visibility rules at the prompt layer, not just the UI layer — do not ask the AI to extract fields the agent could not see.
- Localize question text and validation messages; never localize the developer-name contract.

## Deliverables

- Template design (questions, types, target object, visibility rules, translations).
- Extraction contract document tying developer-names to prompt schema and writeback fields.
- Runtime sequence (transcript source → debounce → extractor → merge → UI status → submit).
- Operational plan: failure routing for extractor errors, audit artifact policy, and prompt-version changelog.

## Related Skills

- **sf-service-voice-toolkit**: transcript source contract and debounce strategy.
- **sf-service-models-api**: prompt contract, structured output, and operational controls for the extractor.
- **sf-service-voice-digital**: channel-level rollout, handoff, and quality controls that wrap this pattern.
