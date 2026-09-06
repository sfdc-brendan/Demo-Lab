# Lightning Types

Self-contained Custom Lightning Type cards for Agentforce conversations. Each folder is one card, and each card deploys green into a vanilla org and renders on the first try.

These are surfaced in the **Custom Lightning Types** area of the SE Workshop app, which reads `card.json` from every folder here.

## The rule that makes this library work

Every card ships in **demo mode**: the invocable action returns a fixed sample payload with no SOQL, no custom objects, and no configuration. Someone can deploy a card, wire it to an agent, and see it render before writing a line of their own code. Wiring it to real data is documented per card, not required to get value.

A card with a prerequisite is a card most people will bounce off. Keep `prerequisites` empty unless the pattern genuinely cannot exist without one.

## Folder contract

```
Lightning Types/<Card Name>/
  card.json                 gallery manifest
  states.json               named payloads: the data contract
  README.md                 install, agent wiring, wire-to-real-data
  sfdx-project.json
  preview/
    index.html              flattened static simulation, one block per state
    card.css                VERBATIM copy of the component's stylesheet
    frame.css               preview-only stubs for lightning-card/button + SLDS spacing
    preview.js              state switcher + button feedback (generic, copy as-is)
  force-app/main/default/
    classes/                renderer DTO + demo-mode action
    lightningTypes/<type>/  schema.json, lightningDesktopGenAi/renderer.json, bundle meta
    lwc/<component>/
    permissionsets/         classAccesses only
```

`preview/` sits outside `force-app/` on purpose, so it is never deployed to anyone's org.

## The wiring, in one place

Three independently-named artifacts joined by explicit references:

- **Renderer DTO** — a `global` class with `@JsonAccess` and exactly one `@AuraEnabled String <name>JSON`, plus a parameterless constructor. One per renderer; never shared.
- **Service** — `@InvocableMethod` returning `List<Response>`. `Response` uses `@InvocableVariable` (not `@AuraEnabled`) and carries the DTO under one key plus a plain-text narrative under another. The displayable field is typed as the DTO class and is never null.
- **LightningType** — `schema.json` points at `@apexClassType/c__<DtoClass>`; `lightningDesktopGenAi/renderer.json` points at `c/<lwc>`. No `enhancedWebChat/` folder, no `attributes` block.
- **LWC** — a simple `@api value`, `JSON.parse(this.value.<name>JSON)` in `connectedCallback` inside a try/catch, handling the `{"error":...}` sentinel. Targets `lightning__AgentforceOutput`; no `sourceType` or `targetConfigs`.

A list is just an array inside the JSON string. There is no separate collection binding mode.

## Adding a card

1. Copy the closest existing folder and rename everything, including the class names inside the files.
2. Write `states.json` first. It is the contract, and it drives both the demo action and the simulation.
3. Strip every dependency that would fail in an empty org: custom objects and fields, static resources, shared LWC modules, console-only APIs.
4. Build `preview/` by copying the component's `.css` across verbatim and flattening the template into static HTML, one block per state. `frame.css` and `preview.js` can be copied unchanged.
5. Fill in `card.json`, including the `instructionSnippet` — a card whose planner instructions are vague renders as plain text and never mounts.
6. Deploy it to a scratch org and confirm it renders before opening the PR.
