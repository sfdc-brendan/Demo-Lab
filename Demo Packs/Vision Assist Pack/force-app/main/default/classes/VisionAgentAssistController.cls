/**
 * Agentforce Vision - Agent (CSR) Assist controller.
 *
 * Backs the visionAgentAssist Lightning Web Component that runs in the Service
 * Console beside a live conversation (Messaging Session or Case). It lets a
 * customer service rep triage a screenshot the customer sent in chat without
 * ever leaving the record:
 *
 *   1. getLatestScreenshot(recordId) - finds the most recent image the customer
 *      uploaded to the conversation so the LWC can "listen" for new screenshots.
 *   2. analyzeScreenshot(...)        - sends that image to the vision prompt
 *      template (via the existing AgentforceVisionImageAction), then grounds the
 *      fix in Lightning Knowledge (via the shared VisionArticleRelevance guard)
 *      and returns a diagnosis plus rep-ready troubleshooting steps.
 *
 * This reuses the same on-platform, Trust-Layer path as the customer-facing
 * agent - the difference is only the surface: an assist panel for the human rep
 * instead of an autonomous agent turn.
 */
public with sharing class VisionAgentAssistController {
    // How far back to look for "the screenshot the customer just sent" when no
    // image is directly linked to the conversation record.
    @TestVisible
    private static final Integer RECENT_IMAGE_WINDOW_MINUTES = 30;

    // Images pulled from an inbound email below this size are almost always
    // signature/logo graphics rather than the screenshot the customer sent, so
    // they are skipped when resolving an email attachment on a Case.
    @TestVisible
    private static Integer MIN_EMAIL_IMAGE_BYTES = 12000;

    @TestVisible
    private static final Integer MAX_ARTICLES = 3;

    // Wider SOSL pool so the relevance guard has candidates to rank and filter.
    @TestVisible
    private static final Integer CANDIDATE_POOL = 20;

    // Seam so tests can supply deterministic Knowledge results without depending
    // on article publishing mechanics.
    @TestVisible
    private static Searcher searcher = new SoslSearcher();

    private static final Set<String> IMAGE_TYPES = new Set<String>{
        'PNG', 'JPG', 'JPEG', 'GIF', 'WEBP', 'BMP', 'HEIC'
    };

    /* ------------------------------------------------------------------ *
     *  DTOs returned to the LWC
     * ------------------------------------------------------------------ */

    public class ScreenshotInfo {
        @AuraEnabled public String contentDocumentId;
        @AuraEnabled public String contentVersionId;
        @AuraEnabled public String title;
        @AuraEnabled public String fileType;
        @AuraEnabled public Long createdDateMs;
        @AuraEnabled public String previewUrl;
    }

    public class ArticleRef {
        @AuraEnabled public String title;
        @AuraEnabled public String summary;
        @AuraEnabled public String articleNumber;
        @AuraEnabled public String url;
    }

    public class AssistResult {
        @AuraEnabled public Boolean success = false;
        @AuraEnabled public String message;
        @AuraEnabled public String diagnosis;
        @AuraEnabled public String keywords;
        @AuraEnabled public String contentDocumentId;
        @AuraEnabled public String previewUrl;
        @AuraEnabled public Boolean grounded = false;
        @AuraEnabled public String stepsSource;
        @AuraEnabled public List<String> steps = new List<String>();
        @AuraEnabled public Integer articleCount = 0;
        @AuraEnabled public List<ArticleRef> articles = new List<ArticleRef>();
    }

    /* ------------------------------------------------------------------ *
     *  1) Detect the latest screenshot on the conversation
     * ------------------------------------------------------------------ */

    /**
     * Returns metadata about the most recent image on the conversation so the
     * LWC can detect when the customer sends a new screenshot. Resolution order:
     *   1. Newest image ContentDocument linked directly to the record (Messaging
     *      Session, Case, etc.).
     *   2. On a Case, the newest image attached to a related inbound email -
     *      inbound email attachments link to the EmailMessage, not the Case, and
     *      tiny signature/logo graphics are skipped.
     *   3. Fallback: newest image uploaded org-wide within the recent window -
     *      covers channels that don't link the file directly to the record.
     * Returns null when nothing is found.
     */
    @AuraEnabled(cacheable=false)
    public static ScreenshotInfo getLatestScreenshot(String recordId) {
        try {
            ContentVersion cv = resolveLatestVersion(recordId);
            return cv == null ? null : toScreenshotInfo(cv);
        } catch (Exception e) {
            throw new AuraHandledException('Could not check for a screenshot: ' + e.getMessage());
        }
    }

    /**
     * Returns up to maxItems recent screenshots on the conversation, newest
     * first, so the LWC can show a gallery when a customer sends several images.
     * Same sources as getLatestScreenshot (direct links, plus a Case's inbound
     * email attachments with the signature/logo size floor), de-duplicated by
     * ContentDocument, with the org-wide recent-upload window as a fallback.
     */
    @AuraEnabled(cacheable=false)
    public static List<ScreenshotInfo> getConversationScreenshots(String recordId, Integer maxItems) {
        try {
            Integer lim = (maxItems == null || maxItems <= 0) ? 12 : maxItems;

            Set<Id> keepDocIds = new Set<Id>();
            if (String.isNotBlank(recordId)) {
                keepDocIds.addAll(passingDocIds(docIdsLinkedTo(new Set<Id>{ (Id) recordId }), 0));
                if (isCase(recordId)) {
                    Set<Id> emailIds = new Set<Id>();
                    for (EmailMessage em : [SELECT Id FROM EmailMessage WHERE ParentId = :recordId]) {
                        emailIds.add(em.Id);
                    }
                    if (!emailIds.isEmpty()) {
                        keepDocIds.addAll(passingDocIds(docIdsLinkedTo(emailIds), MIN_EMAIL_IMAGE_BYTES));
                    }
                }
            }

            List<ContentVersion> versions = keepDocIds.isEmpty()
                ? recentUploadedImages(lim)
                : orderedImages(keepDocIds, lim);

            List<ScreenshotInfo> results = new List<ScreenshotInfo>();
            for (ContentVersion cv : versions) {
                results.add(toScreenshotInfo(cv));
            }
            return results;
        } catch (Exception e) {
            throw new AuraHandledException('Could not load screenshots: ' + e.getMessage());
        }
    }

    private static Set<Id> passingDocIds(Set<Id> docIds, Integer minBytes) {
        Set<Id> passing = new Set<Id>();
        if (docIds == null || docIds.isEmpty()) {
            return passing;
        }
        for (ContentVersion cv : [
            SELECT ContentDocumentId
            FROM ContentVersion
            WHERE ContentDocumentId IN :docIds
                AND IsLatest = true
                AND FileType IN :IMAGE_TYPES
                AND ContentSize >= :minBytes
        ]) {
            passing.add(cv.ContentDocumentId);
        }
        return passing;
    }

    private static List<ContentVersion> orderedImages(Set<Id> docIds, Integer lim) {
        return [
            SELECT Id, ContentDocumentId, Title, FileType, CreatedDate
            FROM ContentVersion
            WHERE ContentDocumentId IN :docIds
                AND IsLatest = true
                AND FileType IN :IMAGE_TYPES
            ORDER BY CreatedDate DESC
            LIMIT :lim
        ];
    }

    private static List<ContentVersion> recentUploadedImages(Integer lim) {
        Datetime cutoff = Datetime.now().addMinutes(-RECENT_IMAGE_WINDOW_MINUTES);
        return [
            SELECT Id, ContentDocumentId, Title, FileType, CreatedDate
            FROM ContentVersion
            WHERE IsLatest = true
                AND FileType IN :IMAGE_TYPES
                AND CreatedDate >= :cutoff
            ORDER BY CreatedDate DESC
            LIMIT :lim
        ];
    }

    private static ContentVersion resolveLatestVersion(String recordId) {
        if (String.isBlank(recordId)) {
            return findMostRecentUploadedImage();
        }

        // 1) Files linked directly to the record - no size floor, a rep may drop
        //    any screenshot here intentionally.
        ContentVersion direct = latestImage(docIdsLinkedTo(new Set<Id>{ (Id) recordId }), 0);

        // 2) On a Case, also look at attachments on related inbound emails. These
        //    link to the EmailMessage, so a Case-only lookup never sees them.
        ContentVersion fromEmail = null;
        if (isCase(recordId)) {
            Set<Id> emailIds = new Set<Id>();
            for (EmailMessage em : [SELECT Id FROM EmailMessage WHERE ParentId = :recordId]) {
                emailIds.add(em.Id);
            }
            if (!emailIds.isEmpty()) {
                fromEmail = latestImage(docIdsLinkedTo(emailIds), MIN_EMAIL_IMAGE_BYTES);
            }
        }

        ContentVersion chosen = mostRecent(direct, fromEmail);
        return chosen != null ? chosen : findMostRecentUploadedImage();
    }

    private static Boolean isCase(String recordId) {
        try {
            return ((Id) recordId).getSObjectType() == Case.SObjectType;
        } catch (Exception e) {
            return false;
        }
    }

    private static Set<Id> docIdsLinkedTo(Set<Id> entityIds) {
        Set<Id> docIds = new Set<Id>();
        for (ContentDocumentLink link : [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :entityIds
        ]) {
            docIds.add(link.ContentDocumentId);
        }
        return docIds;
    }

    private static ContentVersion latestImage(Set<Id> docIds, Integer minBytes) {
        if (docIds == null || docIds.isEmpty()) {
            return null;
        }
        List<ContentVersion> matches = [
            SELECT Id, ContentDocumentId, Title, FileType, CreatedDate
            FROM ContentVersion
            WHERE ContentDocumentId IN :docIds
                AND IsLatest = true
                AND FileType IN :IMAGE_TYPES
                AND ContentSize >= :minBytes
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        return matches.isEmpty() ? null : matches[0];
    }

    private static ContentVersion mostRecent(ContentVersion a, ContentVersion b) {
        if (a == null) {
            return b;
        }
        if (b == null) {
            return a;
        }
        return a.CreatedDate >= b.CreatedDate ? a : b;
    }

    private static ContentVersion findMostRecentUploadedImage() {
        Datetime cutoff = Datetime.now().addMinutes(-RECENT_IMAGE_WINDOW_MINUTES);
        List<ContentVersion> recent = [
            SELECT Id, ContentDocumentId, Title, FileType, CreatedDate
            FROM ContentVersion
            WHERE IsLatest = true
                AND FileType IN :IMAGE_TYPES
                AND CreatedDate >= :cutoff
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        return recent.isEmpty() ? null : recent[0];
    }

    private static ScreenshotInfo toScreenshotInfo(ContentVersion cv) {
        ScreenshotInfo info = new ScreenshotInfo();
        info.contentDocumentId = cv.ContentDocumentId;
        info.contentVersionId = cv.Id;
        info.title = cv.Title;
        info.fileType = cv.FileType;
        info.createdDateMs = cv.CreatedDate == null ? null : cv.CreatedDate.getTime();
        info.previewUrl = '/sfc/servlet.shepherd/version/download/' + cv.Id;
        return info;
    }

    /* ------------------------------------------------------------------ *
     *  2) Analyze the screenshot + ground the fix in Knowledge
     * ------------------------------------------------------------------ */

    @AuraEnabled(cacheable=false)
    public static AssistResult analyzeScreenshot(
        String recordId,
        String contentDocumentId,
        String customerDescription
    ) {
        AssistResult result = new AssistResult();
        try {
            // Reuse the exact vision path the customer-facing agent uses.
            AgentforceVisionImageAction.Request visionReq = new AgentforceVisionImageAction.Request();
            visionReq.recordId = recordId;
            visionReq.contentDocumentId = contentDocumentId;
            visionReq.userDescription = customerDescription;

            List<AgentforceVisionImageAction.Response> visionResults =
                AgentforceVisionImageAction.analyze(
                    new List<AgentforceVisionImageAction.Request>{ visionReq }
                );
            AgentforceVisionImageAction.Response vision = visionResults[0];

            if (vision.success != true) {
                result.success = false;
                result.message = String.isBlank(vision.message)
                    ? 'The screenshot could not be analyzed.'
                    : vision.message;
                return result;
            }

            result.success = true;
            result.diagnosis = vision.diagnosis;
            result.keywords = vision.searchKeywords;
            result.contentDocumentId = vision.contentDocumentId;
            if (String.isNotBlank(vision.contentDocumentId)) {
                result.previewUrl = previewUrlForDocument(vision.contentDocumentId);
            }

            groundInKnowledge(vision.searchKeywords, result);
            return result;
        } catch (Exception e) {
            result.success = false;
            result.message = 'Screenshot analysis failed: ' + e.getMessage();
            return result;
        }
    }

    /**
     * Turns the vision keywords into grounded, rep-ready troubleshooting steps by
     * searching published Knowledge and applying the shared relevance guard so a
     * loose keyword collision can't surface the wrong article's steps.
     */
    private static void groundInKnowledge(String keywords, AssistResult result) {
        String terms = sanitize(keywords);
        if (String.isBlank(terms)) {
            return;
        }

        List<Knowledge__kav> candidates = searcher.search(terms, CANDIDATE_POOL);
        List<Knowledge__kav> articles = VisionArticleRelevance.selectRelevant(
            keywords,
            candidates,
            MAX_ARTICLES
        );
        if (articles == null || articles.isEmpty()) {
            return;
        }

        result.articleCount = articles.size();
        for (Knowledge__kav a : articles) {
            ArticleRef ref = new ArticleRef();
            ref.title = a.Title;
            ref.summary = a.Summary;
            ref.articleNumber = a.ArticleNumber;
            ref.url = String.isBlank(a.UrlName) ? null : '/article/' + a.UrlName;
            result.articles.add(ref);
        }

        // The steps the rep should follow/relay come from the single most
        // relevant article - never invented by the model.
        Knowledge__kav top = articles[0];
        List<String> steps = toSteps(top.FAQ_Answer__c);
        if (!steps.isEmpty()) {
            result.grounded = true;
            result.stepsSource = top.Title;
            result.steps = steps;
        }
    }

    private static String previewUrlForDocument(String contentDocumentId) {
        List<ContentVersion> cvs = [
            SELECT Id
            FROM ContentVersion
            WHERE ContentDocumentId = :contentDocumentId AND IsLatest = true
            LIMIT 1
        ];
        return cvs.isEmpty() ? null : '/sfc/servlet.shepherd/version/download/' + cvs[0].Id;
    }

    /* ------------------------------------------------------------------ *
     *  Knowledge search seam + helpers
     * ------------------------------------------------------------------ */

    public interface Searcher {
        List<Knowledge__kav> search(String terms, Integer maxArticles);
    }

    public class SoslSearcher implements Searcher {
        public List<Knowledge__kav> search(String terms, Integer maxArticles) {
            String soslQuery = 'FIND :terms IN ALL FIELDS RETURNING Knowledge__kav('
                + 'Id, Title, Summary, UrlName, ArticleNumber, FAQ_Answer__c '
                + 'WHERE PublishStatus = \'Online\' AND Language = \'en_US\' AND IsLatestVersion = true) '
                + 'LIMIT ' + maxArticles;
            List<List<SObject>> results = Search.query(soslQuery);
            return (results != null && !results.isEmpty())
                ? (List<Knowledge__kav>) results[0]
                : new List<Knowledge__kav>();
        }
    }

    /**
     * Converts a Knowledge FAQ answer (rich text/HTML) into an ordered list of
     * discrete troubleshooting steps for display in the assist panel. Splits on
     * list items and block/line boundaries, strips markup, and drops empties.
     */
    @TestVisible
    private static List<String> toSteps(String html) {
        List<String> steps = new List<String>();
        if (String.isBlank(html)) {
            return steps;
        }
        // Normalize common block boundaries to newlines before stripping tags.
        String normalized = html
            .replaceAll('(?i)<\\s*br\\s*/?>', '\n')
            .replaceAll('(?i)</\\s*(li|p|div|h[1-6])\\s*>', '\n')
            .replaceAll('(?i)<\\s*li[^>]*>', '\n');
        String text = normalized
            .replaceAll('<[^>]+>', ' ')
            .replaceAll('&nbsp;', ' ')
            .replaceAll('&amp;', '&')
            .replaceAll('&lt;', '<')
            .replaceAll('&gt;', '>');

        for (String rawLine : text.split('\n')) {
            String line = rawLine.replaceAll('\\s+', ' ').trim();
            // Strip a leading manual list marker ("1.", "2)", "-", "*") if present.
            line = line.replaceFirst('^([0-9]{1,2}[\\.\\)]|[-*\\u2022])\\s+', '');
            if (String.isNotBlank(line)) {
                steps.add(line);
            }
        }
        return steps;
    }

    // SOSL reserved characters must be escaped so caller-supplied text can't break the query.
    @TestVisible
    private static String sanitize(String input) {
        if (String.isBlank(input)) {
            return '';
        }
        String cleaned = input.replaceAll('[?&|!{}\\[\\]()^~*:"+\\-\\\\]', ' ');
        return cleaned.replaceAll('\\s+', ' ').trim();
    }
}
