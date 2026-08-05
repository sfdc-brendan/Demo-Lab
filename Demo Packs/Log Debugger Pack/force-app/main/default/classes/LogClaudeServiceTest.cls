@IsTest
private class LogClaudeServiceTest {
  @IsTest
  static void parsesAPlainJsonReply() {
    LogClaudeService.responder = new LogTestData.StubResponder();

    Map<String, Object> parsed = LogClaudeService.chatJson(
      'triaging a log',
      'digest'
    );

    Assert.areEqual(
      'java.lang.OutOfMemoryError',
      parsed.get('signature'),
      'The stub triage reply should round-trip through the parser'
    );
  }

  @IsTest
  static void toleratesAMarkdownFencedReply() {
    LogTestData.StubResponder stub = new LogTestData.StubResponder();
    stub.triageReply = '```json\n' + LogTestData.TRIAGE_JSON + '\n```';
    LogClaudeService.responder = stub;

    Map<String, Object> parsed = LogClaudeService.chatJson(
      'triaging a log',
      'digest'
    );

    Assert.areEqual(
      'Driver',
      parsed.get('component'),
      'A fenced reply is common enough that it must parse rather than fail'
    );
  }

  @IsTest
  static void toleratesProseWrappedAroundTheJson() {
    LogTestData.StubResponder stub = new LogTestData.StubResponder();
    stub.triageReply =
      'Here is the analysis:\n' +
      LogTestData.TRIAGE_JSON +
      '\nHope that helps.';
    LogClaudeService.responder = stub;

    Map<String, Object> parsed = LogClaudeService.chatJson(
      'triaging a log',
      'digest'
    );

    Assert.areEqual(
      'Critical',
      parsed.get('severity'),
      'Surrounding prose should be ignored'
    );
  }

  @IsTest
  static void raisesAReadableErrorWhenTheReplyIsNotJson() {
    LogClaudeService.responder = new LogTestData.ProseResponder();

    try {
      LogClaudeService.chatJson('triaging a log', 'digest');
      Assert.fail('A non-JSON reply must not be returned as if it parsed');
    } catch (LogClaudeService.ModelException e) {
      Assert.isTrue(
        e.getMessage().contains('could not be read as JSON'),
        'Expected a parse failure message, got: ' + e.getMessage()
      );
    }
  }

  @IsTest
  static void surfacesTransportFailures() {
    LogClaudeService.responder = new LogTestData.FailingResponder();

    try {
      LogClaudeService.chat('triaging a log', 'digest');
      Assert.fail('A failed model call must propagate');
    } catch (LogClaudeService.ModelException e) {
      Assert.areEqual(
        'model unavailable',
        e.getMessage(),
        'The cause should not be masked'
      );
    }
  }

  @IsTest
  static void defaultsToASupportedClaudeModel() {
    Assert.areEqual(
      'sfdc_ai__DefaultBedrockAnthropicClaude45Sonnet',
      LogClaudeService.MODEL_SONNET_45,
      'The API name must match the AI Models configuration or every call 404s'
    );
    Assert.areEqual(
      LogClaudeService.MODEL_SONNET_45,
      LogClaudeService.modelName,
      'Sonnet is the default; Opus is opt-in'
    );
  }

  @IsTest
  static void unwrapsASuccessfulResponse() {
    aiplatform.ModelsAPI.createChatGenerations_Response response = buildResponse(
      200,
      'PONG'
    );

    LogClaudeService.Reply reply = LogClaudeService.toReply(response);

    Assert.areEqual(
      'PONG',
      reply.content,
      'The completion text is what callers need'
    );
    Assert.isNotNull(reply.model, 'The model name is shown in the UI footer');
  }

  @IsTest
  static void rejectsANonSuccessResponse() {
    try {
      LogClaudeService.toReply(buildResponse(429, null));
      Assert.fail('A throttled call must not look like an empty answer');
    } catch (LogClaudeService.ModelException e) {
      Assert.isTrue(
        e.getMessage().contains('429'),
        'The status code tells the rep whether to retry: ' + e.getMessage()
      );
    }
  }

