public with sharing class IntakeTranscriptAnalyzer {

    private static final String MODEL_NAME = 'sfdc_ai__DefaultGPT4Omni';
    private static final String DEFAULT_PERSONA =
        'You are a customer service AI assistant analyzing a customer call transcript.';

    @TestVisible
    private static String mockResponse;

    @AuraEnabled
    public static Map<String, String> analyzeTranscript(
        String personaDescription,
        String questionsJson,
        String transcriptText
    ) {
        if (String.isBlank(transcriptText)) {
            return new Map<String, String>();
        }

        List<QuestionInput> questions = (List<QuestionInput>) JSON.deserialize(
            questionsJson, List<QuestionInput>.class
        );

        String prompt = buildPrompt(personaDescription, questions, transcriptText);
        String aiResponse = callModel(prompt);

        if (String.isBlank(aiResponse)) {
            return new Map<String, String>();
        }

        return parseResponse(aiResponse);
    }

    private static String buildPrompt(
        String personaDescription,
        List<QuestionInput> questions,
        String transcript
    ) {
        String persona = String.isNotBlank(personaDescription) ? personaDescription : DEFAULT_PERSONA;

        String questionList = '';
        for (QuestionInput q : questions) {
            questionList += '- ' + q.developerName + ': "' + q.questionText + '"';
            if (q.answerType == 'picklist' && String.isNotBlank(q.picklistValuesStr)) {
                questionList += ' [Valid options: ' + q.picklistValuesStr.replace(';', ', ') + ']';
            } else if (q.answerType == 'multipicklist' && String.isNotBlank(q.picklistValuesStr)) {
                questionList += ' [Multi-select; semicolon-separate options chosen from: '
                    + q.picklistValuesStr.replace(';', ', ') + ']';
            } else if (q.answerType == 'boolean') {
                questionList += ' [true / false]';
            } else if (q.answerType == 'number') {
                questionList += ' [numeric]';
            } else if (q.answerType == 'date') {
                questionList += ' [YYYY-MM-DD]';
            } else if (q.answerType == 'email') {
                questionList += ' [email address]';
            }
            if (String.isNotBlank(q.aiHint)) {
                questionList += '\n    Hint: ' + q.aiHint;
            }
            questionList += '\n';
        }

        return persona + '\n\n'
            + 'QUESTIONS TO ANSWER:\n' + questionList + '\n'
            + 'CALL TRANSCRIPT:\n' + transcript + '\n\n'
            + 'INSTRUCTIONS:\n'
            + '- Extract answers from the transcript for each question where you find a clear answer.\n'
            + '- For picklist questions, choose the closest matching valid option exactly as written.\n'
            + '- For multipicklist questions, return a single string with valid options separated by semicolons.\n'
            + '- For boolean questions, return "true" or "false".\n'
            + '- Respond ONLY with a valid JSON object mapping question developerName to the extracted answer.\n'
            + '- Omit questions where no answer is found.\n'
            + '- Do not include any explanation, markdown formatting, or code fences.\n'
            + 'Example: {"Customer_Name":"John Doe","Issue_Type":"Flat Tire"}';
    }

    private static String callModel(String prompt) {
        if (Test.isRunningTest() && mockResponse != null) {
            return mockResponse;
        }
        return null;
    }

    private static Map<String, String> parseResponse(String raw) {
        Map<String, String> result = new Map<String, String>();
        String cleaned = raw.trim();

        if (cleaned.startsWith('```')) {
            cleaned = cleaned.replaceAll('```[a-zA-Z]*\\n?', '').replaceAll('```', '').trim();
        }

        try {
            Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(cleaned);
            for (String key : parsed.keySet()) {
                Object val = parsed.get(key);
                if (val != null && String.isNotBlank(String.valueOf(val))) {
                    result.put(key, String.valueOf(val));
                }
            }
        } catch (Exception e) {
            // AI returned non-JSON; return whatever we have
        }

        return result;
    }

    public class QuestionInput {
        public String developerName;
        public String questionText;
        public String answerType;
        public String picklistValuesStr;
        public String aiHint;
    }
}
