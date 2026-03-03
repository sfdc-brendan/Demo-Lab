---
name: sf-lwc-experience
description: >
  Experience Cloud design patterns for Lightning Web Components. Covers external-facing
  site design, theme customization, guest user considerations, community navigation,
  branding overrides, SEO metadata, and Experience Builder component configuration.
  Use when building for Experience Cloud, Digital Experiences, communities, portals,
  external sites, or when the user mentions Experience Cloud, community, portal,
  guest user, or external-facing LWC.
license: MIT
metadata:
  version: "1.0.0"
  author: "Brendan Sheridan"
  scoring: "100 points across 6 categories"
---

# sf-lwc-experience: Experience Cloud Design for LWC

Build Lightning Web Components for external-facing Experience Cloud sites. Different design rules apply compared to internal Lightning pages — public audiences, branding requirements, SEO, and guest user security.

## Core Principles

1. **Brand-first, not SLDS-first** — external sites use customer branding, not Salesforce blue
2. **Guest-safe** — every component must handle unauthenticated users gracefully
3. **Performance** — external sites face real-world network conditions
4. **SEO-aware** — content must be crawlable and metadata-rich
5. **Responsive** — external users are on any device, not just desktop

---

## Experience Cloud vs Internal Lightning

| Aspect | Internal Lightning | Experience Cloud |
|--------|-------------------|-----------------|
| **Audience** | Employees | Customers, partners, public |
| **Branding** | Salesforce/org theme | Custom brand colors, fonts, logos |
| **Authentication** | Always logged in | Guest users, self-registration |
| **CSS scope** | Shadow DOM only | Shadow DOM + global theme CSS |
| **Navigation** | Lightning tabs/app | Community navigation, URL routing |
| **Performance** | Corporate network | Public internet, mobile, slow |
| **SEO** | Not applicable | Critical for public sites |

---

## Theme Customization

Experience Cloud sites use a separate theme system. Components should consume theme tokens, not hardcode brand colors.

### Theme Token Consumption

```css
.hero-banner {
    background-color: var(--dxp-g-root, var(--slds-g-color-surface-1, #ffffff));
    color: var(--dxp-g-root-contrast, var(--slds-g-color-on-surface-1, #181818));
}

.brand-accent {
    color: var(--dxp-s-brand-1, var(--slds-g-color-accent-1, #0176d3));
}

.brand-button {
    background: var(--dxp-s-brand-1, var(--slds-g-color-accent-1, #0176d3));
    color: var(--dxp-s-brand-1-contrast, var(--slds-g-color-on-accent-1, #ffffff));
    border-radius: var(--dxp-s-button-radius,
        var(--slds-g-radius-border-2, 0.25rem));
}

.nav-link {
    color: var(--dxp-s-link-text-color, var(--slds-g-color-accent-1, #0176d3));
}

.nav-link:hover {
    color: var(--dxp-s-link-text-color-hover, var(--slds-g-color-accent-2, #014486));
}
```

### DXP Token Categories

| Prefix | Category | Examples |
|--------|----------|---------|
| `--dxp-g-` | Global | `root`, `root-contrast`, `root-inverse` |
| `--dxp-s-brand-` | Brand colors | `brand-1`, `brand-1-contrast`, `brand-2` |
| `--dxp-s-link-` | Links | `link-text-color`, `link-text-color-hover` |
| `--dxp-s-button-` | Buttons | `button-radius`, `button-color` |
| `--dxp-s-text-` | Typography | `text-heading-large`, `text-body` |

### Fallback Chain

Always fall back from DXP tokens to SLDS hooks to literal values:

```css
color: var(--dxp-s-brand-1, var(--slds-g-color-accent-1, #0176d3));
```

This ensures the component works in Experience Cloud (DXP tokens), internal Lightning (SLDS hooks), and degraded environments (literal fallback).

---

## Guest User Design

### Authentication-Aware Components

```javascript
import { LightningElement, wire } from 'lwc';
import isGuest from '@salesforce/user/isGuest';
import Id from '@salesforce/user/Id';

export default class MyComponent extends LightningElement {
    get isAuthenticated() {
        return !isGuest;
    }

    get userId() {
        return Id;
    }
}
```

```html
<template>
    <!-- Authenticated: full experience -->
    <template if:true={isAuthenticated}>
        <c-full-dashboard></c-full-dashboard>
    </template>

    <!-- Guest: limited experience with CTA to log in -->
    <template if:false={isAuthenticated}>
        <div class="guest-cta">
            <h2 class="guest-cta__title">Sign in to view your dashboard</h2>
            <p class="guest-cta__description">
                Access your account details, open cases, and recent activity.
            </p>
            <lightning-button label="Sign In" variant="brand" onclick={handleLogin}>
            </lightning-button>
        </div>
    </template>
</template>
```

### Guest User Security Checklist

