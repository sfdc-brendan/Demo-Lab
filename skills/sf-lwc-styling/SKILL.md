---
name: sf-lwc-styling
description: >
  Utility-first CSS patterns for Lightning Web Components inspired by Tailwind CSS
  and Shadcn component design, mapped entirely to SLDS 2 global styling hooks with
  zero external dependencies. Provides reusable CSS class systems, component recipes
  (cards, badges, tables, forms, modals), and spacing/sizing scale references. Use when
  styling LWC, creating custom CSS classes, building UI components, or when the user
  mentions Tailwind, utility classes, Shadcn, CSS patterns, or component recipes.
license: MIT
metadata:
  version: "1.0.0"
  author: "Brendan Sheridan"
  scoring: "100 points across 6 categories"
---

# sf-lwc-styling: Utility-First CSS for LWC

Bring Tailwind CSS methodology and Shadcn-inspired component design to Lightning Web Components using only SLDS 2 global styling hooks. Zero external dependencies — every pattern maps to `--slds-g-*` custom properties.

## Philosophy

1. **Utility-first, SLDS-native** — predefined CSS classes that map to SLDS hooks, not raw values
2. **Scoped by design** — LWC shadow DOM means utility classes are per-component, no global leaking
3. **Composable** — combine utility classes in HTML; override nothing
4. **Zero dependencies** — no Tailwind build step, no static resources, works in any Salesforce org

---

## SLDS-to-Tailwind Mapping

### Colors

| Tailwind Concept | SLDS 2 Hook | CSS |
|-----------------|-------------|-----|
| `bg-white` | `surface-1` | `background: var(--slds-g-color-surface-1, #fff)` |
| `bg-gray-50` | `surface-container-1` | `background: var(--slds-g-color-surface-container-1)` |
| `bg-gray-100` | `surface-container-2` | `background: var(--slds-g-color-surface-container-2)` |
| `bg-blue-50` | `accent-container-1` | `background: var(--slds-g-color-accent-container-1)` |
| `bg-red-50` | `error-container-1` | `background: var(--slds-g-color-error-container-1)` |
| `bg-green-50` | `success-container-1` | `background: var(--slds-g-color-success-container-1)` |
| `text-gray-900` | `on-surface-1` | `color: var(--slds-g-color-on-surface-1)` |
| `text-gray-500` | `on-surface-2` | `color: var(--slds-g-color-on-surface-2)` |
| `text-gray-400` | `on-surface-3` | `color: var(--slds-g-color-on-surface-3)` |
| `text-blue-600` | `accent-1` | `color: var(--slds-g-color-accent-1)` |
| `border-gray-200` | `border-1` | `border-color: var(--slds-g-color-border-1)` |

### Spacing

| Tailwind | SLDS 2 Hook | Approx Value |
|----------|-------------|-------------|
| `p-1` / `m-1` | `--slds-g-spacing-1` | 0.25rem |
| `p-2` / `m-2` | `--slds-g-spacing-2` | 0.5rem |
| `p-3` / `m-3` | `--slds-g-spacing-3` | 0.75rem |
| `p-4` / `m-4` | `--slds-g-spacing-4` | 1rem |
| `p-5` / `m-5` | `--slds-g-spacing-5` | 1.25rem |
| `p-6` / `m-6` | `--slds-g-spacing-6` | 1.5rem |
| `p-8` / `m-8` | `--slds-g-spacing-8` | 2rem |
| `p-10` / `m-10` | `--slds-g-spacing-10` | 2.5rem |
| `p-12` / `m-12` | `--slds-g-spacing-12` | 3rem |

### Typography

| Tailwind | SLDS 2 Hook |
|----------|-------------|
| `text-xs` | `--slds-g-font-size-1` |
| `text-sm` | `--slds-g-font-size-2` |
| `text-base` | `--slds-g-font-size-4` |
| `text-lg` | `--slds-g-font-size-5` |
| `text-xl` | `--slds-g-font-size-7` |
| `text-2xl` | `--slds-g-font-size-9` |
| `text-3xl` | `--slds-g-font-size-11` |
| `font-normal` | `--slds-g-font-weight-4` |
| `font-medium` | `--slds-g-font-weight-5` |
| `font-semibold` | `--slds-g-font-weight-6` |
| `font-bold` | `--slds-g-font-weight-7` |

