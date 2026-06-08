import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getTemplate from '@salesforce/apex/IntakeRuntimeController.getTemplate';
import getAvailableTemplates from '@salesforce/apex/IntakeRuntimeController.getAvailableTemplates';
import submitIntake from '@salesforce/apex/IntakeRuntimeController.submitIntake';
import attachIntakePDF from '@salesforce/apex/IntakeRuntimeController.attachIntakePDF';
import getDraftIntake from '@salesforce/apex/IntakeRuntimeController.getDraftIntake';
import saveDraftIntake from '@salesforce/apex/IntakeRuntimeController.saveDraftIntake';
import getTranscriptEntries from '@salesforce/apex/IntakeRuntimeController.getTranscriptEntries';
import getVoiceCallContext from '@salesforce/apex/IntakeRuntimeController.getVoiceCallContext';
import runAnalysis from '@salesforce/apex/IntakeRuntimeController.runAnalysis';
import USER_LOCALE from '@salesforce/i18n/locale';

const ANALYSIS_DEBOUNCE_MS = 3000;
const DRAFT_SAVE_DEBOUNCE_MS = 2000;
const TRANSCRIPT_POLL_MS = 5000;

export default class IntakeRuntime extends NavigationMixin(LightningElement) {
    @api recordId;
    @api templateId;
    @api previewMode = false;
    @api previewBundle;

    bundle;
    answers = {};
    isLoading = true;
    isSubmitting = false;
    isSubmitted = false;
    showConfirmModal = false;
    newIntakeId;
    intakeName;
    errorMessage;
    voiceCallContext;
    transcriptUtterances = [];
    suggestions = {};
    isAnalyzing = false;
    locale = 'en_US';

    availableTemplates = [];
    showTemplatePicker = false;
    selectedTemplateValue = '';

    _prefillApplied = false;
    _toolkitSubscribed = false;
    _analysisTimer;
    _draftSaveTimer;
    _draftIntakeId;
    _lastAnalyzedCount = 0;
    _manuallyEdited = new Set();
    _expandedSections = [];
    _transcriptPollTimer;
    _liveTranscriptActive = false;
    _knownEntryIds = new Set();
    _lastSeenSeq = -1;

    connectedCallback() {
        this.locale = this.normalizeLocale(USER_LOCALE);
        this.initialize();
    }

    async initialize() {
        if (this.previewMode && this.previewBundle) {
            this.bundle = this.previewBundle;
            this.applyTemplateLocaleFallback();
            this.isLoading = false;
            return;
        }
        if (!this.templateId) {
            await this.loadAvailableTemplates();
            return;
        }
        await this.loadTemplate();
    }

    async loadAvailableTemplates() {
        try {
            const templates = await getAvailableTemplates();
            this.availableTemplates = templates || [];
            if (this.availableTemplates.length === 0) {
                this.errorMessage = 'No active intake templates found. Open the Intake Builder app to create one, then refresh this page.';
                this.isLoading = false;
                return;
            }
            if (this.availableTemplates.length === 1) {
                this.templateId = this.availableTemplates[0].templateId;
                this.selectedTemplateValue = this.templateId;
                await this.loadTemplate();
                return;
            }
            this.showTemplatePicker = true;
            this.isLoading = false;
        } catch (e) {
            this.errorMessage = this.reduceError(e);
            this.isLoading = false;
        }
    }

    async loadTemplate() {
        try {
            this.bundle = await getTemplate({ templateId: this.templateId });
            if (!this.bundle) {
                this.errorMessage = 'Template not found.';
                this.isLoading = false;
                return;
            }
            this.applyTemplateLocaleFallback();
            this.isLoading = false;
            await this.loadVoiceCallContext();
        } catch (e) {
            this.errorMessage = this.reduceError(e);
            this.isLoading = false;
        }
    }

    handleTemplatePicked(event) {
        const id = event.detail.value;
        if (!id) return;
        this.selectedTemplateValue = id;
        this.templateId = id;
        this.showTemplatePicker = false;
        this.isLoading = true;
        this.loadTemplate();
    }

