---
name: sf-lwc-content
description: >
  Microcopy and UI writing patterns for Lightning Web Components. Covers error message
  structure, empty state copy, button labels, help text, confirmation dialogs, placeholder
  text, toast messages, and internationalization-ready string patterns. Use when writing
  UI text, error messages, labels, help text, or when the user mentions microcopy,
  UX writing, content design, error messages, empty states, or button labels.
license: MIT
metadata:
  version: "1.0.0"
  author: "Brendan Sheridan"
  scoring: "100 points across 6 categories"
---

# sf-lwc-content: Microcopy and UI Writing for LWC

The words inside a component matter as much as the visual design. Write clear, helpful, human UI text that guides users and reduces confusion.

## Core Principles

1. **Clear over clever** — say exactly what happened and what to do next
2. **Active voice** — "Save the record" not "The record will be saved"
3. **Verb-first buttons** — "Create Account" not "Account Creation"
4. **No jargon** — "Something went wrong" not "Null pointer exception in line 42"
5. **Consistent terminology** — pick one word and use it everywhere

---

## Error Messages

### Structure: What + Why + What to Do

Every error message answers three questions:

```
┌─────────────────────────────────────────────┐
│  WHAT happened    │ "Record couldn't be saved"
│  WHY it happened  │ "Required fields are missing"
│  WHAT TO DO next  │ "Fill in Account Name and click Save again"
└─────────────────────────────────────────────┘
```

### Error Templates

| Scenario | Message |
|----------|---------|
| **Field validation** | `{Field Name} is required. Enter a value to continue.` |
| **Server error** | `We couldn't save this record. Check your entries and try again.` |
| **Permission denied** | `You don't have access to {action}. Contact your admin for help.` |
| **Network error** | `We couldn't connect to Salesforce. Check your connection and try again.` |
| **Not found** | `This {record type} was deleted or you don't have access to it.` |
| **Limit reached** | `You've reached the maximum of {limit} {items}. Remove one to add another.` |

### Error in Code

```javascript
get userFriendlyError() {
    if (!this._error) return '';
    if (this._error.body?.message) {
        return this._error.body.message;
    }
    return 'Something went wrong. Try again, or contact your admin if the problem continues.';
}
```

### Anti-Patterns

| Do NOT Say | Say Instead |
|-----------|-------------|
| `Error: 500 Internal Server Error` | `Something went wrong. Try again in a moment.` |
| `FIELD_CUSTOM_VALIDATION_EXCEPTION` | `{Validation rule error message text}` |
| `null` or blank | `Something unexpected happened. Try again.` |
| `Invalid input` | `Enter a valid {field type}. Example: name@company.com` |

---

## Empty States

Empty states are opportunities to guide users, not dead ends.

### Structure: Explain + Guide + Act

```
┌─────────────────────────────────────────────┐
│           [Icon or illustration]             │
│                                             │
│     No {items} yet                          │  ← Explain
│     {Why this is empty or what items are}   │  ← Guide
│     [Create {Item}]                         │  ← Act
└─────────────────────────────────────────────┘
```

### Empty State Templates

| Context | Title | Description | Action |
|---------|-------|-------------|--------|
| **First use** | `No cases yet` | `Cases appear here when customers reach out.` | `Create a Case` |
| **No results** | `No matching records` | `Try adjusting your filters or search terms.` | `Clear Filters` |
| **Filtered empty** | `No {items} match "{query}"` | `Check your spelling or try different keywords.` | `Clear Search` |
| **Completed** | `All caught up` | `You've resolved all open cases. Nice work.` | — |
| **Permission** | `Nothing to show` | `Ask your admin for access to {feature}.` | `Request Access` |

---

## Button Labels

### Rules

- **Verb first**: `Save Record`, `Create Contact`, `Send Email`
- **Specific over generic**: `Save Changes` not `Submit`, `Delete Account` not `OK`
- **Match the action**: the button label should describe what happens when clicked
- **Destructive actions**: use the verb that matches (`Delete`, `Remove`, `Disconnect`)

### Common Pairs

| Primary | Secondary | Context |
|---------|-----------|---------|
| `Save` | `Cancel` | Edit form |
| `Create {Item}` | `Cancel` | New record form |
| `Delete` | `Keep` | Destructive confirmation |
| `Confirm` | `Go Back` | Multi-step process |
| `Send` | `Cancel` | Email/message action |
| `Apply` | `Reset` | Filter/settings |

### Anti-Patterns

| Do NOT | Do Instead |
|--------|------------|
| `OK` / `Yes` / `No` | Specific: `Delete Record` / `Keep Record` |
| `Submit` (generic) | `Save Changes`, `Create Account`, `Send Request` |
| `Click Here` | `View Details`, `Download Report` |
| `Process` | `Run Report`, `Calculate Total` |

---

## Help Text and Tooltips

### When to Use

| Pattern | Use When |
|---------|----------|
| **Inline help text** | Field needs context every time (format, constraints) |
| **Tooltip** | Supplementary info; not needed for task completion |
| **Info icon + popover** | Detailed explanation that would clutter inline |

