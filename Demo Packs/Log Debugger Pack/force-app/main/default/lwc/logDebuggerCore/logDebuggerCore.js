/**
 * Shared state machine and formatting for the two log debugger surfaces.
 *
 * c/logDebugger runs on the Case page for a support rep; c/logDebuggerPortal runs
 * on an Experience Cloud site for the customer. They drive the same three Apex
 * calls in the same order and present the same triage and steps, so the phase
 * model and the display formatting live here rather than in both files where they
 * would drift apart the first time either one is touched.
 *
 * Everything exported is pure. The components own their own state and their own
 * markup; this module only decides what a value should look like.
 */

export const ACCEPTED_FORMATS = [".log", ".txt", ".out", ".err"];

export const PHASE = {
  IDLE: "idle",
  READY: "ready",
  TRIAGING: "triaging",
  SEARCHING: "searching",
  SYNTHESIZING: "synthesizing",
  DONE: "done"
};

export const BUSY_PHASES = [PHASE.TRIAGING, PHASE.SEARCHING, PHASE.SYNTHESIZING];

/** Stage order, used to decide whether a stage is pending, running, or complete. */
export const STAGES = [
  { key: PHASE.TRIAGING, label: "Reading the log and classifying the failure" },
  { key: PHASE.SEARCHING, label: "Searching the knowledge base" },
  { key: PHASE.SYNTHESIZING, label: "Drafting grounded troubleshooting steps" }
];

/*
 * lightning-badge has no variant attribute; SLDS theme utility classes are the
 * documented way to colour one, and they carry the SLDS 2 feedback hooks with
 * them so the badges follow the org into dark mode.
 *
 * Severity and confidence read in opposite directions: a Low severity is good
 * news and a Low confidence is not, so they get separate lookups.
 */
export const SEVERITY_THEME = {
  critical: "slds-theme_error",
  high: "slds-theme_error",
  medium: "slds-theme_warning",
  low: "slds-theme_success"
};

export const CONFIDENCE_THEME = {
  high: "slds-theme_success",
  medium: "slds-theme_warning",
  low: "slds-theme_error"
};

/**
 * Expands the stage list for the current phase.
 *
 * @param phase     the component's current PHASE
 * @param baseClass CSS class each row carries, minus the active modifier
 */
export function buildStages(phase, baseClass) {
  const activeIndex = STAGES.findIndex((stage) => stage.key === phase);
  const finished = phase === PHASE.DONE;

  return STAGES.map((stage, index) => {
    const complete = finished || (activeIndex > -1 && index < activeIndex);
    const running = index === activeIndex;
    return {
      key: stage.key,
      label: stage.label,
      running,
      complete,
      iconName: complete ? "utility:success" : "utility:routing_offline",
      itemClass: `slds-p-vertical_xx-small ${baseClass}${
        running || complete ? ` ${baseClass}_active` : ""
      }`
    };
  });
}

/**
 * Adds the view-only fields the templates need to each retrieved article.
 *
 * Apex results reach LWC frozen, so this rebuilds each hit rather than mutating
 * it. Scores are shown relative to the strongest match: the absolute number is an
 * internal weighting and would mean nothing to whoever is reading it.
 */
export function decorate(hits) {
  const best = hits.reduce((max, hit) => Math.max(max, hit.score), 0) || 1;
  return hits.map((hit) => {
    const matchPercent = Math.round((hit.score / best) * 100);
    return {
      ...hit,
      selected: true,
      matchPercent,
      matchLabel: `Match strength ${matchPercent}%`
    };
  });
}

/** Adds the flags the step template branches on. */
export function decorateSteps(analysis) {
  if (!analysis) {
    return [];
  }
  return analysis.steps.map((step) => ({
    ...step,
    hasCommand: !!step.command,
    hasSource: !!step.sourceArticle
  }));
}

/** One line on how far the distiller got, for the file card. */
export function describeDigest(digest) {
  if (!digest) {
    return "";
  }
  const kept = formatNumber(digest.retainedLines);
  const total = formatNumber(digest.originalLines);
  const size = Math.max(1, Math.round(digest.originalBytes / 1024));
  return `${total} lines (${size} KB) reduced to ${kept} lines of signal`;
}

export function badgeClass(themes, value) {
  const theme = themes[(value || "").toLowerCase()] || "";
  return `slds-var-m-left_xx-small ${theme}`.trim();
}

/**
 * Pulls the message Apex actually threw.
 *
 * The default AuraHandledException text is "Script-thrown exception", which hides
 * exactly the detail that is useful here, such as the log being over the limit.
 */
export function readError(error, fallback) {
  return (
    error?.body?.message ||
    error?.message ||
    fallback ||
    "Something went wrong running the analysis. Try again."
  );
}

export function formatNumber(value) {
  return typeof value === "number" ? value.toLocaleString() : value;
}
