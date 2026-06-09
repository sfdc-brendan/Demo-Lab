# Agentforce CLT — Reference Pattern Catalog

These eight patterns are field-tested CLT shapes that have shipped in Agentforce demos. Use them as recipes: pick the closest shape, copy the data contract, adapt the LWC. Each one is a working unmanaged package — install to inspect, then bring into Cursor/Claude to customize.

When the user describes a problem, map it to a pattern first; building from scratch is rarely needed.

---

## 1. Dynamic Product Carousel

**Use when** the agent needs to surface 1–N items the user browses sideways: products, recommendations, time slots, agents. Each card has title, description, image, a "stage" pill, and an AM/PM/AM-PM time indicator (sun/moon icon).

**Shape (Apex)**
- `List<CarouselCard>` where `CarouselCard` has: `title` (String), `description` (String), `imageUrl` (String), `stage` (String — shown as side label), `time` (String — `"AM"`, `"PM"`, or `"AM/PM"`).

**LWC notes**
- Horizontal scroll container, snap on cards.
- The "stage" is the white side text (e.g., "PREP").
- Sun/moon icon driven entirely by the `time` value.

**Install (reference)**: `04tHo0000012vh3` — package `ASA_ProductCarouselCardsStage`, Lightning Type `asaCarousel`.

---

## 2. Dynamic Item Selector

**Use when** the agent asks the user to choose one or many from a generated list: appointment options, product variants, cases to merge.

**Shape (Apex)**
- `title` (String), `mode` (String: `"single"` or `"multiple"`), `options` (`List<Option>`), where `Option` has `id`, `label`, optional `description`, optional `imageUrl`.
- Output back to the agent: selected option(s) returned as the utterance.

**LWC notes**
- Single-select uses radio cards; multi-select uses checkbox cards with a Submit button.
- Build a `test-single` and `test-multiple` mode early — saves a lot of round-trip iteration.

**Install (reference)**: `04tHo0000012wAl` — package `ASA_ItemSelector`, Lightning Type `asaItemSelector`.

---

## 3. Add to Cart / Quote

**Use when** the chat needs a transactional CTA: "add this to cart", "add to quote", "order this".

**Shape (Apex)**
- Either single item or `List<Item>`. Each item: `title`, `description`, `imageUrl`, `defaultQuantity` (Integer), `callToAction` (String — button label, e.g., `"Add to Cart"`).
- Agent sets all four dynamically per render.

**LWC notes**
- Quantity stepper + CTA button.
- On click, dispatch `valuechange` so the action records what was added.

**Install (reference)**: `04tHo0000012wNY` — package `ASA_AddToCartQuote`, Lightning Type `asaAddItem`.

---

## 4. Embedded Form (with conditional visibility)

**Use when** you need 3–8 structured fields collected mid-chat, with branching: "if Country = Canada, show province dropdown".

**Shape (Apex)**
- `title` (String), `submitText` (String), `fields` (`List<FormField>`).
- `FormField`: `id`, `label`, `type` (`"text"|"email"|"phone"|"select"`), `required` (Boolean), `options` (`List<String>` for select), `width` (`"half"` or `"full"`), `showIf` (`{ field, value }`).

**Example payload**
```json
{
  "title": "Contact Information",
  "submitText": "Submit",
  "fields": [
    { "id": "country", "label": "Where is your business based?",
      "type": "select", "options": ["Canada", "USA"], "required": true },
    { "id": "firstName", "label": "First Name", "type": "text",
      "required": true, "width": "half",
      "showIf": { "field": "country", "value": "Canada" } }
  ]
}
```

**LWC notes**
- Renders as a vertical stack; pairs of `width: "half"` fields render side-by-side.
- On submit, the entire form is sent back as the user's utterance (so the agent has all values in context).

**Install (reference)**: `04tWt000000DyRN` — package `ASA_AsaLeadForm`, Lightning Type `asaLeadForm`.

---

## 5. File Upload v1 — Confirm & Send

**Use when** the user must attach files that get logged on the chat session record itself (Messaging Session). Simpler permission model.

**Shape (Apex)**
- `title`, `acceptedFormats` (`List<String>`), `maxFiles` (Integer), `maxSizeMb` (Integer).

**Wire-up gotchas**
- ESD site **must** have CORS configured to my-domain or upload silently fails.
- Agent user needs full access to Messaging Session object.
- Files become ContentDocuments linked to the Messaging Session.

**Install (reference)**: `04tWt000000Dyb3` — package `ASA_FileUpload`, Lightning Type `asaFileUpload`.

---

## 6. File Upload v2 — Send & Summarize (target record)

**Use when** files attach to a specific record (Case, Account, custom object) the agent identifies via instructions.

**Shape (Apex)**
- `targetRecordId` (Id, set by the agent), `acceptedFormats`, `maxFiles`, `maxSizeMb`.
- Apex action takes `targetRecordId` as input and returns a `FileUploadResponse` shape.

**Wire-up gotchas**
- Same CORS requirement as v1.
- Agent action is built directly from an Apex action class (`FileUploadAction`), not a Flow — simpler than v1.
- Agent instructions must explicitly tell the model which record ID to use.

**Install (reference)**: `04tKZ000000xyKu` — Lightning Type `fileUploadResponse`, Apex `FileUploadAction`.

---

## 7. Send Formatted URL

**Use when** the agent surfaces a single link as a styled card instead of a raw URL — for product pages, articles, deep links.

**Shape (Apex)**
- `title` (String), `url` (String), optional `description`, optional `imageUrl`.
- Note: `_self` target does **not** work — link opens in a new tab.

**Install (reference)**: `04tWt000000Dyj7` — package `ASA_SendURL`, Lightning Type `asaOpenLink`.

---

## 8. Article Cards (long-form + recommended links)

**Use when** the agent answers from a knowledge article and wants to embed the article content plus a list of related links — common in healthcare, financial services, legal.

**Shape (Apex)**
- `articleTitle` (String), `articleBody` (String, rich text or HTML), `recommendedContent` (`List<Link>`), where `Link = { text, url }`.

**LWC notes**
- The component is intentionally **extra-wide** to minimize scrolling. Enhanced Chat v2 doesn't allow setting `width` in setup yet, so the embedding page must use the inline embed methods (not the floating launcher) to give it the room.

**Install (reference)**: `04tHu000004VUbc` — package `ArticleViewerCLT`, Lightning Type `asaArticleWithLinks`.

---

## Bonus — Employee Agent Embedded Screen Flow

The Employee Agent (LEX assist panel) has a constraint: it can't push utterances back to the agent. So the canonical pattern is to embed a Screen Flow that the agent has pre-populated with input variables. The user completes the form, then copy/pastes the result back into chat.

**Shape (Apex)**
```json
{
  "flowApiName": "Submit_Deal_Support_Request",
  "inputVariables": [
    { "name": "recordId", "value": "001XXX...", "type": "String" }
  ]
}
```

**Channel folder**: `lightningDesktopGenAi/` only.

**Install (reference)**: `04tWt000000E2un` — package `AEA_EmbeddedScreenFlow`, Lightning Type `aeaEmbeddedScreenFlow`.

---

## When you can't find a matching pattern

Default to **Pattern 1 (Carousel)** if it's a list of similar things, **Pattern 4 (Form)** if it's collecting structured input, or **Pattern 7 (Formatted URL)** if it's pointing the user somewhere.
