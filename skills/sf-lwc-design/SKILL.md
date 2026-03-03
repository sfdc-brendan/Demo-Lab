---
name: sf-lwc-design
description: >
  SLDS 2 design system foundation for Lightning Web Components. Generates LWC
  with correct global styling hooks (--slds-g-*), surface/accent/feedback color systems,
  theme-safe styling (light mode default, dark mode opt-in), and proper component
  structure. Use when creating LWC components, styling LWC, applying SLDS 2 tokens,
  migrating from SLDS 1, or when the user mentions design system, theming, or SLDS 2.
license: MIT
metadata:
  version: "1.0.0"
  author: "Brendan Sheridan"
  scoring: "100 points across 6 categories"
---

# sf-lwc-design: SLDS 2 Design System Foundation

Generate Lightning Web Components that are fully compliant with SLDS 2 (Salesforce Cosmos theme). All styling must use global styling hooks (`--slds-g-*`) — never hardcoded values.

## Core Rules

1. **Always use `--slds-g-*` CSS custom properties** for colors, spacing, sizing, typography, shadows, and radii
2. **Never hardcode** hex colors, pixel sizes, or font stacks
3. **Always provide fallback values** in `var()` for resilience
4. **Prefer `lightning-*` base components** over custom HTML where available
5. **Structure CSS** with semantic intent, not visual description

---

## SLDS 2 Architecture

SLDS 2 decouples **structure** (layout, spacing) from **visual design** (colors, radii, shadows). This enables theme switching (light/dark/custom) without component changes.

```
┌─────────────────────────────────────────┐
│  Theme Layer (Cosmos, custom, dark)     │  --slds-g-color-*, --slds-g-shadow-*
├─────────────────────────────────────────┤
│  Structure Layer (layout, spacing)      │  --slds-g-spacing-*, --slds-g-sizing-*
├─────────────────────────────────────────┤
│  Component Layer (lightning-*, LWC)     │  Consumes hooks, never overrides them
└─────────────────────────────────────────┘
```

---

## Global Styling Hooks Reference

### Surface Colors

Use for backgrounds, text on backgrounds, and borders of content areas.

| Hook | Purpose | Example Use |
|------|---------|-------------|
| `--slds-g-color-surface-1` | Primary background | Page/card background |
| `--slds-g-color-surface-2` | Secondary background | Nested card, sidebar |
| `--slds-g-color-surface-3` | Tertiary background | Hover row highlight |
| `--slds-g-color-surface-container-1` | Container background | Outer wrapper |
| `--slds-g-color-surface-container-2` | Nested container | Inner panel |
| `--slds-g-color-surface-container-3` | Deep nested container | Collapsible section |
| `--slds-g-color-on-surface-1` | Primary text | Body text |
| `--slds-g-color-on-surface-2` | Secondary text | Labels, captions |
| `--slds-g-color-on-surface-3` | Tertiary text | Placeholder, disabled |
| `--slds-g-color-border-1` | Default border | Card border, dividers |
| `--slds-g-color-border-2` | Subtle border | Inner separators |

### Accent Colors

Use for interactive elements, links, and branded highlights.

| Hook | Purpose |
|------|---------|
| `--slds-g-color-accent-1` | Primary interactive (links, active) |
| `--slds-g-color-accent-2` | Secondary interactive |
| `--slds-g-color-accent-3` | Tertiary interactive |
| `--slds-g-color-accent-container-1` | Active/selected background |
| `--slds-g-color-on-accent-1` | Text on accent background |
| `--slds-g-color-border-accent-1` | Active/focus border |

### Feedback Colors

Use for status indicators, alerts, and validation states.

| State | Color | Container | Text | Border |
|-------|-------|-----------|------|--------|
| **Error** | `error-1`, `error-2` | `error-container-1` | `on-error-1` | `border-error-1` |
| **Warning** | `warning-1`, `warning-2` | `warning-container-1` | `on-warning-1` | `border-warning-1` |
| **Success** | `success-1`, `success-2` | `success-container-1` | `on-success-1` | `border-success-1` |
| **Info** | `info-1`, `info-2` | `info-container-1` | `on-info-1` | — |
| **Disabled** | `disabled-1`, `disabled-2` | `disabled-container-1` | `on-disabled-1` | `border-disabled-1` |

All hooks above are prefixed with `--slds-g-color-`. Example: `var(--slds-g-color-error-1)`.

### Typography

| Hook | Purpose |
|------|---------|
| `--slds-g-font-size-1` through `-15` | Font size scale (1 = smallest) |
| `--slds-g-font-size-base` | Root font size |
| `--slds-g-font-weight-1` through `-7` | Weight scale (4 = normal, 7 = bold) |
| `--slds-g-line-height-1` through `-5` | Line height scale (unitless) |

### Spacing

Use for margin and padding. Do **not** use for width/height (use sizing instead).

| Hook | Scale |
|------|-------|
| `--slds-g-spacing-1` through `-12` | Modular scale of 4, relative to root font size |

### Sizing

Use for element dimensions (width, height, icons).

| Hook | Scale |
|------|-------|
| `--slds-g-sizing-1` through `-12` | Relative to root font size |

### Shadows and Borders

| Hook | Purpose |
|------|---------|
| `--slds-g-shadow-1` through `-4` | Elevation layers (1 = subtle, 4 = prominent) |
| `--slds-g-radius-border-1` through `-4` | Corner radius scale |
| `--slds-g-radius-circle` | Circle (50%) |
| `--slds-g-radius-border-pill` | Pill shape |
| `--slds-g-sizing-border-1` through `-4` | Border width scale |

---

## Theme-Safe Styling

