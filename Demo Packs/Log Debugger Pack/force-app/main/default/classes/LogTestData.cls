/**
 * Shared fixtures for the log debugger tests.
 *
 * The model is always stubbed. A test that made a real Models API call would be
 * slow, non-deterministic, and would fail in any org where the feature is off,
 * none of which tells us anything about this code.
 */
@IsTest
public class LogTestData {
  /**
   * Stands in for Claude, returning canned JSON chosen by which prompt it is given.
   *
   * Branching on the system prompt keeps a single stub usable across the whole
   * pipeline, so a controller test can drive triage and synthesis in one pass.
   */
  public class StubResponder implements LogClaudeService.Responder {
    public String triageReply = TRIAGE_JSON;
    public String synthesisReply = SYNTHESIS_JSON;
    public String lastUserPrompt;
    public Integer callCount = 0;

    public String respond(String systemPrompt, String userPrompt) {
      callCount++;
      lastUserPrompt = userPrompt;
      return systemPrompt != null && systemPrompt.contains('triaging')
        ? triageReply
        : synthesisReply;
    }
  }

  /** Always throws, for the error-handling paths. */
  public class FailingResponder implements LogClaudeService.Responder {
    public String respond(String systemPrompt, String userPrompt) {
      throw new LogClaudeService.ModelException('model unavailable');
    }
  }

  /** Returns text that is not JSON, for the malformed-reply path. */
  public class ProseResponder implements LogClaudeService.Responder {
    public String respond(String systemPrompt, String userPrompt) {
      return 'I am afraid I cannot help with that.';
    }
  }

  public static final String TRIAGE_JSON =
    '{' +
    '"signature":"java.lang.OutOfMemoryError",' +
    '"component":"Driver",' +
    '"severity":"Critical",' +
    '"summary":"The driver heap was exhausted collecting a large result.",' +
    '"searchTerms":["java.lang.OutOfMemoryError driver heap","toPandas collect rows"],' +
    '"evidence":["java.lang.OutOfMemoryError: Java heap space"]' +
    '}';

  public static final String SYNTHESIS_JSON =
    '{' +
    '"rootCause":"toPandas pulled the full result set onto the driver.",' +
    '"confidence":"High",' +
    '"confidenceReason":"The stack trace names the Arrow converter directly.",' +
    '"steps":[' +
    '{"action":"Find the toPandas call","detail":"Open the notebook.",' +
    '"command":"","expected":"You see the call.","sourceArticle":"KB-001"},' +
    '{"action":"Bound the collect","detail":"Add a limit.",' +
    '"command":"df.limit(1000).toPandas()","expected":"No OOM.","sourceArticle":"KB-999"}' +
    '],' +
    '"escalation":"Send the driver log to the platform team.",' +
    '"customerReply":"We have identified the cause and have next steps."' +
    '}';

  /** A log with enough noise, repetition, and signal to exercise the distiller. */
  public static String buildLog() {
    List<String> lines = new List<String>();
    lines.add(
      '26/07/14 02:11:04 INFO DriverDaemon: Starting Lakehouse Runtime 14.3 LTS'
    );
    lines.add(
      '26/07/14 02:11:04 INFO DriverDaemon: Cluster id: 0714-test-cluster'
    );

    for (Integer i = 0; i < 400; i++) {
      lines.add(
        '26/07/14 02:11:05 INFO TaskSetManager: Starting task ' +
          i +
          '.0 in stage 3.0 (TID ' +
          i +
          ')'
      );
    }
    for (Integer i = 0; i < 300; i++) {
      lines.add(
        '26/07/14 02:11:21 [Full GC (Allocation Failure)  27100M->27092M(28160M)]'
      );
    }

    lines.add(
      '26/07/14 02:12:03 ERROR Executor: Exception in task 0.0 in stage 5.0'
    );
    lines.add('java.lang.OutOfMemoryError: Java heap space');
    lines.add(
      '\tat org.apache.spark.sql.Dataset.withAction(Dataset.scala:4197)'
    );
    lines.add(
      '26/07/14 02:12:03 INFO LakehouseMain: Shutting down driver JVM, exit code 52'
    );
    return String.join(lines, '\n');
  }

  /**
   * Uploads a log and returns its ContentDocumentId.
   *
   * Deliberately not linked to a Case. The demo org runs a heavy record-triggered
   * flow on Case creation that cannot read its own configuration in a test
   * context, and none of the pipeline except saveToCase needs a parent record.
   */
  public static Id uploadLog(String fileName, String body) {
    ContentVersion version = new ContentVersion(
      Title = fileName,
      PathOnClient = fileName,
      VersionData = Blob.valueOf(body)
    );
    insert version;

    return [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :version.Id]
    .ContentDocumentId;
  }

  /** A ready-made analysis, for tests that only care about what gets persisted. */
  public static LogAnalysis.Analysis sampleAnalysis() {
    LogAnalysis.Analysis analysis = new LogAnalysis.Analysis();
    analysis.rootCause = 'toPandas pulled the full result set onto the driver.';
    analysis.confidence = 'High';
    analysis.confidenceReason = 'The stack trace names the Arrow converter directly.';
    analysis.escalation = 'Send the driver log to the platform team.';
    analysis.customerReply = 'We have identified the cause and have next steps.';
    analysis.modelUsed = LogClaudeService.MODEL_SONNET_45;

    LogAnalysis.Step step = new LogAnalysis.Step();
    step.position = 1;
    step.action = 'Bound the collect';
    step.detail = 'Add a limit before converting to pandas.';
    step.command = 'df.limit(1000).toPandas()';
    step.expected = 'The query completes without exhausting the driver heap.';
    step.sourceArticle = 'KB-001';
    analysis.steps.add(step);

    LogAnalysis.ArticleHit cited = new LogAnalysis.ArticleHit();
    cited.externalId = 'KB-001';
    cited.title = 'Driver Out of Memory: java.lang.OutOfMemoryError: Java heap space';
    cited.cited = true;
    analysis.citedArticles.add(cited);

    return analysis;
  }

  /**
   * Publishes a KB-tagged Knowledge article.
   *
   * Articles have to be Online to be retrievable, and publishing is a separate
   * step from insert, so both happen here.
   */
  public static Knowledge__kav publishArticle(
    String externalId,
    String title,
    String issue,
    String resolution
  ) {
    Knowledge__kav draft = new Knowledge__kav(
      Title = title,
      UrlName = externalId.toLowerCase() +
        '-' +
        String.valueOf(Crypto.getRandomInteger()).replace('-', ''),
      Language = 'en_US',
      External_ID__c = externalId,
      Summary = title,
      KCSArticle_Issue__c = issue,
      KCSArticle_Cause__c = 'Cause for ' + externalId,
      KCSArticle_Environment__c = 'All Lakehouse Runtime versions',
      KCSArticle_Resolution__c = resolution
    );
    insert draft;

    Id masterId = [
      SELECT KnowledgeArticleId
      FROM Knowledge__kav
      WHERE Id = :draft.Id
    ]
    .KnowledgeArticleId;
    KbManagement.PublishingService.publishArticle(masterId, true);

    return [
      SELECT Id, KnowledgeArticleId, External_ID__c, Title
      FROM Knowledge__kav
      WHERE KnowledgeArticleId = :masterId AND PublishStatus = 'Online'
      LIMIT 1
    ];
  }
}
