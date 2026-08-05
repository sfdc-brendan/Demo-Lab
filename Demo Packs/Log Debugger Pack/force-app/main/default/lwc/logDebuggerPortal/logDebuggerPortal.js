import { LightningElement, api, track } from "lwc";
import {
  ACCEPTED_FORMATS,
  PHASE,
  BUSY_PHASES,
  SEVERITY_THEME,
  CONFIDENCE_THEME,
  buildStages,
  decorate,
  decorateSteps,
  describeDigest,
  badgeClass,
  readError
} from "c/logDebuggerCore";
import triage from "@salesforce/apex/LogDebuggerController.triage";
import findArticles from "@salesforce/apex/LogDebuggerController.findArticles";
import synthesize from "@salesforce/apex/LogDebuggerController.synthesize";

/**
 * Customer-facing log debugger for an Experience Cloud site.
 *
 * Runs the same three Apex calls as c/logDebugger on the Case page and shows the
 * same triage, the same retrieved articles, and the same grounded steps. What it
 * deliberately does not show is the part of the analysis written for an internal
 * audience: the escalation routing, which names internal teams, and the draft
 * reply a rep would send to this customer. Both are still produced by the model
 * and still stored on the Case when a rep runs it; they are simply not for the
 * person who filed the ticket.
 *
 * There is no record-id on the upload. The docs are explicit that omitting it
 * leaves the file private to the authenticated user who uploaded it, which is the
 * behaviour we want on a portal: the customer's log is their own, and it is not
 * attached to anything until a rep picks the case up.
 */
export default class LogDebuggerPortal extends LightningElement {
  /** Both are editable in Experience Builder so the site can set its own voice. */
  @api heading = "Troubleshoot a log file";
  @api
  introduction =
    "Upload the cluster or job log from the run that failed. We read it, work out what went wrong, and give you the steps to fix it, based on our published troubleshooting guides.";

  acceptedFormats = ACCEPTED_FORMATS;

  @track phase = PHASE.IDLE;
  @track documentId;
  @track fileName;
  @track triageResult;
  @track articles = [];
  @track analysis;
  @track errorMessage;

  showDigest = false;
  copyNotice;

  // ------------------------------------------------------------- lifecycle

  handleUploadFinished(event) {
    const [file] = event.detail.files;
    if (!file) {
      return;
    }
    this.reset();
    this.documentId = file.documentId;
    this.fileName = file.name;
    this.phase = PHASE.READY;
  }

  async handleAnalyze() {
    this.errorMessage = undefined;
    this.analysis = undefined;

    try {
      this.phase = PHASE.TRIAGING;
      this.triageResult = await triage({ contentDocumentId: this.documentId });

      this.phase = PHASE.SEARCHING;
      const hits = await findArticles({
        searchTerms: this.triageResult.searchTerms
      });
      this.articles = decorate(hits);

      this.phase = PHASE.SYNTHESIZING;
      this.analysis = await synthesize({
        contentDocumentId: this.documentId,
        triageJson: JSON.stringify(this.triageResult),
        articleExternalIds: this.articles.map((a) => a.externalId)
      });

      this.phase = PHASE.DONE;
    } catch (error) {
      this.errorMessage = readError(
        error,
        "We could not read that log. Check the file and try again."
      );
      this.phase = this.triageResult ? PHASE.DONE : PHASE.READY;
    }
  }

  handleToggleDigest() {
    this.showDigest = !this.showDigest;
  }

  handleStartOver() {
    this.reset();
    this.phase = PHASE.IDLE;
  }

  /**
   * Toasts are a Lightning Experience affordance and do not render on an LWR
   * site, so the copy confirmation is inline text instead.
   */
  async handleCopy(event) {
    const text = event.currentTarget.dataset.copy;
    try {
      await navigator.clipboard.writeText(text);
      this.copyNotice = "Copied to your clipboard.";
    } catch {
      this.copyNotice = "Copying is blocked here. Select the text and copy it.";
    }
  }

  // ------------------------------------------------------------- derived UI

  get stages() {
    return buildStages(this.phase, "log-stage");
  }

  get decoratedSteps() {
    return decorateSteps(this.analysis);
  }

  get hasArticles() {
    return this.articles.length > 0;
  }

  get hasCitations() {
    return !!this.analysis && this.analysis.citedArticles.length > 0;
  }

  get isBusy() {
    return BUSY_PHASES.includes(this.phase);
  }

  get showUpload() {
    return this.phase === PHASE.IDLE;
  }

  get showFileCard() {
    return this.phase !== PHASE.IDLE;
  }

  get showTriage() {
    return !!this.triageResult && !this.isBusy;
  }

  get showAnalysis() {
    return !!this.analysis && this.phase === PHASE.DONE;
  }

  get analyzeDisabled() {
    return this.isBusy || !this.documentId;
  }

  get digestToggleLabel() {
    return this.showDigest
      ? "Hide what we read"
      : "Show what we read from your log";
  }

  get digestSummary() {
    return describeDigest(this.triageResult && this.triageResult.digest);
  }

  get severityClass() {
    return badgeClass(
      SEVERITY_THEME,
      this.triageResult && this.triageResult.severity
    );
  }

  get confidenceClass() {
    return badgeClass(
      CONFIDENCE_THEME,
      this.analysis && this.analysis.confidence
    );
  }

  get confidenceLabel() {
    return this.analysis ? `${this.analysis.confidence} confidence` : "";
  }

  // ------------------------------------------------------------- internals

  reset() {
    this.documentId = undefined;
    this.fileName = undefined;
    this.triageResult = undefined;
    this.articles = [];
    this.analysis = undefined;
    this.errorMessage = undefined;
    this.showDigest = false;
    this.copyNotice = undefined;
  }
}
