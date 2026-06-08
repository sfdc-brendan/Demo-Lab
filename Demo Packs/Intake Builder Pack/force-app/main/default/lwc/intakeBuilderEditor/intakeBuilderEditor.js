import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getTemplate from '@salesforce/apex/IntakeBuilderController.getTemplate';
import saveTemplate from '@salesforce/apex/IntakeBuilderController.saveTemplate';
import validateTemplate from '@salesforce/apex/IntakeBuilderController.validateTemplate';
import activateTemplate from '@salesforce/apex/IntakeBuilderController.activateTemplate';
import archiveTemplate from '@salesforce/apex/IntakeBuilderController.archiveTemplate';
import newVersion from '@salesforce/apex/IntakeBuilderController.newVersion';
import generateQuestionsFromDescription from '@salesforce/apex/IntakeBuilderController.generateQuestionsFromDescription';
import createTestRecordAndPdf from '@salesforce/apex/IntakeBuilderController.createTestRecordAndPdf';

const STATUS_OPTIONS = [
    { label: 'Draft', value: 'Draft' },
    { label: 'Active', value: 'Active' },
    { label: 'Archived', value: 'Archived' }
];

const LOCALE_OPTIONS = [
    { label: 'English (US)', value: 'en_US' },
    { label: 'Spanish (Mexico)', value: 'es_MX' },
    { label: 'French (France)', value: 'fr_FR' },
    { label: 'German (Germany)', value: 'de_DE' },
    { label: 'Portuguese (Brazil)', value: 'pt_BR' },
    { label: 'Japanese (Japan)', value: 'ja_JP' }
];

const SCENARIO_PRESET_OPTIONS = [
    { label: 'Blown / Flat Tire', value: 'blown_tire' },
    { label: 'Dead Battery / Jump Start', value: 'dead_battery' },
    { label: 'Tow Request', value: 'tow' }
];

const SCENARIO_PRESET_LABELS = {
    blown_tire: 'Blown / Flat Tire',
    dead_battery: 'Dead Battery / Jump Start',
    tow: 'Tow Request'
};

const SCENARIO_PRESET_QUESTIONS = {
    blown_tire: [
        {
            developerName: 'Tire_Position',
            questionText: 'Which tire is damaged?',
            answerType: 'picklist',
            isRequired: true,
            category: 'Tire Service',
            aiExtractionHint: 'Capture front/rear and driver/passenger side when available.',
            picklistValues: ['Front Driver', 'Front Passenger', 'Rear Driver', 'Rear Passenger', 'Unknown']
        },
        {
            developerName: 'Spare_Tire_Available',
            questionText: 'Does the customer have a usable spare tire?',
            answerType: 'boolean',
            isRequired: true,
            category: 'Tire Service',
            aiExtractionHint: 'Set true only if customer confirms spare is available and usable.'
        },
        {
            developerName: 'Tire_Size_Or_Spec',
            questionText: 'What tire size/specification is needed (if known)?',
            answerType: 'text',
            isRequired: false,
            category: 'Tire Service',
            aiExtractionHint: 'Capture tire size format like 225/65R17 when mentioned.'
        }
    ],
    dead_battery: [
        {
            developerName: 'Vehicle_Will_Not_Start',
            questionText: 'Does the vehicle fail to start (no crank / clicking)?',
            answerType: 'boolean',
            isRequired: true,
            category: 'Battery Service',
            aiExtractionHint: 'Set true when customer reports battery-related startup failure.'
        },
        {
            developerName: 'Battery_Accessibility',
            questionText: 'Is the battery accessible for a jump start?',
            answerType: 'picklist',
            isRequired: true,
            category: 'Battery Service',
            aiExtractionHint: 'Identify whether technician can reach the battery terminals.',
            picklistValues: ['Accessible', 'Not Accessible', 'Unsure']
        },
        {
            developerName: 'Electrical_Symptoms',
            questionText: 'What electrical symptoms are present?',
            answerType: 'textarea',
            isRequired: false,
            category: 'Battery Service',
            aiExtractionHint: 'Capture details like dim lights, rapid clicking, or no power.'
        }
    ],
    tow: [
        {
            developerName: 'Tow_Destination',
            questionText: 'Where should the vehicle be towed?',
            answerType: 'textarea',
            isRequired: true,
            category: 'Tow Service',
            aiExtractionHint: 'Capture full destination address or shop name.'
        },
        {
            developerName: 'Vehicle_Driveable',
            questionText: 'Is the vehicle currently driveable?',
            answerType: 'boolean',
            isRequired: true,
            category: 'Tow Service',
            aiExtractionHint: 'Set false when customer reports the vehicle cannot be driven safely.'
        },
        {
            developerName: 'Vehicle_Location_Context',
            questionText: 'Where is the vehicle located right now?',
            answerType: 'textarea',
            isRequired: true,
            category: 'Tow Service',
            aiExtractionHint: 'Capture exact pickup location and notable access details.'
        }
    ]
};

