/**
 * Retrieves the troubleshooting articles that ground the analysis.
 *
 * Every query is scoped to External_ID__c LIKE 'KB-%'. The demo org holds a few
 * hundred unrelated Knowledge articles, and without that scope a search for a term
 * like "connection timeout" happily returns consumer-hardware content.
 *
 * SOSL is the primary path because it is what a customer with a real article
 * library would use. A scored SOQL scan backs it up, because the search index takes
 * time to catch up after articles are published and an empty result set part-way
 * through a demo is not recoverable.
 */
public with sharing class LogKnowledgeSearch {
  private static final Integer MAX_HITS = 5;
  private static final Integer SOSL_LIMIT = 20;

  /** Characters SOSL treats as operators, which have to leave the search terms. */
  private static final String SOSL_RESERVED = '?&|!{}[]()^~*:\\"\'+-';

  /**
   * Finds the articles most likely to explain a failure.
   *
   * Terms arrive from triage as short phrases such as "toPandas collect too many
   * rows". Matching those whole finds nothing, because no article contains that
   * exact string, so they are searched and scored as individual tokens with a
   * bonus when a full phrase does happen to land.
   *
   * @param terms error signatures and keywords from the triage pass
   */
  public static List<LogAnalysis.ArticleHit> find(List<String> terms) {
    List<String> phrases = sanitize(terms);
    List<String> tokens = tokenize(phrases);
    if (tokens.isEmpty()) {
      return new List<LogAnalysis.ArticleHit>();
    }

    List<Knowledge__kav> candidates = searchIndex(tokens);
    if (candidates.isEmpty()) {
      candidates = allScopedArticles();
    }

    return rank(candidates, phrases, tokens);
  }

  /** Reloads specific articles by external ID, for the synthesis pass. */
  public static List<LogAnalysis.ArticleHit> byExternalIds(
    List<String> externalIds
  ) {
    if (externalIds == null || externalIds.isEmpty()) {
      return new List<LogAnalysis.ArticleHit>();
    }

    List<LogAnalysis.ArticleHit> hits = new List<LogAnalysis.ArticleHit>();
    for (Knowledge__kav article : [
      SELECT
        Id,
        KnowledgeArticleId,
        External_ID__c,
        Title,
        Summary,
        KCSArticle_Issue__c,
        KCSArticle_Cause__c,
        KCSArticle_Environment__c,
        KCSArticle_Resolution__c
      FROM Knowledge__kav
      WHERE
        External_ID__c IN :externalIds
        AND PublishStatus = 'Online'
        AND Language = 'en_US'
      WITH USER_MODE
    ]) {
      hits.add(toHit(article));
    }
    return hits;
  }

  private static List<Knowledge__kav> searchIndex(List<String> tokens) {
    String expression = '\'' + String.join(tokens, ' OR ') + '\'';
    String sosl =
      'FIND ' +
      expression +
      ' IN ALL FIELDS RETURNING Knowledge__kav(' +
      'Id, KnowledgeArticleId, External_ID__c, Title, Summary, ' +
      'KCSArticle_Issue__c, KCSArticle_Cause__c, KCSArticle_Environment__c, KCSArticle_Resolution__c ' +
      'WHERE PublishStatus = \'Online\' AND Language = \'en_US\' AND External_ID__c LIKE \'KB-%\' ' +
      'LIMIT ' +
      SOSL_LIMIT +
      ')';

    try {
      List<List<SObject>> results = Search.query(sosl);
      return (List<Knowledge__kav>) results[0];
    } catch (Exception e) {
      // A malformed term should degrade to the full scan, not fail the analysis.
      return new List<Knowledge__kav>();
    }
  }

  private static List<Knowledge__kav> allScopedArticles() {
    return [
      SELECT
        Id,
        KnowledgeArticleId,
        External_ID__c,
        Title,
        Summary,
        KCSArticle_Issue__c,
        KCSArticle_Cause__c,
        KCSArticle_Environment__c,
        KCSArticle_Resolution__c
      FROM Knowledge__kav
      WHERE
        External_ID__c LIKE 'KB-%'
        AND PublishStatus = 'Online'
        AND Language = 'en_US'
      WITH USER_MODE
      LIMIT 200
    ];
  }

  /**
   * Orders candidates by how much of the failure they actually describe.
   *
   * SOSL returns relevance-ordered rows but no score, and the fallback scan returns
   * none at all, so both paths are re-scored here against the same rule. A term in
   * the title is worth far more than one buried in a resolution step, because
   * resolution text mentions adjacent failure modes it is not actually about.
   */
  private static List<LogAnalysis.ArticleHit> rank(
    List<Knowledge__kav> candidates,
    List<String> phrases,
    List<String> tokens
  ) {
    Map<Integer, List<LogAnalysis.ArticleHit>> byScore = new Map<Integer, List<LogAnalysis.ArticleHit>>();
    List<Integer> scores = new List<Integer>();

    for (Knowledge__kav article : candidates) {
      LogAnalysis.ArticleHit hit = toHit(article);
      hit.score = score(article, phrases, tokens);
      if (hit.score == 0) {
        continue;
      }
      if (!byScore.containsKey(hit.score)) {
        byScore.put(hit.score, new List<LogAnalysis.ArticleHit>());
        scores.add(hit.score);
      }
      byScore.get(hit.score).add(hit);
    }

    scores.sort();

    List<LogAnalysis.ArticleHit> ranked = new List<LogAnalysis.ArticleHit>();
    for (
      Integer i = scores.size() - 1; i >= 0 && ranked.size() < MAX_HITS; i--
    ) {
      for (LogAnalysis.ArticleHit hit : byScore.get(scores[i])) {
        ranked.add(hit);
        if (ranked.size() >= MAX_HITS) {
          break;
        }
      }
    }
    return ranked;
  }

  private static Integer score(
    Knowledge__kav article,
    List<String> phrases,
    List<String> tokens
  ) {
    String title = lower(article.Title);
    String summary = lower(article.Summary);
    String issue = lower(article.KCSArticle_Issue__c);
    String body =
      lower(article.KCSArticle_Cause__c) +
      ' ' +
      lower(article.KCSArticle_Environment__c) +
      ' ' +
      lower(article.KCSArticle_Resolution__c);

    Integer total = 0;

    for (String token : tokens) {
      String needle = token.toLowerCase();
      if (title.contains(needle)) {
        total += 6;
      }
      if (summary.contains(needle)) {
        total += 3;
      }
      if (issue.contains(needle)) {
        total += 2;
      }
      if (body.contains(needle)) {
        total += 1;
      }
    }

    // An exact phrase match is a much stronger signal than its words landing
    // separately, so it earns on top of the per-token score rather than instead.
    for (String phrase : phrases) {
      if (!phrase.contains(' ')) {
        continue;
      }
      String needle = phrase.toLowerCase();
      if (
        title.contains(needle) ||
        summary.contains(needle) ||
        issue.contains(needle)
      ) {
        total += 15;
      }
    }
    return total;
  }

  private static LogAnalysis.ArticleHit toHit(Knowledge__kav article) {
    LogAnalysis.ArticleHit hit = new LogAnalysis.ArticleHit();
    hit.articleVersionId = article.Id;
    hit.knowledgeArticleId = article.KnowledgeArticleId;
    hit.externalId = article.External_ID__c;
    hit.title = article.Title;
    hit.summary = plainText(article.Summary);
    hit.issue = plainText(article.KCSArticle_Issue__c);
    hit.cause = plainText(article.KCSArticle_Cause__c);
    hit.environment = plainText(article.KCSArticle_Environment__c);
    hit.resolution = plainText(article.KCSArticle_Resolution__c);
    hit.score = 0;
    return hit;
  }

  /**
   * Drops SOSL operator characters and terms too short to be indexed.
   *
   * Error signatures arrive with punctuation that SOSL would read as syntax:
   * "java.lang.OutOfMemoryError: Java heap space" contains a colon, and an
   * unescaped one turns the whole expression into a malformed field query.
   *
   * Terms come back unquoted so they can also be used for scoring; searchIndex()
   * adds phrase quoting only where SOSL needs it.
   */
  @TestVisible
  private static List<String> sanitize(List<String> terms) {
    List<String> cleaned = new List<String>();
    Set<String> seen = new Set<String>();

    if (terms == null) {
      return cleaned;
    }

    for (String term : terms) {
      if (String.isBlank(term)) {
        continue;
      }
      String stripped = term;
      for (Integer i = 0; i < SOSL_RESERVED.length(); i++) {
        stripped = stripped.replace(SOSL_RESERVED.substring(i, i + 1), ' ');
      }
      stripped = stripped.replaceAll('\\s+', ' ').trim();

      if (stripped.length() < 3 || seen.contains(stripped.toLowerCase())) {
        continue;
      }
      seen.add(stripped.toLowerCase());
      cleaned.add(stripped);
    }
    return cleaned;
  }

  /**
   * Breaks the triage phrases into the individual words worth searching on.
   *
   * Dots survive the split so that a fully qualified class name stays intact, and
   * its final segment is added separately: the log says
   * java.lang.OutOfMemoryError while an article may only say OutOfMemoryError.
   */
  @TestVisible
  private static List<String> tokenize(List<String> phrases) {
    List<String> tokens = new List<String>();
    Set<String> seen = new Set<String>();

    for (String phrase : phrases) {
      for (String word : phrase.split('[^A-Za-z0-9._]+')) {
        addToken(word, tokens, seen);

        if (word.contains('.')) {
          List<String> segments = word.split('\\.');
          addToken(segments[segments.size() - 1], tokens, seen);
        }
      }
    }
    return tokens;
  }

  private static void addToken(
    String word,
    List<String> tokens,
    Set<String> seen
  ) {
    String candidate = word == null ? '' : word.trim();
    candidate = candidate.removeEnd('.').removeStart('.');

    if (candidate.length() < 4 || STOPWORDS.contains(candidate.toLowerCase())) {
      return;
    }
    if (seen.add(candidate.toLowerCase())) {
      tokens.add(candidate);
    }
  }

  /**
   * Words common enough across the library that matching on them is noise. Terms
   * like "failure" and "memory" are deliberately absent: in platform logs they carry
   * real discriminating weight.
   */
  private static final Set<String> STOPWORDS = new Set<String>{
    'that',
    'this',
    'with',
    'from',
    'when',
    'what',
    'have',
    'been',
    'they',
    'them',
    'then',
    'than',
    'into',
    'over',
    'some',
    'more',
    'most',
    'much',
    'many',
    'very',
    'your',
    'about',
    'after',
    'before',
    'being',
    'during',
    'while',
    'because',
    'issue',
    'issues',
    'problem',
    'problems'
  };

  /**
   * Converts the rich-text KCS fields to plain text for the prompt.
   *
   * The markup is pure noise to the model and would otherwise consume a meaningful
   * share of the context window across five articles.
   */
  @TestVisible
  private static String plainText(String html) {
    if (String.isBlank(html)) {
      return '';
    }
    return html
      .replaceAll('(?i)<br\\s*/?>', '\n')
      .replaceAll('(?i)</(p|div|li)>', '\n')
      .replaceAll('<[^>]+>', '')
      .replace('&nbsp;', ' ')
      .replace('&amp;', '&')
      .replace('&lt;', '<')
      .replace('&gt;', '>')
      .replace('&quot;', '"')
      .replace('&#39;', '\'')
      .replaceAll('\n{3,}', '\n\n')
      .trim();
  }

  private static String lower(String value) {
    return value == null ? '' : value.toLowerCase();
  }
}
