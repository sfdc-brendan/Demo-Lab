/**
 * Wraps the Salesforce Models API so the rest of the debugger talks to Claude
 * through one place.
 *
 * The Models API exposes hyperparameters through the AI Models configuration rather
 * than the request body, so there is deliberately nothing here for temperature or
 * max tokens. To change them, create a custom model configuration in Setup and point
 * MODEL_NAME at its API name.
 */
public with sharing class LogClaudeService {
  public class ModelException extends Exception {
  }

  public static final String MODEL_SONNET_45 = 'sfdc_ai__DefaultBedrockAnthropicClaude45Sonnet';
  public static final String MODEL_OPUS_45 = 'sfdc_ai__DefaultBedrockAnthropicClaude45Opus';

  /** Swappable so a demo can move to Opus without a redeploy. */
  public static String modelName = MODEL_SONNET_45;

  /**
   * Lets tests exercise the pipeline without a live model call. Production code
   * never sets this; LogClaudeServiceTest and the controller tests do.
   */
  @TestVisible
  private static Responder responder;

  public interface Responder {
    String respond(String systemPrompt, String userPrompt);
  }

  public class Reply {
    public String content;
    public String model;
    public Integer totalTokens;
  }

  /** Sends a system and user turn to Claude and returns the raw text reply. */
  public static String chat(String systemPrompt, String userPrompt) {
    return send(systemPrompt, userPrompt).content;
  }

  /**
   * Sends a turn and parses the reply as a JSON object.
   *
   * Models wrap JSON in markdown fences often enough that tolerating it is worth
   * more than a stricter prompt would be, so the fence is stripped before parsing
   * rather than treated as a failure.
   */
  public static Map<String, Object> chatJson(
    String systemPrompt,
    String userPrompt
  ) {
    String raw = chat(systemPrompt, userPrompt);
    String payload = extractJsonObject(raw);

    try {
      return (Map<String, Object>) JSON.deserializeUntyped(payload);
    } catch (Exception e) {
      throw new ModelException(
        'The model returned a response that could not be read as JSON. ' +
          'Try running the analysis again. Raw reply started: ' +
          raw.abbreviate(200)
      );
    }
  }

  public static Reply send(String systemPrompt, String userPrompt) {
    if (responder != null) {
      Reply stubbed = new Reply();
      stubbed.content = responder.respond(systemPrompt, userPrompt);
      stubbed.model = 'stub';
      stubbed.totalTokens = 0;
      return stubbed;
    }

    aiplatform.ModelsAPI.createChatGenerations_Response response;
    try {
      response = new aiplatform.ModelsAPI()
        .createChatGenerations(buildRequest(systemPrompt, userPrompt));
    } catch (Exception e) {
      throw new ModelException(
        'The call to ' + modelName + ' failed: ' + e.getMessage()
      );
    }

    return toReply(response);
  }

  /** Assembles the chat request. A blank system prompt is omitted rather than sent empty. */
  @TestVisible
  private static aiplatform.ModelsAPI.createChatGenerations_Request buildRequest(
    String systemPrompt,
    String userPrompt
  ) {
    aiplatform.ModelsAPI_ChatGenerationsRequest body = new aiplatform.ModelsAPI_ChatGenerationsRequest();
    body.messages = new List<aiplatform.ModelsAPI_ChatMessageRequest>();
    if (String.isNotBlank(systemPrompt)) {
      body.messages.add(message('system', systemPrompt));
    }
    body.messages.add(message('user', userPrompt));

    aiplatform.ModelsAPI.createChatGenerations_Request request = new aiplatform.ModelsAPI.createChatGenerations_Request();
    request.modelName = modelName;
    request.body = body;
    return request;
  }

  /**
   * Validates a Models API response and pulls the completion out of it.
   *
   * Split from send() so the response handling can be covered without a live call.
   * Everything above this line is I/O; this is the logic worth testing.
   */
  @TestVisible
  private static Reply toReply(
    aiplatform.ModelsAPI.createChatGenerations_Response response
  ) {
    if (
      response == null ||
      response.responseCode != 200 ||
      response.Code200 == null
    ) {
      Integer code = response == null ? null : response.responseCode;
      throw new ModelException(
        'The model returned HTTP ' + code + ' instead of a completion.'
      );
    }

    List<aiplatform.ModelsAPI_ChatMessage> generations = response.Code200.generationDetails ==
      null
      ? null
      : response.Code200.generationDetails.generations;

    if (generations == null || generations.isEmpty()) {
      throw new ModelException('The model returned an empty completion.');
    }

    Reply reply = new Reply();
    reply.content = generations[0].content;
    readUsage(response, reply);
    return reply;
  }

  private static aiplatform.ModelsAPI_ChatMessageRequest message(
    String role,
    String content
  ) {
    aiplatform.ModelsAPI_ChatMessageRequest turn = new aiplatform.ModelsAPI_ChatMessageRequest();
    turn.role = role;
    turn.content = content;
    return turn;
  }

  /**
   * Pulls the model identifier and token count out of the response.
   *
   * The parameters payload is loosely typed by the generated External Services
   * classes, so it is read through untyped JSON rather than by field access. This
   * is telemetry for the UI, never load-bearing, so any failure is swallowed.
   */
  private static void readUsage(
    aiplatform.ModelsAPI.createChatGenerations_Response response,
    Reply reply
  ) {
    try {
      Map<String, Object> parameters = (Map<String, Object>) JSON.deserializeUntyped(
        JSON.serialize(response.Code200.generationDetails.parameters)
      );
      Map<String, Object> properties = (Map<String, Object>) parameters.get(
        'properties'
      );
      reply.model = (String) properties.get('model');

      Map<String, Object> usage = (Map<String, Object>) properties.get('usage');
      reply.totalTokens = Integer.valueOf(usage.get('totalTokenCount'));
    } catch (Exception ignored) {
      reply.model = modelName;
    }
  }

  /**
   * Isolates the JSON object in a reply that may be fenced or prefaced with prose.
   */
  @TestVisible
  private static String extractJsonObject(String raw) {
    if (String.isBlank(raw)) {
      return '';
    }
    String trimmed = raw.trim();
    Integer opening = trimmed.indexOf('{');
    Integer closing = trimmed.lastIndexOf('}');

    if (opening == -1 || closing <= opening) {
      return trimmed;
    }
    return trimmed.substring(opening, closing + 1);
  }
}
