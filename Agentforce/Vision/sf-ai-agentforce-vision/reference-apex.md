# Apex reference — the image-analysis orchestrator

The Apex action is the bridge between the agent and the vision model. It (1) resolves the uploaded image to a `ContentDocument`, and (2) calls the flex prompt template with that file, then parses structured output back for the agent.

## Why Apex (and not a direct model call)

`ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate` is the supported way to send a file to a model. The Models API (Apex `aiplatform.ModelsAPI` / REST) is text/embeddings only — it will not accept an image. So the pattern is always: **agent → Apex invocable → prompt template (file input) → model.**

## The orchestrator action

Key design choices, all visible below:
- `@InvocableMethod` returning a structured `Response` so the agent gets `diagnosis`, `searchKeywords`, `success`, `message`.
- A `PromptRunner` interface **seam** — the real implementation calls `ConnectApi`; tests inject a stub so no callout happens.
- Image resolution priority: explicit doc id → most recent image on the record → most recent image uploaded org-wide in the last 10 minutes.
- Deterministic parsing of the `DIAGNOSIS:` / `KEYWORDS:` output, falling back to raw text.

```apex
public with sharing class AgentforceVisionImageAction {
    @TestVisible private static final String TEMPLATE_API_NAME = 'AgentforceVision_ImageDiagnosis';
    @TestVisible private static PromptRunner runner = new ConnectApiPromptRunner();

    private static final Set<String> IMAGE_TYPES = new Set<String>{
        'PNG','JPG','JPEG','GIF','WEBP','BMP','HEIC'
    };

    public class Request {
        @InvocableVariable(label='Conversation or Record Id'
            description='Id of the messaging session/case/record the image is linked to.')
        public String recordId;
        @InvocableVariable(label='Content Document Id'
            description='Optional explicit ContentDocument Id of the image to analyze.')
        public String contentDocumentId;
        @InvocableVariable(label='Customer Description'
            description='Optional free text the customer typed describing the problem.')
        public String userDescription;
    }

    public class Response {
        @InvocableVariable(label='Diagnosis') public String diagnosis;
        @InvocableVariable(label='Search Keywords') public String searchKeywords;
        @InvocableVariable(label='Analyzed Content Document Id') public String contentDocumentId;
        @InvocableVariable(label='Success') public Boolean success;
        @InvocableVariable(label='Message') public String message;
    }

    @InvocableMethod(label='Agentforce Vision: Analyze Image'
        description='Analyzes the uploaded image and returns a diagnosis and Knowledge search keywords.')
    public static List<Response> analyze(List<Request> requests) {
        List<Response> results = new List<Response>();
        for (Request req : requests) results.add(processOne(req));
        return results;
    }

    private static Response processOne(Request req) {
        Response res = new Response();
        try {
            Id docId = resolveContentDocumentId(req);
            if (docId == null) {
                res.success = false;
                res.message = 'No image was found. Ask the customer to upload a photo and try again.';
                return res;
            }
            res.contentDocumentId = docId;
            String raw = runner.run(TEMPLATE_API_NAME, docId,
                String.isBlank(req.userDescription) ? '' : req.userDescription);
            parseInto(raw, res);
            res.success = true;
        } catch (Exception e) {
            res.success = false;
            res.message = 'Image analysis failed: ' + e.getMessage();
        }
        return res;
    }

    @TestVisible
    private static Id resolveContentDocumentId(Request req) {
        if (String.isNotBlank(req.contentDocumentId)) return (Id) req.contentDocumentId;

        if (String.isNotBlank(req.recordId)) {
            Set<Id> docIds = new Set<Id>();
            for (ContentDocumentLink link : [
                SELECT ContentDocumentId FROM ContentDocumentLink
                WHERE LinkedEntityId = :req.recordId
            ]) docIds.add(link.ContentDocumentId);
            for (ContentVersion cv : [
                SELECT ContentDocumentId FROM ContentVersion
                WHERE ContentDocumentId IN :docIds AND IsLatest = true AND FileType IN :IMAGE_TYPES
                ORDER BY CreatedDate DESC LIMIT 1
            ]) return cv.ContentDocumentId;
        }
        return findMostRecentUploadedImage();
    }

    @TestVisible
    private static Id findMostRecentUploadedImage() {
        Datetime cutoff = Datetime.now().addMinutes(-10);
        for (ContentVersion cv : [
            SELECT ContentDocumentId FROM ContentVersion
            WHERE IsLatest = true AND FileType IN :IMAGE_TYPES AND CreatedDate >= :cutoff
            ORDER BY CreatedDate DESC LIMIT 1
        ]) return cv.ContentDocumentId;
        return null;
    }

    @TestVisible
    private static void parseInto(String raw, Response res) {
        if (String.isBlank(raw)) { res.diagnosis = ''; res.searchKeywords = ''; return; }
        String diagnosis = '', keywords = '';
        for (String line : raw.split('\n')) {
            String t = line.trim();
            if (t.startsWithIgnoreCase('DIAGNOSIS:')) diagnosis = t.substring(t.indexOf(':')+1).trim();
            else if (t.startsWithIgnoreCase('KEYWORDS:')) keywords = t.substring(t.indexOf(':')+1).trim();
        }
        res.diagnosis = String.isBlank(diagnosis) ? raw.trim() : diagnosis; // fall back to raw
        res.searchKeywords = keywords;
    }

    public interface PromptRunner {
        String run(String templateApiName, Id contentDocumentId, String userDescription);
    }

    public class ConnectApiPromptRunner implements PromptRunner {
        public String run(String templateApiName, Id contentDocumentId, String userDescription) {
            Map<String, ConnectApi.WrappedValue> params = new Map<String, ConnectApi.WrappedValue>();

            ConnectApi.WrappedValue fileValue = new ConnectApi.WrappedValue();
            fileValue.value = new Map<String, String>{ 'id' => contentDocumentId, 'type' => 'ContentDocument' };
            params.put('Input:ImageFile', fileValue);   // must match the template referenceName

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

            if (response == null || response.generations == null || response.generations.isEmpty()) return '';
            return response.generations[0].text;
        }
    }
}
```

