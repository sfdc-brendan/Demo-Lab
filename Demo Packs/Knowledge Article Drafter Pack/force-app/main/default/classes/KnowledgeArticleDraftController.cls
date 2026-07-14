/**
 * Generates a drafted Knowledge article for a Case by invoking the
 * "Knowledge Article Generation Template" Flex prompt template, and optionally
 * persists the reviewed draft as a Knowledge__kav article.
 */
public with sharing class KnowledgeArticleDraftController {
    @TestVisible
    private static final String TEMPLATE_DEV_NAME = 'Knowledge_Article_Generation_Template';

    public class ArticleDraft {
        @AuraEnabled public String title;
        @AuraEnabled public String summary;
        @AuraEnabled public String content;
        @AuraEnabled public String customerName;
        @AuraEnabled public String industry;
    }

    /**
     * Invokes the Flex prompt template for the given Case and returns a parsed draft.
     */
    @AuraEnabled
    public static ArticleDraft generateDraft(Id caseId) {
        if (caseId == null) {
            throw new AuraHandledException('A Case Id is required to generate an article.');
        }

        Case theCase = loadCase(caseId);
        String customerName = (theCase.Account != null && String.isNotBlank(theCase.Account.Name))
            ? theCase.Account.Name
            : 'the customer';
        String industry = (theCase.Account != null && String.isNotBlank(theCase.Account.Industry))
            ? theCase.Account.Industry
            : 'Other';
        String additionalDetails = buildAdditionalDetails(theCase);
        String casesSummary = buildCasesSummary(theCase);

        String rawText = invokeTemplate(customerName, industry, additionalDetails, casesSummary);

        ArticleDraft draft = parseDraft(rawText);
        draft.customerName = customerName;
        draft.industry = industry;
        return draft;
    }

    /**
     * Persists a reviewed draft as a Knowledge__kav article in Draft status.
     */
    @AuraEnabled
    public static Id saveDraftArticle(
        String title,
        String summary,
        String content,
        String contentFieldApiName,
        String language
    ) {
        if (String.isBlank(title)) {
            throw new AuraHandledException('A title is required to save the article.');
        }
        String bodyField = String.isBlank(contentFieldApiName) ? 'FAQ_Answer__c' : contentFieldApiName;
        String lang = String.isBlank(language) ? 'en_US' : language;

        Map<String, Schema.SObjectField> kavFields = Schema.SObjectType.Knowledge__kav.fields.getMap();

        Knowledge__kav article = new Knowledge__kav();
        article.put('Title', truncate(title, 255));
        article.put('UrlName', buildUrlName(title));
        article.put('Language', lang);
        if (String.isNotBlank(summary) && kavFields.containsKey('Summary')) {
            article.put('Summary', truncate(summary, 1000));
        }
        if (String.isNotBlank(content) && kavFields.containsKey(bodyField.toLowerCase())) {
            article.put(bodyField, content);
        }

        Database.SaveResult sr = Database.insert(article, AccessLevel.USER_MODE);
        return sr.getId();
    }

    private static Case loadCase(Id caseId) {
        List<Case> cases = [
            SELECT Id, CaseNumber, Subject, Description, Priority, Status, Type, Reason,
                   AccountId, Account.Name, Account.Industry
            FROM Case
            WHERE Id = :caseId
            WITH USER_MODE
            LIMIT 1
        ];
        if (cases.isEmpty()) {
            throw new AuraHandledException('Case not found or not accessible.');
        }
        return cases[0];
    }

    @TestVisible
    private static String buildAdditionalDetails(Case theCase) {
        List<String> parts = new List<String>();
        if (String.isNotBlank(theCase.Subject)) {
            parts.add('Case Subject: ' + theCase.Subject);
        }
        if (String.isNotBlank(theCase.Type)) {
            parts.add('Type: ' + theCase.Type);
        }
        if (String.isNotBlank(theCase.Reason)) {
            parts.add('Reason: ' + theCase.Reason);
        }
        if (String.isNotBlank(theCase.Priority)) {
            parts.add('Priority: ' + theCase.Priority);
        }
        if (String.isNotBlank(theCase.Description)) {
            parts.add('Description: ' + theCase.Description);
        }
        return parts.isEmpty() ? 'No additional case details available.' : String.join(parts, '\n');
    }

    @TestVisible
    private static String buildCasesSummary(Case theCase) {
        if (theCase.AccountId == null) {
            return summarizeCaseLine(theCase);
        }
        List<Case> related = [
            SELECT CaseNumber, Subject, Status, Priority, Type, Description, CreatedDate
            FROM Case
            WHERE AccountId = :theCase.AccountId
            WITH USER_MODE
            ORDER BY CreatedDate DESC
            LIMIT 25
        ];
        if (related.isEmpty()) {
            return summarizeCaseLine(theCase);
        }
        List<String> lines = new List<String>();
        for (Case c : related) {
            lines.add(summarizeCaseLine(c));
        }
        return String.join(lines, '\n');
    }

    private static String summarizeCaseLine(Case c) {
        String subject = String.isBlank(c.Subject) ? '(no subject)' : c.Subject;
        String descText = String.isBlank(c.Description) ? '' : ' - ' + truncate(c.Description, 240);
        return '[' + c.CaseNumber + '] (' + c.Status + '/' + c.Priority + ') ' + subject + descText;
    }

    private static String invokeTemplate(
        String customerName,
        String industry,
        String additionalDetails,
        String casesSummary
    ) {
        Map<String, ConnectApi.WrappedValue> inputParams = new Map<String, ConnectApi.WrappedValue>{
            'Input:customerName' => wrap(customerName),
            'Input:industry' => wrap(industry),
            'Input:additionalDetails' => wrap(additionalDetails),
            'Input:casesSummary' => wrap(casesSummary)
        };

        ConnectApi.EinsteinPromptTemplateGenerationsInput genInput =
            new ConnectApi.EinsteinPromptTemplateGenerationsInput();
        genInput.additionalConfig = new ConnectApi.EinsteinLlmAdditionalConfigInput();
        genInput.additionalConfig.applicationName = 'PromptBuilderPreview';
        genInput.isPreview = false;
        genInput.inputParams = inputParams;

        ConnectApi.EinsteinPromptTemplateGenerationsRepresentation output =
            resolveGeneration(TEMPLATE_DEV_NAME, genInput);

        if (output == null || output.generations == null || output.generations.isEmpty()) {
            throw new AuraHandledException('The prompt template returned no content.');
        }
        return output.generations[0].text;
    }

    // ConnectApi.EinsteinLLM callouts are not permitted in test context and have no
    // native mock, so the invocation is isolated here and short-circuited under test.
    @TestVisible
    private static String mockGenerationText;

    private static ConnectApi.EinsteinPromptTemplateGenerationsRepresentation resolveGeneration(
        String devName,
        ConnectApi.EinsteinPromptTemplateGenerationsInput genInput
    ) {
        if (Test.isRunningTest()) {
            ConnectApi.EinsteinPromptTemplateGenerationsRepresentation mock =
                new ConnectApi.EinsteinPromptTemplateGenerationsRepresentation();
            mock.generations = new List<ConnectApi.EinsteinLLMGenerationItemOutput>();
            ConnectApi.EinsteinLLMGenerationItemOutput item =
                new ConnectApi.EinsteinLLMGenerationItemOutput();
            item.text = mockGenerationText;
            mock.generations.add(item);
            return mock;
        }
        return ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate(devName, genInput);
    }

    private static ConnectApi.WrappedValue wrap(String value) {
        ConnectApi.WrappedValue wrapped = new ConnectApi.WrappedValue();
        wrapped.value = value;
        return wrapped;
    }

    /**
     * The template is instructed to return a JSON object {title, summary, content}.
     * Models occasionally wrap it in prose or markdown fences, so extract the JSON
     * object defensively and fall back to raw text as the content.
     */
    @TestVisible
    private static ArticleDraft parseDraft(String rawText) {
        ArticleDraft draft = new ArticleDraft();
        String text = rawText == null ? '' : rawText.trim();

        Integer firstBrace = text.indexOf('{');
        Integer lastBrace = text.lastIndexOf('}');
        if (firstBrace >= 0 && lastBrace > firstBrace) {
            String jsonSlice = text.substring(firstBrace, lastBrace + 1);
            try {
                Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(jsonSlice);
                draft.title = asString(parsed.get('title'));
                draft.summary = asString(parsed.get('summary'));
                draft.content = asString(parsed.get('content'));
            } catch (Exception e) {
                // fall through to raw text
            }
        }

        if (String.isBlank(draft.content)) {
            draft.content = text;
        }
        if (String.isBlank(draft.title)) {
            draft.title = 'Draft Knowledge Article';
        }
        return draft;
    }

    private static String asString(Object value) {
        return value == null ? null : String.valueOf(value);
    }

    private static String buildUrlName(String title) {
        String base = title.toLowerCase().replaceAll('[^a-z0-9]+', '-').replaceAll('^-+|-+$', '');
        if (String.isBlank(base)) {
            base = 'knowledge-article';
        }
        base = truncate(base, 200);
        String suffix = '-' + String.valueOf(Datetime.now().getTime());
        return truncate(base, 255 - suffix.length()) + suffix;
    }

    private static String truncate(String value, Integer max) {
        if (value == null) {
            return null;
        }
        return value.length() > max ? value.substring(0, max) : value;
    }
}
