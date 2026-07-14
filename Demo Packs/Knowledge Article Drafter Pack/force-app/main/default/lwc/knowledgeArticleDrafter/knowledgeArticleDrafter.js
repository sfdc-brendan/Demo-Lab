import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import generateDraft from '@salesforce/apex/KnowledgeArticleDraftController.generateDraft';
import saveDraftArticle from '@salesforce/apex/KnowledgeArticleDraftController.saveDraftArticle';

export default class KnowledgeArticleDrafter extends NavigationMixin(LightningElement) {
    @api recordId;
    @api cardTitle = 'Knowledge Article Drafter';
    @api contentFieldApiName = 'FAQ_Answer__c';
    @api articleLanguage = 'en_US';

    title = '';
    summary = '';
    content = '';
    customerName = '';
    industry = '';

    isGenerating = false;
    isSaving = false;
    hasDraft = false;

    get isBusy() {
        return this.isGenerating || this.isSaving;
    }

    get generateLabel() {
        return this.hasDraft ? 'Regenerate' : 'Generate Draft';
    }

    get saveDisabled() {
        return this.isBusy || !this.hasDraft || !this.title;
    }

    get showEmptyState() {
        return !this.isGenerating && !this.hasDraft;
    }

    async handleGenerate() {
        this.isGenerating = true;
        try {
            const draft = await generateDraft({ caseId: this.recordId });
            this.title = draft.title || '';
            this.summary = draft.summary || '';
            this.content = draft.content || '';
            this.customerName = draft.customerName || '';
            this.industry = draft.industry || '';
            this.hasDraft = true;
            this.toast('Draft ready', 'Review and edit the article before saving.', 'success');
        } catch (error) {
            this.toast('Generation failed', this.reduceError(error), 'error');
        } finally {
            this.isGenerating = false;
        }
    }

    async handleSave() {
        this.isSaving = true;
        try {
            const articleId = await saveDraftArticle({
                title: this.title,
                summary: this.summary,
                content: this.content,
                contentFieldApiName: this.contentFieldApiName,
                language: this.articleLanguage
            });
            this.toast('Draft article created', 'Opening the new Knowledge draft.', 'success');
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: articleId,
                    objectApiName: 'Knowledge__kav',
                    actionName: 'view'
                }
            });
        } catch (error) {
            this.toast('Save failed', this.reduceError(error), 'error');
        } finally {
            this.isSaving = false;
        }
    }

    handleTitleChange(event) {
        this.title = event.detail.value;
    }

    handleSummaryChange(event) {
        this.summary = event.detail.value;
    }

    handleContentChange(event) {
        this.content = event.detail.value;
    }

    toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    reduceError(error) {
        if (Array.isArray(error?.body)) {
            return error.body.map((e) => e.message).join(', ');
        }
        return error?.body?.message || error?.message || 'Unknown error';
    }
}
