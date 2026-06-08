public with sharing class IntakeTranscriptAnalyzer {

    private static final String MODEL_NAME = 'sfdc_ai__DefaultGPT4Omni';
    private static final String DEFAULT_PERSONA =
        'You are a customer service AI assistant analyzing a customer call transcript.';

    @TestVisible
    private static String mockResponse;

    private class TranscriptPair {
        String agentPrompt;
        String customerReply;
        TranscriptPair(String agentPrompt, String customerReply) {
            this.agentPrompt = agentPrompt;
            this.customerReply = customerReply;
        }
    }

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
            return extractAnswersWithoutModel(questions, transcriptText);
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

    private static Map<String, String> extractAnswersWithoutModel(
        List<QuestionInput> questions,
        String transcriptText
    ) {
        Map<String, String> results = new Map<String, String>();
        if (questions == null || questions.isEmpty() || String.isBlank(transcriptText)) {
            return results;
        }

        List<TranscriptPair> pairs = parseTranscriptPairs(transcriptText);
        String transcriptLower = transcriptText.toLowerCase();
        for (QuestionInput q : questions) {
            if (q == null || String.isBlank(q.developerName)) {
                continue;
            }
            String answer = extractAnswerForQuestion(q, pairs, transcriptLower);
            if (String.isNotBlank(answer)) {
                results.put(q.developerName, answer);
            }
        }
        return results;
    }

    private static List<TranscriptPair> parseTranscriptPairs(String transcriptText) {
        List<TranscriptPair> pairs = new List<TranscriptPair>();
        if (String.isBlank(transcriptText)) {
            return pairs;
        }
        String pendingPrompt;
        for (String rawLine : transcriptText.split('\n')) {
            String line = rawLine == null ? '' : rawLine.trim();
            if (line == '') {
                continue;
            }
            if (line.toLowerCase().startsWith('agent:')) {
                pendingPrompt = line.substring(6).trim();
            } else if (line.toLowerCase().startsWith('customer:') && String.isNotBlank(pendingPrompt)) {
                String reply = line.substring(9).trim();
                pairs.add(new TranscriptPair(pendingPrompt, reply));
                pendingPrompt = null;
            }
        }
        return pairs;
    }

    private static String extractAnswerForQuestion(
        QuestionInput question,
        List<TranscriptPair> pairs,
        String transcriptLower
    ) {
        String targetQuestion = normalizeText(question.questionText);
        for (TranscriptPair pair : pairs) {
            if (normalizeText(pair.agentPrompt) == targetQuestion) {
                return normalizeAnswerByType(question.answerType, question.picklistValuesStr, pair.customerReply);
            }
        }

        String answerType = String.isBlank(question.answerType) ? 'text' : question.answerType.toLowerCase();
        if (answerType == 'picklist' || answerType == 'multipicklist') {
            String picked = pickFromOptions(question.picklistValuesStr, transcriptLower);
            if (String.isNotBlank(picked)) {
                return picked;
            }
        } else if (answerType == 'boolean') {
            if (transcriptLower.contains(' yes') || transcriptLower.contains(' true')) return 'true';
            if (transcriptLower.contains(' no') || transcriptLower.contains(' false')) return 'false';
        } else if (answerType == 'email') {
            Matcher m = Pattern.compile('([A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,})').matcher(transcriptLower);
            if (m.find()) return m.group(1);
        } else if (answerType == 'phone') {
            Matcher m = Pattern.compile('(\\+?[0-9][0-9\\-() ]{6,}[0-9])').matcher(transcriptLower);
            if (m.find()) return m.group(1);
        } else if (answerType == 'number') {
            Matcher m = Pattern.compile('(-?[0-9]+(?:\\.[0-9]+)?)').matcher(transcriptLower);
            if (m.find()) return m.group(1);
        } else if (answerType == 'date') {
            Matcher iso = Pattern.compile('(\\d{4}-\\d{2}-\\d{2})').matcher(transcriptLower);
            if (iso.find()) return iso.group(1);
            Matcher us = Pattern.compile('(\\d{1,2})/(\\d{1,2})/(\\d{4})').matcher(transcriptLower);
            if (us.find()) {
                Integer month = Integer.valueOf(us.group(1));
                Integer day = Integer.valueOf(us.group(2));
                Integer year = Integer.valueOf(us.group(3));
                try {
                    return formatDateIso(Date.newInstance(year, month, day));
                } catch (Exception ex) {
                    return null;
                }
            }
        }

        return null;
    }

    private static String normalizeAnswerByType(String answerType, String picklistValuesStr, String rawAnswer) {
        if (String.isBlank(rawAnswer)) {
            return null;
        }
        String answer = rawAnswer.trim();
        String normalizedType = String.isBlank(answerType) ? 'text' : answerType.toLowerCase();

        if (normalizedType == 'picklist' || normalizedType == 'multipicklist') {
            String picked = pickFromOptions(picklistValuesStr, answer.toLowerCase());
            if (String.isNotBlank(picked)) {
                return picked;
            }
            return answer;
        }
        if (normalizedType == 'boolean') {
            String lower = answer.toLowerCase();
            if (lower.contains('yes') || lower == 'true') return 'true';
            if (lower.contains('no') || lower == 'false') return 'false';
            return null;
        }
        if (normalizedType == 'number') {
            Matcher m = Pattern.compile('(-?[0-9]+(?:\\.[0-9]+)?)').matcher(answer);
            return m.find() ? m.group(1) : null;
        }
        if (normalizedType == 'date') {
            Matcher iso = Pattern.compile('(\\d{4}-\\d{2}-\\d{2})').matcher(answer);
            if (iso.find()) return iso.group(1);
            Matcher us = Pattern.compile('(\\d{1,2})/(\\d{1,2})/(\\d{4})').matcher(answer);
            if (us.find()) {
                try {
                    return formatDateIso(Date.newInstance(
                        Integer.valueOf(us.group(3)),
                        Integer.valueOf(us.group(1)),
                        Integer.valueOf(us.group(2))
                    ));
                } catch (Exception ex) {
                    return null;
                }
            }
            return null;
        }
        if (normalizedType == 'email') {
            Matcher m = Pattern.compile('([A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,})').matcher(answer);
            return m.find() ? m.group(1) : null;
        }
        if (normalizedType == 'phone') {
            Matcher m = Pattern.compile('(\\+?[0-9][0-9\\-() ]{6,}[0-9])').matcher(answer);
            return m.find() ? m.group(1) : null;
        }
        return answer;
    }

    private static String pickFromOptions(String picklistValuesStr, String haystackLower) {
        if (String.isBlank(picklistValuesStr) || String.isBlank(haystackLower)) {
            return null;
        }
        for (String opt : picklistValuesStr.split(';')) {
            String trimmed = opt == null ? '' : opt.trim();
            if (trimmed != '' && haystackLower.contains(trimmed.toLowerCase())) {
                return trimmed;
            }
        }
        return null;
    }

    private static String normalizeText(String text) {
        if (String.isBlank(text)) return '';
        return text.toLowerCase().replaceAll('[^a-z0-9]+', ' ').trim();
    }

    private static String formatDateIso(Date d) {
        if (d == null) return null;
        return String.valueOf(d.year())
            + '-'
            + String.valueOf(d.month()).leftPad(2, '0')
            + '-'
            + String.valueOf(d.day()).leftPad(2, '0');
    }

    public class QuestionInput {
        public String developerName;
        public String questionText;
        public String answerType;
        public String picklistValuesStr;
        public String aiHint;
    }
}
