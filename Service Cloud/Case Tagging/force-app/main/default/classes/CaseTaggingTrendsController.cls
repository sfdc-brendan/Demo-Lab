/**
 * @description Apex controller for Case Tag Trends LWC: tag summary snapshot and cases by tag.
 */
public with sharing class CaseTaggingTrendsController {

    /**
     * @description Wrapper for tag name and case count. Sorts by count desc, then tag asc.
     */
    public class TagSummaryItem implements Comparable {
        @AuraEnabled public String tag;
        @AuraEnabled public Integer count;
        public TagSummaryItem(String tag, Integer count) {
            this.tag = tag;
            this.count = count;
        }
        public Integer compareTo(Object other) {
            TagSummaryItem o = (TagSummaryItem) other;
            if (this.count > o.count) return -1;
            if (this.count < o.count) return 1;
            return this.tag.compareTo(o.tag);
        }
    }

    /**
     * @description Wrapper for case row in trends list.
     */
    public class CaseSummaryItem {
        @AuraEnabled public String id;
        @AuraEnabled public String caseNumber;
        @AuraEnabled public String subject;
        @AuraEnabled public String createdDate;
        @AuraEnabled public String url;
        public CaseSummaryItem(Case c) {
            this.id = c.Id;
            this.caseNumber = c.CaseNumber;
            this.subject = c.Subject != null ? c.Subject : '';
            this.createdDate = c.CreatedDate != null ? c.CreatedDate.format() : '';
            this.url = '/' + c.Id;
        }
    }

    private static final Integer MAX_CASES_TO_QUERY = 10000;
    private static final Integer MAX_CASES_TO_RETURN = 500;

    /**
     * @description Returns tag summary (tag name + count) for cases in the last scopeMonths. Sorted by count descending.
     */
    @AuraEnabled(cacheable=true)
    public static List<TagSummaryItem> getTagSummary(Integer scopeMonths) {
        Date startDate = scopeMonths != null && scopeMonths > 0
            ? Date.today().addMonths(-scopeMonths)
            : Date.today().addYears(-1);

        List<Case> cases = [
            SELECT Id, Case_Tags__c
            FROM Case
            WHERE CreatedDate >= :startDate
            WITH SECURITY_ENFORCED
            LIMIT :MAX_CASES_TO_QUERY
        ];
        List<Case> withTags = new List<Case>();
        for (Case c : cases) {
            if (String.isNotBlank(c.Case_Tags__c)) withTags.add(c);
        }
        cases = withTags;

        Map<String, Integer> tagToCount = new Map<String, Integer>();
        for (Case c : cases) {
            if (String.isBlank(c.Case_Tags__c)) continue;
            for (String s : c.Case_Tags__c.split(',')) {
                String tag = s.trim();
                if (String.isBlank(tag)) continue;
                Integer cnt = tagToCount.get(tag);
                tagToCount.put(tag, cnt == null ? 1 : cnt + 1);
            }
        }

        List<TagSummaryItem> result = new List<TagSummaryItem>();
        for (String tag : tagToCount.keySet()) {
            result.add(new TagSummaryItem(tag, tagToCount.get(tag)));
        }
        result.sort();
        return result;
    }

    /**
     * @description Dashboard data: KPIs plus full tag summary for the given scope. Used by Case Tag Trends dashboard.
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getDashboardData(Integer scopeMonths) {
        List<TagSummaryItem> tagSummary = getTagSummary(scopeMonths);
        Date startDate = scopeMonths != null && scopeMonths > 0
            ? Date.today().addMonths(-scopeMonths)
            : Date.today().addYears(-1);
        List<Case> casesInScope = [
            SELECT Id, Case_Tags__c
            FROM Case
            WHERE CreatedDate >= :startDate
            WITH SECURITY_ENFORCED
            LIMIT :MAX_CASES_TO_QUERY
        ];
        Integer totalCasesTagged = 0;
        for (Case c : casesInScope) {
            if (String.isNotBlank(c.Case_Tags__c)) totalCasesTagged++;
        }
        Map<String, Object> result = new Map<String, Object>();
        result.put('totalCasesTagged', totalCasesTagged);
        result.put('uniqueTagCount', tagSummary != null ? tagSummary.size() : 0);
        result.put('tagSummary', tagSummary);
        result.put('scopeMonths', scopeMonths != null ? scopeMonths : 0);
        return result;
    }

    /**
     * @description Builds tag summary text, creates a context record, runs the AI summary flow, returns the narrative. Falls back to Apex-built summary on failure.
     */
    @AuraEnabled(cacheable=false)
    public static String getTrendsSummary(Integer scopeMonths) {
        Map<String, Object> dashboard = getDashboardData(scopeMonths);
        List<TagSummaryItem> tags = (List<TagSummaryItem>) dashboard.get('tagSummary');
        Integer total = (Integer) dashboard.get('totalCasesTagged');
        Integer unique = (Integer) dashboard.get('uniqueTagCount');
        Integer scope = (Integer) dashboard.get('scopeMonths');
        if (scope == null) scope = 0;
        if (total == null) total = 0;
        if (unique == null) unique = 0;

        String tagSummaryText = buildTagSummaryText(scope, total, unique, tags);

        try {
            Case_Tagging_Summary_Context__c ctx = new Case_Tagging_Summary_Context__c(Input_Text__c = tagSummaryText);
            insert as user ctx;
            try {
                Map<String, Object> inputs = new Map<String, Object>{ 'ContextId' => ctx.Id };
                Flow.Interview.Case_Tagging_Trends_Summary_Flow flow = new Flow.Interview.Case_Tagging_Trends_Summary_Flow(inputs);
                flow.start();
                Object out = flow.getVariableValue('SummaryText');
                if (out != null && String.isNotBlank(String.valueOf(out))) {
                    return String.valueOf(out);
                }
            } finally {
                delete as user ctx;
            }
        } catch (Exception e) {
            /* Flow or prompt not available; fall through to fallback */
        }

        return buildFallbackSummary(scope, total, unique, tags);
    }

    private static String buildTagSummaryText(Integer scope, Integer total, Integer unique, List<TagSummaryItem> tags) {
        String nl = String.fromCharArray(new List<Integer>{ 10 });
        String s = 'CASE TAGGING TRENDS DATA' + nl;
        s += 'Time scope: last ' + scope + ' month(s).' + nl;
        s += 'Total cases with at least one tag: ' + total + '.' + nl;
        s += 'Unique tags in use: ' + unique + '.' + nl;
        if (tags != null && !tags.isEmpty()) {
            Integer topN = Math.min(15, tags.size());
            s += 'Top ' + topN + ' tags by volume (tag name : count):' + nl;
            Integer sumTop = 0;
            for (Integer i = 0; i < topN; i++) {
                TagSummaryItem t = tags[i];
                sumTop += t.count;
                s += '  ' + (i + 1) + '. ' + t.tag + ' : ' + t.count + nl;
            }
            if (total > 0 && topN > 0) {
                Integer pct = (sumTop * 100) / total;
                s += 'These top ' + topN + ' tags account for ' + pct + '% of all tagged case volume.' + nl;
            }
        }
        return s;
    }

    private static String buildFallbackSummary(Integer scope, Integer total, Integer unique, List<TagSummaryItem> tags) {
        String nl = String.fromCharArray(new List<Integer>{ 10 });
        String s = '';

        s += 'Opening: Over the last ' + scope + (scope == 1 ? ' month' : ' months') + ', ' + total + ' case' + (total == 1 ? '' : 's') + ' were tagged using ' + unique + ' unique tag' + (unique == 1 ? '' : 's') + '. ';
        if (total > 0 && unique > 0) {
            Integer ratio = total / unique;
            if (ratio >= 2) {
                s += 'Volume is relatively high compared to tag diversity, suggesting recurring themes. ';
            } else if (ratio <= 1 && unique > 10) {
                s += 'Tag diversity is high relative to volume, indicating a broad spread of case types. ';
            } else {
                s += 'Volume and tag diversity are in a moderate range for the period. ';
            }
        }
        s += nl + nl;

        s += 'Key metrics and themes: ';
        if (tags != null && !tags.isEmpty()) {
            Integer show = Math.min(8, tags.size());
            for (Integer i = 0; i < show; i++) {
                if (i > 0) s += ' ';
                s += tags[i].tag + ' (' + tags[i].count + ')';
                if (i < show - 1) s += ',';
                if (i == show - 2) s += ' and';
            }
            s += '. ';
            if (total > 0 && show > 0) {
                Integer sumTop = 0;
                for (Integer i = 0; i < show; i++) sumTop += tags[i].count;
                Integer pct = (sumTop * 100) / total;
                s += 'These top ' + show + ' tags account for ' + pct + '% of tagged case volume. ';
                if (pct >= 70) {
                    s += 'Concentration in a few themes is notable and may warrant focused training or process review. ';
                } else if (pct <= 40 && unique > 15) {
                    s += 'Volume is spread across many tags; consider reviewing tag definitions for consistency. ';
                }
            }
        } else {
            s += 'No tag data available for this period. ';
        }
        s += nl + nl;

        s += 'Insight and recommendation: ';
        if (tags != null && !tags.isEmpty() && tags[0].count != null && total != null && total > 0) {
            Integer topPct = (tags[0].count * 100) / total;
            if (topPct >= 50) {
                s += 'The leading tag (' + tags[0].tag + ') dominates volume. Consider deep-dive analysis or knowledge-base updates for this area. ';
            } else {
                s += 'Review the top themes above to align training and staffing with current demand. Consider running this summary regularly to spot trends. ';
            }
        } else {
            s += 'Run historical analysis or expand the time scope to build a fuller picture of tagging trends. ';
        }

        return s;
    }

    /**
     * @description Returns cases that have the given tag (exact match, case-insensitive). Optionally limited by scope.
     */
    @AuraEnabled(cacheable=false)
    public static List<CaseSummaryItem> getCasesByTag(String tag, Integer scopeMonths) {
        if (String.isBlank(tag)) {
            return new List<CaseSummaryItem>();
        }

        Date startDate = scopeMonths != null && scopeMonths > 0
            ? Date.today().addMonths(-scopeMonths)
            : null;

        List<Case> allCases = [
            SELECT Id, CaseNumber, Subject, CreatedDate, Case_Tags__c
            FROM Case
            WITH SECURITY_ENFORCED
            LIMIT :MAX_CASES_TO_QUERY
        ];
        List<Case> cases = new List<Case>();
        for (Case c : allCases) {
            if (String.isNotBlank(c.Case_Tags__c)) cases.add(c);
        }

        if (startDate != null) {
            List<Case> filtered = new List<Case>();
            for (Case c : cases) {
                if (c.CreatedDate != null && c.CreatedDate.date() >= startDate) {
                    filtered.add(c);
                }
            }
            cases = filtered;
        }

        String tagLower = tag.trim().toLowerCase();
        List<CaseSummaryItem> result = new List<CaseSummaryItem>();
        for (Case c : cases) {
            if (String.isBlank(c.Case_Tags__c)) continue;
            for (String s : c.Case_Tags__c.split(',')) {
                if (s.trim().toLowerCase().equals(tagLower)) {
                    result.add(new CaseSummaryItem(c));
                    break;
                }
            }
            if (result.size() >= MAX_CASES_TO_RETURN) break;
        }
        return result;
    }

}
