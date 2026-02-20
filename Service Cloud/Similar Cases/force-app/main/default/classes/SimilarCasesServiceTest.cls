/**
 * Test class for SimilarCasesService and SimilarCasesController.
 */
@IsTest
private class SimilarCasesServiceTest {
    @IsTest
    static void getSimilarCasesWithScores_returnsResults() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        Case current = new Case(Subject = 'Current case', Description = 'Description', AccountId = acc.Id, Status = 'New');
        insert current;
        Case other = new Case(Subject = 'Other case', Description = 'Similar issue', AccountId = acc.Id, Status = 'Working');
        insert other;

        SimilarCasesService.testGenerationJson = '[{"caseId":"' + other.Id + '","relevancyScore":85}]';

        Test.startTest();
        SimilarCasesService.SimilarCasesResponse response = SimilarCasesService.getSimilarCasesWithScores(current.Id, null, null, null);
        Test.stopTest();

        System.assertNotEquals(null, response, 'Response should not be null');
        System.assertEquals(null, response.errorMessage, 'No error expected');
        System.assertEquals(1, response.similarCases.size(), 'Should return one similar case');
        System.assertEquals(other.CaseNumber, response.similarCases[0].caseNumber);
        System.assertEquals(85, response.similarCases[0].relevancyScore);
    }

    @IsTest
    static void getSimilarCasesWithScores_invalidId_returnsError() {
        Test.startTest();
        SimilarCasesService.SimilarCasesResponse response = SimilarCasesService.getSimilarCasesWithScores(null, null, null, null);
        Test.stopTest();
        System.assertNotEquals(null, response.errorMessage, 'Should set error for null id');
        System.assertEquals(0, response.similarCases.size());
    }

    @IsTest
    static void controller_getSimilarCasesWithScores() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        Case c = new Case(Subject = 'Test', AccountId = acc.Id, Status = 'New');
        insert c;
        SimilarCasesService.testGenerationJson = '[]';

        Test.startTest();
        SimilarCasesService.SimilarCasesResponse response = SimilarCasesController.getSimilarCasesWithScores(c.Id, 'Closed', null, null);
        Test.stopTest();

        System.assertNotEquals(null, response);
    }
}