export default class IntakeBuilderEditor extends LightningElement {
    @api templateId;

    @track template = this.emptyTemplate();
    @track questions = [];
    @track picklistByQ = {};
    @track rulesByQ = {};
    @track translationsByQ = {};

    @track editingQuestionDevName;
    @track activeView = 'editor';

    statusOptions = STATUS_OPTIONS;
    localeOptions = LOCALE_OPTIONS;

    isLoading = false;
    isSaving = false;
    isGeneratingQuestions = false;
    isTestingPdf = false;
    dragSourceIndex = null;
    aiFormDescription = '';
    replaceExistingQuestions = true;
    uploadedBrandLogoName = '';
    selectedScenarioPresets = [];

    connectedCallback() {
        if (this.templateId) this.load();
    }

    emptyTemplate() {
        return {
            id: null,
            name: 'New Intake Template',
            status: 'Draft',
            description: '',
            targetObject: '',
            personaDescription: '',
            pdfHeader: '',
            pdfFooter: '',
            brandColor: '',
            brandLogoFileId: '',
            brandLogoStaticResource: '',
            defaultLocale: 'en_US',
            version: 1
        };
    }

    async load() {
        this.isLoading = true;
        try {
            const bundle = await getTemplate({ templateId: this.templateId });
            if (!bundle) {
                this.toast('Error', 'Template not found.', 'error');
                return;
            }
            this.template = {
                id: bundle.templateId,
                name: bundle.name,
                status: bundle.status,
                description: bundle.description,
                targetObject: bundle.targetObject,
                personaDescription: bundle.personaDescription,
                pdfHeader: bundle.pdfHeader,
                pdfFooter: bundle.pdfFooter || '',
                brandColor: bundle.brandColor || '',
                brandLogoFileId: bundle.brandLogoFileId || '',
                brandLogoStaticResource: bundle.brandLogoStaticResource || '',
                defaultLocale: bundle.defaultLocale || 'en_US',
                version: bundle.version
            };
            this.uploadedBrandLogoName = '';
            this.questions = (bundle.questions || []).map((q) => ({
                id: q.questionId,
                developerName: q.developerName,
                questionText: q.questionText,
                helpText: q.helpText,
                category: q.category,
                orderNum: q.orderNum,
                isRequired: q.isRequired,
                answerType: q.answerType || 'text',
                targetField: q.targetField,
                picklistSource: q.picklistSource || 'Static',
                picklistSourceObject: q.picklistSourceObject,
                picklistSourceField: q.picklistSourceField,
                lookupObject: q.lookupObject,
                validationRegex: q.validationRegex,
                validationErrorMessage: q.validationErrorMessage,
                aiExtractionHint: q.aiExtractionHint
            }));
            const pv = {}, rules = {}, trans = {};
            for (const q of bundle.questions || []) {
                pv[q.developerName] = (q.picklistOptions || []).map((p, i) => ({
                    label: p.label, value: p.value, orderNum: i + 1
                }));
                rules[q.developerName] = (q.visibilityRules || []).map((r) => ({
                    sourceQuestionDeveloperName: r.sourceQuestionDeveloperName,
                    operator: r.operator,
                    value: r.value,
                    logicGroup: r.logicGroup
                }));
                trans[q.developerName] = (q.translations || []).map((t) => ({
                    locale: t.locale,
                    questionText: t.questionText,
                    helpText: t.helpText
                }));
            }
            this.picklistByQ = pv;
            this.rulesByQ = rules;
            this.translationsByQ = trans;
        } catch (e) {
            this.toast('Error', this.reduceError(e), 'error');
        } finally {
            this.isLoading = false;
        }
    }

