/**
 * Data contracts shared between the log debugger's Apex pipeline and its LWC.
 *
 * Everything here is a plain @AuraEnabled holder with no behaviour, kept in one
 * file so the wire format the component depends on can be read in a single pass.
 */
public with sharing class LogAnalysis {
  /** What the distiller did to the uploaded file, surfaced so the rep can see it. */
  public class Digest {
    @AuraEnabled
    public String fileName;
    @AuraEnabled
    public Integer originalLines;
    @AuraEnabled
    public Integer retainedLines;
    @AuraEnabled
    public Integer originalBytes;
    @AuraEnabled
    public Boolean truncated;
    @AuraEnabled
    public String preview;
  }

  /** Claude's first pass: what kind of failure this is and what to search for. */
  public class Triage {
    @AuraEnabled
    public String signature;
    @AuraEnabled
    public String component;
    @AuraEnabled
    public String severity;
    @AuraEnabled
    public String summary;
    @AuraEnabled
    public List<String> searchTerms = new List<String>();
    @AuraEnabled
    public List<String> evidence = new List<String>();
    @AuraEnabled
    public Digest digest;
  }

  /** A Knowledge article matched to the failure. */
  public class ArticleHit {
    @AuraEnabled
    public String externalId;
    @AuraEnabled
    public Id articleVersionId;
    @AuraEnabled
    public Id knowledgeArticleId;
    @AuraEnabled
    public String title;
    @AuraEnabled
    public String summary;
    @AuraEnabled
    public String issue;
    @AuraEnabled
    public String cause;
    @AuraEnabled
    public String environment;
    @AuraEnabled
    public String resolution;
    @AuraEnabled
    public Integer score;
    @AuraEnabled
    public Boolean cited = false;
  }

  /** One ordered troubleshooting action. */
  public class Step {
    @AuraEnabled
    public Integer position;
    @AuraEnabled
    public String action;
    @AuraEnabled
    public String detail;
    @AuraEnabled
    public String command;
    @AuraEnabled
    public String expected;
    @AuraEnabled
    public String sourceArticle;
  }

  /** Claude's second pass: the grounded answer the rep actually works from. */
  public class Analysis {
    @AuraEnabled
    public String rootCause;
    @AuraEnabled
    public String confidence;
    @AuraEnabled
    public String confidenceReason;
    @AuraEnabled
    public List<Step> steps = new List<Step>();
    @AuraEnabled
    public List<ArticleHit> citedArticles = new List<ArticleHit>();
    @AuraEnabled
    public String escalation;
    @AuraEnabled
    public String customerReply;
    @AuraEnabled
    public String modelUsed;
  }
}