### Help Text Templates

| Field Type | Help Text Pattern |
|-----------|------------------|
| **Email** | `Enter a valid email address. Example: name@company.com` |
| **Phone** | `Include country code for international numbers. Example: +1 (555) 123-4567` |
| **Date** | `Enter a date in MM/DD/YYYY format.` |
| **Currency** | `Enter the amount without currency symbols.` |
| **Lookup** | `Search by name or record number.` |
| **Picklist** | `Select the option that best describes {context}.` |
| **Percentage** | `Enter a number between 0 and 100.` |

### Accessibility Note

Tooltips must be keyboard-accessible. Use `aria-describedby` to link help text to its field:

```html
<lightning-input
    label="Annual Revenue"
    field-name="AnnualRevenue"
    aria-describedby="revenue-help">
</lightning-input>
<div id="revenue-help" class="help-text">
    Enter the company's total annual revenue in USD.
</div>
```

---

## Confirmation Dialogs

### Structure: Consequence + Specific Action

```
┌─────────────────────────────────────────────┐
│  Delete this account?                        │  ← Question (what will happen)
│                                             │
│  This will permanently delete "Acme Corp"   │  ← Consequence
│  and all related contacts and cases.         │
│  This action can't be undone.               │
│                                             │
│        [Cancel]    [Delete Account]          │  ← Specific labels
└─────────────────────────────────────────────┘
```

### Templates

| Action | Title | Body | Confirm Button |
|--------|-------|------|----------------|
| **Delete record** | `Delete this {type}?` | `This will permanently delete "{name}" and its related data. This can't be undone.` | `Delete {Type}` |
| **Discard changes** | `Discard unsaved changes?` | `You have unsaved changes that will be lost.` | `Discard Changes` |
| **Remove from list** | `Remove {name}?` | `{Name} will be removed from this {list}. You can add them back later.` | `Remove` |
| **Reassign** | `Reassign this {type}?` | `{Name} will be reassigned from {current} to {new}.` | `Reassign` |

---

## Toast Messages

### Format

```javascript
// Success: past tense, brief
{ title: 'Account saved', message: 'Your changes have been saved.', variant: 'success' }

// Error: what happened + what to do
{ title: 'Couldn\'t save record', message: 'Check required fields and try again.', variant: 'error' }

// Warning: what to be aware of
{ title: 'Limited results', message: 'Showing first 200 records. Refine your search.', variant: 'warning' }

// Info: neutral notification
{ title: 'Record updated', message: 'Changes made by another user have been loaded.', variant: 'info' }
```

### Rules

- **Title**: 2-4 words, sentence case
- **Message**: 1 sentence, actionable for errors
- **Success toasts**: optional message (title alone is often sufficient)
- **Error toasts**: always include a message with guidance

---

## Placeholder Text

### Rules

- Placeholders are **examples**, not **labels** — never replace a label with a placeholder
- Use realistic examples: `Search accounts...` not `Type here`
- Keep short: max 30-40 characters

### Templates

| Field | Placeholder |
|-------|------------|
| **Search** | `Search {items}...` |
| **Name** | `Enter full name` |
| **Email** | `name@company.com` |
| **Description** | `Describe the issue...` |
| **URL** | `https://example.com` |

---

## Internationalization Readiness

### String Patterns

- **Never concatenate translated strings** — word order varies by language
- **Use Custom Labels** for all user-facing text
- **Allow 40% expansion** for translated text (German/French are longer than English)
- **Avoid text in images** — it can't be translated

```javascript
import SAVE_LABEL from '@salesforce/label/c.Save_Changes';
import ERROR_TITLE from '@salesforce/label/c.Error_Title';

export default class MyComponent extends LightningElement {
    labels = { SAVE_LABEL, ERROR_TITLE };
}
```

```html
<lightning-button label={labels.SAVE_LABEL}></lightning-button>
```

---

## Scoring Rubric (100 Points)

| Category | Points | Pass Criteria |
|----------|--------|---------------|
| **Error Messages** | 25 | All errors follow what/why/do structure; no raw exceptions shown |
| **Empty States** | 20 | Every list/table has an empty state with guidance and action |
| **Button Labels** | 15 | Verb-first, specific, destructive actions clearly labeled |
| **Help Text** | 15 | Fields that need context have help text; accessible linking |
| **Confirmation Dialogs** | 15 | Destructive actions confirmed; specific labels on buttons |
| **i18n Ready** | 10 | Custom Labels used; no string concatenation; expansion room |

---

## Cross-Skill Integration

| Skill | Relationship |
|-------|-------------|
| **sf-lwc-ux** | Empty/error/loading states need well-written content |
| **sf-lwc-review** | Audit includes content quality checks |
| **sf-lwc-page-composition** | App Builder property labels and descriptions need good copy |
| **sf-lwc-mobile** | Mobile copy must be even more concise |
