/**
 * Covers writing the analysis back to a Case.
 *
 * Separate from LogDebuggerControllerTest and running with SeeAllData because
 * the demo org fires a record-triggered flow on Case creation whose configuration
 * is invisible in an isolated test context, so a Case cannot be inserted. These
 * tests therefore reuse an existing Case. Test DML is rolled back either way, so
 * nothing is left behind on the record.
 *
 * Keeping this in its own class means the rest of the suite stays isolated and fast.
 */
@IsTest(SeeAllData=true)
private class LogDebuggerSaveTest {
  @IsTest
  static void writesTheAnalysisToTheCaseAndTheFeed() {
    Case target = existingCase();
    String analysisJson = JSON.serialize(LogTestData.sampleAnalysis());
    Integer postsBefore = feedItemCount(target.Id);

    Test.startTest();
    LogDebuggerController.saveToCase(target.Id, analysisJson, true);
    Test.stopTest();

    Case saved = [SELECT Log_Analysis__c FROM Case WHERE Id = :target.Id];
    Assert.isTrue(
      saved.Log_Analysis__c.contains('ROOT CAUSE'),
      'The rendered analysis should be readable on the record'
    );
    Assert.isTrue(
      saved.Log_Analysis__c.contains('df.limit(1000).toPandas()'),
      'Commands must survive into the saved text so the rep can copy them later'
    );
    Assert.isTrue(
      saved.Log_Analysis__c.contains('KB-001'),
      'The grounding should be recorded alongside the answer'
    );
    Assert.areEqual(
      postsBefore + 1,
      feedItemCount(target.Id),
      'The feed post is how a colleague picking up the case sees the analysis'
    );
  }

  @IsTest
  static void skipsTheFeedPostWhenNotRequested() {
    Case target = existingCase();
    String analysisJson = JSON.serialize(LogTestData.sampleAnalysis());
    Integer postsBefore = feedItemCount(target.Id);

    Test.startTest();
    LogDebuggerController.saveToCase(target.Id, analysisJson, false);
    Test.stopTest();

    Assert.areEqual(
      postsBefore,
      feedItemCount(target.Id),
      'The toggle should actually control the post'
    );
  }

  @IsTest
  static void reportsAFailureRatherThanSilentlyDoingNothing() {
    Test.startTest();
    try {
      LogDebuggerController.saveToCase(existingCase().Id, 'not json', false);
      Assert.fail(
        'A malformed payload must not be treated as a successful save'
      );
    } catch (AuraHandledException e) {
      Assert.isTrue(
        String.isNotBlank(e.getMessage()),
        'The component needs something to show the rep'
      );
    }
    Test.stopTest();
  }

  /** FeedItem.Body cannot be filtered in SOQL, so posts are counted before and after. */
  private static Integer feedItemCount(Id parentId) {
    return [SELECT COUNT() FROM FeedItem WHERE ParentId = :parentId];
  }

  private static Case existingCase() {
    List<Case> cases = [SELECT Id FROM Case LIMIT 1];
    Assert.isFalse(
      cases.isEmpty(),
      'This test needs at least one Case in the org'
    );
    return cases[0];
  }
}
