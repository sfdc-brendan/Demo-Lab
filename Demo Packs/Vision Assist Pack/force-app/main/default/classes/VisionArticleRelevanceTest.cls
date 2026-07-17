/**
 * Unit tests for the Knowledge relevance guard. These are pure in-memory tests -
 * selectRelevant only reads Title/Summary, so no DML or SOSL fixtures are needed.
 */
@IsTest
private class VisionArticleRelevanceTest {
    private static Knowledge__kav article(String title, String summary) {
        return new Knowledge__kav(Title = title, Summary = summary);
    }

    private static Knowledge__kav hairDryer() {
        return article(
            'Hair Dryer or Bathroom Outlet Not Working',
            'Reset the bathroom GFCI outlet when the hair dryer or bathroom plug has no power.'
        );
    }

    private static Knowledge__kav wifiRouter() {
        return article(
            'In-Room Wi-Fi Router Indicator Lights',
            'Understand the in-room Wi-Fi access point light patterns and how to restore your connection.'
        );
    }

    @IsTest
    static void rejectsSingleWordCollision() {
        // A clothes-dryer photo shares only the ambiguous word "dryer" with the
        // Hair Dryer article - it must NOT be returned as a confident match.
        List<Knowledge__kav> result = VisionArticleRelevance.selectRelevant(
            'clothes dryer, lint buildup, drum, belt, not heating',
            new List<Knowledge__kav>{ hairDryer() },
            4
        );
        System.assertEquals(0, result.size(), 'Single ambiguous word should not be a confident match');
    }

    @IsTest
    static void returnsGenuineMultiTermMatch() {
        List<Knowledge__kav> result = VisionArticleRelevance.selectRelevant(
            'router, amber light, no internet',
            new List<Knowledge__kav>{ hairDryer(), wifiRouter() },
            4
        );
        System.assertEquals(1, result.size(), 'Only the Wi-Fi router article is relevant');
        System.assertEquals('In-Room Wi-Fi Router Indicator Lights', result[0].Title);
    }

    @IsTest
    static void allowsStrongSingleTermQuery() {
        // With only one distinctive term, a strong title hit is still a match.
        List<Knowledge__kav> result = VisionArticleRelevance.selectRelevant(
            'thermostat',
            new List<Knowledge__kav>{
                hairDryer(),
                article('In-Room Thermostat Troubleshooting', 'Resolve smart thermostat errors and E1-E5 codes.')
            },
            4
        );
        System.assertEquals(1, result.size(), 'Single distinctive term should still match its article');
        System.assertEquals('In-Room Thermostat Troubleshooting', result[0].Title);
    }

    @IsTest
    static void ranksTitleHitsAboveSummaryHits() {
        // Both articles match the two query terms, but the first matches them in
        // the Title (stronger) and should rank first.
        Knowledge__kav strong = article('Coffee Maker Descale Reset', 'Steps for the machine.');
        Knowledge__kav weak = article('Kitchen Appliances', 'How to descale a coffee maker unit.');
        List<Knowledge__kav> result = VisionArticleRelevance.selectRelevant(
            'coffee, descale',
            new List<Knowledge__kav>{ weak, strong },
            4
        );
        System.assertEquals(2, result.size(), 'Both articles are relevant');
        System.assertEquals('Coffee Maker Descale Reset', result[0].Title, 'Title matches should rank first');
    }

    @IsTest
    static void honorsMaxReturn() {
        List<Knowledge__kav> candidates = new List<Knowledge__kav>{
            article('Smoke Detector Chirping', 'Smoke detector chirping troubleshooting.'),
            article('Smoke Alarm Cover', 'Smoke detector cover open guidance.'),
            article('Detector Battery', 'Smoke detector battery replacement.')
        };
        List<Knowledge__kav> result = VisionArticleRelevance.selectRelevant(
            'smoke detector chirping',
            candidates,
            2
        );
        System.assertEquals(2, result.size(), 'Should not return more than maxReturn');
    }

    @IsTest
    static void handlesBlankKeywordsAndEmptyCandidates() {
        System.assertEquals(
            0,
            VisionArticleRelevance.selectRelevant('   ', new List<Knowledge__kav>{ hairDryer() }, 4).size(),
            'Blank keywords yield no matches'
        );
        System.assertEquals(
            0,
            VisionArticleRelevance.selectRelevant('router', new List<Knowledge__kav>(), 4).size(),
            'Empty candidate list yields no matches'
        );
        System.assertEquals(
            0,
            VisionArticleRelevance.selectRelevant('router', null, 4).size(),
            'Null candidate list yields no matches'
        );
    }

    @IsTest
    static void ignoresGenericStopWords() {
        // "power" and "reset" are generic and must not count toward the match
        // threshold. Here "dryer" + "lint" are the meaningful terms; only "dryer"
        // hits the Hair Dryer article, so the generic words can't rescue it to a
        // confident (2-term) match - it must still be rejected.
        List<Knowledge__kav> result = VisionArticleRelevance.selectRelevant(
            'dryer, lint, no power, reset',
            new List<Knowledge__kav>{ hairDryer() },
            4
        );
        System.assertEquals(0, result.size(), 'Generic support words must not create a confident match');
    }
}
