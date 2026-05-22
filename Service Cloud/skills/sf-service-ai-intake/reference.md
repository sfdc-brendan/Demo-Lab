# sf-service-ai-intake — Reference

Deep reference loaded only when the agent needs the full data model, prompt construction details, or operational dispatch patterns. Primary patterns live in `SKILL.md`.

---

## Data Model — Six Custom Objects

```text
Intake_Template__c    1 ─── many ─── Intake_Question__c
                                          │
                                          ├── 1 ─ many ─ Intake_Picklist_Value__c
                                          ├── 1 ─ many ─ Intake_Visibility_Rule__c
                                          └── 1 ─ many ─ Intake_Translation__c

Intake_Submission__c   ← fallback target when a template has no Target_Object_API_Name__c
```

### `Intake_Template__c` — top-level scenario

| Field | Type | Purpose |
|---|---|---|
| `Name` | Text | Display name |
| `Status__c` | Picklist | `Active` / `Inactive` |
| `Target_Object_API_Name__c` | Text | API name of the SObject to write to. Blank → fallback |
| `Persona_Description__c` | LongText | Custom system prompt prefix for the AI |
| `Default_Locale__c` | Text | Fallback locale |
| `PDF_Header__c` | Text | Title for generated PDF |
| `Version__c` | Number | Template version |
| `Parent_Template__c` | Lookup | Self-reference for clone-as-new versioning |

### `Intake_Question__c` — single question

| Field | Type | Purpose |
|---|---|---|
| `DeveloperName__c` | Text | **Stable key** shared between LWC, AI prompt, and writeback |
| `Question_Text__c` | Text | Natural-language question for the CSR |
| `Help_Text__c` | LongText | Optional context shown under the question |
| `Answer_Type__c` | Picklist | `text` / `textarea` / `phone` / `email` / `number` / `date` / `picklist` / `multipicklist` / `boolean` / `lookup` |
| `Target_Field_API_Name__c` | Text | Field on the target object to write to |
| `Picklist_Source__c` | Picklist | `Static` / `From Field` |
| `Picklist_Source_Object__c` / `_Field__c` | Text | When `From Field`, where to pull options |
| `Lookup_Object__c` | Text | When `Answer_Type__c = lookup` |
| `Validation_Regex__c` / `Validation_Error_Message__c` | Text | Optional client-side regex |
| `AI_Extraction_Hint__c` | LongText | Per-question hint for the LLM |
| `Required__c` | Checkbox | |
| `Order__c` | Number | Display order |
| `Category__c` | Text | Optional grouping |

### Two layers of vocabulary

| Layer | Field | Used by |
|---|---|---|
| AI vocabulary | `DeveloperName__c` (e.g. `Issue_Summary`) | Prompt schema, AI response keys |
| Org vocabulary | `Target_Field_API_Name__c` (e.g. `Description`) | SObject `record.put()` |

This decoupling is what lets the same `Issue_Category` extraction map to `Case.Type` on a Case template, or to `Customer_Issue__c.Category__c` on a custom-object template.

---

## Prompt Construction for Extraction

Build the prompt server-side in Apex from the template + question metadata. Inline every constraint per question type.

```apex
private static String buildPrompt(String persona, List<QuestionInput> questions, String transcript) {
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
```

### Visible-question filter before applying

After the LLM responds, filter to only questions currently visible in the UI before merging. Otherwise the AI can fill a field the agent can't see, and the user has no way to correct it.

```javascript
const visibleDevNames = new Set(this.visibleQuestions.map((q) => q.developerName));
const filtered = {};
for (const [k, v] of Object.entries(aiResult || {})) {
    if (visibleDevNames.has(k)) filtered[k] = v;
}
this.applyAiResults(filtered);
```

---

## Status Icon Mapping (UI Spec)

The CSR scans the form vertically. Each row needs a glanceable status:

| Status | Icon | When |
|---|---|---|
| Empty | Empty circle | No answer yet, no AI suggestion |
| AI suggestion pending | Blue dot | AI proposed an answer, agent has not confirmed |
| Answered | Green check | Agent typed an answer, OR AI filled and agent has not edited |
| Conflict | Yellow dot | Agent typed AND AI proposed a different value (suggestion shown beside) |
| Invalid | Red exclamation | Validation regex / required check failing |

### CSS pattern (SLDS 2 hooks)

```css
.status-mark {
    width: 1rem;
    height: 1rem;
    border-radius: 50%;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    flex-shrink: 0;
}
.status-mark.empty {
    border: 2px solid var(--slds-g-color-border-1, #c9c9c9);
}
.status-mark.ai {
    background: var(--slds-g-color-info-1, #0176d3);
}
.status-mark.answered {
    background: var(--slds-g-color-success-1, #2e844a);
}
```

---

## Submit Dispatch — Two Paths

### Path A: Target-object write (typed SObject)

Used when the template has `Target_Object_API_Name__c` set. The flow:

