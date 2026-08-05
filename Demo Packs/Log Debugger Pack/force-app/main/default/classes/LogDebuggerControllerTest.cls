@IsTest
private class LogDebuggerControllerTest {
  @TestSetup
  static void seedArticles() {
    LogTestData.publishArticle(
      'KB-001',
      'Driver Out of Memory: java.lang.OutOfMemoryError: Java heap space',
      'The driver fails with OutOfMemoryError after a toPandas call.',
      'Replace the collect with a bounded limit or a write to Delta.'
    );
  }

  @IsTest
  static void triageReturnsTheClassificationAndDigestStats() {
    LogClaudeService.responder = new LogTestData.StubResponder();
    Id documentId = LogTestData.uploadLog('driver.log', LogTestData.buildLog());

    Test.startTest();
    LogAnalysis.Triage result = LogDebuggerController.triage(documentId);
    Test.stopTest();

    Assert.areEqual(
      'java.lang.OutOfMemoryError',
      result.signature,
      'Signature comes from the model'
    );
    Assert.areEqual(
      'Driver',
      result.component,
      'Component comes from the model'
    );
    Assert.areEqual(
      2,
      result.searchTerms.size(),
      'Search terms drive the next step'
    );
    Assert.areEqual(
      'driver.log',
      result.digest.fileName,
      'The rep needs to see which file was read'
    );
    Assert.isTrue(
      result.digest.retainedLines < result.digest.originalLines,
      'The digest stats prove the log was actually reduced'
    );
    Assert.isTrue(
      String.isNotBlank(result.digest.preview),
      'A preview is shown in the UI'
    );
  }

  @IsTest
  static void triageSendsTheDigestRatherThanTheRawLog() {
    LogTestData.StubResponder stub = new LogTestData.StubResponder();
    LogClaudeService.responder = stub;
    String raw = LogTestData.buildLog();
    Id documentId = LogTestData.uploadLog('driver.log', raw);

    Test.startTest();
    LogDebuggerController.triage(documentId);
    Test.stopTest();

    Assert.isTrue(
      stub.lastUserPrompt.length() < raw.length(),
      'Sending the raw log would waste most of the context window'
    );
    Assert.isTrue(
      stub.lastUserPrompt.contains('OutOfMemoryError'),
      'The reduction must not have dropped the actual error'
    );
  }

  @IsTest
  static void triageSurfacesAReadableErrorForAnOversizedLog() {
    LogClaudeService.responder = new LogTestData.StubResponder();
    Id documentId = LogTestData.uploadLog(
      'huge.log',
      'x'.repeat(LogDistiller.MAX_FILE_BYTES + 1024)
    );

    Test.startTest();
    try {
      LogDebuggerController.triage(documentId);
      Assert.fail('An oversized log should not reach the model');
    } catch (AuraHandledException e) {
      Assert.isTrue(
        e.getMessage().contains('limit'),
        'The component shows this message verbatim, so it must say what went wrong: ' +
        e.getMessage()
      );
    }
    Test.stopTest();
  }

  @IsTest
  static void findArticlesReturnsScopedHits() {
    Test.startTest();
    List<LogAnalysis.ArticleHit> hits = LogDebuggerController.findArticles(
      new List<String>{ 'java.lang.OutOfMemoryError driver heap' }
    );
    Test.stopTest();

    Assert.areEqual(
      1,
      hits.size(),
      'Only the seeded in-scope article should match'
    );
    Assert.areEqual(
      'KB-001',
      hits[0].externalId,
      'And it should be the OOM article'
    );
  }

  @IsTest
  static void synthesizeGroundsTheAnswerInTheRetrievedArticles() {
    LogTestData.StubResponder stub = new LogTestData.StubResponder();
    LogClaudeService.responder = stub;
    Id documentId = LogTestData.uploadLog('driver.log', LogTestData.buildLog());

    Test.startTest();
    LogAnalysis.Analysis analysis = LogDebuggerController.synthesize(
      documentId,
      LogTestData.TRIAGE_JSON,
      new List<String>{ 'KB-001' }
    );
    Test.stopTest();

    Assert.areEqual(
      'High',
      analysis.confidence,
      'Confidence comes from the model'
    );
    Assert.areEqual(
      2,
      analysis.steps.size(),
      'Both stub steps should map through'
    );
    Assert.areEqual(
      1,
      analysis.steps[0].position,
      'Steps are numbered for the UI'
    );
    Assert.areEqual(2, analysis.steps[1].position, 'And numbered in order');
    Assert.isTrue(
      stub.lastUserPrompt.contains('Replace the collect with a bounded limit'),
      'The article resolution must reach the prompt or the answer is not grounded'
    );
  }

  @IsTest
  static void synthesizeDropsCitationsThatDoNotExist() {
    LogClaudeService.responder = new LogTestData.StubResponder();
    Id documentId = LogTestData.uploadLog('driver.log', LogTestData.buildLog());

    Test.startTest();
    LogAnalysis.Analysis analysis = LogDebuggerController.synthesize(
      documentId,
      LogTestData.TRIAGE_JSON,
      new List<String>{ 'KB-001' }
    );
    Test.stopTest();

    // The stub's second step cites KB-999, which was never retrieved.
    Assert.areEqual(
      'KB-001',
      analysis.steps[0].sourceArticle,
      'A real citation is preserved'
    );
    Assert.areEqual(
      '',
      analysis.steps[1].sourceArticle,
      'An invented article id must not be shown to the rep as a source'
    );
    Assert.areEqual(
      1,
      analysis.citedArticles.size(),
      'Only genuinely cited articles appear in the grounding list'
    );
  }

  @IsTest
  static void synthesizeToleratesNoMatchingArticles() {
    LogClaudeService.responder = new LogTestData.StubResponder();
    Id documentId = LogTestData.uploadLog('driver.log', LogTestData.buildLog());

    Test.startTest();
    LogAnalysis.Analysis analysis = LogDebuggerController.synthesize(
      documentId,
      LogTestData.TRIAGE_JSON,
      new List<String>()
    );
    Test.stopTest();

    Assert.isTrue(
      analysis.citedArticles.isEmpty(),
      'Nothing retrieved means nothing cited'
    );
    Assert.isTrue(
      String.isNotBlank(analysis.rootCause),
      'The analysis still runs against the log alone'
    );
  }

  @IsTest
  static void modelFailuresReachTheComponentAsAReadableMessage() {
    LogClaudeService.responder = new LogTestData.FailingResponder();
    Id documentId = LogTestData.uploadLog('driver.log', LogTestData.buildLog());

    Test.startTest();
    try {
      LogDebuggerController.triage(documentId);
      Assert.fail('A model failure must not return a half-built result');
    } catch (AuraHandledException e) {
      Assert.areEqual(
        'model unavailable',
        e.getMessage(),
        'The default "Script-thrown exception" would tell the rep nothing'
      );
    }
    Test.stopTest();
  }
}