### Border Radius

| Tailwind | SLDS 2 Hook |
|----------|-------------|
| `rounded-sm` | `--slds-g-radius-border-1` |
| `rounded` | `--slds-g-radius-border-2` |
| `rounded-lg` | `--slds-g-radius-border-3` |
| `rounded-xl` | `--slds-g-radius-border-4` |
| `rounded-full` | `--slds-g-radius-circle` |
| `rounded-pill` | `--slds-g-radius-border-pill` |

### Shadows

| Tailwind | SLDS 2 Hook |
|----------|-------------|
| `shadow-sm` | `--slds-g-shadow-1` |
| `shadow` | `--slds-g-shadow-2` |
| `shadow-lg` | `--slds-g-shadow-3` |
| `shadow-xl` | `--slds-g-shadow-4` |

---

## Reusable Utility Classes

Include these in any LWC component's CSS file. Each class maps directly to SLDS 2 hooks.

### Layout Utilities

```css
/* Flex containers */
.util-stack {
    display: flex;
    flex-direction: column;
    gap: var(--slds-g-spacing-4, 1rem);
}

.util-stack--tight { gap: var(--slds-g-spacing-2, 0.5rem); }
.util-stack--loose { gap: var(--slds-g-spacing-6, 1.5rem); }

.util-cluster {
    display: flex;
    flex-wrap: wrap;
    gap: var(--slds-g-spacing-3, 0.75rem);
    align-items: center;
}

.util-between {
    display: flex;
    justify-content: space-between;
    align-items: center;
}

.util-center {
    display: flex;
    align-items: center;
    justify-content: center;
}

/* Grid */
.util-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
    gap: var(--slds-g-spacing-4, 1rem);
}

.util-grid--2col { grid-template-columns: repeat(2, 1fr); }
.util-grid--3col { grid-template-columns: repeat(3, 1fr); }
.util-grid--4col { grid-template-columns: repeat(4, 1fr); }
```

### Surface Utilities

```css
.util-surface {
    background: var(--slds-g-color-surface-1, #ffffff);
    color: var(--slds-g-color-on-surface-1, #181818);
}

.util-surface--muted {
    background: var(--slds-g-color-surface-container-1, #f8f8f8);
    color: var(--slds-g-color-on-surface-1, #181818);
}

.util-surface--raised {
    background: var(--slds-g-color-surface-1, #ffffff);
    box-shadow: var(--slds-g-shadow-2);
}

.util-surface--sunken {
    background: var(--slds-g-color-surface-container-2, #f3f3f3);
}
```

### Text Utilities

```css
.util-text--heading {
    font-size: var(--slds-g-font-size-7, 1.25rem);
    font-weight: var(--slds-g-font-weight-7, 700);
    color: var(--slds-g-color-on-surface-1, #181818);
    line-height: var(--slds-g-line-height-2, 1.25);
}

.util-text--subheading {
    font-size: var(--slds-g-font-size-4, 0.875rem);
    font-weight: var(--slds-g-font-weight-6, 600);
    color: var(--slds-g-color-on-surface-1, #181818);
}

.util-text--body {
    font-size: var(--slds-g-font-size-4, 0.875rem);
    color: var(--slds-g-color-on-surface-1, #181818);
    line-height: var(--slds-g-line-height-4, 1.5);
}

.util-text--caption {
    font-size: var(--slds-g-font-size-2, 0.75rem);
    color: var(--slds-g-color-on-surface-2, #444444);
}

.util-text--muted {
    color: var(--slds-g-color-on-surface-3, #706e6b);
}

.util-text--truncate {
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
}
```

---

## Component Recipes

### Card

Shadcn-inspired card with header, content, and footer slots.

```html
<template>
    <div class={cardClass}>
        <div class="recipe-card__header" if:true={title}>
            <h3 class="recipe-card__title">{title}</h3>
            <div class="recipe-card__actions">
                <slot name="actions"></slot>
            </div>
        </div>
        <div class="recipe-card__body">
            <slot></slot>
        </div>
        <div class="recipe-card__footer" if:true={hasFooter}>
            <slot name="footer"></slot>
        </div>
    </div>
</template>
```

