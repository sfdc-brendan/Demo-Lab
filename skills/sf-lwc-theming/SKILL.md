---
name: sf-lwc-theming
description: >
  Custom theme creation and brand token systems for Lightning Web Components. Covers
  SLDS 2 theme extension, brand color palettes, multi-brand support, component-level
  theme overrides, and Experience Cloud theme tokens. Light mode is the default;
  dark mode is available as an opt-in enhancement. Use when creating custom themes,
  building brand systems, customizing SLDS, or when the user mentions theming,
  branding, custom colors, brand tokens, or white-labeling.
license: MIT
metadata:
  version: "1.0.0"
  author: "Brendan Sheridan"
  scoring: "100 points across 6 categories"
---

# sf-lwc-theming: Custom Themes for LWC

Create and apply custom themes that extend SLDS 2 for branded Salesforce experiences. Build theme systems that support multiple brands and component-level overrides — all without breaking the design system. **Light mode is the default**; dark mode is an optional enhancement when explicitly requested.

## Core Principles

1. **Light mode first** — all themes default to light mode; dark mode is opt-in
2. **Extend, never override** — add brand tokens alongside SLDS hooks, don't reassign them
3. **Semantic naming** — brand tokens describe purpose, not color (`--brand-primary`, not `--brand-blue`)
4. **Theme at the boundary** — apply themes at the `:host` level, not deep in component CSS
5. **Portable** — themes work in internal Lightning, Experience Cloud, and mobile

---

## Theme Architecture

```
┌─────────────────────────────────────────────┐
│  Brand Theme Layer (your custom tokens)     │  --brand-*, --app-*
├─────────────────────────────────────────────┤
│  SLDS 2 Global Hooks (Salesforce)           │  --slds-g-*
├─────────────────────────────────────────────┤
│  Component CSS (consumes both layers)       │  var(--brand-primary, var(--slds-g-...))
└─────────────────────────────────────────────┘
```

Custom brand tokens sit **above** SLDS hooks. Components consume brand tokens first, falling back to SLDS hooks, then to literal values.

---

## Brand Token System

### Defining Brand Tokens

Define brand tokens at the `:host` level of your root/wrapper component:

```css
:host {
    /* Brand palette */
    --brand-primary: #1a73e8;
    --brand-primary-hover: #1557b0;
    --brand-primary-contrast: #ffffff;
    --brand-secondary: #34a853;
    --brand-secondary-contrast: #ffffff;

    /* Semantic tokens */
    --brand-surface: var(--slds-g-color-surface-1, #ffffff);
    --brand-surface-elevated: var(--slds-g-color-surface-1, #ffffff);
    --brand-text: var(--slds-g-color-on-surface-1, #181818);
    --brand-text-muted: var(--slds-g-color-on-surface-2, #444444);
    --brand-border: var(--slds-g-color-border-1, #e5e5e5);

    /* Spacing overrides (if brand has tighter/looser density) */
    --brand-spacing-unit: var(--slds-g-spacing-4, 1rem);
    --brand-radius: var(--slds-g-radius-border-2, 0.25rem);
}
```

### Consuming Brand Tokens

```css
.branded-card {
    background: var(--brand-surface, var(--slds-g-color-surface-1, #ffffff));
    border: var(--slds-g-sizing-border-1) solid var(--brand-border, var(--slds-g-color-border-1));
    border-radius: var(--brand-radius, var(--slds-g-radius-border-2, 0.25rem));
}

.branded-button {
    background: var(--brand-primary, var(--slds-g-color-accent-1, #0176d3));
    color: var(--brand-primary-contrast, var(--slds-g-color-on-accent-1, #ffffff));
    border-radius: var(--brand-radius, var(--slds-g-radius-border-2, 0.25rem));
}

.branded-button:hover {
    background: var(--brand-primary-hover, var(--slds-g-color-accent-2, #014486));
}
```

### Fallback Chain

Always use a three-level fallback:

```
var(--brand-token, var(--slds-g-token, literal-fallback))
```

This ensures the component works in:
1. Branded context (brand tokens defined)
2. Standard Salesforce (SLDS hooks only)
3. Degraded environment (literal fallback)

---

## Dark Mode (Opt-In Enhancement)

Dark mode is **not added by default**. Before implementing, ask the user: "Do you want this component to support dark mode?" If yes, follow the patterns below.

### Dark Token Definitions

```css
:host {
    /* Light mode (default) */
    --brand-surface: #ffffff;
    --brand-surface-elevated: #ffffff;
    --brand-text: #181818;
    --brand-text-muted: #444444;
    --brand-border: #e5e5e5;
}

:host([data-theme="dark"]) {
    --brand-surface: #1a1a1a;
    --brand-surface-elevated: #2d2d2d;
    --brand-text: #e5e5e5;
    --brand-text-muted: #a0a0a0;
    --brand-border: #404040;
}
```

### System Preference Detection

```javascript
connectedCallback() {
    this._darkModeQuery = window.matchMedia('(prefers-color-scheme: dark)');
    this._handleThemeChange = (e) => {
        this.template.host.setAttribute(
            'data-theme',
            e.matches ? 'dark' : 'light'
        );
    };
    this._darkModeQuery.addEventListener('change', this._handleThemeChange);

    if (this._darkModeQuery.matches) {
        this.template.host.setAttribute('data-theme', 'dark');
    }
}

disconnectedCallback() {
    this._darkModeQuery.removeEventListener('change', this._handleThemeChange);
}
```

### Manual Theme Toggle

