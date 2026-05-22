---
name: sf-service-models-api
description: Trust Layer GenAI integration via aiplatform.ModelsAPI from Apex. Use when designing or building model selection, prompt strategy, structured output, response parsing, and operational controls for LLM calls embedded in Service Cloud workflows (case summarization, classification, extraction, drafting, agent assist).
disable-model-invocation: true
---
# Models API and Trust Layer Integration

## Use This Skill When

- Designing or building Apex-side GenAI calls through `aiplatform.ModelsAPI` (Models REST API behind the Einstein Trust Layer).
- Selecting which foundation model to route to for a given Service Cloud workflow.
- Defining prompt structure, structured-output contracts, and response-parsing strategy.
- Planning operational controls: PII handling, retries, latency budgets, governor-limit safety, and audit.

## Quick Start (Code Patterns)

These four patterns cover ~90% of Models API integrations. Copy, adapt, ship. For full request/response shapes, model catalog, and retry/streaming patterns, see [reference.md](reference.md).

### 1. Apex service class skeleton

Centralize every GenAI call through one service class so prompt versioning, model swaps, and telemetry happen in one place. Use a constant for the model name; expose a test seam for mocking.

```apex
public with sharing class CaseSummarizer {

    private static final String MODEL_NAME = 'sfdc_ai__DefaultGPT4Omni';

    @TestVisible
    private static String mockResponse;

    @AuraEnabled
    public static String summarize(String caseDescription) {
        if (String.isBlank(caseDescription)) return null;

        String prompt = buildPrompt(caseDescription);
        String raw = callModel(prompt);
        if (String.isBlank(raw)) return null;

        return raw.trim();
    }

    private static String buildPrompt(String caseDescription) {
        return 'You are a Service Cloud agent assistant.\n\n'
            + 'CASE DESCRIPTION:\n' + caseDescription + '\n\n'
            + 'INSTRUCTIONS:\n'
            + '- Summarize in 2 sentences max.\n'
            + '- Plain text only. No markdown, no preamble.';
    }

    private static String callModel(String prompt) {
        if (Test.isRunningTest() && mockResponse != null) {
            return mockResponse;
        }

        aiplatform.ModelsAPI modelsAPI = new aiplatform.ModelsAPI();

        aiplatform.ModelsAPI_ChatMessageRequest msg = new aiplatform.ModelsAPI_ChatMessageRequest();
        msg.role = 'user';
        msg.content = prompt;

        aiplatform.ModelsAPI_ChatGenerationsRequest body = new aiplatform.ModelsAPI_ChatGenerationsRequest();
        body.messages = new List<aiplatform.ModelsAPI_ChatMessageRequest>{ msg };

        aiplatform.ModelsAPI.createChatGenerations_Request req =
            new aiplatform.ModelsAPI.createChatGenerations_Request();
        req.modelName = MODEL_NAME;
        req.body = body;

        aiplatform.ModelsAPI.createChatGenerations_Response resp =
            modelsAPI.createChatGenerations(req);

        if (resp.Code200 == null
            || resp.Code200.generationDetails == null
            || resp.Code200.generationDetails.generations == null
            || resp.Code200.generationDetails.generations.isEmpty()) {
            return null;
        }

        return resp.Code200.generationDetails.generations[0].content;
    }
}
```

### 2. Structured output via JSON-mode prompting

When you need keys+values back (extraction, classification), specify the contract in the prompt and parse defensively. Strip code fences before deserializing — models often wrap JSON in ` ```json ` blocks regardless of instruction.

```apex
private static String buildExtractionPrompt(String text) {
    return 'You are extracting fields from a customer message.\n\n'
        + 'TEXT:\n' + text + '\n\n'
        + 'INSTRUCTIONS:\n'
        + '- Respond ONLY with a valid JSON object with these keys:\n'
        + '  customer_name (string), severity (one of: Low, Medium, High), wants_callback (true/false).\n'
        + '- Omit a key when no clear answer exists. Do not invent values.\n'
        + '- No markdown, no code fences, no explanation.\n'
        + 'Example: {"customer_name":"Jane Doe","severity":"High"}';
}

private static Map<String, Object> parseJsonResponse(String raw) {
    if (String.isBlank(raw)) return new Map<String, Object>();
    String cleaned = raw.trim();

    if (cleaned.startsWith('```')) {
        cleaned = cleaned.replaceAll('```[a-zA-Z]*\\n?', '')
                         .replaceAll('```', '')
                         .trim();
    }

    try {
        return (Map<String, Object>) JSON.deserializeUntyped(cleaned);
    } catch (Exception e) {
        return new Map<String, Object>();
    }
}
```

### 3. Constrain enums in the prompt

For picklist-style fields, enumerate every allowed value directly. Validate after parse — never trust the model to obey.

```apex
private static final Set<String> VALID_SEVERITIES = new Set<String>{ 'Low', 'Medium', 'High' };

String severity = (String) parsed.get('severity');
if (severity != null && !VALID_SEVERITIES.contains(severity)) {
    severity = null; // drop invalid
}
```

### 4. Test mock pattern

Make the model call mockable so tests run offline and deterministically.

```apex
@IsTest
static void summarize_returnsModelOutput() {
    CaseSummarizer.mockResponse = 'Customer reports a flat tire on I-95. Roadside dispatched.';

    Test.startTest();
    String result = CaseSummarizer.summarize('Caller says they have a flat tire on I-95...');
    Test.stopTest();

    System.assertEquals(
        'Customer reports a flat tire on I-95. Roadside dispatched.',
        result
    );
}
```

## Model Selection Framework

1. **Classify the task**
 - Generation, classification, extraction, summarization, embedding, or chained reasoning.
2. **Match task to model class**
 - Default to the org-provided GPT-class model (`sfdc_ai__DefaultGPT4Omni`) for general extraction and summarization.
 - Choose a long-context or reasoning-tier model only when justified by transcript length, multi-doc context, or chain-of-reasoning needs.
 - Reserve embeddings models for retrieval and similarity, not for generation.
3. **Confirm availability and entitlement**
 - Verify the chosen model is enabled for the org and the running user's permission set.
 - Check Trust Layer policies for the data the prompt will carry (PII masking, retention, zero-data-retention routing).

See [reference.md](reference.md) for the full model catalog and selection cheat sheet.

## Guardrails

- Send only the minimum data needed; rely on Trust Layer masking, never on prompt-side instruction, to protect PII.
- Treat model output as untrusted: validate before writing to records, never `eval`, never inject into SOQL or HTML.
- Cap context size deterministically (truncate by speaker turn or by token budget) — do not let user input determine call cost.
- Fail closed on validation errors: surface the unparsed answer to a human, never silently write a malformed value.
- Version every prompt; treat prompt changes as code changes with review and changelog.
- One model call ≈ one HTTP callout = one transaction's callout limit slot. Batch carefully.

## Deliverables

- Model selection rationale with task class, model tier, and Trust Layer policy notes.
- Prompt contract document (persona, instruction, data envelope, output schema, examples).
- Apex service class boundary that encapsulates the API call, retries, telemetry, and parsing.
- Operational plan: latency budget, timeout, retry policy, failure routing, and prompt-version changelog.

## Additional Resources

- Full model catalog, request/response shapes, embeddings API, retry patterns, and limits: [reference.md](reference.md)
- Companion skill for the transcript source that feeds prompts: `sf-service-voice-toolkit`
- Companion skill for the composite intake pattern: `sf-service-ai-intake`
