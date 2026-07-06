---
name: sf-agent-api-citations
description: Agent API citations — parsing and rendering cited sources returned by an agent. Use when handling the citedReferences array in an Inform response, rendering source lists or inline citations via inlineMetadata (claim + location), or linking cited records back to Salesforce.
disable-model-invocation: true
---
# Agent API Citations

## Use This Skill When

- Parsing the `citedReferences` array from an `Inform` message.
- Rendering cited sources as a source list or as inline citations.
- Mapping cited `recordId`/`value` back to Salesforce records or knowledge articles.

## Concept

Some responses include cited sources in the `citedReferences` array of an `Inform` message. Citations appear in two ways:

- **Source list** — references shown at the bottom of the response.
- **Inline citations** — tied to a specific location in the response text via the `inlineMetadata` object.

## CitedReference Shape

```json
{
  "type": "link",
  "value": "https://myorgdomain.salesforce.com/ka0RZ000002DzSmYAK",
  "recordId": "ka0RZ000002DzSmYAK",
  "label": null,
  "inlineMetadata": [
    {
      "claim": "The 2024 Acura ZDX is Acura's first-ever all-electric vehicle, featuring: ...",
      "location": 236
    }
  ]
}
```

| Field | Meaning |
|-------|---------|
| `type` | Reference type (for example `link`) |
| `value` | URL to the cited source |
| `recordId` | Salesforce record ID of the source (for example a Knowledge article) |
| `label` | Optional display label |
| `inlineMetadata[]` | Inline anchors: `claim` (the supported text span) and `location` (character offset in `message`) |

## Rendering Strategy

### Source list (simplest)
Render every `citedReference` as a footnote/link block beneath the answer. Use `label` when present, else derive a title from `recordId`/`value`.

### Inline citations
1. Read the `Inform` `message` text.
2. For each reference, for each `inlineMetadata` entry, use `location` (character offset) to place a citation marker in the rendered text.
3. Sort markers by `location` before inserting so offsets don't shift incorrectly (insert from the end backwards, or account for inserted marker length).
4. Link each marker to `value` (URL) or navigate to `recordId` in-app.

```javascript
function buildInlineCitations(informMessage) {
  const text = informMessage.message;
  const anchors = [];
  (informMessage.citedReferences || []).forEach((ref, refIdx) => {
    (ref.inlineMetadata || []).forEach((im) => {
      anchors.push({ location: im.location, refIdx: refIdx + 1, ref });
    });
  });
  anchors.sort((a, b) => b.location - a.location); // insert from end
  let out = text;
  for (const a of anchors) {
    const marker = `[${a.refIdx}](${a.ref.value})`;
    out = out.slice(0, a.location) + marker + out.slice(a.location);
  }
  return out;
}
```

## Guardrails

- `citedReferences` may be empty (`[]`) — always guard before iterating.
- `inlineMetadata` may be absent; fall back to a source list when there are no inline anchors.
- Treat `value` URLs as untrusted; validate the host/scheme before rendering as a clickable link.
- When inserting inline markers by `location`, insert from the highest offset backward so earlier offsets stay valid.
- Prefer in-app navigation via `recordId` for internal records rather than exposing raw org URLs externally.

## Deliverables

- A citation parser that normalizes `citedReferences` into source-list and inline forms.
- A rendering component contract (marker style, link vs navigate, empty-state handling).

## Additional Resources

- Where citations arrive in the response: `sf-agent-api-messaging`
- Official docs: [Agent API Examples — Handle Citations](https://developer.salesforce.com/docs/ai/agentforce/guide/agent-api-examples.html)
