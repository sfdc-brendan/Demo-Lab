---
name: sf-service-ai-intake
description: Live-call AI form-fill experiences for Service Cloud Voice. Use when designing or building configurable intake templates that listen to the live transcript, extract structured answers via the Models API, suggest non-destructive answers in the UI, and dispatch results to a target SObject. Composes sf-service-voice-toolkit and sf-service-models-api.
disable-model-invocation: true
---
# AI-Assisted Intake on Voice and Digital

## Use This Skill When

- Building CSR-facing intake forms (roadside, claims, complaints, service requests) that fill themselves while the customer talks.
- Replacing scenario-specific intake LWCs with a configurable, template-driven intake platform.
- Defining how AI suggestions, agent overrides, and final submissions interact safely on a regulated channel.
- Planning extension to digital channels (chat, messaging) using the same template + extractor pattern.

## Quick Start (Code Patterns)

These four patterns are the load-bearing pieces of an AI-assisted intake. Copy, adapt, ship. For the full data model, prompt construction, and visibility-rule evaluator, see [reference.md](reference.md).

### 1. One-shot template bundle query (Apex)

Load the template, all questions, picklist values, and visibility rules in a single round-trip. Cacheable so the LWC hydrates fast.

```apex
@AuraEnabled(cacheable=true)
public static TemplateBundle getTemplate(Id templateId) {
    if (templateId == null) return null;

    List<Intake_Template__c> templates = [
        SELECT Id, Name, Persona_Description__c, Target_Object_API_Name__c,
               Default_Locale__c, Version__c
        FROM Intake_Template__c
        WHERE Id = :templateId AND Status__c = 'Active'
        LIMIT 1
    ];
    if (templates.isEmpty()) return null;

    List<Intake_Question__c> questions = [
        SELECT Id, DeveloperName__c, Question_Text__c, Help_Text__c,
               Answer_Type__c, Target_Field_API_Name__c, Required__c,
               AI_Extraction_Hint__c, Order__c, Category__c,
               (SELECT Id, Value__c, Label__c, Order__c FROM Intake_Picklist_Values__r),
               (SELECT Id, Source_Question_Developer_Name__c, Operator__c,
                       Value__c, Logic_Group__c FROM Intake_Visibility_Rules__r)
        FROM Intake_Question__c
        WHERE Intake_Template__c = :templateId
        ORDER BY Order__c ASC
    ];

    return new TemplateBundle(templates[0], questions);
}
```

### 2. Non-destructive merge (LWC)

The single most important rule: **AI suggestions never overwrite a value the agent typed**. Agent edits always win.

```javascript
_manuallyEdited = new Set();   // dev names the agent has touched

handleAnswerChange(event) {
    const { name, value } = event.detail;
    this._manuallyEdited.add(name);
    this.answers = { ...this.answers, [name]: value };
}

applyAiResults(result) {
    const updatedAnswers = { ...this.answers };
    const newSuggestions = { ...this.suggestions };

    for (const [key, value] of Object.entries(result)) {
        if (this._manuallyEdited.has(key) && updatedAnswers[key]) {
            // Agent already filled this — surface AI guess as a side suggestion only
            if (updatedAnswers[key] !== value) newSuggestions[key] = value;
        } else {
            // Empty or untouched — accept the AI value
            updatedAnswers[key] = value;
            delete newSuggestions[key];
        }
    }

    this.answers = updatedAnswers;
    this.suggestions = newSuggestions;
}
```

### 3. Dynamic SObject dispatch on submit (Apex)

Branch on whether the template has a configured target object. Use `Schema.getGlobalDescribe()` for the dynamic create; check field existence before every `put` so missing optional fields don't blow up.