    get displayQuestions() {
        return this.questions.map((q, idx) => ({
            ...q,
            uiKey: q.id || q.developerName || `q-${idx}`,
            index: idx,
            displayOrder: q.orderNum != null ? q.orderNum : idx + 1
        }));
    }

    get previewBundle() {
        return {
            templateId: this.template.id,
            name: this.template.name,
            description: this.template.description,
            personaDescription: this.template.personaDescription,
            defaultLocale: this.template.defaultLocale,
            questions: this.questions.map((q) => ({
                questionId: q.id,
                developerName: q.developerName,
                questionText: q.questionText,
                helpText: q.helpText,
                category: q.category,
                orderNum: q.orderNum,
                isRequired: q.isRequired,
                answerType: q.answerType,
                targetField: q.targetField,
                picklistOptions: (this.picklistByQ[q.developerName] || []).map((p) => ({
                    label: p.label, value: p.value
                })),
                visibilityRules: this.rulesByQ[q.developerName] || [],
                translations: this.translationsByQ[q.developerName] || []
            }))
        };
    }

    get questionsForRules() {
        return this.questions.map((q) => ({
            developerName: q.developerName,
            questionText: q.questionText
        }));
    }

    get isPreviewModeTrue() {
        return true;
    }

    get previewPicklistFlat() {
        const flat = [];
        for (const [dev, pvList] of Object.entries(this.picklistByQ)) {
            for (const pv of pvList) {
                flat.push({ ...pv, questionDeveloperName: dev });
            }
        }
        return flat;
    }

    get editingQuestion() {
        return this.questions.find((q) => q.developerName === this.editingQuestionDevName);
    }

    get editingPicklistValues() {
        return this.picklistByQ[this.editingQuestionDevName] || [];
    }

    get editingRules() {
        return this.rulesByQ[this.editingQuestionDevName] || [];
    }

    get editingTranslations() {
        return this.translationsByQ[this.editingQuestionDevName] || [];
    }

    handleTemplateField(event) {
        const field = event.currentTarget.dataset.field;
        const value = event.detail?.value ?? event.target.value;
        this.template = { ...this.template, [field]: value };
    }

    get brandSwatchStyle() {
        const bg = this.normalizedBrandColor || '#032D60';
        const fg = this.computeTextColor(bg);
        return `background:${bg};color:${fg};`;
    }

    get brandSwatchLabel() {
        return this.normalizedBrandColor
            ? `Header preview · ${this.normalizedBrandColor}`
            : 'Header preview · #032D60 (default)';
    }

    get normalizedBrandColor() {
        const raw = (this.template.brandColor || '').trim();
        if (!raw) return '';
        const withHash = raw.startsWith('#') ? raw : `#${raw}`;
        return /^#[0-9a-fA-F]{6}$/.test(withHash) ? withHash.toUpperCase() : '';
    }

    computeTextColor(hex) {
        const clean = hex.startsWith('#') ? hex.substring(1) : hex;
        if (clean.length !== 6) return '#FFFFFF';
        const r = parseInt(clean.substring(0, 2), 16);
        const g = parseInt(clean.substring(2, 4), 16);
        const b = parseInt(clean.substring(4, 6), 16);
        const luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255;
        return luminance > 0.6 ? '#181818' : '#FFFFFF';
    }

    handleTargetObjectChange(event) {
        this.template = { ...this.template, targetObject: event.target.value };
    }

    handleAiFormDescriptionChange(event) {
        this.aiFormDescription = event.detail?.value ?? event.target.value;
    }

    get canUploadBrandLogo() {
        return Boolean(this.template?.id);
    }

    handleBrandLogoUploadFinished(event) {
        const files = event.detail?.files || [];
        if (!files.length) {
            return;
        }
        const first = files[0];
        this.template = {
            ...this.template,
            brandLogoFileId: first.documentId,
            brandLogoStaticResource: ''
        };
        this.uploadedBrandLogoName = first.name || '';
        this.toast('Logo uploaded', 'Brand logo uploaded and linked to this template.', 'success');
    }

    handleReplaceExistingQuestionsChange(event) {
        this.replaceExistingQuestions = event.target.checked;
    }

    get scenarioPresetOptions() {
        return SCENARIO_PRESET_OPTIONS;
    }