    get templateOptions() {
        return (this.availableTemplates || []).map((t) => ({
            label: t.description ? `${t.name} — ${t.description}` : t.name,
            value: t.templateId
        }));
    }

    get showTemplatePickerState() {
        return this.showTemplatePicker && !this.isLoading && !this.hasError && !this.isSubmitted;
    }

    applyTemplateLocaleFallback() {
        const supported = (this.bundle?.questions || [])
            .flatMap((q) => (q.translations || []).map((t) => t.locale));
        if (!supported.includes(this.locale) && this.bundle?.defaultLocale) {
            this.locale = this.bundle.defaultLocale;
        }
    }

    normalizeLocale(raw) {
        if (!raw) return 'en_US';
        return raw.replace('-', '_');
    }

    renderedCallback() {
        if (this._toolkitSubscribed || this.previewMode) return;
        const toolkitApi = this.template.querySelector(
            'lightning-service-cloud-voice-toolkit-api'
        );
        if (toolkitApi) {
            toolkitApi.addEventListener('transcript', this.handleTranscriptEvent);
            toolkitApi.addEventListener('callended', this.handleCallEnded);
            this._toolkitSubscribed = true;
        }
    }

    disconnectedCallback() {
        const toolkitApi = this.template.querySelector(
            'lightning-service-cloud-voice-toolkit-api'
        );
        if (toolkitApi) {
            toolkitApi.removeEventListener('transcript', this.handleTranscriptEvent);
            toolkitApi.removeEventListener('callended', this.handleCallEnded);
        }
        this._toolkitSubscribed = false;
        if (this._analysisTimer) clearTimeout(this._analysisTimer);
        if (this._draftSaveTimer) clearTimeout(this._draftSaveTimer);
        if (this._transcriptPollTimer) clearTimeout(this._transcriptPollTimer);
        this._removeEscHandler();
    }

    handleTranscriptEvent = (event) => {
        const { content, sender } = event.detail;
        if (!content?.text) return;
        this._liveTranscriptActive = true;
        const role = sender?.role || 'Customer';
        const label = role === 'Agent' || role === 'Supervisor' ? role : 'Customer';
        this.transcriptUtterances = [
            ...this.transcriptUtterances,
            {
                id: event.detail.id,
                text: content.text,
                role: label,
                timestamp: event.detail.clientSentTimestamp
            }
        ];
        this.scheduleAnalysis();
    };

    handleCallEnded = () => {
        if (this._transcriptPollTimer) clearTimeout(this._transcriptPollTimer);
        if (this.transcriptUtterances.length > this._lastAnalyzedCount) {
            this.runAnalysis();
        }
    };

    scheduleAnalysis() {
        if (this.previewMode) return;
        if (this._analysisTimer) clearTimeout(this._analysisTimer);
        this._analysisTimer = setTimeout(() => this.runAnalysis(), ANALYSIS_DEBOUNCE_MS);
    }

    async loadVoiceCallContext() {
        if (!this.recordId) return;
        try {
            this.voiceCallContext = await getVoiceCallContext({ voiceCallId: this.recordId });
            this.applyPrefill();
        } catch (e) {
            // Optional context
        }
        await this.loadDraft();
        await this.loadNativeTranscript();
        this.startTranscriptPolling();
    }

    async loadDraft() {
        if (!this.recordId || !this.templateId) return;
        try {
            const draft = await getDraftIntake({
                templateId: this.templateId,
                voiceCallId: this.recordId
            });
            if (draft && draft.answersJson) {
                const savedAnswers = JSON.parse(draft.answersJson);
                this.answers = { ...this.answers, ...savedAnswers };
                this._draftIntakeId = draft.intakeId;
            }
        } catch (e) {
            // Best-effort
        }
    }

