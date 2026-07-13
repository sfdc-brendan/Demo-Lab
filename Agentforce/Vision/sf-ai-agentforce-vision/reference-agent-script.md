# Agent Script reference — wiring vision into the agent

The agent doesn't see the image; it calls the Apex action, which does. This file shows how to expose that action in Agent Script and, most importantly, how to keep the agent from calling it at the wrong time.

> For general Agent Script syntax, defer to the `sf-ai-agentscript` skill. This file covers only the vision-specific wiring.

## Variables — pass the conversation id in

Capture the messaging session id so the action can locate the uploaded file, and a mutable variable to stash keywords between actions.

```
variables:
    RoutableId: linked string
        source: @MessagingSession.Id
        description: "MessagingSession Id — the image is linked to this session."
    search_keywords: mutable string = ""
        description: "Keywords returned by image analysis, used to search Knowledge."
```

## The photo-troubleshooting subagent

```
subagent photo_troubleshooting:
    label: "Photo Troubleshooting"
    description: "Diagnose a visible problem from a customer's uploaded photo and give grounded steps."

    reasoning:
        instructions: ->
            | You help customers troubleshoot problems, including from a photo they upload.
              Photos are uploaded through the web/app experience, NOT as chat attachments, so you
              will NOT see the image in this conversation — but a photo the customer uploaded IS
              available to the {!@actions.analyze_image} action.
              CRITICAL: Only call {!@actions.analyze_image} if the customer has ACTUALLY uploaded a
              photo in this conversation (e.g. "I uploaded a photo", "here's a photo", "please look").
              NEVER call analyze_image based only on a text description — you may analyze an unrelated
              image and give a wrong answer.
              If the customer only DESCRIBES the problem: do NOT call analyze_image. Extract concise
              keywords (device type, light color, error text) and call {!@actions.find_articles}
              instead, and invite them to upload a photo for a precise diagnosis.
              If the customer HAS uploaded a photo: call {!@actions.analyze_image}. When it returns
              success = true, tell them in plain language what you see (the diagnosis), then call
              {!@actions.find_articles} with the analysis keywords.
              Only if analyze_image returns success = false should you apologize, share its message,
              and ask for one clear, well-lit photo, then try again.
              Ground all steps ONLY in returned article content — do NOT invent steps.
              Do NOT call the same action twice once you have its result.
        actions:
            analyze_image: @actions.analyze_image
                description: "Analyze a photo the customer UPLOADED. Only when they actually uploaded one."
                with recordId = @variables.RoutableId
                with userDescription = ...
                set @variables.search_keywords = @outputs.searchKeywords
            find_articles: @actions.find_articles
                description: "Search Knowledge for steps using keywords from the diagnosis."
                with keywords = ...

    actions:
        analyze_image:
            description: "Analyze the uploaded image and return a diagnosis and search keywords."
            label: "Analyze Image"
            target: "apex://AgentforceVisionImageAction"
            include_in_progress_indicator: True
            progress_indicator_message: "Analyzing your photo..."
            inputs:
                recordId: string
                    description: "Conversation or record id the uploaded image is linked to."
                    is_required: False
                userDescription: string
                    description: "Any text the customer typed describing the problem."
                    is_required: False
            outputs:
                diagnosis: string
                    description: "Plain-language description of what is in the image and the likely problem."
                    filter_from_agent: False
                searchKeywords: string
                    description: "Keywords for the Knowledge search."
                    filter_from_agent: True
                contentDocumentId: string
                    description: "Id of the analyzed image."
                    filter_from_agent: True
                success: boolean
                    description: "Whether analysis succeeded."
                    filter_from_agent: True
                message: string
                    description: "Failure or status message."
                    filter_from_agent: False
```

## Wiring rules that matter

- **`target: "apex://<ClassName>"`** binds the action to your invocable Apex. The input/output names must match the Apex `@InvocableVariable` names.
- **Pass the conversation id** (`with recordId = @variables.RoutableId`). Without it the action falls back to "most recent image org-wide," which is fine for a demo but risky in production with concurrent sessions.
- **`filter_from_agent: True`** on internal fields (ids, raw keywords, success flags) keeps them out of the reasoning model's context — the model only needs `diagnosis` and, on failure, `message`. This reduces noise and prompt-injection surface.
- **`set @variables.search_keywords = @outputs.searchKeywords`** stashes keywords so the follow-up grounding action can use them.
- **`include_in_progress_indicator` + `progress_indicator_message`** give the customer a "Analyzing your photo…" affordance while the model runs.

## The guardrail, restated

The number-one failure mode of a vision agent is **analyzing an image the customer didn't just send**. Because the Apex resolves "the most recent uploaded image," a text-only turn can trigger analysis of a stale photo and produce a confident-but-wrong diagnosis. The `CRITICAL:` instruction above is what prevents it — keep it, and keep `analyze_image` scoped to a subagent that only runs when a photo is genuinely in play.

## Routing to it

From your start/router agent, route to `photo_troubleshooting` when the customer shows a visible problem, references a device/error screen, or offers to share a photo. Route text-only how-to questions to a Knowledge/FAQ subagent instead (which can still invite a photo).