```apex
public static Id submitIntake(Id templateId, Id voiceCallId, String answersJson) {
    Intake_Template__c tpl = loadTemplate(templateId);
    Map<String, Object> answers = (Map<String, Object>) JSON.deserializeUntyped(answersJson);

    if (String.isNotBlank(tpl.Target_Object_API_Name__c)) {
        return submitToTargetObject(tpl, voiceCallId, answers, answersJson);
    }
    return submitToSubmission(tpl, voiceCallId, answersJson);
}

private static Id submitToTargetObject(Intake_Template__c tpl, Id voiceCallId,
        Map<String, Object> answers, String answersJson) {
    String objApi = tpl.Target_Object_API_Name__c;
    SObject record = Schema.getGlobalDescribe().get(objApi).newSObject();

    if (voiceCallId != null && hasField(objApi, 'VoiceCall__c')) {
        record.put('VoiceCall__c', voiceCallId);
    }

    Map<String, String> devNameToField = getQuestionFieldMap(tpl.Id);
    for (String devName : devNameToField.keySet()) {
        String field = devNameToField.get(devName);
        if (String.isNotBlank(field)
                && hasField(objApi, field)
                && answers.containsKey(devName)) {
            record.put(field, answers.get(devName));
        }
    }

    upsert record;
    return (Id) record.get('Id');
}

private static Boolean hasField(String objApi, String fieldApi) {
    Schema.SObjectType sot = Schema.getGlobalDescribe().get(objApi);
    return sot != null && sot.getDescribe().fields.getMap().containsKey(fieldApi.toLowerCase());
}
```

### 4. Visibility rule evaluator (LWC)

Show questions conditionally based on prior answers. Groups are OR-of-ANDs: a question is visible if ANY group passes; a group passes if ALL its rules pass.

```javascript
isQuestionVisible(question) {
    const rules = question.visibilityRules || [];
    if (rules.length === 0) return true;

    const groups = new Map();
    for (const rule of rules) {
        const g = rule.logicGroup || 'default';
        if (!groups.has(g)) groups.set(g, []);
        groups.get(g).push(rule);
    }

    for (const groupRules of groups.values()) {
        if (groupRules.every((r) => this.evaluateRule(r))) return true;
    }
    return false;
}

evaluateRule(rule) {
    const sv = String(this.answers[rule.sourceQuestionDeveloperName] ?? '');
    const target = String(rule.value ?? '');
    switch (rule.operator) {
        case 'equals':       return sv === target;
        case 'not_equals':   return sv !== target;
        case 'contains':     return sv.toLowerCase().includes(target.toLowerCase());
        case 'in':           return target.split(';').map((s) => s.trim()).includes(sv);
        case 'is_blank':     return sv === '';
        case 'is_not_blank': return sv !== '';
        default:             return true;
    }
}
```

## Pattern Overview

1. **Intake template as data, not code**
 - Model the scenario as records: a template record, ordered question records, picklist values, visibility rules, translations, and an optional target SObject API name.
 - Treat developer-name as the stable contract between the AI extractor and the writeback target field.
2. **Runtime LWC stays generic**
 - One runtime renders any active template; it never knows the scenario.
 - The LWC composes the voice-toolkit transcript source and the Models API extractor, both as injected dependencies.
3. **Non-destructive merge is the rule**
 - AI suggestions populate empty answers and never overwrite a value the agent typed.
 - Agent edits always win over later AI passes for the same field.

## Guardrails

- The agent always controls submit. AI never auto-submits, even at full coverage.
- Surface confidence visibly: clearly distinguish agent-confirmed answers (green check) from AI-suggested answers (AI dot) in the UI.
- Never round-trip free text into a strict picklist field without enum validation against the live field metadata.
- Honor visibility rules at the prompt layer, not just the UI layer — do not ask the AI to extract fields the agent could not see.
- Localize question text and validation messages; never localize the developer-name contract.
- Filter AI responses to the currently visible question set before applying merge — prevents the AI from filling fields hidden by visibility rules.

## Deliverables

- Template design (questions, types, target object, visibility rules, translations).
- Extraction contract document tying developer-names to prompt schema and writeback fields.
- Runtime sequence (transcript source → debounce → extractor → merge → UI status → submit).
- Operational plan: failure routing for extractor errors, audit artifact policy, and prompt-version changelog.

## Additional Resources

- Full data model (6 custom objects), prompt construction for extraction, status icon mapping, and dispatch fallback patterns: [reference.md](reference.md)
- Reference implementation: [sfdc-brendan/voice-intake-builder](https://github.com/sfdc-brendan/voice-intake-builder) ([HOW_IT_WORKS.md](https://github.com/sfdc-brendan/voice-intake-builder/blob/main/docs/HOW_IT_WORKS.md), [GENERAL_INTAKE.md](https://github.com/sfdc-brendan/voice-intake-builder/blob/main/docs/GENERAL_INTAKE.md))
- Companion skills: `sf-service-voice-toolkit` (transcript source), `sf-service-models-api` (extractor), `sf-service-voice-digital` (channel-level rollout)
