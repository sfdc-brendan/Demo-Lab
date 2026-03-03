---
name: sf-lwc-page-composition
description: >
  App Builder-aware component design for Lightning Web Components. Covers Lightning
  page column layouts, component configuration via meta.xml targets, consistent card
  height/alignment, cross-component communication contracts (LMS, events, URL params),
  and design-time preview patterns. Use when building components for record pages,
  app pages, home pages, or when the user mentions App Builder, page layout, record
  page, component placement, or configurable components.
license: MIT
metadata:
  version: "1.0.0"
  author: "Brendan Sheridan"
  scoring: "100 points across 6 categories"
---

# sf-lwc-page-composition: App Builder-Aware LWC Design

Build Lightning Web Components that are excellent citizens on Lightning pages. Components must look great standalone and alongside other components in App Builder's column layouts.

## Core Principles

1. **Fluid, not fixed** — components fill their column, never overflow
2. **Configurable** — expose meaningful properties in App Builder
3. **Consistent height** — cards in the same row should align visually
4. **Communicate cleanly** — use LMS for cross-DOM, events for parent-child
5. **Design-time friendly** — show useful previews in App Builder

---

## App Builder Column Layouts

Lightning pages use a region-based grid. Components must adapt to these widths.

| Layout | Regions | Approximate Widths |
|--------|---------|-------------------|
| Single column | 1 | ~100% (1200px max) |
| Two column (66/33) | 2 | ~780px / ~380px |
| Two column (50/50) | 2 | ~580px / ~580px |
| Three column (25/50/25) | 3 | ~280px / ~580px / ~280px |
| Three column (33/33/33) | 3 | ~380px / ~380px / ~380px |

### Designing for All Columns

```css
:host {
    display: block;
    width: 100%;
    contain: layout;
}

.component-root {
    background: var(--slds-g-color-surface-1, #ffffff);
    border: var(--slds-g-sizing-border-1) solid var(--slds-g-color-border-1, #e5e5e5);
    border-radius: var(--slds-g-radius-border-2, 0.25rem);
    overflow: hidden;
}
```

### Content Reflow Rules

| Column Width | Layout Behavior |
|-------------|----------------|
| >= 580px | Multi-column grids, side-by-side metrics |
| 380-579px | Two-column grids collapse to single, stacked layout |
| 280-379px | Single column, compact spacing, abbreviated labels |

```css
.content-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
    gap: var(--slds-g-spacing-3, 0.75rem);
}
```

---

## meta.xml Configuration

### Exposing Properties in App Builder

```xml
<?xml version="1.0" encoding="UTF-8"?>
<LightningComponentBundle xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>62.0</apiVersion>
    <isExposed>true</isExposed>
    <masterLabel>Account Overview Card</masterLabel>
    <description>Displays key account metrics with configurable sections.</description>
    <targets>
        <target>lightning__RecordPage</target>
        <target>lightning__AppPage</target>
        <target>lightning__HomePage</target>
    </targets>
    <targetConfigs>
        <targetConfig targets="lightning__RecordPage">
            <objects>
                <object>Account</object>
                <object>Contact</object>
            </objects>
            <property name="showMetrics" type="Boolean" label="Show Metrics"
                      description="Display metric cards" default="true" />
            <property name="showChart" type="Boolean" label="Show Chart"
                      description="Display trend chart" default="true" />
            <property name="maxItems" type="Integer" label="Max Items"
                      description="Maximum items to display" default="5"
                      min="1" max="20" />
            <property name="variant" type="String" label="Card Style"
                      datasource="Default,Compact,Detailed"
                      default="Default" />
        </targetConfig>
        <targetConfig targets="lightning__AppPage,lightning__HomePage">
            <property name="title" type="String" label="Card Title"
                      default="Account Overview" />
        </targetConfig>
    </targetConfigs>
</LightningComponentBundle>
```

### Property Type Reference

| Type | Use For | Notes |
|------|---------|-------|
| `String` | Labels, field names | Use `datasource` for picklists |
| `Boolean` | Toggle sections on/off | Default should be the common case |
| `Integer` | Counts, limits | Use `min`/`max` for validation |
| `Color` | Theme accents | Renders a color picker in App Builder |

### Property Best Practices

- Limit to 5-7 properties per target config (avoid overwhelming admins)
- Group related toggles: `showHeader`, `showMetrics`, `showFooter`
- Provide sensible defaults so the component works with zero configuration
- Use `datasource` for string properties with known options instead of free text
- Separate target configs when Record Page needs different options than App Page

---

## Consistent Card Height and Alignment

When multiple components appear in the same row, misaligned heights look broken.

### Self-Sizing Card

