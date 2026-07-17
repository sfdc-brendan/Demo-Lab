/**
 * Relevance guard for Agentforce Vision Knowledge retrieval.
 *
 * The vision model returns terse keywords (e.g. "clothes dryer, lint, drum, belt")
 * that get fed into a `FIND ... IN ALL FIELDS` SOSL search. Because that search
 * matches on every field, a single shared or generic word can promote an
 * unrelated article - e.g. a "clothes dryer" photo matching the "Hair Dryer"
 * article purely on the word "dryer". That produced a confident-looking
 * "Recommended fix" whose steps did not match what was actually diagnosed.
 *
 * This class re-ranks the raw SOSL candidates by how many of the *distinct,
 * meaningful* query terms actually appear in the article's Title/Summary (the
 * high-signal fields) and drops anything that clears only on a single ambiguous
 * word. When nothing is a confident match it returns an empty list, so callers
 * (and the web UI) can show a "no specific article found" state rather than the
 * wrong steps.
 */
public with sharing class VisionArticleRelevance {
    // A confident match must hit at least this many distinct query terms in the
    // Title/Summary. Two independent terms is what separates a real match
    // ("router" + "light") from an ambiguous single-word collision ("dryer").
    @TestVisible
    private static final Integer MIN_DISTINCT_TERM_MATCHES = 2;

    // Query tokens shorter than this are ignored as noise.
    @TestVisible
    private static final Integer MIN_TERM_LENGTH = 3;

    // A Title hit is a stronger relevance signal than a Summary hit.
    private static final Double TITLE_WEIGHT = 2.0;
    private static final Double SUMMARY_WEIGHT = 1.0;

    // Generic grammatical/support words that appear across many troubleshooting
    // articles. Kept out of the meaningful-term set so they can never, on their
    // own, push an unrelated article over the confidence bar. Distinctive nouns
    // (light, code, error, drain, signal, ...) are deliberately NOT here - those
    // only help when paired with the actual subject noun.
    private static final Set<String> STOP_WORDS = new Set<String>{
        'the', 'and', 'for', 'with', 'not', 'you', 'your', 'are', 'has', 'have',
        'from', 'out', 'off', 'use', 'used', 'using', 'get', 'got', 'when', 'how',
        'why', 'what', 'this', 'that', 'they', 'them', 'its', 'was', 'were',
        'power', 'powered', 'reset', 'outlet', 'plug', 'plugged', 'button',
        'work', 'works', 'working', 'broken', 'break', 'fix', 'fixed', 'issue',
        'issues', 'problem', 'problems', 'help', 'turn', 'unit', 'device', 'wall',
        'room', 'guest', 'front', 'desk', 'service', 'stop', 'start', 'need',
        'won', 'wont', 'cant', 'doesnt', 'isnt'
    };

    /**
     * Filters and re-ranks SOSL candidate articles down to the confident matches.
     *
     * @param keywords   the raw comma/space separated keywords from image analysis
     * @param candidates SOSL result articles (must have Title and Summary selected)
     * @param maxReturn  maximum number of articles to return
     * @return           confident matches ranked most-relevant first (possibly empty)
     */
    public static List<Knowledge__kav> selectRelevant(
        String keywords,
        List<Knowledge__kav> candidates,
        Integer maxReturn
    ) {
        List<Knowledge__kav> out = new List<Knowledge__kav>();
        if (candidates == null || candidates.isEmpty()) {
            return out;
        }

        Set<String> terms = meaningfulTerms(keywords);
        if (terms.isEmpty()) {
            // Nothing distinctive to match on - don't guess a recommendation.
            return out;
        }

        // With only a single distinctive term we can't require two matches, so a
        // strong single-term hit is allowed; otherwise demand at least two.
        Integer requiredDistinct = terms.size() <= 1 ? 1 : MIN_DISTINCT_TERM_MATCHES;

        List<Scored> scored = new List<Scored>();
        for (Knowledge__kav a : candidates) {
            String title = a.Title == null ? '' : a.Title.toLowerCase();
            String summary = a.Summary == null ? '' : a.Summary.toLowerCase();

            Integer distinctMatches = 0;
            Double score = 0;
            for (String term : terms) {
                Boolean inTitle = title.contains(term);
                Boolean inSummary = summary.contains(term);
                if (inTitle || inSummary) {
                    distinctMatches++;
                    // Count the strongest field a term appears in, not both, so a
                    // single ambiguous word repeated in Title + Summary can't inflate.
                    score += inTitle ? TITLE_WEIGHT : SUMMARY_WEIGHT;
                }
            }

            if (distinctMatches >= requiredDistinct) {
                scored.add(new Scored(a, score));
            }
        }

        scored.sort();
        for (Integer i = 0; i < scored.size() && i < maxReturn; i++) {
            out.add(scored[i].article);
        }
        return out;
    }

    /**
     * Splits raw keywords into a set of distinct, lowercased, meaningful terms.
     */
    @TestVisible
    private static Set<String> meaningfulTerms(String keywords) {
        Set<String> terms = new Set<String>();
        if (String.isBlank(keywords)) {
            return terms;
        }
        for (String raw : keywords.toLowerCase().split('[^a-z0-9]+')) {
            String token = raw.trim();
            if (token.length() >= MIN_TERM_LENGTH && !STOP_WORDS.contains(token)) {
                terms.add(token);
            }
        }
        return terms;
    }

    /** Article paired with its relevance score, sorted highest-score first. */
    private class Scored implements Comparable {
        public Knowledge__kav article;
        public Double score;

        public Scored(Knowledge__kav article, Double score) {
            this.article = article;
            this.score = score;
        }

        public Integer compareTo(Object other) {
            Scored o = (Scored) other;
            if (this.score == o.score) {
                return 0;
            }
            return this.score < o.score ? 1 : -1;
        }
    }
}