```css
.recipe-card {
    background: var(--slds-g-color-surface-1, #ffffff);
    border: var(--slds-g-sizing-border-1) solid var(--slds-g-color-border-1, #e5e5e5);
    border-radius: var(--slds-g-radius-border-3, 0.5rem);
    overflow: hidden;
}

.recipe-card--elevated {
    box-shadow: var(--slds-g-shadow-2);
    border: none;
}

.recipe-card__header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: var(--slds-g-spacing-4, 1rem) var(--slds-g-spacing-4, 1rem) 0;
}

.recipe-card__title {
    font-size: var(--slds-g-font-size-5, 1rem);
    font-weight: var(--slds-g-font-weight-6, 600);
    color: var(--slds-g-color-on-surface-1, #181818);
    margin: 0;
}

.recipe-card__body {
    padding: var(--slds-g-spacing-4, 1rem);
}

.recipe-card__footer {
    padding: var(--slds-g-spacing-3, 0.75rem) var(--slds-g-spacing-4, 1rem);
    border-top: var(--slds-g-sizing-border-1) solid var(--slds-g-color-border-1, #e5e5e5);
    background: var(--slds-g-color-surface-container-1, #f8f8f8);
}
```

### Badge / Pill

```css
.recipe-badge {
    display: inline-flex;
    align-items: center;
    gap: var(--slds-g-spacing-1, 0.25rem);
    padding: var(--slds-g-spacing-1, 0.25rem) var(--slds-g-spacing-3, 0.75rem);
    font-size: var(--slds-g-font-size-2, 0.75rem);
    font-weight: var(--slds-g-font-weight-5, 500);
    border-radius: var(--slds-g-radius-border-pill, 9999px);
    white-space: nowrap;
}

.recipe-badge--default {
    background: var(--slds-g-color-surface-container-2, #f3f3f3);
    color: var(--slds-g-color-on-surface-1, #181818);
}

.recipe-badge--success {
    background: var(--slds-g-color-success-container-1, #e6f9e6);
    color: var(--slds-g-color-success-1, #2e844a);
}

.recipe-badge--error {
    background: var(--slds-g-color-error-container-1, #fef1f1);
    color: var(--slds-g-color-error-1, #ea001e);
}

.recipe-badge--warning {
    background: var(--slds-g-color-warning-container-1, #fef4e6);
    color: var(--slds-g-color-warning-1, #dd7a01);
}

.recipe-badge--info {
    background: var(--slds-g-color-info-container-1, #e5f0fb);
    color: var(--slds-g-color-info-1, #0176d3);
}
```

### Data Table with Hover

```css
.recipe-table {
    width: 100%;
    border-collapse: collapse;
    font-size: var(--slds-g-font-size-3, 0.8125rem);
}

.recipe-table th {
    text-align: left;
    padding: var(--slds-g-spacing-3, 0.75rem) var(--slds-g-spacing-4, 1rem);
    font-weight: var(--slds-g-font-weight-6, 600);
    color: var(--slds-g-color-on-surface-2, #444444);
    background: var(--slds-g-color-surface-container-1, #f8f8f8);
    border-bottom: var(--slds-g-sizing-border-2) solid var(--slds-g-color-border-1, #e5e5e5);
}

.recipe-table td {
    padding: var(--slds-g-spacing-3, 0.75rem) var(--slds-g-spacing-4, 1rem);
    color: var(--slds-g-color-on-surface-1, #181818);
    border-bottom: var(--slds-g-sizing-border-1) solid var(--slds-g-color-border-2, #eeeeee);
}

.recipe-table tr:hover td {
    background: var(--slds-g-color-surface-3, #f3f3f3);
}

.recipe-table tr:focus-within td {
    background: var(--slds-g-color-accent-container-1, #e5f0fb);
}
```

### Form Input with Focus Ring

