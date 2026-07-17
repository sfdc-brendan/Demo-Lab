/**
 * Agentforce Vision - Analyze Image action.
 *
 * Resolves the most recently uploaded image on a conversation (or an explicitly
 * provided ContentDocument) and sends it to the AgentforceVision_ImageDiagnosis
 * flex prompt template, which is bound to a vision-capable model. The Models API
 * itself cannot accept images, so the prompt template is the supported path for
 * multimodal analysis; this action orchestrates that call for the agent.
 */
public with sharing class AgentforceVisionImageAction {
    @TestVisible
    private static final String TEMPLATE_API_NAME = 'AgentforceVision_ImageDiagnosis';

    // Seam so tests can inject a deterministic template response without a callout.
    @TestVisible
    private static PromptRunner runner = new ConnectApiPromptRunner();

    public class Request {
        @InvocableVariable(
            label='Conversation or Record Id'
            description='Id of the messaging session, case, or record the uploaded image is linked to. Used to locate the image when a ContentDocument Id is not supplied.'
        )
        public String recordId;

        @InvocableVariable(
            label='Content Document Id'
            description='Optional. The ContentDocument Id of the image to analyze. If blank, the most recent image linked to the Conversation or Record Id is used.'
        )
        public String contentDocumentId;

        @InvocableVariable(
            label='Customer Description'
            description='Optional free text the customer typed describing the problem.'
        )
        public String userDescription;
    }

    public class Response {
        @InvocableVariable(label='Diagnosis')
        public String diagnosis;

        @InvocableVariable(label='Search Keywords')
        public String searchKeywords;

        @InvocableVariable(label='Analyzed Content Document Id')
        public String contentDocumentId;

        @InvocableVariable(label='Success')
        public Boolean success;

        @InvocableVariable(label='Message')
        public String message;
    }

    @InvocableMethod(
        label='Agentforce Vision: Analyze Image'
        description='Analyzes the guest-uploaded image and returns a diagnosis and Knowledge search keywords.'
    )
    public static List<Response> analyze(List<Request> requests) {
        List<Response> results = new List<Response>();
        for (Request req : requests) {
            results.add(processOne(req));
        }
        return results;
    }

    private static Response processOne(Request req) {
        Response res = new Response();
        try {
            Id docId = resolveContentDocumentId(req);
            if (docId == null) {
                res.success = false;
                res.message = 'No image was found for this conversation. Ask the guest to upload a photo and try again.';
                return res;
            }
            res.contentDocumentId = docId;

            String raw = runner.run(
                TEMPLATE_API_NAME,
                docId,
                String.isBlank(req.userDescription) ? '' : req.userDescription
            );
            parseInto(raw, res);
            res.success = true;
        } catch (Exception e) {
            res.success = false;
            res.message = 'Image analysis failed: ' + e.getMessage();
        }
        return res;
    }

    // File types treated as analyzable images.
    private static final Set<String> IMAGE_TYPES = new Set<String>{
        'PNG', 'JPG', 'JPEG', 'GIF', 'WEBP', 'BMP', 'HEIC'
    };

    /**
     * Finds the ContentDocument to analyze, in priority order:
     * 1. An explicitly supplied ContentDocument Id.
     * 2. The most recent image linked to the supplied record/conversation id.
     * 3. Fallback: the most recently uploaded image in the org (last 10 minutes),
     *    which is the photo the guest just sent when no context id is wired.
     */
    @TestVisible
    private static Id resolveContentDocumentId(Request req) {
        if (String.isNotBlank(req.contentDocumentId)) {
            return (Id) req.contentDocumentId;
        }

        if (String.isNotBlank(req.recordId)) {
            Set<Id> docIds = new Set<Id>();
            for (ContentDocumentLink link : [
                SELECT ContentDocumentId
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :req.recordId
            ]) {
                docIds.add(link.ContentDocumentId);
            }
            for (ContentVersion cv : [
                SELECT ContentDocumentId
                FROM ContentVersion
                WHERE ContentDocumentId IN :docIds
                    AND IsLatest = true
                    AND FileType IN :IMAGE_TYPES
                ORDER BY CreatedDate DESC
                LIMIT 1
            ]) {
                return cv.ContentDocumentId;
            }
        }

        return findMostRecentUploadedImage();
    }

    @TestVisible
    private static Id findMostRecentUploadedImage() {
        Datetime cutoff = Datetime.now().addMinutes(-10);
        for (ContentVersion cv : [
            SELECT ContentDocumentId
            FROM ContentVersion
            WHERE IsLatest = true
                AND FileType IN :IMAGE_TYPES
                AND CreatedDate >= :cutoff
            ORDER BY CreatedDate DESC
            LIMIT 1
        ]) {
            return cv.ContentDocumentId;
        }
        return null;
    }

    @TestVisible
    private static void parseInto(String raw, Response res) {
        if (String.isBlank(raw)) {
            res.diagnosis = '';
            res.searchKeywords = '';
            return;
        }
        String diagnosis = '';
        String keywords = '';
        for (String line : raw.split('\n')) {
            String trimmed = line.trim();
            if (trimmed.startsWithIgnoreCase('DIAGNOSIS:')) {
                diagnosis = trimmed.substring(trimmed.indexOf(':') + 1).trim();
            } else if (trimmed.startsWithIgnoreCase('KEYWORDS:')) {
                keywords = trimmed.substring(trimmed.indexOf(':') + 1).trim();
            }
        }
        // Fall back to the whole response if the model didn't follow the format.
        res.diagnosis = String.isBlank(diagnosis) ? raw.trim() : diagnosis;
        res.searchKeywords = keywords;
    }

    /** Abstraction over the prompt template call so it can be mocked in tests. */
    public interface PromptRunner {
        String run(String templateApiName, Id contentDocumentId, String userDescription);
    }

    public class ConnectApiPromptRunner implements PromptRunner {
        public String run(String templateApiName, Id contentDocumentId, String userDescription) {
            Map<String, ConnectApi.WrappedValue> params = new Map<String, ConnectApi.WrappedValue>();

            ConnectApi.WrappedValue fileValue = new ConnectApi.WrappedValue();
            fileValue.value = new Map<String, String>{
                'id' => contentDocumentId,
                'type' => 'ContentDocument'
            };
            params.put('Input:ImageFile', fileValue);

            ConnectApi.WrappedValue descValue = new ConnectApi.WrappedValue();
            descValue.value = userDescription;
            params.put('Input:UserDescription', descValue);

            ConnectApi.EinsteinPromptTemplateGenerationsInput input =
                new ConnectApi.EinsteinPromptTemplateGenerationsInput();
            input.inputParams = params;
            input.isPreview = false;
            input.additionalConfig = new ConnectApi.EinsteinLlmAdditionalConfigInput();
            input.additionalConfig.applicationName = 'PromptTemplateGenerationsInvocable';

            ConnectApi.EinsteinPromptTemplateGenerationsRepresentation response =
                ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate(templateApiName, input);

            if (response == null || response.generations == null || response.generations.isEmpty()) {
                return '';
            }
            return response.generations[0].text;
        }
    }
}
