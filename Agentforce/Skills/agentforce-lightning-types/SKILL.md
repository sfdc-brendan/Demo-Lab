---
name: agentforce-lightning-types
description: Build custom Lightning Types (CLTs) that render rich UI inside an Agentforce chat window — Service Agent (Enhanced Chat v2), Employee Agent (LEX assist panel), and Mobile. TRIGGER when the user asks to build, customize, or debug a custom Lightning Type for Agentforce; render forms, cards, carousels, file uploads, or interactive components in an agent chat; or works in a `lightningTypes/**` folder, edits an LWC with `lightning__AgentforceInput`/`lightning__AgentforceOutput` targets, or wires an agent action's "Output Rendering" to a custom LWC. DO NOT TRIGGER for object-based Lightning Types intended for Experience Builder or Prompt Builder only (use object schema patterns directly), MIAW (non–Chat V2) deployments, or plain LWCs on record/app/home pages.
---

# Agentforce Lightning Types

Custom Lightning Types (CLTs) let an Agentforce agent return data that the chat surface renders as a rich LWC — a card, carousel, form, file uploader, etc. — instead of plain text. This skill encodes the working pattern for **Apex-based** CLTs, which are the variant that works inside agent chat surfaces.

## Decision tree

1. **Is this an Agentforce chat surface?** (Service Agent in Enhanced Chat v2, Employee Agent assist panel in LEX, or Mobile.) → Use Apex-based CLT (this skill).
2. **Is this Experience Builder, Prompt Builder, or Flow Structured Outputs?** → Use object-based CLT (`lightning__objectType`); not covered here.
3. **Is the surface MIAW (standard, not Chat V2)?** → Stop. CLTs are not supported.
4. **Is this just an LWC on a record page?** → Stop. Use a normal LWC, not a CLT.

## Three surfaces, three channel folders

A single CLT can target one or more surfaces by adding the matching folder under the bundle:

| Surface | Channel folder |
|---|---|
| Service Agent · Enhanced Chat v2 | `enhancedWebChat/` |
| Employee Agent · LEX assist panel | `lightningDesktopGenAi/` |
| Mobile (iOS/Android, Service or Employee) | `lightningMobileGenAi/` |

For chat-only output, only `renderer.json` is needed. Add `editor.json` only when the agent must collect input via Inquire/Confirm steps (inputs do **not** fire on plain Inform steps).

## File anatomy

```
force-app/main/default/
├── lightningTypes/
│   └── myType/
│       ├── schema.json                    # Required. References the Apex class.
│       ├── enhancedWebChat/
│       │   ├── renderer.json              # Output UI for Service Agent
│       │   └── editor.json                # Optional input UI
│       ├── lightningDesktopGenAi/
│       │   └── renderer.json              # Output UI for Employee Agent
│       └── lightningMobileGenAi/
│           └── renderer.json              # Output UI for mobile
├── classes/
│   ├── MyTypeData.cls                     # global Apex shape; @AuraEnabled fields
│   └── MyTypeData.cls-meta.xml
└── lwc/
    └── myComponent/
        ├── myComponent.html               # The view
        ├── myComponent.js                 # @api value, dispatches valuechange
        ├── myComponent.js-meta.xml        # target = lightning__AgentforceOutput
        └── myComponent.css
```

API requires version **64.0 or later** for `LightningTypeBundle` metadata.

## Contracts (must follow exactly)

### Apex class
- Top-level **only**. No inner classes. Inner classes break the introspection that builds the schema.
- Every class in the chain: `global` (not `public` or `private` — those fail in namespaced/managed contexts).
- Every field exposed to the agent: `@AuraEnabled`.
- Every class: `@JsonAccess(serializable='always' deserializable='always')`.
- Supported types: primitives (Integer, Double, Long, Date, Datetime, Time, String, ID, Boolean), sObjects, lists/arrays of any of the above, `Map<String, ...>`, and other user-defined Apex classes following the same rules.

### `schema.json`
```json
{
  "title": "My Type",
  "description": "What this represents.",
  "lightning:type": "@apexClass/c__MyTypeData"
}
```
- `lightning:type` always uses the namespace prefix: `c__` for the local org and any new managed-package metadata in the same package; the package's namespace prefix when referencing existing managed metadata.

### `renderer.json` / `editor.json`
Top-level override (one LWC for the whole shape — typical for chat):
```json
{
  "componentOverrides": {
    "$": { "definition": "c/myComponent" }
  }
}
```
Property-level override (only override one field; defaults handle the rest):
```json
{
  "componentOverrides": {
    "rating": {
      "component": "c/ratingEditor",
      "attributes": { "value": "{!$attrs.rating}" }
    }
  }
}
```

### LWC view
- `js-meta.xml` target: `lightning__AgentforceOutput` (renderer) or `lightning__AgentforceInput` (editor). Set `isExposed=true`.
- The component receives data via `@api value`. The shape of `value` matches the Apex class.
- The component receives `@api readOnly` (Boolean) — true when displayed as a past message, false when interactive.
- To send input back, dispatch `new CustomEvent('valuechange', { detail: { value: <newShape> } })`.
- Don't reach into the parent DOM; CLTs render in a sandboxed slot inside the chat surface.

