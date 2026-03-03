---
name: sf-lwc-mobile
description: >
  Mobile-first design patterns for Lightning Web Components. Covers touch target
  sizing, thumb-zone-aware layouts, Salesforce Mobile App constraints, offline-capable
  UI patterns, responsive type scales, and swipe/tap interaction design mapped to
  SLDS 2 styling hooks. Use when building mobile LWC, optimizing for Salesforce Mobile,
  creating touch-friendly interfaces, or when the user mentions mobile, touch, responsive,
  phone, tablet, or Salesforce Mobile App.
license: MIT
metadata:
  version: "1.0.0"
  author: "Brendan Sheridan"
  scoring: "100 points across 6 categories"
---

# sf-lwc-mobile: Mobile-First Design for LWC

Build Lightning Web Components that work beautifully on the Salesforce Mobile App and mobile browsers. Design for touch first, then enhance for desktop.

## Core Principles

1. **Touch targets: 48px minimum** — fingers are not mouse cursors
2. **Thumb zone first** — critical actions in the bottom center of the screen
3. **Progressive enhancement** — works on mobile, enhanced on desktop
4. **Content priority** — show what matters most; hide the rest behind progressive disclosure
5. **Offline-aware** — graceful degradation when connectivity drops

---

## Touch Target Sizing

Every interactive element must be at least 48x48px (WCAG 2.5.8, Salesforce mobile guidelines).

### Minimum Sizes

| Element | Minimum Size | SLDS Hook |
|---------|-------------|-----------|
| Buttons | 48px height | `min-height: var(--slds-g-sizing-8, 2.5rem)` |
| Icon buttons | 48x48px | `min-width/min-height: var(--slds-g-sizing-8)` |
| List item rows | 48px height | `min-height: var(--slds-g-sizing-8)` |
| Checkbox/radio hit area | 48x48px | Padding around the input |
| Links in body text | 48px line-height | `line-height: var(--slds-g-sizing-8)` |

### Touch Target CSS

```css
.touch-target {
    min-height: 48px;
    min-width: 48px;
    display: flex;
    align-items: center;
    justify-content: center;
    padding: var(--slds-g-spacing-2, 0.5rem);
}

.touch-list-item {
    min-height: 48px;
    padding: var(--slds-g-spacing-3, 0.75rem) var(--slds-g-spacing-4, 1rem);
    display: flex;
    align-items: center;
    gap: var(--slds-g-spacing-3, 0.75rem);
    border-bottom: var(--slds-g-sizing-border-1) solid var(--slds-g-color-border-2, #eeeeee);
}

/* Spacing between adjacent touch targets */
.touch-actions {
    display: flex;
    gap: var(--slds-g-spacing-3, 0.75rem);
}
```

---

## Thumb Zone Layout

On mobile, the bottom-center of the screen is the easiest area to reach. Design layouts with this in mind.

```
┌─────────────────────┐
│   Hard to reach      │  ← Status bar, read-only info
│                     │
│   Comfortable        │  ← Scrollable content
│                     │
│ ████ Easy ████      │  ← Primary actions, navigation
└─────────────────────┘
```

### Bottom Action Bar

```html
<template>
    <div class="mobile-layout">
        <div class="mobile-content">
            <slot></slot>
        </div>
        <div class="mobile-action-bar">
            <lightning-button label="Cancel" onclick={handleCancel}></lightning-button>
            <lightning-button label="Save" variant="brand" onclick={handleSave}></lightning-button>
        </div>
    </div>
</template>
```

```css
.mobile-layout {
    display: flex;
    flex-direction: column;
    height: 100%;
}

.mobile-content {
    flex: 1;
    overflow-y: auto;
    padding: var(--slds-g-spacing-4, 1rem);
    -webkit-overflow-scrolling: touch;
}

.mobile-action-bar {
    display: flex;
    gap: var(--slds-g-spacing-3, 0.75rem);
    padding: var(--slds-g-spacing-3, 0.75rem) var(--slds-g-spacing-4, 1rem);
    background: var(--slds-g-color-surface-1, #ffffff);
    border-top: var(--slds-g-sizing-border-1) solid var(--slds-g-color-border-1, #e5e5e5);
    box-shadow: var(--slds-g-shadow-2);
}

.mobile-action-bar > * {
    flex: 1;
}
```

---

## Salesforce Mobile App Constraints

| Constraint | Impact | Workaround |
|-----------|--------|------------|
| No custom fonts | Cannot load web fonts | Rely on system font stack via SLDS |
| Limited viewport (~375px) | Content must fit narrow screens | Use single-column layout |
| No browser DevTools | Harder to debug | Use `console.log` + Salesforce Mobile debug mode |
| Slower network | Data loads feel sluggish | Skeleton screens, cache wire results |
| No `:hover` on touch | Hover-only interactions break | Use `:active` and tap feedback instead |
| Status bar insets | Content can be hidden | Respect `safe-area-inset-*` |

