# Prompt template reference — the flex template that "sees"

The vision happens here. A **flex** GenAI prompt template with a `ContentDocument` file input, bound to a vision-capable model, is the only supported way to feed an image to the model from the platform.

## Full template metadata

```xml
<?xml version="1.0" encoding="UTF-8"?>
<GenAiPromptTemplate xmlns="http://soap.sforce.com/2006/04/metadata">
    <description>Analyzes a customer-uploaded image and returns a diagnosis plus search keywords.</description>
    <developerName>AgentforceVision_ImageDiagnosis</developerName>
    <masterLabel>Agentforce Vision - Image Diagnosis</masterLabel>
    <overridable>false</overridable>
    <templateVersions>
        <content>You are a senior technical support specialist. A customer sent a photo of a device or screen, plus an optional description. Analyze the attached image and determine what they&apos;re looking at and the most likely problem.

Attached image: {!$Input:ImageFile.Id}

Guest description (may be blank): {!$Input:UserDescription}

How to analyze:
- Make a genuine best effort even if the photo is dim, low-res, or slightly blurry. Read any on-screen text or error codes verbatim, and note the color/state of any status lights.
- Do NOT refuse or call the image unclear just because lighting is modest. Only if it&apos;s essentially all black, blank, or unrelated should you say you can&apos;t identify it — and still give general keywords.
Respond EXACTLY in this format:
DIAGNOSIS: &lt;one or two sentences: what you see and the single most likely problem&gt;
KEYWORDS: &lt;3-6 comma-separated search terms for a support article&gt;
</content>
        <fileDroppingStrategy>{&quot;dropFilesBy&quot;:&quot;LAST_MODIFIED_DATE&quot;,&quot;dropFileStartingWith&quot;:&quot;OLDEST&quot;}</fileDroppingStrategy>
        <inputs>
            <apiName>ImageFile</apiName>
            <definition>SOBJECT://ContentDocument</definition>
            <masterLabel>Image File</masterLabel>
            <referenceName>Input:ImageFile</referenceName>
            <required>true</required>
        </inputs>
        <inputs>
            <apiName>UserDescription</apiName>
            <definition>primitive://String</definition>
            <masterLabel>User Description</masterLabel>
            <referenceName>Input:UserDescription</referenceName>
            <required>false</required>
        </inputs>
        <isCitationEnabled>false</isCitationEnabled>
        <primaryModel>sfdc_ai__DefaultGPT55</primaryModel>
        <status>Published</status>
        <templateFormat>FormulaExpression</templateFormat>
        <versionIdentifier>REPLACED_ON_PUBLISH</versionIdentifier>
    </templateVersions>
    <type>einstein_gpt__flex</type>
    <visibility>Global</visibility>
</GenAiPromptTemplate>
```

## Anatomy — what each part does

- **`<type>einstein_gpt__flex</type>`** — must be **flex**. Flex templates support file inputs and arbitrary parameters; the record-bound template types do not give you this file-in path for a raw uploaded image.
- **File input** — `<definition>SOBJECT://ContentDocument</definition>` with `<referenceName>Input:ImageFile</referenceName>`. The `referenceName` is the exact key your Apex uses in `inputParams` (`params.put('Input:ImageFile', fileValue)`). The model receives the file bytes; it does **not** just read the id string.
- **`{!$Input:ImageFile.Id}` in the body** — references the bound file so the template resolves it. Keep it in the prompt even though the model's real input is the file itself.
- **A second String input (`UserDescription`)** — optional customer free-text, so the model can weight the diagnosis toward what the customer said.
- **`fileDroppingStrategy`** — controls which file is "dropped into" the model when multiple are present (here: by last-modified date, oldest first). Set this deliberately if a record can carry several files.
- **`primaryModel`** — must be a **vision-capable** model. `sfdc_ai__DefaultGPT55` is used here; availability varies by org/edition/region. If it is not present, pick another multimodal model in Prompt Builder. A text-only model will "run" but be blind.
- **`templateFormat` = `FormulaExpression`** — enables the `{!$Input:...}` merge syntax.
- **`isCitationEnabled`** — off here because grounding is done by a separate Knowledge action; turn on only if you want the template itself to cite.

## Prompt-engineering rules for reliable vision

1. **Force a machine-parseable shape.** `DIAGNOSIS:` / `KEYWORDS:` on their own lines lets Apex split deterministically. Add a raw-text fallback in Apex for when the model drifts.
2. **Pre-empt over-refusal.** Vision models often bail on modest lighting. Explicitly tell it to try hard on dim/blurry photos and only decline on blank/unrelated images — and to still emit keywords.
3. **Tell it what to extract, concretely.** "Read on-screen text and error codes verbatim; note status-light color/state." Concrete extraction targets beat "describe the image."
4. **Keep keywords short and searchable.** 3–6 comma-separated terms feed a downstream search cleanly; long sentences pollute retrieval.
5. **Set the persona to your domain.** The system line ("senior technical support specialist for <domain>") measurably sharpens the diagnosis.

## Editing the model after deploy

Metadata deploys the template, but the **active model binding** is managed in Prompt Builder. If the deploy's `primaryModel` is unavailable in the target org, open the template in Prompt Builder and repoint it at an available vision model, then re-activate. The `activeVersionIdentifier` / `versionIdentifier` values are regenerated on publish — don't hand-craft them.
