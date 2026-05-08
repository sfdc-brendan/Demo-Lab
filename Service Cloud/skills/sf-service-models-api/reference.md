# sf-service-models-api — Reference

Deep reference loaded only when the agent needs specific model names, request/response shapes, embeddings, or operational patterns. Primary patterns live in `SKILL.md`.

---

## Model Catalog (Org-Provided Defaults)

These names are the standard provisioned defaults. An org may have additional custom-named models — query `ai__GenAiModelConfig` to confirm.

| Model name | Class | Best for | Cost tier |
|---|---|---|---|
| `sfdc_ai__DefaultGPT4Omni` | OpenAI GPT-4o | General extraction, summarization, classification | Mid |
| `sfdc_ai__DefaultGPT4OmniMini` | OpenAI GPT-4o-mini | High-volume cheap classification, simple extraction | Low |
| `sfdc_ai__DefaultGPT35Turbo` | OpenAI GPT-3.5 Turbo | Legacy, basic generation, low cost | Low |
| `sfdc_ai__DefaultAnthropicClaude35Sonnet` | Anthropic Claude 3.5 Sonnet | Long-context reasoning, careful extraction | Mid |
| `sfdc_ai__DefaultGoogleGeminiPro` | Google Gemini Pro | Multimodal, long context | Mid |
| `sfdc_ai__DefaultOpenAIAdaV2` | OpenAI text-embedding-ada-002 | Embeddings for retrieval | Low |
| `sfdc_ai__DefaultOpenAITextEmbedding3Large` | OpenAI text-embedding-3-large | Higher-quality embeddings | Low-Mid |

### Selection cheat sheet

| Task | First choice | Why |
|---|---|---|
| Extract fields from short text (<1KB) | `sfdc_ai__DefaultGPT4OmniMini` | Cheap, fast, accurate enough |
| Extract fields from a live transcript (1–10KB rolling) | `sfdc_ai__DefaultGPT4Omni` | Sweet spot of accuracy + latency |
| Summarize 50+ transcript turns or multi-doc | `sfdc_ai__DefaultAnthropicClaude35Sonnet` | Best at maintaining long-context fidelity |
| Classify into 3–10 enum values | `sfdc_ai__DefaultGPT4OmniMini` | Cheap and accurate on enum tasks |
| Generate customer-facing email reply | `sfdc_ai__DefaultGPT4Omni` | Best balance of tone + reliability |
| Embed text for vector search | `sfdc_ai__DefaultOpenAITextEmbedding3Large` | Higher recall vs ada-v2 |

---

## Request/Response Shapes

### Chat generations request

```apex
aiplatform.ModelsAPI_ChatMessageRequest msg =
    new aiplatform.ModelsAPI_ChatMessageRequest();
msg.role = 'user';        // 'system' | 'user' | 'assistant'
msg.content = prompt;

aiplatform.ModelsAPI_ChatGenerationsRequest body =
    new aiplatform.ModelsAPI_ChatGenerationsRequest();
body.messages = new List<aiplatform.ModelsAPI_ChatMessageRequest>{ msg };
body.temperature = 0.0;        // optional, 0.0–2.0
body.max_tokens = 1000;        // optional cap
body.top_p = 1.0;              // optional, 0.0–1.0

aiplatform.ModelsAPI.createChatGenerations_Request req =
    new aiplatform.ModelsAPI.createChatGenerations_Request();
req.modelName = MODEL_NAME;
req.body = body;

aiplatform.ModelsAPI modelsAPI = new aiplatform.ModelsAPI();
aiplatform.ModelsAPI.createChatGenerations_Response resp =
    modelsAPI.createChatGenerations(req);
```

### Chat generations response shape

```text
resp.Code200
  .generationDetails
    .generations[]            // List
      .content                // String — the model output
      .role                   // 'assistant'
      .parameters             // Map of model-specific params used
    .parameters               // Map (token usage, finish reason, etc.)
      get('usage')            // { 'prompt_tokens': N, 'completion_tokens': N, 'total_tokens': N }
      get('finish_reason')    // 'stop' | 'length' | 'content_filter'
```

Always null-check the chain: `Code200 → generationDetails → generations → !isEmpty()`. Any link can be null on rate limit, content filter, or upstream error.

### HTTP status mapping

| Status | Meaning | Recommended action |
|---|---|---|
| `Code200` | Success | Parse `.generationDetails` |
| `Code400` | Bad request (malformed body) | Log and surface; don't retry |
| `Code401` | Trust Layer auth failure | Check permission set, model availability |
| `Code403` | Model not enabled for org | Surface to admin |
| `Code429` | Rate limited | Retry with exponential backoff |
| `Code500` | Upstream provider error | Retry once, then surface |
| `Code503` | Trust Layer / model temporarily unavailable | Retry with backoff |

---

## Embeddings API

For vector search and semantic similarity.

