@isTest
private class CoachingResultTest {
    private static String validJson() {
        Map<String, Object> categories = new Map<String, Object>{
            'agentProcess' => 'Greeted and verified identity.',
            'customerFocus' => 'Offered first-contact resolution.',
            'softSkills' => 'Used the customer name and showed empathy.',
            'toneLanguageClarity' => 'Clear and concise.',
            'professionalConduct' => 'Professional throughout.'
        };
        Map<String, Object> root = new Map<String, Object>{
            'performanceRating' => 8,
            'categories' => categories,
            'summary' => 'Strong handling overall.',
            'sentimentRating' => 'Positive',
            'sentimentNarrative' => 'Customer thanked the agent multiple times.'
        };
        return JSON.serialize(root);
    }

    @isTest
    static void parsesCleanJson() {
        CoachingResult r = CoachingResult.parse(validJson());
        System.Assert.areEqual(8, r.performanceRating);
        System.Assert.areEqual('Positive', r.sentimentRating);
        System.Assert.isNotNull(r.categories);
        System.Assert.areEqual('Clear and concise.', r.categories.toneLanguageClarity);
    }

    @isTest
    static void parsesJsonWrappedInProseAndFences() {
        String wrapped = 'Here is the result:\n```json\n' + validJson() + '\n```\nThanks!';
        CoachingResult r = CoachingResult.parse(wrapped);
        System.Assert.isNotNull(r, 'Should extract JSON object from surrounding text/fences');
        System.Assert.areEqual('Strong handling overall.', r.summary);
    }

    @isTest
    static void returnsNullForBlankOrInvalid() {
        System.Assert.isNull(CoachingResult.parse(null));
        System.Assert.isNull(CoachingResult.parse('   '));
        System.Assert.isNull(CoachingResult.parse('no json here'));
    }

    @isTest
    static void evaluationTextContainsHeadersAndRating() {
        CoachingResult r = CoachingResult.parse(validJson());
        String txt = r.toEvaluationText();
        System.Assert.isTrue(txt.contains('Agent Process:'), 'Has Agent Process header');
        System.Assert.isTrue(txt.contains('Overall Summary:'), 'Has Overall Summary header');
        System.Assert.isTrue(txt.contains('Rating Score: 8'), 'Has rating line');
    }
}