```css
:host {
    display: block;
    height: 100%;
}

.card {
    display: flex;
    flex-direction: column;
    height: 100%;
    background: var(--slds-g-color-surface-1, #ffffff);
    border: var(--slds-g-sizing-border-1) solid var(--slds-g-color-border-1, #e5e5e5);
    border-radius: var(--slds-g-radius-border-2, 0.25rem);
}

.card__header {
    flex-shrink: 0;
    padding: var(--slds-g-spacing-3, 0.75rem) var(--slds-g-spacing-4, 1rem);
    border-bottom: var(--slds-g-sizing-border-1) solid var(--slds-g-color-border-1, #e5e5e5);
}

.card__body {
    flex: 1;
    overflow-y: auto;
    padding: var(--slds-g-spacing-4, 1rem);
}

.card__footer {
    flex-shrink: 0;
    padding: var(--slds-g-spacing-3, 0.75rem) var(--slds-g-spacing-4, 1rem);
    border-top: var(--slds-g-sizing-border-1) solid var(--slds-g-color-border-1, #e5e5e5);
    margin-top: auto;
}
```

### Fixed-Height Scrollable Body

For components that can have variable amounts of data:

```css
.card__body--scrollable {
    max-height: 400px;
    overflow-y: auto;
}
```

---

## Cross-Component Communication

### Decision Matrix

| Pattern | Direction | Scope | Use When |
|---------|-----------|-------|----------|
| `@api` properties | Parent to child | Same DOM tree | Passing data down |
| `CustomEvent` | Child to parent | Same DOM tree | Bubbling actions up |
| Lightning Message Service | Any to any | Same Lightning page | Cross-DOM, different components |
| URL parameters | Page to component | Navigation | Deep linking, page context |
| `lightning/navigation` | Component to page | App-wide | Record navigation, tab switching |

### Lightning Message Service Pattern

```javascript
import { publish, subscribe, unsubscribe, MessageContext } from 'lightning/messageService';
import RECORD_SELECTED from '@salesforce/messageChannel/RecordSelected__c';

@wire(MessageContext)
messageContext;

connectedCallback() {
    this._subscription = subscribe(
        this.messageContext,
        RECORD_SELECTED,
        (message) => this.handleRecordSelected(message)
    );
}

disconnectedCallback() {
    unsubscribe(this._subscription);
    this._subscription = null;
}

handleRecordSelected(message) {
    this.selectedRecordId = message.recordId;
}

publishSelection(recordId) {
    publish(this.messageContext, RECORD_SELECTED, { recordId });
}
```

---

## Design-Time Preview

Components should look meaningful in App Builder even without live data.

### Placeholder Pattern

```javascript
get isDesignMode() {
    return !this.recordId && !this._dataLoaded;
}

get displayData() {
    if (this.isDesignMode) {
        return this.placeholderData;
    }
    return this._liveData;
}

get placeholderData() {
    return [
        { id: '1', name: 'Sample Account', amount: '$125,000' },
        { id: '2', name: 'Example Corp', amount: '$89,000' },
        { id: '3', name: 'Demo Inc', amount: '$210,000' }
    ];
}
```

```html
<template>
    <div class={rootClass}>
        <div if:true={isDesignMode} class="design-mode-badge">
            Preview Mode
        </div>
        <!-- Component content renders with placeholder or live data -->
    </div>
</template>
```

```css
.design-mode-badge {
    position: absolute;
    top: var(--slds-g-spacing-2, 0.5rem);
    right: var(--slds-g-spacing-2, 0.5rem);
    padding: var(--slds-g-spacing-1, 0.25rem) var(--slds-g-spacing-2, 0.5rem);
    font-size: var(--slds-g-font-size-1, 0.625rem);
    background: var(--slds-g-color-info-container-1, #e5f0fb);
    color: var(--slds-g-color-info-1, #0176d3);
    border-radius: var(--slds-g-radius-border-1, 0.125rem);
}
```

---

## Scoring Rubric (100 Points)

| Category | Points | Pass Criteria |
|----------|--------|---------------|
| **Fluid Layout** | 20 | Works in all column widths; no overflow; reflows content |
| **meta.xml Quality** | 20 | Correct targets, sensible defaults, 5-7 configurable properties |
| **Card Consistency** | 15 | Full-height cards, aligned headers/footers, scrollable body |
| **Communication** | 20 | Correct pattern chosen per use case; LMS for cross-DOM |
| **Design-Time Preview** | 15 | Shows meaningful content in App Builder without live data |
| **Slot Architecture** | 10 | Uses `<slot>` for extensibility; allows parent customization |

---

## Cross-Skill Integration

| Skill | Relationship |
|-------|-------------|
| **sf-lwc-design** | Provides SLDS 2 hooks for all card/layout CSS |
| **sf-lwc-ux** | Loading/empty/error states must work in all column widths |
| **sf-lwc-styling** | Utility classes must be fluid-aware |
| **sf-lwc-mobile** | Small-column behavior mirrors mobile viewport patterns |