    handleScenarioPresetChange(event) {
        this.selectedScenarioPresets = event.detail?.value || [];
    }

    handleApplyScenarioPreset() {
        if (!this.selectedScenarioPresets.length) {
            this.toast('Select scenarios', 'Choose at least one roadside scenario preset first.', 'warning');
            return;
        }

        const existingDevNames = new Set(this.questions.map((q) => q.developerName));
        const nextQuestions = [...this.questions];
        const nextPicklists = { ...this.picklistByQ };
        const nextRules = { ...this.rulesByQ };
        const nextTranslations = { ...this.translationsByQ };

        let order = nextQuestions.length;
        let addedCount = 0;
        let skippedCount = 0;

        const scenarioLabels = this.selectedScenarioPresets.map(
            (scenario) => SCENARIO_PRESET_LABELS[scenario]
        ).filter(Boolean);

        let scenarioQuestion = nextQuestions.find((q) => q.developerName === 'Roadside_Scenario');
        let scenarioDeveloperName = 'Roadside_Scenario';
        if (!scenarioQuestion) {
            order += 1;
            scenarioDeveloperName = this.ensureUniqueDeveloperName('Roadside_Scenario', existingDevNames);
            scenarioQuestion = {
                id: null,
                developerName: scenarioDeveloperName,
                questionText: 'What roadside scenario best matches this call?',
                helpText: 'This drives which scenario-specific questions appear in the intake.',
                category: 'Scenario Routing',
                orderNum: order,
                isRequired: true,
                answerType: 'picklist',
                targetField: '',
                picklistSource: 'Static',
                picklistSourceObject: '',
                picklistSourceField: '',
                lookupObject: '',
                validationRegex: '',
                validationErrorMessage: '',
                aiExtractionHint: 'Choose the most likely roadside scenario from the available options.'
            };
            nextQuestions.push(scenarioQuestion);
            nextPicklists[scenarioDeveloperName] = [];
            nextRules[scenarioDeveloperName] = [];
            nextTranslations[scenarioDeveloperName] = [];
            addedCount += 1;
        } else {
            scenarioDeveloperName = scenarioQuestion.developerName;
        }

        const existingScenarioPicklist = nextPicklists[scenarioDeveloperName] || [];
        const existingScenarioValues = new Set(existingScenarioPicklist.map((p) => p.value));
        const mergedScenarioPicklist = [...existingScenarioPicklist];
        scenarioLabels.forEach((label) => {
            if (!existingScenarioValues.has(label)) {
                mergedScenarioPicklist.push({
                    label,
                    value: label,
                    orderNum: mergedScenarioPicklist.length + 1
                });
            }
        });
        nextPicklists[scenarioDeveloperName] = mergedScenarioPicklist;

        for (const scenario of this.selectedScenarioPresets) {
            const defs = SCENARIO_PRESET_QUESTIONS[scenario] || [];
            const scenarioLabel = SCENARIO_PRESET_LABELS[scenario];
            for (const def of defs) {
                const exists = nextQuestions.some((q) => q.developerName === def.developerName);
                if (exists) {
                    skippedCount += 1;
                    continue;
                }

                order += 1;
                const developerName = this.ensureUniqueDeveloperName(def.developerName, existingDevNames);
                nextQuestions.push({
                    id: null,
                    developerName,
                    questionText: def.questionText,
                    helpText: '',
                    category: def.category || '',
                    orderNum: order,
                    isRequired: def.isRequired === true,
                    answerType: def.answerType || 'text',
                    targetField: '',
                    picklistSource: 'Static',
                    picklistSourceObject: '',
                    picklistSourceField: '',
                    lookupObject: '',
                    validationRegex: '',
                    validationErrorMessage: '',
                    aiExtractionHint: def.aiExtractionHint || ''
                });

                const picklistValues = (def.picklistValues || []).map((value, idx) => ({
                    label: value,
                    value,
                    orderNum: idx + 1
                }));
                nextPicklists[developerName] = picklistValues;
                nextTranslations[developerName] = [];
                nextRules[developerName] = [
                    {
                        sourceQuestionDeveloperName: scenarioDeveloperName,
                        operator: 'equals',
                        value: scenarioLabel,
                        logicGroup: 'scenario'
                    }
                ];
                addedCount += 1;
            }
        }

        this.questions = nextQuestions;
        this.picklistByQ = nextPicklists;
        this.rulesByQ = nextRules;
        this.translationsByQ = nextTranslations;

        const baseMsg = `Added ${addedCount} scenario preset question${addedCount === 1 ? '' : 's'}.`;
        const skipMsg = skippedCount > 0 ? ` Skipped ${skippedCount} existing question${skippedCount === 1 ? '' : 's'}.` : '';
        this.toast('Scenario presets applied', `${baseMsg}${skipMsg}`, 'success');
    }

