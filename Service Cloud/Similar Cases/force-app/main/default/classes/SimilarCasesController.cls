/**
 * Apex controller for Similar Cases LWC.
 * Exposes getSimilarCasesWithScores to the client.
 */
public with sharing class SimilarCasesController {
    @AuraEnabled(cacheable=false)
    public static SimilarCasesService.SimilarCasesResponse getSimilarCasesWithScores(Id recordId, String statusFilter) {
        return SimilarCasesService.getSimilarCasesWithScores(recordId, statusFilter);
    }
}