- Never expose record IDs, org IDs, or internal URLs to guests
- Never query data without `WITH SECURITY_ENFORCED` or FLS checks
- Use `@AuraEnabled(cacheable=true)` for guest-visible Apex methods
- Validate all input from guest users (treat as untrusted)
- Never expose admin email addresses or internal team names

---

## Navigation Patterns

### Community Navigation

```javascript
import { NavigationMixin } from 'lightning/navigation';

export default class MyComponent extends NavigationMixin(LightningElement) {
    navigateToPage(pageName) {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: { name: pageName }
        });
    }

    navigateToRecord(recordId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                actionName: 'view'
            }
        });
    }

    navigateToExternalUrl(url) {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: { url }
        });
    }
}
```

### Breadcrumb Pattern for Sites

```html
<template>
    <nav aria-label="Breadcrumb">
        <ol class="breadcrumb">
            <template for:each={breadcrumbs} for:item="crumb">
                <li key={crumb.id} class="breadcrumb__item">
                    <a if:false={crumb.isCurrent}
                       href={crumb.url}
                       onclick={handleNavigate}
                       data-page={crumb.page}>
                        {crumb.label}
                    </a>
                    <span if:true={crumb.isCurrent} aria-current="page">
                        {crumb.label}
                    </span>
                </li>
            </template>
        </ol>
    </nav>
</template>
```

---

## Experience Builder Configuration

### meta.xml for Experience Cloud

```xml
<?xml version="1.0" encoding="UTF-8"?>
<LightningComponentBundle xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>62.0</apiVersion>
    <isExposed>true</isExposed>
    <masterLabel>Customer Knowledge Base</masterLabel>
    <description>Searchable knowledge articles for site visitors.</description>
    <targets>
        <target>lightningCommunity__Page</target>
        <target>lightningCommunity__Default</target>
    </targets>
    <targetConfigs>
        <targetConfig targets="lightningCommunity__Default">
            <property name="heading" type="String" label="Section Heading"
                      default="Knowledge Base" />
            <property name="maxArticles" type="Integer" label="Articles to Show"
                      default="10" min="3" max="50" />
            <property name="showSearch" type="Boolean" label="Show Search Bar"
                      default="true" />
        </targetConfig>
    </targetConfigs>
</LightningComponentBundle>
```

### Target Reference

| Target | Where |
|--------|-------|
| `lightningCommunity__Page` | Experience Builder page (any) |
| `lightningCommunity__Default` | Default community layout |
| `lightningCommunity__Page_Layout` | Page layout region |

---

## Performance for External Sites

### Critical Rendering Path

```html
<template>
    <!-- Above the fold: render immediately -->
    <div class="hero">
        <h1>{headline}</h1>
        <p>{subheadline}</p>
    </div>

    <!-- Below the fold: lazy load -->
    <template if:true={belowFoldVisible}>
        <c-article-grid articles={articles}></c-article-grid>
    </template>
</template>
```

```javascript
_belowFoldVisible = false;

connectedCallback() {
    requestAnimationFrame(() => {
        this._belowFoldVisible = true;
    });
}
```

### Image Optimization

```html
<img src={imageUrl}
     alt={imageAlt}
     loading="lazy"
     width="400"
     height="300"
     class="responsive-img" />
```

```css
.responsive-img {
    width: 100%;
    height: auto;
    border-radius: var(--slds-g-radius-border-2, 0.25rem);
}
```

---

## SEO Considerations

- Use semantic HTML: `<h1>` for page title, `<h2>` for sections, `<article>` for content blocks
- Add `<meta>` tags via Head Markup in Experience Builder (not in LWC)
- Use meaningful link text: `View case details` not `Click here`
- Provide alt text on all images
- Structured data (JSON-LD) via Head Markup for articles and FAQs

---

## Scoring Rubric (100 Points)

| Category | Points | Pass Criteria |
|----------|--------|---------------|
| **Theme Compliance** | 20 | Uses `--dxp-*` tokens with SLDS fallbacks; no hardcoded brand colors |
| **Guest User Handling** | 20 | Auth-aware rendering; secure data access; graceful guest CTA |
| **Navigation** | 15 | Uses `NavigationMixin`; breadcrumbs; accessible link patterns |
| **Experience Builder Config** | 15 | Correct targets; configurable properties; sensible defaults |
| **Performance** | 15 | Lazy loading; optimized images; minimal DOM |
| **SEO & Accessibility** | 15 | Semantic HTML; alt text; meaningful link text; aria labels |

---

## Cross-Skill Integration

| Skill | Relationship |
|-------|-------------|
| **sf-lwc-design** | SLDS 2 hooks used as fallbacks when DXP tokens aren't available |
| **sf-lwc-theming** | Custom theme creation for Experience Cloud sites |
| **sf-lwc-mobile** | External sites have high mobile traffic — mobile patterns critical |
| **sf-lwc-content** | Microcopy must be guest-friendly, no internal jargon |