  @IsTest
  static void rejectsANullResponse() {
    try {
      LogClaudeService.toReply(null);
      Assert.fail('A null response is a failure, not a blank answer');
    } catch (LogClaudeService.ModelException e) {
      Assert.isTrue(
        String.isNotBlank(e.getMessage()),
        'There must be a message to show'
      );
    }
  }

  @IsTest
  static void rejectsAResponseWithNoGenerations() {
    aiplatform.ModelsAPI.createChatGenerations_Response response = buildResponse(
      200,
      null
    );

    try {
      LogClaudeService.toReply(response);
      Assert.fail('A 200 with no completion is still a failure');
    } catch (LogClaudeService.ModelException e) {
      Assert.isTrue(
        e.getMessage().contains('empty completion'),
        'Expected an empty-completion message, got: ' + e.getMessage()
      );
    }
  }

  @IsTest
  static void buildsATwoTurnRequestAgainstTheConfiguredModel() {
    aiplatform.ModelsAPI.createChatGenerations_Request request = LogClaudeService.buildRequest(
      'You triage platform logs.',
      'Here is the log.'
    );

    Assert.areEqual(
      LogClaudeService.modelName,
      request.modelName,
      'The demo depends on the request naming Claude explicitly'
    );
    Assert.areEqual(
      2,
      request.body.messages.size(),
      'System and user turns are both sent'
    );
    Assert.areEqual(
      'system',
      request.body.messages[0].role,
      'The system turn goes first'
    );
    Assert.areEqual(
      'user',
      request.body.messages[1].role,
      'The log is the user turn'
    );
  }

  @IsTest
  static void omitsTheSystemTurnWhenThereIsNoSystemPrompt() {
    aiplatform.ModelsAPI.createChatGenerations_Request request = LogClaudeService.buildRequest(
      '',
      'Here is the log.'
    );

    Assert.areEqual(
      1,
      request.body.messages.size(),
      'An empty system turn is worse than none'
    );
    Assert.areEqual(
      'user',
      request.body.messages[0].role,
      'Only the user turn remains'
    );
  }

  /** Builds the response shape the Models API returns, without calling it. */
  private static aiplatform.ModelsAPI.createChatGenerations_Response buildResponse(
    Integer code,
    String content
  ) {
    aiplatform.ModelsAPI.createChatGenerations_Response response = new aiplatform.ModelsAPI.createChatGenerations_Response();
    response.responseCode = code;

    if (code != 200) {
      return response;
    }

    aiplatform.ModelsAPI_ChatGenerationsResponse payload = new aiplatform.ModelsAPI_ChatGenerationsResponse();
    aiplatform.ModelsAPI_GenerationDetails details = new aiplatform.ModelsAPI_GenerationDetails();
    details.generations = new List<aiplatform.ModelsAPI_ChatMessage>();

    if (content != null) {
      aiplatform.ModelsAPI_ChatMessage generation = new aiplatform.ModelsAPI_ChatMessage();
      generation.role = 'assistant';
      generation.content = content;
      details.generations.add(generation);
    }

    payload.generationDetails = details;
    response.Code200 = payload;
    return response;
  }

  @IsTest
  static void extractsTheObjectFromSurroundingText() {
    Assert.areEqual(
      '{"a":1}',
      LogClaudeService.extractJsonObject('prefix {"a":1} suffix'),
      'Extraction should span the first brace to the last'
    );
    Assert.areEqual(
      '',
      LogClaudeService.extractJsonObject(null),
      'A null reply should not blow up the extractor'
    );
    Assert.areEqual(
      'no braces here',
      LogClaudeService.extractJsonObject('no braces here'),
      'With no object present the raw text is returned for the error message'
    );
  }
}