    async loadNativeTranscript() {
        if (!this.recordId) return;
        try {
            const entries = await getTranscriptEntries({
                voiceCallId: this.recordId,
                lastSeenSeq: this._lastSeenSeq
            });
            if (entries && entries.length > 0) {
                this._liveTranscriptActive = true;
                const newUtterances = [];
                for (const entry of entries) {
                    const id = `native-${entry.seq}`;
                    if (!this._knownEntryIds.has(id)) {
                        this._knownEntryIds.add(id);
                        newUtterances.push({
                            id,
                            text: entry.message,
                            role: entry.isCustomer ? 'Customer' : 'Agent',
                            timestamp: entry.entryTime
                        });
                    }
                    if (entry.seq > this._lastSeenSeq) this._lastSeenSeq = entry.seq;
                }
                if (newUtterances.length > 0) {
                    this.transcriptUtterances = [...this.transcriptUtterances, ...newUtterances];
                    this.scheduleAnalysis();
                }
            }
        } catch (e) {
            // Best-effort
        }
    }

    startTranscriptPolling() {
        if (!this.recordId || this.isSubmitted) return;
        this._transcriptPollTimer = setTimeout(async () => {
            if (this.isSubmitted) return;
            await this.loadNativeTranscript();
            this.startTranscriptPolling();
        }, TRANSCRIPT_POLL_MS);
    }

    scheduleDraftSave() {
        if (this.previewMode || !this.recordId || this.isSubmitted) return;
        if (this._draftSaveTimer) clearTimeout(this._draftSaveTimer);
        this._draftSaveTimer = setTimeout(() => this.saveDraft(), DRAFT_SAVE_DEBOUNCE_MS);
    }

    async saveDraft() {
        if (this.previewMode || !this.recordId || !this.templateId || this.isSubmitted) return;
        try {
            const result = await saveDraftIntake({
                templateId: this.templateId,
                voiceCallId: this.recordId,
                answersJson: JSON.stringify(this.answers)
            });
            if (result) this._draftIntakeId = result.intakeId;
        } catch (e) {
            // Best-effort
        }
    }

    applyPrefill() {
        if (this._prefillApplied || !this.voiceCallContext) return;
        this._prefillApplied = true;
        const updated = { ...this.answers };
        const questions = this.bundle?.questions || [];
        for (const q of questions) {
            const targetField = (q.targetField || '').toLowerCase();
            if (targetField === 'customer_name__c' && this.voiceCallContext.contactName && !updated[q.developerName]) {
                updated[q.developerName] = this.voiceCallContext.contactName;
            } else if (targetField === 'callback_phone__c' && this.voiceCallContext.callbackPhone && !updated[q.developerName]) {
                updated[q.developerName] = this.voiceCallContext.callbackPhone;
            }
        }
        this.answers = updated;
    }

    get hasError() {
        return !this.isLoading && !this.isSubmitted && this.errorMessage != null;
    }

    get showIntakeFlow() {
        return !this.isLoading && !this.isSubmitted && !this.hasError && this.questions.length > 0;
    }

    get questions() {
        return this.bundle?.questions || [];
    }

    get totalQuestions() {
        return this.visibleQuestions.length;
    }

    get visibleQuestions() {
        return this.questions.filter((q) => this.isQuestionVisible(q));
    }

    isQuestionVisible(question) {
        const rules = question.visibilityRules || [];
        if (rules.length === 0) return true;

        const groups = new Map();
        for (const rule of rules) {
            const g = rule.logicGroup || 'default';
            if (!groups.has(g)) groups.set(g, []);
            groups.get(g).push(rule);
        }

        for (const groupRules of groups.values()) {
            const groupPasses = groupRules.every((r) => this.evaluateRule(r));
            if (groupPasses) return true;
        }
        return false;
    }

    evaluateRule(rule) {
        const sourceVal = this.answers[rule.sourceQuestionDeveloperName];
        const sv = sourceVal == null ? '' : String(sourceVal);
        const target = rule.value == null ? '' : String(rule.value);

        switch (rule.operator) {
            case 'equals':
                return sv === target;
            case 'not_equals':
                return sv !== target;
            case 'contains':
                return sv.toLowerCase().includes(target.toLowerCase());
            case 'in':
                return target.split(';').map((s) => s.trim()).includes(sv);
            case 'is_blank':
                return sv === '';
            case 'is_not_blank':
                return sv !== '';
            default:
                return true;
        }
    }

    get hasTranscript() {
        return this.transcriptUtterances.length > 0;
    }

