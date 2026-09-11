/**
 * @description Typed wrapper for the strict-JSON response produced by the Coaching Intelligence v2
 *              prompt templates (Voice / Chat / Case). Deserialized by CoachingIngestService.
 *              Replaces the fragile string parsing used by the v1 extractor classes.
 */
public with sharing class CoachingResult {
    public Integer performanceRating;
    public Categories categories;
    public String summary;
    public String sentimentRating;
    public String sentimentNarrative;

    public class Categories {
        public String agentProcess;
        public String customerFocus;
        public String softSkills;
        public String toneLanguageClarity;
        public String professionalConduct;
    }

    /**
     * @description Parse a raw model response into a CoachingResult. Tolerates surrounding prose
     *              or markdown code fences by extracting the outermost JSON object.
     * @param raw the raw text returned by the prompt template
     * @return parsed CoachingResult, or null if no JSON object could be located/parsed
     */
    public static CoachingResult parse(String raw) {
        if (String.isBlank(raw)) {
            return null;
        }
        String jsonText = extractJsonObject(raw);
        if (jsonText == null) {
            return null;
        }
        try {
            return (CoachingResult) JSON.deserialize(jsonText, CoachingResult.class);
        } catch (Exception e) {
            return null;
        }
    }

    private static String extractJsonObject(String raw) {
        Integer startIdx = raw.indexOf('{');
        Integer endIdx = raw.lastIndexOf('}');
        if (startIdx == -1 || endIdx == -1 || endIdx < startIdx) {
            return null;
        }
        return raw.substring(startIdx, endIdx + 1);
    }

    /**
     * @description Compose a human-readable evaluation string with section headers that match the
     *              display LWC's bolding conventions (and the v1 fields it mirrors into).
     */
    public String toEvaluationText() {
        List<String> parts = new List<String>();
        if (categories != null) {
            if (String.isNotBlank(categories.agentProcess)) {
                parts.add('Agent Process: ' + categories.agentProcess);
            }
            if (String.isNotBlank(categories.customerFocus)) {
                parts.add('Customer Focus: ' + categories.customerFocus);
            }
            if (String.isNotBlank(categories.softSkills)) {
                parts.add('Soft Skills: ' + categories.softSkills);
            }
            if (String.isNotBlank(categories.toneLanguageClarity)) {
                parts.add('Tone, Language, and Clarity: ' + categories.toneLanguageClarity);
            }
            if (String.isNotBlank(categories.professionalConduct)) {
                parts.add('Professional Conduct: ' + categories.professionalConduct);
            }
        }
        if (String.isNotBlank(summary)) {
            parts.add('Overall Summary: ' + summary);
        }
        if (performanceRating != null) {
            parts.add('Rating Score: ' + performanceRating);
        }
        return String.join(parts, '\n\n');
    }
}