    handleAddQuestion() {
        const idx = this.questions.length + 1;
        const devName = `Question_${idx}_${Date.now()}`.slice(0, 80);
        this.questions = [
            ...this.questions,
            {
                id: null,
                developerName: devName,
                questionText: 'New Question',
                helpText: '',
                category: '',
                orderNum: idx,
                isRequired: false,
                answerType: 'text',
                targetField: '',
                picklistSource: 'Static',
                picklistSourceObject: '',
                picklistSourceField: '',
                lookupObject: '',
                validationRegex: '',
                validationErrorMessage: '',
                aiExtractionHint: ''
            }
        ];
        this.picklistByQ = { ...this.picklistByQ, [devName]: [] };
        this.rulesByQ = { ...this.rulesByQ, [devName]: [] };
        this.translationsByQ = { ...this.translationsByQ, [devName]: [] };
    }

    async handleGenerateQuestions() {
        if (!this.aiFormDescription || !this.aiFormDescription.trim()) {
            this.toast('Description required', 'Describe the intake form before generating questions.', 'warning');
            return;
        }

        this.isGeneratingQuestions = true;
        try {
            const generated = await generateQuestionsFromDescription({
                formDescription: this.aiFormDescription,
                targetObjectApiName: this.template.targetObject
            });
            if (!generated || generated.length === 0) {
                this.toast('No questions generated', 'Try adding more detail in the description.', 'warning');
                return;
            }

            const existingDevNames = this.replaceExistingQuestions
                ? new Set()
                : new Set(this.questions.map((q) => q.developerName));
            const nextQuestions = this.replaceExistingQuestions ? [] : [...this.questions];
            const nextPicklists = this.replaceExistingQuestions ? {} : { ...this.picklistByQ };
            const nextRules = this.replaceExistingQuestions ? {} : { ...this.rulesByQ };
            const nextTranslations = this.replaceExistingQuestions ? {} : { ...this.translationsByQ };
            let order = nextQuestions.length;
            let addedCount = 0;

            generated.forEach((q) => {
                if (!q.questionText || !q.questionText.trim()) {
                    return;
                }
                order += 1;
                const developerName = this.ensureUniqueDeveloperName(
                    q.developerName || q.questionText || `Question_${order}`,
                    existingDevNames
                );
                nextQuestions.push({
                    id: null,
                    developerName,
                    questionText: q.questionText.trim(),
                    helpText: q.helpText || '',
                    category: q.category || '',
                    orderNum: order,
                    isRequired: q.isRequired === true,
                    answerType: q.answerType || 'text',
                    targetField: q.targetField || '',
                    picklistSource: 'Static',
                    picklistSourceObject: '',
                    picklistSourceField: '',
                    lookupObject: '',
                    validationRegex: '',
                    validationErrorMessage: '',
                    aiExtractionHint: q.aiExtractionHint || ''
                });
                nextPicklists[developerName] = [];
                nextRules[developerName] = [];
                nextTranslations[developerName] = [];
                addedCount += 1;
            });

            if (addedCount === 0) {
                this.toast('No valid questions generated', 'AI returned invalid questions. Try a more detailed description.', 'warning');
                return;
            }

            this.questions = nextQuestions;
            this.picklistByQ = nextPicklists;
            this.rulesByQ = nextRules;
            this.translationsByQ = nextTranslations;
            const actionLabel = this.replaceExistingQuestions ? 'Replaced with' : 'Added';
            this.toast('Questions generated', `${actionLabel} ${addedCount} AI-generated questions.`, 'success');
        } catch (e) {
            this.toast('Generation failed', this.reduceError(e), 'error');
        } finally {
            this.isGeneratingQuestions = false;
        }
    }