    get transcriptStatusLabel() {
        const count = this.transcriptUtterances.length;
        if (this.isAnalyzing) return `Analyzing ${count} utterances...`;
        if (this._liveTranscriptActive && count > 0) return `Live transcript — ${count} utterance${count > 1 ? 's' : ''} captured`;
        if (count > 0) return `${count} utterance${count > 1 ? 's' : ''} captured`;
        return 'Waiting for voice transcript...';
    }

    get showPasteArea() {
        return !this._liveTranscriptActive;
    }

    get showAnalyzeButton() {
        return this.hasTranscript && !this.isAnalyzing && !this.previewMode;
    }

    get hasSuggestions() {
        return Object.keys(this.suggestions).length > 0;
    }

    get suggestionsCount() {
        return Object.keys(this.suggestions).length;
    }

    get suggestionsLabel() {
        const count = this.suggestionsCount;
        return `${count} AI suggestion${count > 1 ? 's' : ''} pending`;
    }

    get answeredCount() {
        return this.visibleQuestions.filter((q) => this.answers[q.developerName]).length;
    }

    get confirmSummary() {
        return `${this.answeredCount} of ${this.totalQuestions} questions answered.`;
    }

    get hasUnansweredRequired() {
        return this.visibleQuestions.some((q) => q.isRequired && !this.answers[q.developerName]);
    }

    get progressPercent() {
        if (this.totalQuestions === 0) return 0;
        return Math.round((this.answeredCount / this.totalQuestions) * 100);
    }

    get progressLabel() {
        return `${this.answeredCount} of ${this.totalQuestions} answered`;
    }

    get progressBarStyle() {
        return `width: ${this.progressPercent}%;`;
    }

    get transcriptUtteranceLabel() {
        const count = this.transcriptUtterances.length;
        return `${count} utterance${count === 1 ? '' : 's'}`;
    }

    get hasSidePanel() {
        return this._liveTranscriptActive;
    }

    get gridClass() {
        return this.hasSidePanel ? 'ix-grid ix-grid--with-side' : 'ix-grid';
    }

    get questionItems() {
        return this.visibleQuestions.map((q, idx) => {
            const answer = this.answers[q.developerName] || '';
            const isAnswered = !!answer;
            const isExpanded = this._expandedSections.includes(q.developerName);
            const suggestionValue = this.suggestions[q.developerName];
            const hasSuggestion = !!suggestionValue;

            const localizedQ = this.localizedFor(q, 'questionText') || q.questionText;

            // Status icon: success → answered, AI dot → suggestion ready on an
            // unanswered row, empty otherwise. Only one is rendered.
            const showAiMark = !isAnswered && hasSuggestion;
            const showEmptyMark = !isAnswered && !hasSuggestion;

            const previewText = isAnswered && !isExpanded ? this.previewFor(answer) : '';

            const rowClasses = ['ix-row'];
            if (isExpanded) rowClasses.push('ix-row--expanded');
            else if (isAnswered) rowClasses.push('ix-row--answered');
            else if (showAiMark) rowClasses.push('ix-row--ai');

            const chevronClass = isExpanded
                ? 'ix-row__chevron ix-row__chevron--open'
                : 'ix-row__chevron';

            return {
                developerName: q.developerName,
                questionText: localizedQ,
                question: q,
                answer,
                required: q.isRequired,
                stepLabel: `${idx + 1}`,
                isExpanded,
                isExpandedString: isExpanded ? 'true' : 'false',
                isAnswered,
                hasSuggestion,
                showAiMark,
                showEmptyMark,
                suggestion: suggestionValue ? { questionName: q.developerName, value: suggestionValue } : null,
                answerPreview: previewText,
                rowClass: rowClasses.join(' '),
                chevronClass,
                chevronAlt: isExpanded ? 'Collapse' : 'Expand'
            };
        });
    }

    previewFor(answer) {
        if (Array.isArray(answer)) return answer.join(', ');
        const str = String(answer);
        return str.length > 80 ? `${str.slice(0, 77)}...` : str;
    }

    localizedFor(question, fieldName) {
        const t = (question.translations || []).find((tr) => tr.locale === this.locale);
        return t ? t[fieldName] : null;
    }