## Critical implementation notes

- **Param keys must match the template `referenceName` exactly**, including the `Input:` prefix (e.g. `Input:ImageFile`). A mismatch silently drops the file and the model "sees nothing."
- **File value shape:** `WrappedValue.value = Map<String,String>{'id' => <ContentDocumentId>, 'type' => 'ContentDocument'}`. Pass the **ContentDocument** id, not the ContentVersion id.
- **`with sharing`** means the running (agent) user must be able to read the file and any queried records — reflect that in the permission set.
- **10-minute fallback window** is a pragmatic way to grab "the photo the customer just sent" when no context id is wired. Tighten or remove it if multiple concurrent uploads could collide.
- The Models API cannot replace this — keep the file path through the prompt template.

## Testing without a callout

Inject a stub `PromptRunner`. `ConnectApi.EinsteinLLM` cannot be exercised in a normal unit test, and inserting a `ContentVersion` auto-creates a `ContentDocumentLink` to the running user (handy for the resolution test).

```apex
@IsTest
private class AgentforceVisionImageActionTest {
    private class StubRunner implements AgentforceVisionImageAction.PromptRunner {
        public Id lastDoc; public String returnValue;
        public String run(String t, Id doc, String desc) { lastDoc = doc; return returnValue; }
    }
    private static Id insertImage() {
        ContentVersion cv = new ContentVersion(Title='t', PathOnClient='t.png',
            VersionData=Blob.valueOf('bytes'));
        insert cv;
        return [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
    }
    @IsTest static void analyzesAndParses() {
        Id docId = insertImage();
        StubRunner stub = new StubRunner();
        stub.returnValue = 'DIAGNOSIS: Thermostat shows E5.\nKEYWORDS: thermostat, E5, climate';
        AgentforceVisionImageAction.runner = stub;
        AgentforceVisionImageAction.Request req = new AgentforceVisionImageAction.Request();
        req.contentDocumentId = docId;
        Test.startTest();
        List<AgentforceVisionImageAction.Response> r =
            AgentforceVisionImageAction.analyze(new List<AgentforceVisionImageAction.Request>{ req });
        Test.stopTest();
        System.assertEquals(true, r[0].success);
        System.assertEquals('Thermostat shows E5.', r[0].diagnosis);
        System.assertEquals(docId, stub.lastDoc);
    }
}
```

## Grounding the fix (recommended companion action)

Vision tells you *what* is wrong; do not let the agent invent *how* to fix it. A companion action turns the model's keywords into a grounded answer from a system of record (Knowledge shown here) and applies a **relevance guard** so a loose single-word match can't surface an unrelated article.

- **Search action:** run `FIND :terms IN ALL FIELDS RETURNING Knowledge__kav(...)` with a wider candidate pool than you'll return, then re-rank/filter.
- **Relevance guard:** count how many *distinct, meaningful* keywords actually appear in each article's Title/Summary; ignore generic support words (power, reset, outlet...); drop anything clearing on only one ambiguous term. When nothing is a confident match, return **no article** so the agent says it couldn't find specific guidance (and can escalate) instead of handing over wrong steps.
- Escape SOSL reserved characters in caller-supplied text before building the query.

This same two-action shape (analyze → ground) generalizes to any vision use case: swap Knowledge for Assets, Products, work orders, etc.