```css
.recipe-input {
    width: 100%;
    padding: var(--slds-g-spacing-2, 0.5rem) var(--slds-g-spacing-3, 0.75rem);
    font-size: var(--slds-g-font-size-4, 0.875rem);
    color: var(--slds-g-color-on-surface-1, #181818);
    background: var(--slds-g-color-surface-1, #ffffff);
    border: var(--slds-g-sizing-border-1) solid var(--slds-g-color-border-1, #e5e5e5);
    border-radius: var(--slds-g-radius-border-2, 0.25rem);
    transition: border-color 150ms ease, box-shadow 150ms ease;
}

.recipe-input:hover {
    border-color: var(--slds-g-color-accent-2, #014486);
}

.recipe-input:focus {
    outline: none;
    border-color: var(--slds-g-color-accent-1, #0176d3);
    box-shadow: 0 0 0 3px var(--slds-g-color-accent-container-1, #e5f0fb);
}

.recipe-input::placeholder {
    color: var(--slds-g-color-on-surface-3, #706e6b);
}

.recipe-input--error {
    border-color: var(--slds-g-color-error-1, #ea001e);
}

.recipe-input--error:focus {
    box-shadow: 0 0 0 3px var(--slds-g-color-error-container-1, #fef1f1);
}
```

### Custom Button (Beyond lightning-button)

When `lightning-button` doesn't fit the design, use custom buttons that still respect SLDS hooks.

```css
.recipe-btn {
    display: inline-flex;
    align-items: center;
    gap: var(--slds-g-spacing-2, 0.5rem);
    padding: var(--slds-g-spacing-2, 0.5rem) var(--slds-g-spacing-4, 1rem);
    font-size: var(--slds-g-font-size-4, 0.875rem);
    font-weight: var(--slds-g-font-weight-6, 600);
    border-radius: var(--slds-g-radius-border-2, 0.25rem);
    border: var(--slds-g-sizing-border-1) solid transparent;
    cursor: pointer;
    transition: background-color 150ms ease, border-color 150ms ease;
}

.recipe-btn--primary {
    background: var(--slds-g-color-accent-1, #0176d3);
    color: var(--slds-g-color-on-accent-1, #ffffff);
}

.recipe-btn--primary:hover {
    background: var(--slds-g-color-accent-2, #014486);
}

.recipe-btn--secondary {
    background: transparent;
    color: var(--slds-g-color-accent-1, #0176d3);
    border-color: var(--slds-g-color-border-1, #e5e5e5);
}

.recipe-btn--secondary:hover {
    background: var(--slds-g-color-surface-container-1, #f8f8f8);
}

.recipe-btn--ghost {
    background: transparent;
    color: var(--slds-g-color-on-surface-1, #181818);
    border-color: transparent;
}

.recipe-btn--ghost:hover {
    background: var(--slds-g-color-surface-3, #f3f3f3);
}

.recipe-btn:focus-visible {
    outline: 2px solid var(--slds-g-color-accent-1, #0176d3);
    outline-offset: 2px;
}

.recipe-btn:disabled {
    background: var(--slds-g-color-disabled-container-1, #ecebea);
    color: var(--slds-g-color-on-disabled-1, #706e6b);
    cursor: not-allowed;
    border-color: transparent;
}
```

### Modal / Dialog Overlay

```css
.recipe-overlay {
    position: fixed;
    inset: 0;
    background: rgba(0, 0, 0, 0.5);
    display: flex;
    align-items: center;
    justify-content: center;
    z-index: 9000;
}

.recipe-dialog {
    background: var(--slds-g-color-surface-1, #ffffff);
    border-radius: var(--slds-g-radius-border-3, 0.5rem);
    box-shadow: var(--slds-g-shadow-4);
    max-width: 600px;
    width: 90%;
    max-height: 80vh;
    overflow-y: auto;
}

.recipe-dialog__header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: var(--slds-g-spacing-4, 1rem);
    border-bottom: var(--slds-g-sizing-border-1) solid var(--slds-g-color-border-1, #e5e5e5);
}

.recipe-dialog__body {
    padding: var(--slds-g-spacing-4, 1rem);
}

.recipe-dialog__footer {
    display: flex;
    justify-content: flex-end;
    gap: var(--slds-g-spacing-3, 0.75rem);
    padding: var(--slds-g-spacing-3, 0.75rem) var(--slds-g-spacing-4, 1rem);
    border-top: var(--slds-g-sizing-border-1) solid var(--slds-g-color-border-1, #e5e5e5);
}
```