## Wire-up (org-side, after deploy)

1. Create the agent action — either an **Apex Invocable** action whose return type is the Apex class, or a **Flow** with an output variable typed `c__MyTypeData`. For input CLTs, the Apex parameter (or Flow input variable) must be typed to the corresponding Apex class as well — referenced as `@apexClassType/c__MyFilterData` at the action-variable level.
2. In the agent action settings:
   - **Show in conversation** = ON
   - **Output Rendering** parameter on the relevant output variable → select your CLT (e.g., `flightResponse`).
   - **Input Rendering** parameter on the relevant input variable → select your input CLT (e.g., `flightFilter`). Inputs only render on Inquire/Confirm steps.
   - When you pick a CLT, the "Map to Variable" field may show **"Unsupported Data Type"** — per the docs this is a UI artifact and "doesn't affect your saved work and can be safely ignored."
3. Agent user permissions:
   - Permission set granting access to the Apex class.
   - For file-upload patterns: read/write on `Messaging Session` (v1) or the target object (v2).
4. For Service Agent only: configure CORS on the Embedded Service Deployment site to your my-domain, or the LWC will fail to load.
5. Reload the agent page before the next test — newly attached CLTs don't pick up live in an open agent session.

### Multi-CLT actions (input + output on the same action)
The canonical "filter and respond" pattern (e.g., `FlightAgent`) wires two CLTs to one action: a filter CLT on the input variable (`flightFilter`, with `editor.json` + input LWC) and a response CLT on the output variable (`flightResponse`, with `renderer.json` + output LWC). They live in separate `lightningTypes/` bundles and share the agent action.

### Steering the LLM toward the input form
When an input CLT exists, the planner can either render the form **or** ask the user for the same fields inline as text. Bias it toward the form by tuning the subagent/topic instructions (e.g., "When asking for filters, present the filter form rather than asking field by field"). Without this, ranges (price, date, discount) often get asked inline.

## Testing — important

- **Agent Builder preview does not render custom Lightning Types** for the Service Agent. Don't trust the "no UI" you see there.
- Test via **Setup → Embedded Service Deployments → \[your deployment\] → Test Enhanced Web Chat**.
- Re-deploy after any Apex shape change. If you renamed a field or changed a type after the action was created, **delete and recreate the agent action** — references go stale silently.

## Common gotchas (in order of frequency)

1. LWC `js-meta.xml` missing `lightning__AgentforceInput`/`lightning__AgentforceOutput` target → component never renders, no error.
2. Apex class is `public` instead of `global` → fails only in managed package or namespaced org.
3. Missing `@JsonAccess` → silent serialization failure at runtime.
4. UI Configuration reverts from "Enhanced Chat V2" to "Agentforce (Lightning Experience)" after save → the Service Agent isn't connected to a Chat V2 channel; fix the Embedded Service Deployment, not the agent.
5. Input LWC is set up but the agent ignores it and goes straight to output → action is an Inform step. Check "Require user confirmation" on the action to make it a Confirm step, and mark inputs required.
6. Input form exists but the agent asks for fields inline as text → planner is choosing text over the form. Tune the topic/subagent instructions to prefer the rendered form.
7. Apex shape changed after the agent action was built → reload the agent page first; if still stale, delete & recreate the action.
8. "Unsupported Data Type" shown on the Map to Variable parameter → benign per docs; ignore.
9. Service Agent fails to load the LWC silently → ESD site missing CORS to my-domain.
10. Local org class referenced as `MyTypeData` instead of `c__MyTypeData` → the `lightning:type` resolver can't find it.

## When to reach for which pattern

For the catalog of 8 reference patterns (carousel, item selector, add-to-cart, embedded form with conditional fields, file upload v1/v2, formatted URL, article cards, embedded screen flow), see `references/patterns.md`.

For a runnable starter (HighlightCard — title + description + image + URL → card in chat), see `examples/highlightCard/`. Copy that bundle, rename, and adapt the shape.

## What this skill does NOT cover

- Object-based CLTs targeting Experience Builder, Prompt Builder, or generic Einstein Agent actions — use `generating-custom-lightning-type` instead.
- Standard out-of-the-box Lightning Types (`lightning__textType` etc.) — those don't need a bundle.
- The Agentforce Lightning Type Builder web tool (separate workflow at `agentforce-clt-builder-e4e03ec84f1a.herokuapp.com`) — use that for visual generation, then bring the downloaded zip back here for editing.

## Related skills

- `generating-custom-lightning-type` — object-based CLTs, JSON Schema, generic Einstein Agent actions.
- `developing-agentforce` / `sf-ai-agentforce` — building the agent itself (topics, actions, .agent files).
- `generating-lwc-components` — general LWC patterns; this skill assumes you already have working LWC fundamentals.
