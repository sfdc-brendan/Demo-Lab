@IsTest
private class LogDistillerTest {
  @IsTest
  static void keepsErrorsAndDropsRoutineChatter() {
    LogDistiller.Result result = LogDistiller.distill(
      LogTestData.buildLog()
    );

    Assert.isTrue(
      result.text.contains('java.lang.OutOfMemoryError: Java heap space'),
      'The exception is the whole point of the digest and must survive'
    );
    Assert.isTrue(
      result.text.contains('at org.apache.spark.sql.Dataset.withAction'),
      'Stack frames near an error are kept as context'
    );
    Assert.isTrue(
      result.retainedLines < result.originalLines / 4,
      'A log that is mostly routine task chatter should reduce sharply, got ' +
        result.retainedLines +
        ' of ' +
        result.originalLines
    );
  }

  @IsTest
  static void keepsClusterSpecFromTheHead() {
    LogDistiller.Result result = LogDistiller.distill(
      LogTestData.buildLog()
    );

    Assert.isTrue(
      result.text.contains('Starting Lakehouse Runtime 14.3 LTS'),
      'The runtime version sits in the healthy preamble but is needed to reason about the failure'
    );
  }

  @IsTest
  static void reportsRepeatCountsInsteadOfRepeatingLines() {
    LogDistiller.Result result = LogDistiller.distill(
      LogTestData.buildLog()
    );

    Assert.isTrue(
      result.text.contains('REPEATED LINES SUPPRESSED'),
      'A log with 300 identical GC lines should produce a suppression summary'
    );
    Assert.isTrue(
      result.text.contains('300x'),
      'The true occurrence count is the finding, so it must be reported: ' +
      result.text
    );

    String gcLine = '[Full GC (Allocation Failure)  27100M->27092M(28160M)]';
    Integer occurrences = result.text.countMatches(gcLine);
    Assert.isTrue(
      occurrences <= 4,
      'At most a few examples of a repeated line should appear, found ' +
      occurrences
    );
  }

  @IsTest
  static void collapsesLinesThatDifferOnlyByNumbers() {
    List<String> lines = new List<String>();
    for (Integer i = 0; i < 50; i++) {
      lines.add(
        '26/07/14 02:11:0' +
          Math.mod(i, 10) +
          ' WARN Retry: attempt ' +
          i +
          ' failed'
      );
    }
    LogDistiller.Result result = LogDistiller.distill(
      String.join(lines, '\n')
    );

    Assert.isTrue(
      result.text.contains('50x'),
      'Retry lines differing only in a counter are the same line for suppression purposes'
    );
  }

  @IsTest
  static void handlesEmptyInput() {
    LogDistiller.Result result = LogDistiller.distill('');

    Assert.areEqual(0, result.originalLines, 'An empty log has no lines');
    Assert.isTrue(
      result.text.contains('empty'),
      'The digest should say the log was empty'
    );
  }

  @IsTest
  static void readsAnUploadedFile() {
    Id documentId = LogTestData.uploadLog('driver.log', LogTestData.buildLog());

    Test.startTest();
    LogDistiller.Result result = LogDistiller.fromContentDocument(
      documentId
    );
    Test.stopTest();

    Assert.areEqual(
      'driver.log',
      result.fileName,
      'Title already carries the extension'
    );
    Assert.isTrue(result.originalBytes > 0, 'The file size should be reported');
    Assert.isTrue(
      result.text.contains('OutOfMemoryError'),
      'The digest should come from the uploaded content'
    );
  }

  @IsTest
  static void rejectsAFileOverTheSizeLimit() {
    // 'x' repeated past the 1 MB ceiling.
    String oversized = 'x'.repeat(LogDistiller.MAX_FILE_BYTES + 1024);
    Id documentId = LogTestData.uploadLog('huge.log', oversized);

    Test.startTest();
    try {
      LogDistiller.fromContentDocument(documentId);
      Assert.fail(
        'An oversized log must be rejected before its blob is loaded'
      );
    } catch (LogDistiller.LogAccessException e) {
      Assert.isTrue(
        e.getMessage().contains('over the'),
        'The rep needs to be told it is a size problem: ' + e.getMessage()
      );
    }
    Test.stopTest();
  }

  @IsTest
  static void reportsAMissingFileClearly() {
    Test.startTest();
    try {
      LogDistiller.fromContentDocument('069000000000000AAA');
      Assert.fail('A missing document should not return a digest');
    } catch (LogDistiller.LogAccessException e) {
      Assert.isTrue(
        e.getMessage().contains('could not be found'),
        'Expected a not-found message, got: ' + e.getMessage()
      );
    }
    Test.stopTest();
  }
}