---

## CSS Composition Patterns

### Layering Hooks for Complex Effects

Combine SLDS hooks to create sophisticated visual treatments without hardcoded values.

```css
/* Glassmorphism-inspired panel using SLDS hooks */
.frosted-panel {
    background: var(--slds-g-color-surface-1, #ffffff);
    border: var(--slds-g-sizing-border-1) solid var(--slds-g-color-border-1, #e5e5e5);
    border-radius: var(--slds-g-radius-border-3, 0.5rem);
    box-shadow: var(--slds-g-shadow-3);
    backdrop-filter: blur(8px);
}

/* Gradient accent bar using accessible palette */
.accent-bar {
    height: var(--slds-g-spacing-1, 0.25rem);
    background: linear-gradient(
        90deg,
        var(--slds-g-color-accent-1, #0176d3),
        var(--slds-g-color-accent-3, #1b96ff)
    );
    border-radius: var(--slds-g-radius-border-pill) var(--slds-g-radius-border-pill) 0 0;
}
```

### Status Indicator Pattern

Reusable status dot + text pattern using feedback colors.

```css
.status-indicator {
    display: inline-flex;
    align-items: center;
    gap: var(--slds-g-spacing-2, 0.5rem);
    font-size: var(--slds-g-font-size-3, 0.8125rem);
}

.status-dot {
    width: var(--slds-g-sizing-1, 0.5rem);
    height: var(--slds-g-sizing-1, 0.5rem);
    border-radius: var(--slds-g-radius-circle);
    flex-shrink: 0;
}

.status-dot--active { background: var(--slds-g-color-success-1, #2e844a); }
.status-dot--warning { background: var(--slds-g-color-warning-1, #dd7a01); }
.status-dot--error { background: var(--slds-g-color-error-1, #ea001e); }
.status-dot--inactive { background: var(--slds-g-color-disabled-1, #c9c7c5); }
```

---

## Scoring Rubric (100 Points)

| Category | Points | Pass Criteria |
|----------|--------|---------------|
| **SLDS Hook Usage** | 25 | All visual values come from `--slds-g-*` hooks; zero hardcoded colors/sizes |
| **Utility Class Quality** | 20 | Reusable, semantic naming; follows `.util-*` or `.recipe-*` conventions |
| **Composition** | 20 | CSS classes combine cleanly; no `!important`; no deep nesting (max 2 levels) |
| **Fallback Values** | 15 | Every `var()` includes a fallback for resilience |
| **Theme-Safe** | 10 | All patterns use `--slds-g-*` hooks; no hardcoded values that break under alternate themes |
| **Performance** | 10 | No redundant declarations; efficient selectors; no `*` wildcards |

### Scoring Guide

- **90-100**: Exemplary — clean utility system, fully SLDS-native, composable
- **70-89**: Good — minor hardcoded values or missing fallbacks
- **50-69**: Needs rework — inconsistent naming, hardcoded colors
- **Below 50**: Not utility-first — monolithic CSS, heavy overrides

---

## Cross-Skill Integration

| Skill | Relationship |
|-------|-------------|
| **sf-lwc-design** | Provides the SLDS 2 hook reference that all utility classes map to |
| **sf-lwc-ux** | UX patterns (loading, empty, error states) use these utility classes |
| **sf-lwc** | Provides JS logic, wire service, events — this skill handles the CSS layer |

---

## Anti-Patterns

| Do NOT | Do Instead |
|--------|------------|
| `color: #181818` | `color: var(--slds-g-color-on-surface-1, #181818)` |
| `padding: 16px` | `padding: var(--slds-g-spacing-4, 1rem)` |
| `border-radius: 8px` | `border-radius: var(--slds-g-radius-border-3, 0.5rem)` |
| `.slds-m-bottom_medium` (SLDS 1) | `margin-bottom: var(--slds-g-spacing-4)` |
| `!important` overrides | Specificity via component scoping |
| Deeply nested selectors | Flat utility classes (max 2 levels) |

---

## Dependencies

- Target org with LWC support (API 45.0+)
- SLDS 2 recommended (API 62.0+) for full styling hook support
- No build tools, no npm packages, no static resources required
