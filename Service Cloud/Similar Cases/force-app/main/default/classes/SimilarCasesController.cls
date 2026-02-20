/**
 * Apex controller for Similar Cases LWC.
 * Exposes getSimilarCasesWithScores to the client.
 */
public with sharing class SimilarCasesController {
    @AuraEnabled(cacheable=false)
    public static SimilarCasesService.SimilarCasesResponse getSimilarCasesWithScores(Id recordId, String statusFilter, Integer maxSimilarCases, Integer maxRelatedArticles) {
        return SimilarCasesService.getSimilarCasesWithScores(recordId, statusFilter, maxSimilarCases, maxRelatedArticles);
    }
}
