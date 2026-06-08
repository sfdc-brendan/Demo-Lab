@IsTest
private class IntakeTranscriptAnalyzerTest {

    @IsTest
    static void analyze_returnsEmptyMapForBlankTranscript() {
        Map<String, String> result =
            IntakeTranscriptAnalyzer.analyzeTranscript('persona', '[]', '');
        System.assertEquals(0, result.size());
    }

    @IsTest
    static void analyze_parsesJsonResponse() {
        IntakeTranscriptAnalyzer.mockResponse = '{"Customer_Name":"Alice","Issue_Type":"Flat Tire"}';
        String qJson = '[' +
            '{"developerName":"Customer_Name","questionText":"Name?","answerType":"text"},' +
            '{"developerName":"Issue_Type","questionText":"Issue?","answerType":"picklist","picklistValuesStr":"Flat Tire;Lockout","aiHint":"Pick the closest"}' +
            ']';

        Test.startTest();
        Map<String, String> result = IntakeTranscriptAnalyzer.analyzeTranscript(
            'You are a roadside assistance analyst.', qJson, 'Customer: This is Alice with a flat tire.'
        );
        Test.stopTest();

        System.assertEquals('Alice', result.get('Customer_Name'));
        System.assertEquals('Flat Tire', result.get('Issue_Type'));
    }

    @IsTest
    static void analyze_stripsCodeFences() {
        IntakeTranscriptAnalyzer.mockResponse = '```json\n{"Customer_Name":"Bob"}\n```';
        String qJson = '[{"developerName":"Customer_Name","questionText":"Name?","answerType":"text"}]';
        Map<String, String> result = IntakeTranscriptAnalyzer.analyzeTranscript(
            null, qJson, 'Customer: Bob speaking.'
        );
        System.assertEquals('Bob', result.get('Customer_Name'));
    }

    @IsTest
    static void analyze_handlesInvalidJson() {
        IntakeTranscriptAnalyzer.mockResponse = 'not actually json';
        String qJson = '[{"developerName":"Customer_Name","questionText":"Name?","answerType":"text"}]';
        Map<String, String> result = IntakeTranscriptAnalyzer.analyzeTranscript(
            null, qJson, 'Customer: hi.'
        );
        System.assertEquals(0, result.size());
    }

    @IsTest
    static void analyze_usesTranscriptFallbackWhenModelUnavailable() {
        IntakeTranscriptAnalyzer.mockResponse = null;
        String qJson =
            '[' +
            '{"developerName":"Customer_Name","questionText":"What is the requester\'s full name?","answerType":"text"},' +
            '{"developerName":"Callback","questionText":"What is the best contact phone number or email?","answerType":"phone"},' +
            '{"developerName":"Need_By","questionText":"When is this needed by?","answerType":"date"},' +
            '{"developerName":"Priority","questionText":"What is the priority level?","answerType":"picklist","picklistValuesStr":"High;Medium;Low"}' +
            ']';
        String transcript =
            'Agent: What is the requester\'s full name?\n' +
            'Customer: Jane Martinez\n' +
            'Agent: What is the best contact phone number or email?\n' +
            'Customer: 555-867-5309\n' +
            'Agent: When is this needed by?\n' +
            'Customer: 6/10/2026\n' +
            'Agent: What is the priority level?\n' +
            'Customer: High';

        Map<String, String> result = IntakeTranscriptAnalyzer.analyzeTranscript(null, qJson, transcript);
        System.assertEquals('Jane Martinez', result.get('Customer_Name'));
        System.assertEquals('555-867-5309', result.get('Callback'));
        System.assertEquals('2026-06-10', result.get('Need_By'));
        System.assertEquals('High', result.get('Priority'));
    }
}
