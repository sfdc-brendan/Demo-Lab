---
name: sf-lwc-ux
description: >
  UX patterns, interaction design, and accessibility for Lightning Web Components.
  Applies Shadcn-inspired component composition, modern interaction patterns (loading states,
  skeleton screens, empty states, error boundaries), WCAG 2.1 AA accessibility, and
  responsive layout design within LWC platform constraints. Use when building LWC user
  interfaces, improving UX quality, adding accessibility, creating layouts, or when the user
  mentions UX, accessibility, a11y, responsive, loading states, or user experience.
license: MIT
metadata:
  version: "1.0.0"
  author: "Brendan Sheridan"
  scoring: "100 points across 6 categories"
---

# sf-lwc-ux: UX Patterns and Accessibility

Build Lightning Web Components with best-of-class user experience. Apply modern web UX patterns (inspired by Shadcn's composable philosophy) within the Salesforce platform, ensuring WCAG 2.1 AA accessibility.

## Core Principles

1. **Composable over monolithic** — small, focused components that slot together
2. **Every state has a UI** — loading, empty, error, success, partial
3. **Keyboard-first** — all interactions reachable without a mouse
4. **Progressive disclosure** — show what's needed, reveal on demand
5. **Consistent feedback** — users always know what happened and what to do next

---

## Component Composition (Shadcn-Inspired)

Adopt the "open code, own your components" philosophy. Build a library of small, composable primitives rather than large all-in-one components.

### Composition Hierarchy

```
Page Layout (grid/split/stack)
  └── Section (card, panel, collapsible)
       └── Content Block (list, table, form group)
            └── Primitive (badge, pill, metric, avatar)
```

### Slot-Based Composition

```html
<!-- Parent: composes child components via slots -->
<template>
    <c-section-card title="Customer Overview">
        <c-metric-row slot="header-metrics"
            label="Health Score" value={healthScore} variant="success">
        </c-metric-row>
        <c-contact-list slot="body" contacts={contacts}></c-contact-list>
        <div slot="footer">
            <lightning-button label="View All" onclick={handleViewAll}></lightning-button>
        </div>
    </c-section-card>
</template>
```

### Component API Design

Follow consistent `@api` conventions across all components:

| Prop Pattern | Type | Purpose |
|-------------|------|---------|
| `variant` | String | Visual style: `"default"`, `"success"`, `"warning"`, `"error"`, `"info"` |
| `size` | String | Dimensions: `"small"`, `"medium"`, `"large"` |
| `label` | String | Accessible visible text |
| `disabled` | Boolean | Disable interaction |
| `loading` | Boolean | Show loading state |

---

## Layout Patterns

### Card Grid (Dashboard)

Responsive card grid that adapts to container width using CSS-only (no JS resize observers).

```css
.card-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
    gap: var(--slds-g-spacing-4, 1rem);
    padding: var(--slds-g-spacing-4, 1rem);
}
```

### Split View (Master-Detail)

```css
.split-view {
    display: grid;
    grid-template-columns: 320px 1fr;
    gap: var(--slds-g-spacing-4, 1rem);
    height: 100%;
}

.split-view__list {
    overflow-y: auto;
    border-right: var(--slds-g-sizing-border-1) solid var(--slds-g-color-border-1, #e5e5e5);
}

.split-view__detail {
    overflow-y: auto;
    padding: var(--slds-g-spacing-4, 1rem);
}
```

### Stacked Form

```css
.form-stack {
    display: flex;
    flex-direction: column;
    gap: var(--slds-g-spacing-4, 1rem);
    max-width: 600px;
}

.form-stack__section {
    padding: var(--slds-g-spacing-4, 1rem);
    background: var(--slds-g-color-surface-1, #ffffff);
    border-radius: var(--slds-g-radius-border-2, 0.25rem);
    border: var(--slds-g-sizing-border-1) solid var(--slds-g-color-border-1, #e5e5e5);
}

.form-stack__actions {
    display: flex;
    justify-content: flex-end;
    gap: var(--slds-g-spacing-3, 0.75rem);
    padding-top: var(--slds-g-spacing-4, 1rem);
    border-top: var(--slds-g-sizing-border-1) solid var(--slds-g-color-border-1, #e5e5e5);
}
```

---

## Interaction Patterns

### Loading States

Always show a loading indicator. Never leave the user staring at a blank screen.

```html
<template>
    <!-- Skeleton: structural placeholder while data loads -->
    <template if:true={isLoading}>
        <div class="skeleton-card">
            <div class="skeleton-line skeleton-line--title"></div>
            <div class="skeleton-line skeleton-line--body"></div>
            <div class="skeleton-line skeleton-line--body skeleton-line--short"></div>
        </div>
    </template>

    <!-- Content: rendered after data arrives -->
    <template if:false={isLoading}>
        <div class="content-card">
            <h2>{title}</h2>
            <p>{description}</p>
        </div>
    </template>
</template>
```

```css
.skeleton-line {
    height: var(--slds-g-spacing-3, 0.75rem);
    background: var(--slds-g-color-surface-container-2, #f3f3f3);
    border-radius: var(--slds-g-radius-border-1, 0.125rem);
    margin-bottom: var(--slds-g-spacing-2, 0.5rem);
    animation: pulse 1.5s ease-in-out infinite;
}

.skeleton-line--title {
    width: 40%;
    height: var(--slds-g-spacing-4, 1rem);
}

.skeleton-line--short { width: 60%; }

@keyframes pulse {
    0%, 100% { opacity: 1; }
    50% { opacity: 0.4; }
}
```

### Empty States

Provide guidance, not just "No records found."

```html
<template>
    <template if:true={isEmpty}>
        <div class="empty-state" role="status">
            <lightning-icon icon-name="utility:info" size="large"></lightning-icon>
            <h3 class="empty-state__title">{emptyTitle}</h3>
            <p class="empty-state__message">{emptyMessage}</p>
            <lightning-button
                if:true={showAction}
                label={emptyActionLabel}
                variant="brand"
                onclick={handleEmptyAction}>
            </lightning-button>
        </div>
    </template>
</template>
```

```css
.empty-state {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: var(--slds-g-spacing-3, 0.75rem);
    padding: var(--slds-g-spacing-8, 2rem) var(--slds-g-spacing-4, 1rem);
    text-align: center;
    color: var(--slds-g-color-on-surface-2, #444444);
}

.empty-state__title {
    font-size: var(--slds-g-font-size-5, 1rem);
    font-weight: var(--slds-g-font-weight-6, 600);
    color: var(--slds-g-color-on-surface-1, #181818);
}
```

### Error Boundaries

Catch and display errors gracefully. Never show raw error text to users.

```html
<template>
    <template if:true={hasError}>
        <div class="error-boundary" role="alert">
            <lightning-icon icon-name="utility:error" variant="error" size="small"></lightning-icon>
            <div class="error-boundary__content">
                <p class="error-boundary__title">Something went wrong</p>
                <p class="error-boundary__detail">{userFriendlyError}</p>
                <lightning-button label="Try Again" onclick={handleRetry} variant="neutral">
                </lightning-button>
            </div>
        </div>
    </template>
</template>
```

```css
.error-boundary {
    display: flex;
    gap: var(--slds-g-spacing-3, 0.75rem);
    padding: var(--slds-g-spacing-4, 1rem);
    background: var(--slds-g-color-error-container-1, #fef1f1);
    border: var(--slds-g-sizing-border-1) solid var(--slds-g-color-border-error-1, #ea001e);
    border-radius: var(--slds-g-radius-border-2, 0.25rem);
}
```

### Toast / Inline Notifications

Use `lightning/platformShowToastEvent` for transient feedback. Use inline alerts for persistent messages.

```javascript
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

handleSuccess() {
    this.dispatchEvent(new ShowToastEvent({
        title: 'Record Saved',
        message: 'Account has been updated successfully.',
        variant: 'success'
    }));
}
```

### Optimistic Updates

Update the UI immediately, then reconcile with the server response.

```javascript
async handleToggleFavorite() {
    const previousState = this._isFavorite;
    this._isFavorite = !this._isFavorite; // optimistic

    try {
        await toggleFavorite({ recordId: this.recordId });
    } catch (error) {
        this._isFavorite = previousState; // rollback
        this.dispatchEvent(new ShowToastEvent({
            title: 'Error',
            message: 'Could not update favorite status.',
            variant: 'error'
        }));
    }
}
```

---

## Micro-Interactions

### Focus Rings

All interactive elements must have visible focus indicators.

```css
:host {
    --focus-ring-color: var(--slds-g-color-accent-1, #0176d3);
    --focus-ring-offset: 2px;
}

.interactive:focus-visible {
    outline: 2px solid var(--focus-ring-color);
    outline-offset: var(--focus-ring-offset);
    border-radius: var(--slds-g-radius-border-1, 0.125rem);
}
```

### Hover States

```css
.list-item {
    transition: background-color 150ms ease;
}

.list-item:hover {
    background-color: var(--slds-g-color-surface-3, #f3f3f3);
}

.list-item:active {
    background-color: var(--slds-g-color-accent-container-1, #e5f0fb);
}
```

### Transitions

Use short, purposeful transitions. Avoid decorative animation.

```css
.expandable {
    overflow: hidden;
    max-height: 0;
    transition: max-height 200ms ease-out;
}

.expandable--open {
    max-height: 500px;
}
```

---

## Accessibility (WCAG 2.1 AA)

### ARIA Checklist

| Requirement | Implementation |
|-------------|----------------|
| Interactive elements labeled | `aria-label` or visible `<label>` on every input/button |
| Dynamic content announced | `role="status"` or `role="alert"` on live regions |
| Custom widgets have roles | `role="tablist"`, `role="tab"`, `role="tabpanel"` |
| Expanded/collapsed state | `aria-expanded="true/false"` on toggles |
| Loading announced | `aria-busy="true"` on container during load |
| Disabled communicated | `aria-disabled="true"` + visual indicator |

### Keyboard Navigation

| Pattern | Keys | Behavior |
|---------|------|----------|
| **Tab order** | Tab / Shift+Tab | Move through interactive elements in DOM order |
| **Action** | Enter / Space | Activate buttons, links, checkboxes |
| **List navigation** | Arrow Up/Down | Move through list items, menu options |
| **Tab panel** | Arrow Left/Right | Switch between tabs |
| **Escape** | Esc | Close modal, dismiss popover, cancel action |

```javascript
handleKeyDown(event) {
    switch (event.key) {
        case 'ArrowDown':
            event.preventDefault();
            this.focusNextItem();
            break;
        case 'ArrowUp':
            event.preventDefault();
            this.focusPreviousItem();
            break;
        case 'Enter':
        case ' ':
            event.preventDefault();
            this.selectCurrentItem();
            break;
        case 'Escape':
            this.closeDropdown();
            break;
        default:
            break;
    }
}
```

### Focus Management

```javascript
handleOpenModal() {
    this.isModalOpen = true;
    // After render, move focus to the modal's first focusable element
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    setTimeout(() => {
        const firstFocusable = this.template.querySelector('[data-first-focus]');
        if (firstFocusable) firstFocusable.focus();
    }, 0);
}

handleCloseModal() {
    this.isModalOpen = false;
    // Return focus to the trigger element
    const trigger = this.template.querySelector('[data-modal-trigger]');
    if (trigger) trigger.focus();
}
```

### Color Contrast

Use SLDS accessible color palettes (`--slds-g-color-*-base-*`) to guarantee 4.5:1 contrast ratio for normal text and 3:1 for large text. Never rely on color alone to convey meaning — always pair with icons or text labels.

---

## Responsive Design in LWC

LWC shadow DOM prevents global media queries from targeting component internals. Use these CSS-only patterns:

### Container-Based Sizing

```css
.responsive-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));
    gap: var(--slds-g-spacing-4, 1rem);
}
```

### Flexible Wrapping

```css
.metric-row {
    display: flex;
    flex-wrap: wrap;
    gap: var(--slds-g-spacing-3, 0.75rem);
}

.metric-item {
    flex: 1 1 150px;
    min-width: 0;
}
```

### Clamp for Typography

```css
.hero-title {
    font-size: clamp(
        var(--slds-g-font-size-5, 1rem),
        4vw,
        var(--slds-g-font-size-9, 1.75rem)
    );
}
```

---

## Scoring Rubric (100 Points)

| Category | Points | Pass Criteria |
|----------|--------|---------------|
| **State Management** | 20 | All states covered: loading, empty, error, success, partial data |
| **Accessibility** | 25 | ARIA labels, keyboard nav, focus management, screen reader support |
| **Layout Quality** | 15 | Responsive grid/flex, no fixed pixel widths, proper spacing scale |
| **Interaction Design** | 15 | Hover/focus/active states, transitions, toasts for feedback |
| **Component Composition** | 15 | Slot-based, consistent @api, composable hierarchy |
| **Responsive** | 10 | Works across viewport sizes using CSS-only techniques |

### Scoring Guide

- **90-100**: Exceptional UX — all states, fully accessible, responsive
- **70-89**: Good UX — minor missing states or accessibility gaps
- **50-69**: Needs improvement — missing loading/empty states, weak keyboard support
- **Below 50**: Major UX issues — no error handling, inaccessible

---

## Cross-Skill Integration

| Skill | Relationship |
|-------|-------------|
| **sf-lwc** | Provides JS patterns (wire, Apex, events) that this skill's UX patterns wrap |
| **sf-lwc-design** | Provides the SLDS 2 hooks used in all CSS examples above |
| **sf-lwc-styling** | Provides utility classes that implement these UX patterns efficiently |

---

## Dependencies

- Target org with LWC support (API 45.0+)
- SLDS 2 recommended (API 62.0+) for full styling hook support
- `sf` CLI authenticated