    ensureUniqueDeveloperName(seed, existingDevNames) {
        let base = (seed || 'Question')
            .replace(/[^A-Za-z0-9_]/g, '_')
            .replace(/_+/g, '_')
            .replace(/^_+|_+$/g, '')
            .slice(0, 80);
        if (!base) {
            base = 'Question';
        }
        let next = base;
        let counter = 2;
        while (existingDevNames.has(next)) {
            next = `${base}_${counter}`.slice(0, 80);
            counter += 1;
        }
        existingDevNames.add(next);
        return next;
    }

    handleEditQuestion(event) {
        const idx = parseInt(event.currentTarget.dataset.index, 10);
        this.editingQuestionDevName = this.questions[idx].developerName;
    }

    handleDeleteQuestion(event) {
        const idx = parseInt(event.currentTarget.dataset.index, 10);
        const devName = this.questions[idx].developerName;
        this.questions = this.questions.filter((_, i) => i !== idx);
        const { [devName]: _pv, ...restPv } = this.picklistByQ;
        const { [devName]: _r, ...restR } = this.rulesByQ;
        const { [devName]: _t, ...restT } = this.translationsByQ;
        this.picklistByQ = restPv;
        this.rulesByQ = restR;
        this.translationsByQ = restT;
        this.reorder();
    }

    handleDuplicateQuestion(event) {
        const idx = parseInt(event.currentTarget.dataset.index, 10);
        const src = this.questions[idx];
        const newDev = `${src.developerName}_copy_${Date.now()}`.slice(0, 80);
        const clone = { ...src, id: null, developerName: newDev };
        const next = [...this.questions];
        next.splice(idx + 1, 0, clone);
        this.questions = next;
        this.picklistByQ = {
            ...this.picklistByQ,
            [newDev]: [...(this.picklistByQ[src.developerName] || [])]
        };
        this.rulesByQ = {
            ...this.rulesByQ,
            [newDev]: [...(this.rulesByQ[src.developerName] || [])]
        };
        this.translationsByQ = {
            ...this.translationsByQ,
            [newDev]: [...(this.translationsByQ[src.developerName] || [])]
        };
        this.reorder();
    }

    handleDragStart(event) {
        this.dragSourceIndex = parseInt(event.currentTarget.dataset.index, 10);
    }

    handleDragOver(event) {
        event.preventDefault();
    }

    handleDrop(event) {
        event.preventDefault();
        const target = parseInt(event.currentTarget.dataset.index, 10);
        if (this.dragSourceIndex == null || this.dragSourceIndex === target) return;
        const next = [...this.questions];
        const [moved] = next.splice(this.dragSourceIndex, 1);
        next.splice(target, 0, moved);
        this.questions = next;
        this.dragSourceIndex = null;
        this.reorder();
    }

    reorder() {
        this.questions = this.questions.map((q, i) => ({ ...q, orderNum: i + 1 }));
    }

    handleQuestionChange(event) {
        const { field, value } = event.detail;
        const dev = this.editingQuestionDevName;
        this.questions = this.questions.map((q) =>
            q.developerName === dev ? { ...q, [field]: value } : q
        );
        // If developerName changed, migrate child maps
        if (field === 'developerName' && value && value !== dev) {
            const pv = this.picklistByQ[dev] || [];
            const rules = this.rulesByQ[dev] || [];
            const trans = this.translationsByQ[dev] || [];
            const { [dev]: _pv, ...restPv } = this.picklistByQ;
            const { [dev]: _r, ...restR } = this.rulesByQ;
            const { [dev]: _t, ...restT } = this.translationsByQ;
            this.picklistByQ = { ...restPv, [value]: pv };
            this.rulesByQ = { ...restR, [value]: rules };
            this.translationsByQ = { ...restT, [value]: trans };
            this.editingQuestionDevName = value;
        }
    }

    handlePicklistValuesChange(event) {
        const dev = this.editingQuestionDevName;
        this.picklistByQ = {
            ...this.picklistByQ,
            [dev]: event.detail.picklistValues
        };
    }

    handleRulesChange(event) {
        const dev = this.editingQuestionDevName;
        this.rulesByQ = {
            ...this.rulesByQ,
            [dev]: event.detail.rules
        };
    }

    handleTranslationsChange(event) {
        const dev = this.editingQuestionDevName;
        this.translationsByQ = {
            ...this.translationsByQ,
            [dev]: event.detail.translations
        };
    }

