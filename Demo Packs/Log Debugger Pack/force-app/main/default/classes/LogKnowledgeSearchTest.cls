@IsTest
private class LogKnowledgeSearchTest {
  /**
   * Two in-scope articles plus one from another product line.
   *
   * The third article is the point of the fixture: the demo org holds hundreds of
   * unrelated articles, and a search that returns them is worse than no search.
   */
  @TestSetup
  static void seedArticles() {
    LogTestData.publishArticle(
      'KB-001',
      'Driver Out of Memory: java.lang.OutOfMemoryError: Java heap space',
      'The driver fails with OutOfMemoryError after a toPandas call.',
      'Replace the collect with a bounded limit or a write to Delta.'
    );
    LogTestData.publishArticle(
      'KB-005',
      'Delta ConcurrentAppendException on concurrent writes',
      'Two writers commit to the same Delta partition.',
      'Add a partition predicate to the merge condition.'
    );
    LogTestData.publishArticle(
      'FAQ-100',
      'Troubleshooting router connection timeout on smart glasses',
      'The device cannot reach the network and reports a connection timeout.',
      'Power cycle the router.'
    );
  }

  @IsTest
  static void rankstheMatchingArticleFirst() {
    List<LogAnalysis.ArticleHit> hits = LogKnowledgeSearch.find(
      new List<String>{
        'java.lang.OutOfMemoryError driver heap',
        'toPandas collect rows'
      }
    );

    Assert.isFalse(hits.isEmpty(), 'The OOM article should be found');
    Assert.areEqual(
      'KB-001',
      hits[0].externalId,
      'The article whose title names the exception must outrank the rest'
    );
  }

  @IsTest
  static void neverReturnsArticlesOutsideTheScopedLibrary() {
    // "connection timeout" appears verbatim in the smart glasses article.
    List<LogAnalysis.ArticleHit> hits = LogKnowledgeSearch.find(
      new List<String>{ 'connection timeout', 'router' }
    );

    for (LogAnalysis.ArticleHit hit : hits) {
      Assert.isTrue(
        hit.externalId.startsWith('KB-'),
        'Retrieval is scoped to the KB library, but returned ' +
        hit.externalId
      );
    }
  }

  @IsTest
  static void separatesTheTwoFailureModes() {
    List<LogAnalysis.ArticleHit> hits = LogKnowledgeSearch.find(
      new List<String>{
        'ConcurrentAppendException',
        'Delta partition concurrent write'
      }
    );

    Assert.isFalse(hits.isEmpty(), 'The Delta article should be found');
    Assert.areEqual(
      'KB-005',
      hits[0].externalId,
      'A Delta conflict must not resolve to the OOM article'
    );
  }

  @IsTest
  static void returnsNothingForEmptyInput() {
    Assert.isTrue(
      LogKnowledgeSearch.find(new List<String>()).isEmpty(),
      'No terms means no search'
    );
    Assert.isTrue(
      LogKnowledgeSearch.find(null).isEmpty(),
      'A null term list is not a crash'
    );
  }

  @IsTest
  static void reloadsArticlesByExternalId() {
    List<LogAnalysis.ArticleHit> hits = LogKnowledgeSearch.byExternalIds(
      new List<String>{ 'KB-001', 'KB-005' }
    );

    Assert.areEqual(2, hits.size(), 'Both requested articles should come back');
    Assert.isTrue(
      LogKnowledgeSearch.byExternalIds(new List<String>()).isEmpty(),
      'An empty request should not query'
    );
  }

  @IsTest
  static void stripsMarkupBeforeTheTextReachesThePrompt() {
    String html = '<b>Test Your Router</b><br>Bypass it&nbsp;first.<br><br><code>a &lt; b</code>';

    String plain = LogKnowledgeSearch.plainText(html);

    Assert.isFalse(
      plain.contains('<b>'),
      'Tags are noise in a prompt: ' + plain
    );
    Assert.isTrue(
      plain.contains('Test Your Router'),
      'Text content must survive'
    );
    Assert.isTrue(
      plain.contains('a < b'),
      'Entities should decode, got: ' + plain
    );
    Assert.areEqual(
      '',
      LogKnowledgeSearch.plainText(null),
      'Null is empty, not an error'
    );
  }

  @IsTest
  static void tokenizesClassNamesIntoSearchableParts() {
    List<String> tokens = LogKnowledgeSearch.tokenize(
      new List<String>{ 'java.lang.OutOfMemoryError driver heap' }
    );

    Assert.isTrue(
      tokens.contains('java.lang.OutOfMemoryError'),
      'The fully qualified name is worth searching on: ' + tokens
    );
    Assert.isTrue(
      tokens.contains('OutOfMemoryError'),
      'Articles often use the short class name only: ' + tokens
    );
    Assert.isTrue(tokens.contains('driver'), 'Plain words are kept: ' + tokens);
  }

  @IsTest
  static void dropsSoslOperatorsAndNoiseWords() {
    List<String> cleaned = LogKnowledgeSearch.sanitize(
      new List<String>{
        'OutOfMemoryError: heap*',
        '  ',
        'ab',
        'OutOfMemoryError: heap*'
      }
    );

    Assert.areEqual(
      1,
      cleaned.size(),
      'Blank, too-short, and duplicate terms drop out'
    );
    Assert.isFalse(
      cleaned[0].contains(':'),
      'A colon would make the SOSL malformed'
    );
    Assert.isFalse(
      cleaned[0].contains('*'),
      'A wildcard would change the query semantics'
    );
  }
}
