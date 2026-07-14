@IsTest
private class KnowledgeArticleDraftControllerTest {
    private static final String SAMPLE_JSON =
        '```json\n{"title":"VoIP Connectivity Guide",' +
        '"summary":"Troubleshooting steps for VoIP issues.",' +
        '"content":"<div><h1>Guide</h1><p>Steps</p></div>"}\n```';

    @IsTest
    static void parseDraftHandlesJsonWithFences() {
        KnowledgeArticleDraftController.ArticleDraft draft =
            KnowledgeArticleDraftController.parseDraft(SAMPLE_JSON);

        System.assertEquals('VoIP Connectivity Guide', draft.title, 'Title parsed from JSON');
        System.assertEquals('Troubleshooting steps for VoIP issues.', draft.summary, 'Summary parsed');
        System.assert(draft.content.contains('<h1>Guide</h1>'), 'Content HTML parsed');
    }

    @IsTest
    static void parseDraftFallsBackToRawText() {
        KnowledgeArticleDraftController.ArticleDraft draft =
            KnowledgeArticleDraftController.parseDraft('Plain text with no JSON object.');

        System.assertEquals('Draft Knowledge Article', draft.title, 'Default title used');
        System.assertEquals('Plain text with no JSON object.', draft.content, 'Raw text used as content');
    }

    @IsTest
    static void buildHelpersSummarizeCaseInMemory() {
        // In-memory Case with no AccountId avoids the org's record-triggered flow and DML.
        Case c = new Case(
            Subject = 'Streaming outage',
            Description = 'Customer cannot access streaming service.',
            Priority = 'High',
            Status = 'New',
            Type = 'Problem'
        );

        String details = KnowledgeArticleDraftController.buildAdditionalDetails(c);
        String summary = KnowledgeArticleDraftController.buildCasesSummary(c);

        System.assert(details.contains('Streaming outage'), 'Details include subject');
        System.assert(details.contains('High'), 'Details include priority');
        System.assert(summary.contains('Streaming outage'), 'Summary includes case subject');
    }

    @IsTest
    static void generateDraftRequiresCaseId() {
        Boolean threw = false;
        try {
            KnowledgeArticleDraftController.generateDraft(null);
        } catch (Exception e) {
            threw = true;
        }
        System.assert(threw, 'Null case id should throw');
    }

    @IsTest
    static void saveDraftArticleCreatesKnowledge() {
        Test.startTest();
        Id articleId = KnowledgeArticleDraftController.saveDraftArticle(
            'Test Article Title',
            'A short summary.',
            '<div><p>Body content</p></div>',
            'FAQ_Answer__c',
            'en_US'
        );
        Test.stopTest();

        System.assertNotEquals(null, articleId, 'Article should be created');
        List<Knowledge__kav> articles = [
            SELECT Id, Title, UrlName, Summary
            FROM Knowledge__kav
            WHERE Id = :articleId
        ];
        System.assertEquals(1, articles.size(), 'One article created');
        System.assertEquals('Test Article Title', articles[0].Title, 'Title stored');
    }

    @IsTest
    static void saveDraftArticleRequiresTitle() {
        Boolean threw = false;
        try {
            KnowledgeArticleDraftController.saveDraftArticle(null, 's', 'c', 'FAQ_Answer__c', 'en_US');
        } catch (Exception e) {
            threw = true;
        }
        System.assert(threw, 'Blank title should throw');
    }
}
