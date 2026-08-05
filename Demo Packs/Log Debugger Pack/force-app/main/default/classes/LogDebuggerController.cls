/**
 * Entry points for the log debugger LWC.
 *
 * The analysis runs as three separate round-trips rather than one long call. Each
 * returns in seconds, so the component can show real progress and can put the
 * matched Knowledge articles on screen before the answer is written, which is what
 * makes the grounding visible rather than merely claimed.
 *
 * The digest is re-derived from the uploaded file on the synthesis call instead of
 * being carried back through the browser. LogDistiller.distill() is pure, so the
 * second derivation is identical to the first, and a 40KB payload never crosses the
 * wire twice.
 */
public with sharing class LogDebuggerController {
  public class DebuggerException extends Exception {
  }

  private static final Integer PREVIEW_CHARS = 4000;

  // ---------------------------------------------------------------- step 1

  /**
   * Distills the uploaded log and asks Claude what kind of failure it is.
   */
  @AuraEnabled
  public static LogAnalysis.Triage triage(Id contentDocumentId) {
    try {
      LogDistiller.Result distilled = LogDistiller.fromContentDocument(
        contentDocumentId
      );
      Map<String, Object> parsed = LogClaudeService.chatJson(
        TRIAGE_SYSTEM_PROMPT,
        'Log digest:\n\n' + distilled.text
      );

      LogAnalysis.Triage result = new LogAnalysis.Triage();
      result.signature = text(parsed.get('signature'));
      result.component = text(parsed.get('component'));
      result.severity = text(parsed.get('severity'));
      result.summary = text(parsed.get('summary'));
      result.searchTerms = textList(parsed.get('searchTerms'));
      result.evidence = textList(parsed.get('evidence'));
      result.digest = toDigest(distilled);
      return result;
    } catch (Exception e) {
      throw asAuraException(e);
    }
  }

  // ---------------------------------------------------------------- step 2

  /**
   * Searches the Knowledge library for the triaged failure.
   */
  @AuraEnabled
  public static List<LogAnalysis.ArticleHit> findArticles(
    List<String> searchTerms
  ) {
    try {
      return LogKnowledgeSearch.find(searchTerms);
    } catch (Exception e) {
      throw asAuraException(e);
    }
  }

  // ---------------------------------------------------------------- step 3

  /**
   * Produces the grounded troubleshooting plan.
   *
   * @param contentDocumentId the uploaded log, re-distilled here
   * @param triageJson        the step 1 result, passed back so the model is not re-run
   * @param articleExternalIds the KB ids the rep is grounding on
   */
  @AuraEnabled
  public static LogAnalysis.Analysis synthesize(
    Id contentDocumentId,
    String triageJson,
    List<String> articleExternalIds
  ) {
    try {
      LogDistiller.Result distilled = LogDistiller.fromContentDocument(
        contentDocumentId
      );
      List<LogAnalysis.ArticleHit> articles = LogKnowledgeSearch.byExternalIds(
        articleExternalIds
      );

      Map<String, Object> parsed = LogClaudeService.chatJson(
        SYNTHESIS_SYSTEM_PROMPT,
        buildSynthesisPrompt(distilled.text, triageJson, articles)
      );

      return toAnalysis(parsed, articles);
    } catch (Exception e) {
      throw asAuraException(e);
    }
  }

  // ---------------------------------------------------------------- persist

  /**
   * Writes the analysis onto the Case and posts it to the feed.
   *
   * The field write is the record of what the rep acted on; the Chatter post is
   * what a colleague picking the case up later will actually see.
   */
  @AuraEnabled
  public static void saveToCase(
    Id caseId,
    String analysisJson,
    Boolean postToChatter
  ) {
    try {
      LogAnalysis.Analysis analysis = (LogAnalysis.Analysis) JSON.deserialize(
        analysisJson,
        LogAnalysis.Analysis.class
      );
      String rendered = renderForCase(analysis);

      Case target = new Case(
        Id = caseId,
        Log_Analysis__c = rendered.abbreviate(32000)
      );
      SObjectAccessDecision decision = Security.stripInaccessible(
        AccessType.UPDATABLE,
        new List<Case>{ target }
      );
      update decision.getRecords();

      if (postToChatter == true) {
        insert new FeedItem(
          ParentId = caseId,
          Type = 'TextPost',
          Body = rendered.abbreviate(10000)
        );
      }
    } catch (Exception e) {
      throw asAuraException(e);
    }
  }

  // ---------------------------------------------------------------- prompts

  private static final String TRIAGE_SYSTEM_PROMPT =
    'You are a senior data platform support engineer triaging a customer log.\n\n' +
    'You will be given a distilled log digest. Lines reading "--- N lines omitted ---" mark ' +
    'removed healthy output. A "REPEATED LINES SUPPRESSED" section at the end gives true ' +
    'occurrence counts for lines that recurred; a very high count is itself a finding.\n\n' +
    'Identify the single primary failure. Spark logs cascade, so a FetchFailedException ' +
    'or a stage abort is usually a downstream symptom of an executor that died earlier. ' +
    'Report the earliest cause, not the loudest error.\n\n' +
    'Reply with a JSON object only. No prose, no markdown fence. Schema:\n' +
    '{\n' +
    '  "signature": "the exception class or platform error code, e.g. java.lang.OutOfMemoryError or INSTANCE_LIMIT_EXCEEDED",\n' +
    '  "component": "one of: Driver, Executor, Cluster, Unity Catalog, Delta Lake, Structured Streaming, SQL Warehouse, Storage, Libraries",\n' +
    '  "severity": "one of: Critical, High, Medium, Low",\n' +
    '  "summary": "one or two sentences describing what failed and why, in plain language",\n' +
    '  "searchTerms": ["4 to 7 short keyword phrases for a knowledge base search; use error class names and platform terminology, not full sentences"],\n' +
    '  "evidence": ["2 to 4 verbatim log lines that justify the conclusion"]\n' +
    '}';

  private static final String SYNTHESIS_SYSTEM_PROMPT =
    'You are a senior data platform support engineer writing troubleshooting guidance for a ' +
    'customer service representative who is not a Spark expert.\n\n' +
    'You will be given a distilled log, a triage summary, and the troubleshooting articles ' +
    'retrieved from the internal knowledge base.\n\n' +
    'Ground your answer in those articles. When an article covers a step, cite it by its ' +
    'KB id. If the articles do not cover the failure, say so plainly in confidenceReason ' +
    'and set confidence to Low rather than inventing procedure. Never invent a KB id.\n\n' +
    'Order the steps so the cheapest diagnostic that discriminates between causes comes ' +
    'first. Do not open with "resize the cluster" when the log shows skew.\n\n' +
    'Reply with a JSON object only. No prose, no markdown fence. Schema:\n' +
    '{\n' +
    '  "rootCause": "two to four sentences on what actually went wrong, referencing specific log evidence",\n' +
    '  "confidence": "one of: High, Medium, Low",\n' +
    '  "confidenceReason": "one sentence on why, including anything the log does not show",\n' +
    '  "steps": [\n' +
    '    {\n' +
    '      "action": "short imperative title, under 60 characters",\n' +
    '      "detail": "what to do and what it tells you, two or three sentences",\n' +
    '      "command": "an exact command, SQL statement, or Spark config to run, or an empty string if the step is a UI action",\n' +
    '      "expected": "what a healthy result looks like, so the rep knows whether it worked",\n' +
    '      "sourceArticle": "the KB id this came from, or an empty string if it came from the log alone"\n' +
    '    }\n' +
    '  ],\n' +
    '  "escalation": "what to collect and which team to route to if the steps do not resolve it",\n' +
    '  "customerReply": "a short, non-technical message the rep can send the customer now"\n' +
    '}';

  private static String buildSynthesisPrompt(
    String digest,
    String triageJson,
    List<LogAnalysis.ArticleHit> articles
  ) {
    List<String> sections = new List<String>();
    sections.add('## Triage\n' + triageJson);

    if (articles.isEmpty()) {
      sections.add(
        '## Knowledge base articles\n' +
          'No articles matched this failure. Say so in confidenceReason and keep ' +
          'confidence at Low.'
      );
    } else {
      List<String> rendered = new List<String>();
      for (LogAnalysis.ArticleHit article : articles) {
        rendered.add(
          '### ' +
            article.externalId +
            ' - ' +
            article.title +
            '\nISSUE: ' +
            article.issue +
            '\nCAUSE: ' +
            article.cause +
            '\nENVIRONMENT: ' +
            article.environment +
            '\nRESOLUTION: ' +
            article.resolution
        );
      }
      sections.add(
        '## Knowledge base articles\n' + String.join(rendered, '\n\n')
      );
    }

    sections.add('## Log digest\n' + digest);
    return String.join(sections, '\n\n');
  }

  // ---------------------------------------------------------------- mapping

  private static LogAnalysis.Digest toDigest(
    LogDistiller.Result distilled
  ) {
    LogAnalysis.Digest digest = new LogAnalysis.Digest();
    digest.fileName = distilled.fileName;
    digest.originalLines = distilled.originalLines;
    digest.retainedLines = distilled.retainedLines;
    digest.originalBytes = distilled.originalBytes;
    digest.truncated = distilled.truncated;
    digest.preview = distilled.text.abbreviate(PREVIEW_CHARS);
    return digest;
  }

  /**
   * Maps the model's JSON onto the analysis DTO.
   *
   * Cited articles are resolved against the retrieved set by KB id, so an id the
   * model invented is dropped rather than shown to the rep as a real citation.
   */
  private static LogAnalysis.Analysis toAnalysis(
    Map<String, Object> parsed,
    List<LogAnalysis.ArticleHit> retrieved
  ) {
    LogAnalysis.Analysis analysis = new LogAnalysis.Analysis();
    analysis.rootCause = text(parsed.get('rootCause'));
    analysis.confidence = text(parsed.get('confidence'));
    analysis.confidenceReason = text(parsed.get('confidenceReason'));
    analysis.escalation = text(parsed.get('escalation'));
    analysis.customerReply = text(parsed.get('customerReply'));
    analysis.modelUsed = LogClaudeService.modelName;

    Map<String, LogAnalysis.ArticleHit> byExternalId = new Map<String, LogAnalysis.ArticleHit>();
    for (LogAnalysis.ArticleHit article : retrieved) {
      byExternalId.put(article.externalId, article);
    }

    Object rawSteps = parsed.get('steps');
    if (rawSteps instanceof List<Object>) {
      Integer position = 1;
      for (Object entry : (List<Object>) rawSteps) {
        if (!(entry instanceof Map<String, Object>)) {
          continue;
        }
        Map<String, Object> raw = (Map<String, Object>) entry;

        LogAnalysis.Step step = new LogAnalysis.Step();
        step.position = position++;
        step.action = text(raw.get('action'));
        step.detail = text(raw.get('detail'));
        step.command = text(raw.get('command'));
        step.expected = text(raw.get('expected'));
        step.sourceArticle = text(raw.get('sourceArticle'));

        if (byExternalId.containsKey(step.sourceArticle)) {
          byExternalId.get(step.sourceArticle).cited = true;
        } else {
          step.sourceArticle = '';
        }
        analysis.steps.add(step);
      }
    }

    for (LogAnalysis.ArticleHit article : retrieved) {
      if (article.cited == true) {
        analysis.citedArticles.add(article);
      }
    }
    return analysis;
  }

  private static String renderForCase(LogAnalysis.Analysis analysis) {
    List<String> out = new List<String>();
    out.add('AI LOG ANALYSIS (' + analysis.modelUsed + ')');
    out.add('');
    out.add('ROOT CAUSE');
    out.add(analysis.rootCause);
    out.add('');
    out.add(
      'CONFIDENCE: ' + analysis.confidence + ' - ' + analysis.confidenceReason
    );
    out.add('');
    out.add('TROUBLESHOOTING STEPS');

    for (LogAnalysis.Step step : analysis.steps) {
      out.add('');
      out.add(step.position + '. ' + step.action);
      out.add('   ' + step.detail);
      if (String.isNotBlank(step.command)) {
        out.add('   Command: ' + step.command);
      }
      if (String.isNotBlank(step.expected)) {
        out.add('   Expected: ' + step.expected);
      }
      if (String.isNotBlank(step.sourceArticle)) {
        out.add('   Source: ' + step.sourceArticle);
      }
    }

    if (!analysis.citedArticles.isEmpty()) {
      out.add('');
      out.add('GROUNDED IN');
      for (LogAnalysis.ArticleHit article : analysis.citedArticles) {
        out.add('  ' + article.externalId + ' - ' + article.title);
      }
    }

    if (String.isNotBlank(analysis.escalation)) {
      out.add('');
      out.add('IF UNRESOLVED');
      out.add(analysis.escalation);
    }
    return String.join(out, '\n');
  }

  // ---------------------------------------------------------------- helpers

  private static String text(Object value) {
    return value == null ? '' : String.valueOf(value).trim();
  }

  private static List<String> textList(Object value) {
    List<String> items = new List<String>();
    if (value instanceof List<Object>) {
      for (Object entry : (List<Object>) value) {
        String item = text(entry);
        if (String.isNotBlank(item)) {
          items.add(item);
        }
      }
    }
    return items;
  }

  /**
   * Surfaces the underlying message to the component.
   *
   * The default AuraHandledException message is "Script-thrown exception", which
   * hides exactly the detail a rep needs, such as the log being over the size limit.
   */
  private static AuraHandledException asAuraException(Exception e) {
    AuraHandledException handled = new AuraHandledException(e.getMessage());
    handled.setMessage(e.getMessage());
    return handled;
  }
}
