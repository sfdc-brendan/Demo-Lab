import { LightningElement, api, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
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
import saveToCase from "@salesforce/apex/LogDebuggerController.saveToCase";

export default class LogDebugger extends LightningElement {
  @api recordId;

  acceptedFormats = ACCEPTED_FORMATS;

  @track phase = PHASE.IDLE;
  @track documentId;
  @track fileName;
  @track triageResult;
  @track articles = [];
  @track analysis;
  @track errorMessage;

  saving = false;
  postToChatter = true;
  showDigest = false;

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
        articleExternalIds: this.selectedExternalIds
      });

      this.phase = PHASE.DONE;
    } catch (error) {
      this.errorMessage = readError(error);
      this.phase = this.triageResult ? PHASE.DONE : PHASE.READY;
    }
  }

  /**
   * Re-runs only the synthesis pass.
   *
   * Changing which articles ground the answer should not cost another triage call,
   * and being able to watch the answer change as articles are toggled is the
   * clearest demonstration that the grounding is real.
   */
  async handleResynthesize() {
    this.errorMessage = undefined;
    try {
      this.phase = PHASE.SYNTHESIZING;
      this.analysis = await synthesize({
        contentDocumentId: this.documentId,
        triageJson: JSON.stringify(this.triageResult),
        articleExternalIds: this.selectedExternalIds
      });
      this.phase = PHASE.DONE;
    } catch (error) {
      this.errorMessage = readError(error);
      this.phase = PHASE.DONE;
    }
  }

  async handleSave() {
    this.saving = true;
    try {
      await saveToCase({
        caseId: this.recordId,
        analysisJson: JSON.stringify(this.analysis),
        postToChatter: this.postToChatter
      });
      this.toast(
        "Saved to case",
        "The analysis is on the case record.",
        "success"
      );
    } catch (error) {
      this.toast("Could not save", readError(error), "error");
    } finally {
      this.saving = false;
    }
  }

  handleArticleToggle(event) {
    const externalId = event.target.dataset.externalId;
    const selected = event.target.checked;
    this.articles = this.articles.map((article) => {
      return article.externalId === externalId
        ? { ...article, selected }
        : article;
    });
  }

  handleChatterToggle(event) {
    this.postToChatter = event.target.checked;
  }

  handleToggleDigest() {
    this.showDigest = !this.showDigest;
  }

  handleStartOver() {
    this.reset();
    this.phase = PHASE.IDLE;
  }

  async handleCopy(event) {
    const text = event.currentTarget.dataset.copy;
    try {
      await navigator.clipboard.writeText(text);
      this.toast("Copied", "", "success");
    } catch {
      // Clipboard access is blocked in some embedded contexts.
      this.toast(
        "Could not copy",
        "Select the text and copy it manually.",
        "warning"
      );
    }
  }

  // ------------------------------------------------------------- derived UI

  get stages() {
    return buildStages(this.phase, "log-stage");
  }

  get decoratedSteps() {
    return decorateSteps(this.analysis);
  }

  get selectedExternalIds() {
    return this.articles
      .filter((article) => article.selected)
      .map((a) => a.externalId);
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

  get showProgress() {
    return this.isBusy;
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

  get resynthesizeDisabled() {
    return this.isBusy || this.selectedExternalIds.length === 0;
  }

  get digestToggleLabel() {
    return this.showDigest
      ? "Hide the distilled log"
      : "Show the distilled log";
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
  }

  toast(title, message, variant) {
    this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
  }
}
