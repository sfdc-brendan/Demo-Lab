import { LightningElement, api } from 'lwc';
import testAnalyze from '@salesforce/apex/IntakeBuilderController.testAnalyze';
import generateTestCallScript from '@salesforce/apex/IntakeBuilderController.generateTestCallScript';
import runTestExtractionAndCreatePdf from '@salesforce/apex/IntakeBuilderController.runTestExtractionAndCreatePdf';

const SAMPLE_TRANSCRIPT = `Agent: Thanks for calling. Can I have your name?
Customer: Hi, this is Jane Martinez.
Agent: And the best callback number?
Customer: 555-867-5309.
Agent: What's going on with your vehicle?
Customer: I have a flat tire on the highway, it's pretty unsafe here.`;

export default class IntakeTestRunner extends LightningElement {
    @api templateId;
    @api personaDescription;
    @api questions = [];
    @api picklistValues = [];

    transcriptText = SAMPLE_TRANSCRIPT;
    scenarioHint = '';
    isRunning = false;
    isGeneratingScript = false;
    isRunningFullTest = false;
    extractedJson = '';
    latestPdfUrl = '';
    error;

    handleTranscriptChange(event) {
        this.transcriptText = event.target.value;
    }

    handleScenarioHintChange(event) {
        this.scenarioHint = event.target.value;
    }

    async handleGenerateScript() {
        if (!this.templateId) {
            this.error = 'Save the template first before generating a script.';
            return;
        }
        this.isGeneratingScript = true;
        this.error = null;
        try {
            const transcript = await generateTestCallScript({
                templateId: this.templateId,
                scenarioHint: this.scenarioHint
            });
            if (transcript) {
                this.transcriptText = transcript;
            }
        } catch (e) {
            this.error = e?.body?.message || e?.message || 'Script generation failed.';
        } finally {
            this.isGeneratingScript = false;
        }
    }

    async handleRun() {
        this.isRunning = true;
        this.error = null;
        this.extractedJson = '';
        this.latestPdfUrl = '';
        try {
            const picklistByQ = new Map();
            for (const pv of this.picklistValues || []) {
                if (!picklistByQ.has(pv.questionDeveloperName)) {
                    picklistByQ.set(pv.questionDeveloperName, []);
                }
                picklistByQ.get(pv.questionDeveloperName).push(pv.value);
            }
            const payload = (this.questions || []).map((q) => ({
                developerName: q.developerName,
                questionText: q.questionText,
                answerType: q.answerType,
                picklistValuesStr: (picklistByQ.get(q.developerName) || []).join(';'),
                aiHint: q.aiExtractionHint || ''
            }));
            const result = await testAnalyze({
                personaDescription: this.personaDescription || '',
                questionsJson: JSON.stringify(payload),
                transcriptText: this.transcriptText
            });
            this.extractedJson = JSON.stringify(result, null, 2);
        } catch (e) {
            this.error = e?.body?.message || e?.message || 'Test run failed.';
        } finally {
            this.isRunning = false;
        }
    }

    async handleRunWithPdf() {
        if (!this.templateId) {
            this.error = 'Save the template first before running full extraction + PDF test.';
            return;
        }
        this.isRunningFullTest = true;
        this.error = null;
        this.latestPdfUrl = '';
        try {
            const result = await runTestExtractionAndCreatePdf({
                templateId: this.templateId,
                transcriptText: this.transcriptText
            });
            this.extractedJson = result?.extractedAnswersJson
                ? JSON.stringify(JSON.parse(result.extractedAnswersJson), null, 2)
                : '';
            this.latestPdfUrl = result?.pdfUrl || '';
            if (this.latestPdfUrl) {
                window.open(this.latestPdfUrl, '_blank');
            }
        } catch (e) {
            this.error = e?.body?.message || e?.message || 'Full extraction + PDF test failed.';
        } finally {
            this.isRunningFullTest = false;
        }
    }
}