### Mobile-Safe Interaction Replacement

```css
/* Desktop: hover */
@media (hover: hover) {
    .list-item:hover {
        background: var(--slds-g-color-surface-3, #f3f3f3);
    }
}

/* Mobile: active (tap feedback) */
.list-item:active {
    background: var(--slds-g-color-accent-container-1, #e5f0fb);
}
```

---

## Responsive Patterns

### Single-Column Mobile, Multi-Column Desktop

```css
.responsive-layout {
    display: grid;
    grid-template-columns: 1fr;
    gap: var(--slds-g-spacing-4, 1rem);
}

@media (min-width: 768px) {
    .responsive-layout {
        grid-template-columns: 1fr 1fr;
    }
}

@media (min-width: 1024px) {
    .responsive-layout {
        grid-template-columns: 1fr 1fr 1fr;
    }
}
```

### Mobile-First Typography

```css
.page-title {
    font-size: var(--slds-g-font-size-7, 1.25rem);
    font-weight: var(--slds-g-font-weight-7, 700);
    line-height: var(--slds-g-line-height-2, 1.25);
}

@media (min-width: 768px) {
    .page-title {
        font-size: var(--slds-g-font-size-9, 1.75rem);
    }
}
```

### Collapsible Sections for Mobile

```html
<template>
    <div class="collapsible">
        <button class="collapsible__trigger touch-target"
                onclick={handleToggle}
                aria-expanded={isExpanded}>
            <span>{sectionTitle}</span>
            <lightning-icon
                icon-name={expandIcon}
                size="x-small">
            </lightning-icon>
        </button>
        <div class={sectionClass}>
            <slot></slot>
        </div>
    </div>
</template>
```

```css
.collapsible__trigger {
    width: 100%;
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: var(--slds-g-spacing-3, 0.75rem) var(--slds-g-spacing-4, 1rem);
    background: var(--slds-g-color-surface-container-1, #f8f8f8);
    border: none;
    border-bottom: var(--slds-g-sizing-border-1) solid var(--slds-g-color-border-1, #e5e5e5);
    cursor: pointer;
    font-size: var(--slds-g-font-size-4, 0.875rem);
    font-weight: var(--slds-g-font-weight-6, 600);
    color: var(--slds-g-color-on-surface-1, #181818);
}

.collapsible__content {
    max-height: 0;
    overflow: hidden;
    transition: max-height 200ms ease-out;
}

.collapsible__content--open {
    max-height: 2000px;
}
```

---

## Offline-Capable UI Patterns

### Cached State Display

```javascript
@wire(getRecord, { recordId: '$recordId', fields: FIELDS })
wiredRecord({ error, data }) {
    if (data) {
        this._cachedData = data;
        this._isOffline = false;
    } else if (error) {
        if (this._cachedData) {
            this._isOffline = true;
        } else {
            this._hasError = true;
        }
    }
}
```

```html
<template>
    <div if:true={_isOffline} class="offline-banner" role="status">
        <lightning-icon icon-name="utility:offline" size="x-small"></lightning-icon>
        <span>Showing cached data. Changes will sync when online.</span>
    </div>
</template>
```

```css
.offline-banner {
    display: flex;
    align-items: center;
    gap: var(--slds-g-spacing-2, 0.5rem);
    padding: var(--slds-g-spacing-2, 0.5rem) var(--slds-g-spacing-4, 1rem);
    background: var(--slds-g-color-warning-container-1, #fef4e6);
    color: var(--slds-g-color-warning-1, #dd7a01);
    font-size: var(--slds-g-font-size-2, 0.75rem);
    border-bottom: var(--slds-g-sizing-border-1) solid var(--slds-g-color-border-warning-1);
}
```

---

## Scoring Rubric (100 Points)

| Category | Points | Pass Criteria |
|----------|--------|---------------|
| **Touch Targets** | 25 | All interactive elements >= 48px; adequate spacing between targets |
| **Layout** | 20 | Single-column mobile, thumb-zone actions, no horizontal overflow |
| **Responsive** | 20 | Adapts to mobile/tablet/desktop; mobile-first CSS |
| **Interaction** | 15 | Tap feedback (`:active`), no hover-only interactions, swipe support |
| **Performance** | 10 | Skeleton loading, minimal DOM, efficient CSS |
| **Offline Awareness** | 10 | Graceful degradation, cached data display, connectivity indicators |

---

## Cross-Skill Integration

| Skill | Relationship |
|-------|-------------|
| **sf-lwc-design** | Provides SLDS 2 hooks for all mobile CSS |
| **sf-lwc-ux** | Loading/error states especially critical on slow mobile networks |
| **sf-lwc-styling** | Utility classes adapted for mobile (`.util-stack` works well on small screens) |
| **sf-lwc-motion** | Reduced motion critical on mobile for performance |