    get transcriptEntries() {
        return this.transcriptUtterances.map((u, idx) => ({
            seq: idx,
            message: u.text,
            actorName: u.role,
            actorType: u.role,
            isCustomer: u.role === 'Customer'
        }));
    }

    handleToggleSection(event) {
        const name = event.currentTarget.dataset.name;
        if (this._expandedSections.includes(name)) {
            this._expandedSections = this._expandedSections.filter((n) => n !== name);
        } else {
            this._expandedSections = [...this._expandedSections, name];
        }
    }

    handleAnswerChange(event) {
        const { questionName, value } = event.detail;
        this._manuallyEdited.add(questionName);
        this.answers = { ...this.answers, [questionName]: value };
        this.scheduleDraftSave();
    }

    async handleAnalyzeTranscript() {
        await this.runAnalysis();
    }

    async runAnalysis() {
        if (this.previewMode || this.isAnalyzing || this.isSubmitted) return;
        if (this.transcriptUtterances.length === 0) return;
        if (this.transcriptUtterances.length === this._lastAnalyzedCount) return;

        this.isAnalyzing = true;
        this._lastAnalyzedCount = this.transcriptUtterances.length;

        try {
            const transcriptText = this.transcriptUtterances
                .map((u) => `${u.role}: ${u.text}`)
                .join('\n');

            const visibleDevNames = new Set(this.visibleQuestions.map((q) => q.developerName));
            const questionsPayload = this.visibleQuestions.map((q) => ({
                developerName: q.developerName,
                questionText: q.questionText,
                answerType: q.answerType,
                picklistValuesStr: (q.picklistOptions || []).map((o) => o.value).join(';'),
                aiHint: q.aiExtractionHint || ''
            }));

            const result = await runAnalysis({
                templateId: this.templateId,
                questionsJson: JSON.stringify(questionsPayload),
                transcriptText
            });

            const filtered = {};
            for (const [k, v] of Object.entries(result || {})) {
                if (visibleDevNames.has(k)) filtered[k] = v;
            }
            this.applyAiResults(filtered);
        } catch (e) {
            // Best-effort
        } finally {
            this.isAnalyzing = false;
        }
    }