1. Look for an existing draft (template's target object has `VoiceCall__c` + `Status__c` fields → query for `Status__c = 'Draft'`).
2. If no draft, instantiate via `Schema.getGlobalDescribe().get(objApi).newSObject()`.
3. Map each `developerName → targetField` from the question metadata.
4. Optionally write `Status__c = 'Submitted'`, `Raw_Responses_JSON__c`, `Intake_Template__c` if those fields exist.
5. `upsert` the record.
6. Generate a PDF audit artifact via `IntakePDFController.attachIntakePDF(intakeId)`.

```apex
private static Id submitToTargetObject(Intake_Template__c tpl, Id voiceCallId,
        Map<String, Object> answers, String answersJson) {
    String objApi = tpl.Target_Object_API_Name__c;
    SObject record;

    // Reuse existing draft if conventions met
    if (voiceCallId != null
            && hasField(objApi, 'VoiceCall__c')
            && hasField(objApi, 'Status__c')) {
        String soql = 'SELECT Id FROM ' + escapeIdentifier(objApi)
            + ' WHERE VoiceCall__c = :voiceCallId AND Status__c = \'Draft\''
            + ' ORDER BY LastModifiedDate DESC LIMIT 1';
        List<SObject> drafts = Database.query(soql);
        if (!drafts.isEmpty()) record = drafts[0];
    }
    if (record == null) {
        record = Schema.getGlobalDescribe().get(objApi).newSObject();
        if (voiceCallId != null && hasField(objApi, 'VoiceCall__c')) {
            record.put('VoiceCall__c', voiceCallId);
        }
    }

    applyAnswersToRecord(record, objApi, answers, getQuestionFieldMap(tpl.Id));

    if (hasField(objApi, 'Status__c')) record.put('Status__c', 'Submitted');
    if (hasField(objApi, 'Raw_Responses_JSON__c')) record.put('Raw_Responses_JSON__c', answersJson);
    if (hasField(objApi, 'Intake_Template__c')) record.put('Intake_Template__c', tpl.Id);

    upsert record;
    return (Id) record.get('Id');
}
```

### Path B: Submission fallback

Used when `Target_Object_API_Name__c` is blank. Stores the entire answer payload as JSON on `Intake_Submission__c.Answers_JSON__c`. Lets admins prototype a new intake before designing the schema; same audit artifact, no typed SObject required.

```apex
private static Id submitToSubmission(Intake_Template__c tpl, Id voiceCallId, String answersJson) {
    Intake_Submission__c sub = new Intake_Submission__c(
        Intake_Template__c = tpl.Id,
        VoiceCall__c = voiceCallId,
        Status__c = 'Submitted',
        Answers_JSON__c = answersJson,
        Template_Version__c = tpl.Version__c
    );
    upsert sub;
    return sub.Id;
}
```

---

## Three Cadences in the Runtime

| Cadence | Default | Why |
|---|---|---|
| `ANALYSIS_DEBOUNCE_MS` | 3000 | Time after the last transcript fragment before triggering AI extraction |
| `DRAFT_SAVE_DEBOUNCE_MS` | 2000 | Time after the last answer change before saving draft to server |
| `TRANSCRIPT_POLL_MS` | 5000 | ConversationEntry poll interval (safety net behind toolkit) |

Tune `ANALYSIS_DEBOUNCE_MS` higher for chatty templates (more fields = more expensive prompt). Cap with a max-latency timer (8s) so the AI still runs during a long monologue — see `sf-service-voice-toolkit` reference.md for the cap pattern.

---

## Permission Sets

Two-role split, mirrors admin vs runtime separation:

| Permission Set | Grants |
|---|---|
| `Intake_Builder_Admin` | CRUD on all `Intake_*__c` objects, access to Intake Builder app |
| `Intake_Runtime_User` | Read on `Intake_Template__c` / `Intake_Question__c` / related; CRUD on `Intake_Submission__c`; access to runtime LWC |

Both also need:
- `View All` or row-level access on `VoiceCall` and `ConversationEntry`
- Access to `aiplatform.ModelsAPI` (granted via Einstein Generative AI permission set)

---

## Test Patterns

### Mocking the AI in tests

```apex
@IsTest
static void runAnalysis_appliesAiAnswersToEmptyFields() {
    IntakeTranscriptAnalyzer.mockResponse =
        '{"Customer_Name":"Jane Doe","Severity":"High"}';

    Test.startTest();
    Map<String, String> result = IntakeTranscriptAnalyzer.analyzeTranscript(
        'persona', '[{"developerName":"Customer_Name","questionText":"Name?","answerType":"text"}]',
        'Hi this is Jane Doe, I have a high severity issue.'
    );
    Test.stopTest();

    System.assertEquals('Jane Doe', result.get('Customer_Name'));
    System.assertEquals('High', result.get('Severity'));
}
```

### Seeding sample templates

Use an Anonymous Apex script (`scripts/apex/seed_intake_templates.apex` in the reference repo) to create three demo templates: one against a custom SObject, one against a standard SObject (`Case`), and one using the `Intake_Submission__c` fallback. Reproducible demos.

---

## Anti-Patterns to Avoid

| Anti-pattern | Why it fails | Do this instead |
|---|---|---|
| Hardcoding the question list in the LWC | Adding a question requires a deploy | Drive everything off `Intake_Question__c` records |
| Auto-submitting at 100% coverage | CSR loses control of what was filed | Submit is always a manual button click |
| Letting the AI overwrite agent edits | Agent loses trust in the assist | Track `_manuallyEdited` set; non-destructive merge |
| Sending the entire transcript history every analysis | Cost grows unboundedly | Truncate by speaker turn or by token budget |
| Asking the AI for fields the visibility rules hide | UI shows answers from invisible fields | Filter AI response by visible developerName set |
| Validating regex only on submit | Agent fixes 8 issues at once at the end | Validate on blur per field |
