/**
 * Service for finding similar cases and related knowledge using Gen AI.
 * Builds a prompt with current case + candidate cases, calls Models API,
 * parses relevancy scores and returns data for the Similar Cases LWC.
 */
public with sharing class SimilarCasesService {
    private static final Integer CANDIDATE_LIMIT = 30;
    private static final Integer MAX_SIMILAR_TO_RETURN = 10;
    private static final String DEFAULT_MODEL = 'sfdc_ai__DefaultGPT41';

    @TestVisible
    private static String testGenerationJson;

    /**
     * DTO for a similar case with relevancy score.
     */
    public class SimilarCaseResult {
        @AuraEnabled public String caseId;
        @AuraEnabled public String caseNumber;
        @AuraEnabled public String subject;
        @AuraEnabled public String status;
        @AuraEnabled public String type;
        @AuraEnabled public String priority;
        @AuraEnabled public String reason;
        @AuraEnabled public Integer relevancyScore;
    }

    /**
     * DTO for a related knowledge article with relevance score.
     */
    public class RelatedArticleResult {
        @AuraEnabled public String title;
        @AuraEnabled public String url;
        @AuraEnabled public String summary;
        @AuraEnabled public Integer relevancyScore;
    }

    /**
     * Response for getSimilarCasesWithScores.
     */
    public class SimilarCasesResponse {
        @AuraEnabled public List<SimilarCaseResult> similarCases;
        @AuraEnabled public List<RelatedArticleResult> relatedArticles;
        @AuraEnabled public String errorMessage;

        public SimilarCasesResponse() {
            this.similarCases = new List<SimilarCaseResult>();
            this.relatedArticles = new List<RelatedArticleResult>();
        }
    }

    private static final Integer DEFAULT_MAX_SIMILAR = 10;
    private static final Integer DEFAULT_MAX_ARTICLES = 10;
    private static final Integer MAX_LIMIT_CAP = 20;

    public static SimilarCasesResponse getSimilarCasesWithScores(Id caseId, String statusFilter, Integer maxSimilarCases, Integer maxRelatedArticles) {
        SimilarCasesResponse response = new SimilarCasesResponse();
        if (caseId == null || caseId.getSobjectType() != Case.SObjectType) {
            response.errorMessage = 'Invalid Case Id.';
            return response;
        }
        Integer similarLimit = (maxSimilarCases != null && maxSimilarCases >= 1 && maxSimilarCases <= MAX_LIMIT_CAP) ? maxSimilarCases : DEFAULT_MAX_SIMILAR;
        Integer articlesLimit = (maxRelatedArticles != null && maxRelatedArticles >= 1 && maxRelatedArticles <= MAX_LIMIT_CAP) ? maxRelatedArticles : DEFAULT_MAX_ARTICLES;

        try {
            Case sourceCase = getCurrentCase(caseId);
            if (sourceCase == null) {
                response.errorMessage = 'Case not found.';
                return response;
            }

            List<Case> candidates = getCandidateCases(sourceCase, statusFilter);
            String prompt = buildSimilarityPrompt(sourceCase, candidates);
            String generatedJson = invokeModelsApi(prompt);
            List<SimilarCaseResult> scored = parseScoredCases(generatedJson, candidates);
            response.similarCases = enrichAndLimit(scored, similarLimit);

            response.relatedArticles = getRelatedKnowledgeArticles(sourceCase, articlesLimit);
        } catch (Exception e) {
            response.errorMessage = e.getMessage();
            response.similarCases = new List<SimilarCaseResult>();
            response.relatedArticles = new List<RelatedArticleResult>();
        }
        return response;
    }

    private static Case getCurrentCase(Id caseId) {
        List<Case> cases = [
            SELECT Id, CaseNumber, Subject, Description, AccountId, Type, Status, Reason, Priority
            FROM Case
            WHERE Id = :caseId
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
        return cases.isEmpty() ? null : cases[0];
    }

    private static List<Case> getCandidateCases(Case sourceCase, String statusFilter) {
        Set<Id> accountIds = new Set<Id>();
        if (sourceCase.AccountId != null) {
            accountIds.add(sourceCase.AccountId);
        }
        if (accountIds.isEmpty()) {
            if (sourceCase.Type != null) {
                if (String.isNotBlank(statusFilter)) {
                    return [
                        SELECT Id, CaseNumber, Subject, Description, Type, Status, Priority, Reason
                        FROM Case
                        WHERE Id != :sourceCase.Id
                        AND Type = :sourceCase.Type
                        AND Status = :statusFilter
                        WITH SECURITY_ENFORCED
                        ORDER BY LastModifiedDate DESC
                        LIMIT :CANDIDATE_LIMIT
                    ];
                }
                return [
                    SELECT Id, CaseNumber, Subject, Description, Type, Status, Priority, Reason
                    FROM Case
                    WHERE Id != :sourceCase.Id
                    AND Type = :sourceCase.Type
                    WITH SECURITY_ENFORCED
                    ORDER BY LastModifiedDate DESC
                    LIMIT :CANDIDATE_LIMIT
                ];
            }
            if (String.isNotBlank(statusFilter)) {
                return [
                    SELECT Id, CaseNumber, Subject, Description, Type, Status, Priority, Reason
                    FROM Case
                    WHERE Id != :sourceCase.Id
                    AND Status = :statusFilter
                    WITH SECURITY_ENFORCED
                    ORDER BY LastModifiedDate DESC
                    LIMIT :CANDIDATE_LIMIT
                ];
            }
            return [
                SELECT Id, CaseNumber, Subject, Description, Type, Status, Priority, Reason
                FROM Case
                WHERE Id != :sourceCase.Id
                WITH SECURITY_ENFORCED
                ORDER BY LastModifiedDate DESC
                LIMIT :CANDIDATE_LIMIT
            ];
        }
        if (String.isNotBlank(statusFilter)) {
            return [
                SELECT Id, CaseNumber, Subject, Description, Type, Status, Priority, Reason
                FROM Case
                WHERE AccountId IN :accountIds
                AND Id != :sourceCase.Id
                AND Status = :statusFilter
                WITH SECURITY_ENFORCED
                ORDER BY LastModifiedDate DESC
                LIMIT :CANDIDATE_LIMIT
            ];
        }
        return [
            SELECT Id, CaseNumber, Subject, Description, Type, Status, Priority, Reason
            FROM Case
            WHERE AccountId IN :accountIds
            AND Id != :sourceCase.Id
            WITH SECURITY_ENFORCED
            ORDER BY LastModifiedDate DESC
            LIMIT :CANDIDATE_LIMIT
        ];
    }

    private static String buildSimilarityPrompt(Case sourceCase, List<Case> candidates) {
        String currentDesc = sourceCase.Description != null ? sourceCase.Description : '';
        if (currentDesc.length() > 2000) {
            currentDesc = currentDesc.substring(0, 2000) + '...';
        }
        List<String> candidateLines = new List<String>();
        for (Case c : candidates) {
            String caseDesc = c.Description != null ? c.Description : '';
            if (caseDesc.length() > 500) {
                caseDesc = caseDesc.substring(0, 500) + '...';
            }
            candidateLines.add('---\nCase Id: ' + c.Id + '\nCase Number: ' + (c.CaseNumber != null ? c.CaseNumber : '') + '\nSubject: ' + (c.Subject != null ? c.Subject : '') + '\nDescription: ' + caseDesc);
        }
        String candidateBlock = String.join(candidateLines, '\n');

        return 'You are a customer service assistant. Given the current case and a list of candidate cases, return a JSON array of the most similar cases with a relevancy score from 0 to 100. Only include cases that are meaningfully related.\n\n'
            + 'Current case:\n'
            + 'Subject: ' + (sourceCase.Subject != null ? sourceCase.Subject : '') + '\n'
            + 'Description: ' + currentDesc + '\n\n'
            + 'Candidate cases:\n'
            + candidateBlock
            + '\n\nReturn ONLY a valid JSON array with no other text. Each element must have: "caseId" (the Case Id string), "relevancyScore" (integer 0-100). Example: [{"caseId":"500xx","relevancyScore":85}]\n';
    }

    private static String invokeModelsApi(String prompt) {
        if (Test.isRunningTest()) {
            return String.isNotBlank(testGenerationJson) ? testGenerationJson : '[]';
        }
        aiplatform.ModelsAPI modelsAPI = new aiplatform.ModelsAPI();
        aiplatform.ModelsAPI.createGenerations_Request request = new aiplatform.ModelsAPI.createGenerations_Request();
        request.modelName = DEFAULT_MODEL;
        aiplatform.ModelsAPI_GenerationRequest body = new aiplatform.ModelsAPI_GenerationRequest();
        body.prompt = prompt;
        request.body = body;

        aiplatform.ModelsAPI.createGenerations_Response response = modelsAPI.createGenerations(request);
        if (response?.Code200?.generation?.generatedText != null) {
            return response.Code200.generation.generatedText.trim();
        }
        return '[]';
    }

    private static List<SimilarCaseResult> parseScoredCases(String generatedJson, List<Case> candidates) {
        List<SimilarCaseResult> results = new List<SimilarCaseResult>();
        Map<Id, Case> caseById = new Map<Id, Case>();
        for (Case c : candidates) {
            caseById.put(c.Id, c);
        }

        try {
            String jsonStr = generatedJson;
            if (jsonStr.startsWith('```')) {
                Integer startIdx = jsonStr.indexOf('[');
                Integer endIdx = jsonStr.lastIndexOf(']') + 1;
                if (startIdx >= 0 && endIdx > startIdx) {
                    jsonStr = jsonStr.substring(startIdx, endIdx);
                }
            }
            List<Object> items = (List<Object>) JSON.deserializeUntyped(jsonStr);
            for (Object item : items) {
                Map<String, Object> m = (Map<String, Object>) item;
                String caseIdStr = (String) m.get('caseId');
                Object scoreObj = m.get('relevancyScore');
                Integer score = 0;
                if (scoreObj instanceof Integer) {
                    score = (Integer) scoreObj;
                } else if (scoreObj != null) {
                    score = Integer.valueOf(String.valueOf(scoreObj));
                }
                Id caseId = null;
                try {
                    caseId = Id.valueOf(caseIdStr);
                } catch (Exception e) {
                    continue;
                }
                Case c = caseById.get(caseId);
                if (c == null) {
                    continue;
                }
                SimilarCaseResult r = new SimilarCaseResult();
                r.caseId = c.Id;
                r.caseNumber = c.CaseNumber;
                r.subject = c.Subject;
                r.status = c.Status;
                r.type = c.Type;
                r.priority = c.Priority;
                r.reason = c.Reason;
                r.relevancyScore = Math.min(100, Math.max(0, score));
                results.add(r);
            }
        } catch (Exception e) {
            // Return empty on parse error
        }
        return results;
    }

    private static List<SimilarCaseResult> enrichAndLimit(List<SimilarCaseResult> scored, Integer maxReturn) {
        Integer cap = (maxReturn != null && maxReturn >= 1) ? Math.min(maxReturn, MAX_LIMIT_CAP) : MAX_SIMILAR_TO_RETURN;
        List<SimilarCaseResult> sorted = new List<SimilarCaseResult>(scored);
        sorted.sort(new RelevancyComparator());
        List<SimilarCaseResult> out = new List<SimilarCaseResult>();
        for (Integer i = 0; i < sorted.size() && i < cap; i++) out.add(sorted[i]);
        return out;
    }

    private class RelevancyComparator implements System.Comparator<SimilarCaseResult> {
        public Integer compare(SimilarCaseResult a, SimilarCaseResult b) {
            return (b.relevancyScore != null ? b.relevancyScore : 0) - (a.relevancyScore != null ? a.relevancyScore : 0);
        }
    }

    private static List<RelatedArticleResult> getRelatedKnowledgeArticles(Case sourceCase, Integer maxArticles) {
        List<RelatedArticleResult> articles = new List<RelatedArticleResult>();
        String searchTerm = sourceCase.Subject != null ? sourceCase.Subject.trim() : '';
        if (String.isBlank(searchTerm) || searchTerm.length() < 2) {
            return articles;
        }
        String searchPhrase = searchTerm.length() > 80 ? searchTerm.substring(0, 80) : searchTerm;
        searchPhrase = searchPhrase.replace('*', ' ').replace('?', ' ').replace('\\', ' ')
            .replace('&', ' ').replace('|', ' ').replace('!', ' ').replace('{', ' ').replace('}', ' ')
            .replace('[', ' ').replace(']', ' ').replace('(', ' ').replace(')', ' ')
            .replace('^', ' ').replace('~', ' ').replace(':', ' ').replace('"', ' ').replace('\'', ' ')
            .replace('+', ' ').trim();
        if (String.isBlank(searchPhrase)) {
            return articles;
        }
        List<String> findWords = getSearchWordsForSosl(searchPhrase);
        if (findWords.isEmpty()) return articles;
        final String kavType = 'Knowledge__kav';
        List<RelatedArticleResult> found = runKnowledgeSosl(kavType, findWords, sourceCase, maxArticles);
        if (found.isEmpty() && findWords.size() > 1) {
            found = runKnowledgeSosl(kavType, new List<String>{ searchPhrase }, sourceCase, maxArticles);
        }
        return found;
    }

    private static final Integer KAV_SEARCH_WORD_LIMIT = 10;
    private static final Integer KAV_RESULT_LIMIT = 10;

    private static List<String> getSearchWordsForSosl(String searchPhrase) {
        List<String> words = new List<String>();
        Set<String> stopWords = new Set<String>{ 'an', 'as', 'at', 'be', 'by', 'do', 'for', 'if', 'in', 'is', 'it', 'my', 'no', 'of', 'on', 'or', 'so', 'to', 'up', 'us', 'we' };
        for (String token : searchPhrase.split('\\s+')) {
            String t = token.replaceAll('[^a-zA-Z0-9]', '').toLowerCase();
            if (t.length() >= 2 && !stopWords.contains(t)) words.add(t);
        }
        if (words.size() > KAV_SEARCH_WORD_LIMIT) {
            List<String> trimmed = new List<String>();
            for (Integer i = 0; i < KAV_SEARCH_WORD_LIMIT; i++) trimmed.add(words[i]);
            return trimmed;
        }
        return words;
    }

    private static List<RelatedArticleResult> runKnowledgeSosl(String kavType, List<String> terms, Case sourceCase, Integer maxArticles) {
        List<RelatedArticleResult> articles = new List<RelatedArticleResult>();
        if (terms.isEmpty()) return articles;
        Integer articleCap = (maxArticles != null && maxArticles >= 1) ? Math.min(maxArticles, MAX_LIMIT_CAP) : KAV_RESULT_LIMIT;
        String subjectLower = (sourceCase.Subject != null ? sourceCase.Subject : '').toLowerCase();
        Set<String> subjectWords = subjectWordSet(subjectLower);
        Map<String, RelatedArticleResult> byId = new Map<String, RelatedArticleResult>();
        for (String w : terms) {
            String safe = w.replace('"', '\\"').replaceAll('[\\\\{}]', '') + '*';
            if (String.isBlank(safe) || safe.length() <= 1) continue;
            try {
                String sosl = 'FIND {"' + safe + '"} IN ALL FIELDS RETURNING ' + kavType + '(Id, Title, Summary, UrlName WHERE PublishStatus = \'Online\' LIMIT ' + articleCap + ')';
                List<List<SObject>> searchList = Search.query(sosl);
                if (searchList.isEmpty() || searchList[0].isEmpty()) continue;
                for (SObject row : searchList[0]) {
                    String articleId = (String) row.get('Id');
                    if (byId.containsKey(articleId)) continue;
                    RelatedArticleResult a = new RelatedArticleResult();
                    a.title = (String) row.get('Title');
                    a.summary = (String) row.get('Summary');
                    if (a.summary != null && a.summary.length() > 200) a.summary = a.summary.substring(0, 200) + '...';
                    a.url = '/lightning/r/' + kavType + '/' + articleId + '/view';
                    a.relevancyScore = computeArticleRelevancy(subjectWords, subjectLower, a.title, a.summary, w);
                    byId.put(articleId, a);
                }
            } catch (Exception e) { }
        }
        articles.addAll(byId.values());
        articles.sort(new ArticleRelevancyComparator());
        List<RelatedArticleResult> capped = new List<RelatedArticleResult>();
        for (Integer i = 0; i < articles.size() && i < articleCap; i++) capped.add(articles[i]);
        return capped;
    }

    private static Integer computeArticleRelevancy(Set<String> subjectWords, String subjectLower, String title, String summary, String searchTermThatFoundArticle) {
        if (subjectWords.isEmpty()) return 50;
        String combined = ((title != null ? title : '') + ' ' + (summary != null ? summary : '')).toLowerCase();
        Integer matches = 0;
        for (String w : subjectWords) { if (combined.contains(w)) matches++; }
        if (String.isNotBlank(searchTermThatFoundArticle) && subjectWords.contains(searchTermThatFoundArticle.toLowerCase()) && matches == 0) matches = 1;
        if (matches == 0) return 15;
        Integer score = subjectWords.size() > 0 ? (matches * 100) / subjectWords.size() : 50;
        return Math.min(100, Math.max(0, score));
    }

    private static Set<String> subjectWordSet(String subjectLower) {
        Set<String> words = new Set<String>();
        if (String.isBlank(subjectLower)) {
            return words;
        }
        for (String token : subjectLower.split('\\s+')) {
            String t = token.replaceAll('[^a-z0-9]', '');
            if (t.length() > 1) {
                words.add(t);
            }
        }
        return words;
    }

    private class ArticleRelevancyComparator implements System.Comparator<RelatedArticleResult> {
        public Integer compare(RelatedArticleResult a, RelatedArticleResult b) {
            Integer scoreA = a.relevancyScore != null ? a.relevancyScore : 0;
            Integer scoreB = b.relevancyScore != null ? b.relevancyScore : 0;
            return scoreB - scoreA;
        }
    }
}