```apex
aiplatform.ModelsAPI_EmbeddingsRequest body =
    new aiplatform.ModelsAPI_EmbeddingsRequest();
body.input = new List<String>{ 'text to embed' };

aiplatform.ModelsAPI.createEmbeddings_Request req =
    new aiplatform.ModelsAPI.createEmbeddings_Request();
req.modelName = 'sfdc_ai__DefaultOpenAITextEmbedding3Large';
req.body = body;

aiplatform.ModelsAPI modelsAPI = new aiplatform.ModelsAPI();
aiplatform.ModelsAPI.createEmbeddings_Response resp = modelsAPI.createEmbeddings(req);

// resp.Code200.embeddingsList.embeddings[0].embedding  // List<Decimal>
```

Batch up to ~25 inputs per call to amortize latency. Each input has its own embedding in the response, indexed positionally.

---

## Retry Pattern

Models API calls fail intermittently on rate limits and upstream provider hiccups. Wrap calls in a small retry helper.

```apex
private static String callWithRetry(String prompt, Integer maxAttempts) {
    Integer attempt = 0;
    Exception lastError;
    while (attempt < maxAttempts) {
        try {
            return callModel(prompt);
        } catch (Exception e) {
            lastError = e;
            attempt++;
            if (attempt < maxAttempts) {
                // Exponential backoff: 200ms, 400ms, 800ms
                Long delayMs = (Long) (200 * Math.pow(2, attempt - 1));
                Long until = System.currentTimeMillis() + delayMs;
                while (System.currentTimeMillis() < until) { /* wait */ }
            }
        }
    }
    throw new AuraHandledException('Model call failed after retries: ' + lastError.getMessage());
}
```

For higher-volume use cases, move to Queueable + Platform Events instead of in-loop retries.

---

## Token Budget Math

Keep prompts small. Token budget rule of thumb: 1 token ≈ 4 characters of English.

| Model | Context window | Practical input target | Practical output target |
|---|---|---|---|
| GPT-4o | 128K tokens | 4K–16K input | 500–2000 output |
| GPT-4o-mini | 128K tokens | 4K–8K input | 250–1000 output |
| Claude 3.5 Sonnet | 200K tokens | 8K–32K input | 500–4000 output |
| Gemini Pro | 32K tokens | 4K–16K input | 500–2000 output |

For voice transcript work: a typical 5-minute call is 1500–2500 tokens. A 15-minute call comfortably fits in any modern context window. Truncate by speaker turn (oldest first) when capping.

---

## Operational Patterns

### Per-call telemetry

Wrap every Models API call in a logging boundary. Capture model name, prompt version, latency, token usage, and validation outcome.

```apex
public class ModelCallLog {
    public String modelName;
    public String promptVersion;
    public Long latencyMs;
    public Integer promptTokens;
    public Integer completionTokens;
    public String finishReason;
    public Boolean validationPassed;
}
```

Persist to a custom object (`Model_Call_Log__c`) or a Platform Event for ops dashboards.

### Prompt versioning

Treat prompts as code. Three options:

1. **Inline constant** — simplest. Bump a version string in the Apex class.
2. **Custom Metadata Type** — `Prompt_Template__mdt` with active flag. Lets non-devs A/B test.
3. **Custom Setting** — runtime-mutable. Use only when admin override is genuinely needed.

Always log the prompt version with each call so failures can be traced to a specific prompt revision.

### PII discipline

The Einstein Trust Layer masks PII server-side using rule sets configured at the org level. Never rely on prompt-side instruction ("don't repeat names back") for PII protection.

If you must redact before sending (additional defense-in-depth), use a centralized helper:

```apex
public static String redactSSN(String text) {
    if (String.isBlank(text)) return text;
    return text.replaceAll('\\b\\d{3}-\\d{2}-\\d{4}\\b', '[SSN-REDACTED]');
}
```

### Governor limits to watch

| Limit | Per transaction | Notes |
|---|---|---|
| Callouts | 100 | Each `createChatGenerations` is one callout |
| Total callout time | 120 seconds | Models API calls are 1–10s each |
| Heap | 6MB sync / 12MB async | Long transcripts + responses can blow this |
| CPU time | 10s sync / 60s async | Prompt building + parsing is cheap; model wait does not count |

Move long batch processing to Queueable. Streaming responses are not currently supported through `aiplatform.ModelsAPI` — for streaming, use Connect REST API directly via `HttpRequest`.

---

## Anti-Patterns to Avoid

| Anti-pattern | Why it fails | Do this instead |
|---|---|---|
| Hardcoding model name in every method | Can't swap models per env | Single `MODEL_NAME` constant per service class |
| Calling Models API from a `before` trigger | Synchronous callout in a trigger context fails | Move to Queueable or Platform Event handler |
| Parsing model output with `JSON.deserialize` (typed) | Field mismatches throw | `JSON.deserializeUntyped` then validate keys |
| Raising the actual model error message to the UI | Leaks model internals, confusing to CSRs | Catch, log, surface a generic "AI assist unavailable" message |
| `Integer.valueOf(modelOutput)` without try/catch | Model returns "five" not "5" | Wrap conversions, fall back to null on parse fail |
| One-shot prompt with no examples | Inconsistent output shape | Include 1–2 examples in the prompt for any non-trivial schema |