Components use **light mode by default**. By using `--slds-g-*` hooks instead of hardcoded values, components automatically adapt if an org later enables dark mode (Cosmos dark theme) — no code changes needed. Dark mode is an opt-in enhancement, not a default requirement.

**Before adding dark mode support, ask the user**: "Do you want this component to support dark mode, or is light mode sufficient?"

### Rules (Apply Always — Light and Dark)

- **No hex/rgb/hsl literals** in CSS — always `var(--slds-g-color-*)`
- **No inline color styles** in HTML templates
- **Provide fallbacks**: `var(--slds-g-color-surface-1, #ffffff)` (fallback to light mode values)
- **Icons**: Use `lightning-icon` with SLDS utility sprites, never custom SVGs with hardcoded fill

### Additional Rules (Only When Dark Mode Requested)

- **Images**: Use `mix-blend-mode` or CSS filters when images must adapt to dark backgrounds
- **Test in both themes**: Verify all text is readable and contrast ratios meet WCAG AA in both light and dark

### CSS Pattern

```css
.card {
    background-color: var(--slds-g-color-surface-1, #ffffff);
    color: var(--slds-g-color-on-surface-1, #181818);
    border: var(--slds-g-sizing-border-1) solid var(--slds-g-color-border-1, #e5e5e5);
    border-radius: var(--slds-g-radius-border-2, 0.25rem);
    box-shadow: var(--slds-g-shadow-1);
    padding: var(--slds-g-spacing-4, 1rem);
}

.card-header {
    color: var(--slds-g-color-on-surface-1, #181818);
    font-size: var(--slds-g-font-size-5, 1rem);
    font-weight: var(--slds-g-font-weight-7, 700);
    margin-bottom: var(--slds-g-spacing-3, 0.75rem);
}
```

---

## SLDS 1 to SLDS 2 Migration

| SLDS 1 (Deprecated) | SLDS 2 Replacement |
|----------------------|--------------------|
| `var(--lwc-colorBackground)` | `var(--slds-g-color-surface-1)` |
| `var(--lwc-colorTextDefault)` | `var(--slds-g-color-on-surface-1)` |
| `var(--lwc-colorBorder)` | `var(--slds-g-color-border-1)` |
| `var(--lwc-colorTextLink)` | `var(--slds-g-color-accent-1)` |
| `var(--lwc-colorTextError)` | `var(--slds-g-color-error-1)` |
| `var(--lwc-colorTextSuccess)` | `var(--slds-g-color-success-1)` |
| `var(--lwc-colorTextWarning)` | `var(--slds-g-color-warning-1)` |
| `var(--lwc-spacingMedium)` | `var(--slds-g-spacing-4)` |
| `var(--lwc-borderRadiusMedium)` | `var(--slds-g-radius-border-2)` |
| `var(--lwc-fontSize4)` | `var(--slds-g-font-size-5)` |
| `var(--lwc-fontWeightBold)` | `var(--slds-g-font-weight-7)` |
| `t-salesforce-sans` (font token) | `var(--slds-g-font-family)` |

---

## Component Structure Patterns

### Prefer Base Components

```html
<!-- Preferred: base component with built-in SLDS 2 -->
<lightning-card title="Account Details">
    <lightning-badge label="Active"></lightning-badge>
    <lightning-icon icon-name="utility:check" size="small"></lightning-icon>
</lightning-card>

<!-- Custom HTML only when base components lack functionality -->
<div class="custom-metric-card">
    <span class="metric-label">{label}</span>
    <span class="metric-value">{value}</span>
</div>
```

### Template Structure

```html
<template>
    <lightning-card title={cardTitle} icon-name={iconName}>
        <!-- Status region: use feedback hooks -->
        <div class="status-banner" if:true={hasStatus}>
            <lightning-icon icon-name={statusIcon} size="x-small"></lightning-icon>
            <span class="status-text">{statusMessage}</span>
        </div>

        <!-- Content region: use surface hooks -->
        <div class="content-body">
            <slot></slot>
        </div>

        <!-- Action region: use accent hooks -->
        <div slot="actions">
            <lightning-button label="Edit" onclick={handleEdit}></lightning-button>
        </div>
    </lightning-card>
</template>
```

---

## Scoring Rubric (100 Points)

| Category | Points | Pass Criteria |
|----------|--------|---------------|
| **SLDS 2 Hook Usage** | 25 | All colors, spacing, sizing, typography use `--slds-g-*` hooks |
| **Theme-Safe Styling** | 20 | Zero hardcoded colors; fallbacks on every `var()`; no inline styles |
| **Migration Compliance** | 15 | No SLDS 1 `--lwc-*` tokens; no deprecated class names |
| **Component Structure** | 15 | Uses `lightning-*` base components where available; semantic HTML |
| **Surface/Accent/Feedback** | 15 | Correct semantic use of color categories (not accent for errors, etc.) |
| **Typography & Spacing** | 10 | Consistent use of scale hooks; no magic numbers |

### Scoring Guide

- **90-100**: Production-ready, fully SLDS 2 compliant
- **70-89**: Minor issues (missing fallbacks, 1-2 hardcoded values)
- **50-69**: Needs rework (mixed SLDS 1/2, several hardcoded values)
- **Below 50**: Major redesign needed

---

## Cross-Skill Integration

| Skill | Relationship |
|-------|-------------|
| **sf-lwc** | Handles JS logic, wire service, Apex, Jest — this skill handles design tokens |
| **sf-lwc-ux** | Consumes the design foundation for UX patterns and accessibility |
| **sf-lwc-styling** | Maps these hooks to utility-first CSS classes |

---

## Dependencies

- Target org with SLDS 2 support (API 62.0+, Spring '25+)
- Salesforce Cosmos theme enabled (or custom SLDS 2 theme)
- `sf` CLI authenticated for deployment validation