```html
<template>
    <button class="theme-toggle touch-target" onclick={handleToggleTheme}
            aria-label={themeToggleLabel}>
        <lightning-icon icon-name={themeIcon} size="small"></lightning-icon>
    </button>
</template>
```

```javascript
_isDark = false;

handleToggleTheme() {
    this._isDark = !this._isDark;
    this.template.host.setAttribute(
        'data-theme',
        this._isDark ? 'dark' : 'light'
    );
}

get themeIcon() {
    return this._isDark ? 'utility:daylight' : 'utility:night';
}

get themeToggleLabel() {
    return this._isDark ? 'Switch to light mode' : 'Switch to dark mode';
}
```

---

## Multi-Brand Support

For ISVs or orgs with multiple brands sharing components.

### Brand Configuration Object

```javascript
const BRANDS = {
    default: {
        primary: '#0176d3',
        primaryHover: '#014486',
        primaryContrast: '#ffffff',
        radius: 'var(--slds-g-radius-border-2, 0.25rem)',
        fontWeight: 'var(--slds-g-font-weight-6, 600)'
    },
    acme: {
        primary: '#e63946',
        primaryHover: '#c1121f',
        primaryContrast: '#ffffff',
        radius: 'var(--slds-g-radius-border-4, 1rem)',
        fontWeight: 'var(--slds-g-font-weight-7, 700)'
    },
    globex: {
        primary: '#2d6a4f',
        primaryHover: '#1b4332',
        primaryContrast: '#ffffff',
        radius: '0',
        fontWeight: 'var(--slds-g-font-weight-5, 500)'
    }
};
```

### Applying Brand at Runtime

```javascript
@api brandName = 'default';

renderedCallback() {
    const brand = BRANDS[this.brandName] || BRANDS.default;
    const host = this.template.host;
    host.style.setProperty('--brand-primary', brand.primary);
    host.style.setProperty('--brand-primary-hover', brand.primaryHover);
    host.style.setProperty('--brand-primary-contrast', brand.primaryContrast);
    host.style.setProperty('--brand-radius', brand.radius);
    host.style.setProperty('--brand-font-weight', brand.fontWeight);
}
```

### App Builder Brand Property

```xml
<property name="brandName" type="String" label="Brand"
          datasource="Default,Acme,Globex" default="Default" />
```

---

## Experience Cloud Theme Integration

Experience Cloud sites use DXP tokens. Map brand tokens to DXP tokens for seamless theming.

```css
:host {
    --brand-primary: var(--dxp-s-brand-1, var(--slds-g-color-accent-1, #0176d3));
    --brand-primary-contrast: var(--dxp-s-brand-1-contrast,
        var(--slds-g-color-on-accent-1, #ffffff));
    --brand-surface: var(--dxp-g-root, var(--slds-g-color-surface-1, #ffffff));
    --brand-text: var(--dxp-g-root-contrast, var(--slds-g-color-on-surface-1, #181818));
    --brand-link: var(--dxp-s-link-text-color, var(--slds-g-color-accent-1, #0176d3));
}
```

This way, one set of brand tokens works everywhere:
- In Experience Cloud: picks up DXP tokens set in Experience Builder
- In internal Lightning: falls back to SLDS hooks
- In custom branded context: brand tokens can be overridden at the host

---

## Component-Level Theme Overrides

Allow individual instances to override theme tokens via `@api` properties.

```javascript
@api accentColor;

renderedCallback() {
    if (this.accentColor) {
        this.template.host.style.setProperty('--brand-primary', this.accentColor);
    }
}
```

```xml
<property name="accentColor" type="Color" label="Accent Color" />
```

The `Color` type renders a color picker in App Builder for admin-friendly customization.

---

## Theme Validation

### Contrast Checking

When defining custom brand colors, verify contrast ratios:

| Pair | Minimum Ratio | Standard |
|------|--------------|----------|
| Text on surface | 4.5:1 | WCAG AA normal text |
| Large text on surface | 3:1 | WCAG AA large text |
| Button text on button bg | 4.5:1 | WCAG AA |
| Icon on surface | 3:1 | WCAG AA non-text |

### Theme Test Checklist

- [ ] All text readable on brand surface
- [ ] Buttons visible and readable
- [ ] Links distinguishable from body text
- [ ] Error/warning/success states visible against brand surface
- [ ] Dark mode renders correctly
- [ ] Focus indicators visible against brand surface

---

## Scoring Rubric (100 Points)

| Category | Points | Pass Criteria |
|----------|--------|---------------|
| **Token Architecture** | 20 | Brand tokens above SLDS; three-level fallback chain |
| **Dark Mode (if requested)** | 20 | When requested: dark variants defined, system preference detection, manual toggle. When not requested: light mode works correctly, no hardcoded colors that would break under dark theme. |
| **Contrast & Accessibility** | 20 | All color pairs meet WCAG AA contrast ratios |
| **Multi-Context** | 15 | Works in internal Lightning, Experience Cloud, and mobile |
| **Configurability** | 15 | Brand selectable via App Builder; color picker for accents |
| **Naming & Semantics** | 10 | Tokens named by purpose, not color; consistent naming |

---

## Cross-Skill Integration

| Skill | Relationship |
|-------|-------------|
| **sf-lwc-design** | Themes extend SLDS 2 hooks; never override them |
| **sf-lwc-experience** | DXP token integration for Experience Cloud sites |
| **sf-lwc-styling** | Utility classes consume brand tokens for branded patterns |
| **sf-lwc-review** | Audit checks theme contrast ratios and fallback chains |