    handleCloseEditor() {
        this.editingQuestionDevName = null;
    }

    handleViewChange(event) {
        this.activeView = event.target.value;
    }

    async handleSave() {
        this.isSaving = true;
        try {
            const payload = this.buildSavePayload();
            const result = await saveTemplate({ payloadJson: JSON.stringify(payload) });
            if (result?.success) {
                this.template = { ...this.template, id: result.templateId };
                this.templateId = result.templateId;
                this.toast('Saved', 'Template saved successfully.', 'success');
                await this.load();
            } else {
                this.toast('Save failed', result?.errorMessage || 'Unknown error', 'error');
            }
        } catch (e) {
            this.toast('Save failed', this.reduceError(e), 'error');
        } finally {
            this.isSaving = false;
        }
    }

    buildSavePayload() {
        const picklistValues = [];
        for (const [dev, pvList] of Object.entries(this.picklistByQ)) {
            for (const pv of pvList) {
                picklistValues.push({ ...pv, questionDeveloperName: dev });
            }
        }
        const visibilityRules = [];
        for (const [dev, rList] of Object.entries(this.rulesByQ)) {
            for (const r of rList) {
                visibilityRules.push({ ...r, questionDeveloperName: dev });
            }
        }
        const translations = [];
        for (const [dev, tList] of Object.entries(this.translationsByQ)) {
            for (const t of tList) {
                translations.push({ ...t, questionDeveloperName: dev });
            }
        }
        return {
            template: this.template,
            questions: this.questions,
            picklistValues,
            visibilityRules,
            translations
        };
    }

    async handleValidate() {
        if (!this.template.id) {
            this.toast('Save first', 'Save the template before validating.', 'warning');
            return;
        }
        try {
            const result = await validateTemplate({ templateId: this.template.id });
            if (result.isValid) {
                const warnings = (result.warnings || []).join('; ');
                this.toast(
                    'Valid',
                    warnings ? `No errors. Warnings: ${warnings}` : 'No errors or warnings.',
                    warnings ? 'warning' : 'success'
                );
            } else {
                this.toast('Invalid', (result.errors || []).join('; '), 'error');
            }
        } catch (e) {
            this.toast('Validate failed', this.reduceError(e), 'error');
        }
    }

    async handleActivate() {
        if (!this.template.id) {
            this.toast('Save first', 'Save the template before activating.', 'warning');
            return;
        }
        try {
            await activateTemplate({ templateId: this.template.id });
            this.template = { ...this.template, status: 'Active' };
            this.toast('Activated', 'Template is now Active.', 'success');
        } catch (e) {
            this.toast('Activate failed', this.reduceError(e), 'error');
        }
    }

    async handleArchive() {
        if (!this.template.id) return;
        try {
            await archiveTemplate({ templateId: this.template.id });
            this.template = { ...this.template, status: 'Archived' };
            this.toast('Archived', 'Template is archived.', 'success');
        } catch (e) {
            this.toast('Archive failed', this.reduceError(e), 'error');
        }
    }

    async handleNewVersion() {
        if (!this.template.id) return;
        try {
            const newId = await newVersion({ sourceId: this.template.id });
            this.templateId = newId;
            await this.load();
            this.toast('New version', 'A new draft version was created.', 'success');
        } catch (e) {
            this.toast('Failed', this.reduceError(e), 'error');
        }
    }

    async handleTestRecordPdf() {
        if (!this.template.id) {
            this.toast('Save first', 'Save the template before running the test record + PDF action.', 'warning');
            return;
        }
        this.isTestingPdf = true;
        try {
            const result = await createTestRecordAndPdf({ templateId: this.template.id });
            if (result?.pdfUrl) {
                window.open(result.pdfUrl, '_blank');
            }
            this.toast('Test record created', 'Created a sample intake record and opened the generated PDF.', 'success');
        } catch (e) {
            this.toast('Test run failed', this.reduceError(e), 'error');
        } finally {
            this.isTestingPdf = false;
        }
    }

    handleBack() {
        this.dispatchEvent(new CustomEvent('back'));
    }

    toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    reduceError(error) {
        if (typeof error === 'string') return error;
        if (error?.body?.message) return error.body.message;
        if (error?.message) return error.message;
        return 'An unexpected error occurred.';
    }
}