    applyAiResults(result) {
        const updatedAnswers = { ...this.answers };
        const newSuggestions = { ...this.suggestions };
        let autoFilledCount = 0;

        for (const [key, value] of Object.entries(result)) {
            if (this._manuallyEdited.has(key) && updatedAnswers[key]) {
                if (updatedAnswers[key] !== value) newSuggestions[key] = value;
            } else {
                updatedAnswers[key] = value;
                delete newSuggestions[key];
                autoFilledCount++;
            }
        }

        this.answers = updatedAnswers;
        this.suggestions = newSuggestions;
        this.scheduleDraftSave();

        // Intentionally do NOT auto-expand any rows here. The status icon flips
        // to a green check on each newly answered row, and unanswered rows with
        // a pending suggestion show the AI dot. The CSR opens what they want.
        if (autoFilledCount > 0) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'AI Auto-Fill',
                    message: `${autoFilledCount} answer${autoFilledCount > 1 ? 's' : ''} extracted from the transcript.`,
                    variant: 'success'
                })
            );
        }
    }

    handleAcceptQuestionSuggestion(event) {
        const name = event.currentTarget.dataset.name;
        const value = this.suggestions[name];
        if (!value) return;
        this.answers = { ...this.answers, [name]: value };
        const updated = { ...this.suggestions };
        delete updated[name];
        this.suggestions = updated;
        this.scheduleDraftSave();
    }

    handleDismissQuestionSuggestion(event) {
        const name = event.currentTarget.dataset.name;
        const updated = { ...this.suggestions };
        delete updated[name];
        this.suggestions = updated;
    }

    handleAcceptAllSuggestions() {
        const updated = { ...this.answers };
        for (const [key, value] of Object.entries(this.suggestions)) updated[key] = value;
        this.answers = updated;
        this.suggestions = {};
        this.scheduleDraftSave();
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Suggestions Applied',
                message: 'All AI suggestions have been accepted.',
                variant: 'success'
            })
        );
    }

    handleSubmit() {
        if (!this.allRegexValid()) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Fix validation errors',
                    message: 'One or more answers do not match the required format.',
                    variant: 'error'
                })
            );
            return;
        }
        this.showConfirmModal = true;
        this._boundEscHandler = this._handleEscKey.bind(this);
        window.addEventListener('keyup', this._boundEscHandler);
        Promise.resolve().then(() => this._trapFocus());
    }

    allRegexValid() {
        const questionEls = this.template.querySelectorAll('c-intake-question');
        let valid = true;
        questionEls.forEach((el) => {
            if (!el.validate()) valid = false;
        });
        return valid;
    }

    handleCancelSubmit() {
        this.showConfirmModal = false;
        this._removeEscHandler();
    }

    async handleConfirmSubmit() {
        this.showConfirmModal = false;
        this._removeEscHandler();
        if (this._draftSaveTimer) clearTimeout(this._draftSaveTimer);
        this.isSubmitting = true;
        try {
            this.newIntakeId = await submitIntake({
                templateId: this.templateId,
                voiceCallId: this.recordId,
                answersJson: JSON.stringify(this.answers)
            });
            this.isSubmitted = true;
            this.intakeName = this.newIntakeId;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Intake Submitted',
                    message: 'Submission has been recorded.',
                    variant: 'success'
                })
            );
            try {
                await attachIntakePDF({ intakeId: this.newIntakeId });
            } catch (pdfErr) {
                // PDF generation is best-effort
            }
        } catch (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Submission Failed',
                    message: this.reduceError(error),
                    variant: 'error',
                    mode: 'sticky'
                })
            );
        } finally {
            this.isSubmitting = false;
        }
    }

    _handleEscKey(event) {
        if (event.key === 'Escape' && this.showConfirmModal) this.handleCancelSubmit();
    }

    _removeEscHandler() {
        if (this._boundEscHandler) {
            window.removeEventListener('keyup', this._boundEscHandler);
            this._boundEscHandler = null;
        }
    }

    _trapFocus() {
        const modal = this.template.querySelector('[data-id="confirm-modal"]');
        if (!modal) return;
        const focusable = modal.querySelectorAll('lightning-button');
        if (focusable.length > 0) focusable[focusable.length - 1].focus();
    }

    handleRetry() {
        this.errorMessage = null;
        this.isLoading = true;
        this.initialize();
    }

    handleViewIntake() {
        if (!this.newIntakeId) return;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.newIntakeId,
                actionName: 'view'
            }
        });
    }

    handleTranscriptPaste(event) {
        const text = event.detail.text;
        if (!text) return;

        const lines = text.split('\n').filter((line) => line.trim());
        const newUtterances = [];

        for (const line of lines) {
            const trimmed = line.trim();
            if (!trimmed || trimmed.length < 2) continue;

            const roleMatch = trimmed.match(
                /^(Agent|Customer|Supervisor|Rep|CSR|Caller|End User):\s*(.+)/i
            );
            if (roleMatch) {
                const role = roleMatch[1].toLowerCase();
                const isAgent = ['agent', 'rep', 'csr', 'supervisor'].includes(role);
                newUtterances.push({
                    id: `paste-${Date.now()}-${newUtterances.length}`,
                    text: roleMatch[2],
                    role: isAgent ? 'Agent' : 'Customer',
                    timestamp: Date.now()
                });
            } else {
                newUtterances.push({
                    id: `paste-${Date.now()}-${newUtterances.length}`,
                    text: trimmed,
                    role: 'Customer',
                    timestamp: Date.now()
                });
            }
        }

        if (newUtterances.length > 0) {
            this.transcriptUtterances = newUtterances;
            this._lastAnalyzedCount = 0;
            this.runAnalysis();
        }
    }

    reduceError(error) {
        if (typeof error === 'string') return error;
        if (error?.body?.message) return error.body.message;
        if (error?.message) return error.message;
        if (Array.isArray(error?.body)) return error.body.map((e) => e.message).join(', ');
        return 'An unexpected error occurred.';
    }
}
