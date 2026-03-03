---
name: sf-lwc-motion
description: >
  Animation and motion design for Lightning Web Components. Covers purposeful transitions,
  entry/exit animations, loading sequences, staggered reveals, easing functions, and
  mandatory prefers-reduced-motion support using SLDS 2 styling hooks. Use when adding
  animations, transitions, motion, or visual polish to LWC, or when the user mentions
  animation, transition, motion, easing, fade, slide, or reduced motion.
license: MIT
metadata:
  version: "1.0.0"
  author: "Brendan Sheridan"
  scoring: "100 points across 6 categories"
---

# sf-lwc-motion: Animation and Motion Design for LWC

Add purposeful, accessible motion to Lightning Web Components. Every animation must serve a functional purpose and respect user preferences.

## Core Principles

1. **Purposeful, not decorative** — animation communicates state changes, not showing off
2. **`prefers-reduced-motion` is mandatory** — always provide a no-animation fallback
3. **Fast** — 150-300ms for most transitions; never more than 500ms
4. **Only animate `transform` and `opacity`** — these are GPU-composited and performant
5. **Ease-out for entrances, ease-in for exits** — matches natural physical motion

---

## Reduced Motion (Mandatory)

Every component with animation must include this. No exceptions.

```css
@media (prefers-reduced-motion: reduce) {
    *,
    *::before,
    *::after {
        animation-duration: 0.01ms !important;
        animation-iteration-count: 1 !important;
        transition-duration: 0.01ms !important;
    }
}
```

Alternatively, per-element:

```css
.animated-element {
    transition: opacity 200ms ease-out, transform 200ms ease-out;
}

@media (prefers-reduced-motion: reduce) {
    .animated-element {
        transition: none;
    }
}
```

---

## Timing Reference

| Duration | Use Case | Easing |
|----------|----------|--------|
| 100ms | Hover/focus state changes | `ease` |
| 150ms | Button press, toggle, micro-feedback | `ease-out` |
| 200ms | Panel expand/collapse, tab switch | `ease-out` |
| 300ms | Modal open, card entrance | `ease-out` |
| 400ms | Page-level transitions, staggered list | `ease-out` |
| 500ms | Maximum — complex multi-element sequences | `ease-in-out` |

### Easing Functions

| Name | CSS | Motion Feel |
|------|-----|-------------|
| **Ease-out** | `cubic-bezier(0, 0, 0.2, 1)` | Fast start, gentle stop (entrances) |
| **Ease-in** | `cubic-bezier(0.4, 0, 1, 1)` | Gentle start, fast stop (exits) |
| **Ease-in-out** | `cubic-bezier(0.4, 0, 0.2, 1)` | Symmetric (state changes) |
| **Spring** | `cubic-bezier(0.34, 1.56, 0.64, 1)` | Slight overshoot (playful) |

---

## Entry Animations

### Fade In

```css
.fade-enter {
    opacity: 0;
    animation: fadeIn 300ms ease-out forwards;
}

@keyframes fadeIn {
    to { opacity: 1; }
}
```

### Slide Up + Fade

The most versatile entry animation — content rises into view.

```css
.slide-up-enter {
    opacity: 0;
    transform: translateY(12px);
    animation: slideUp 300ms ease-out forwards;
}

@keyframes slideUp {
    to {
        opacity: 1;
        transform: translateY(0);
    }
}
```

### Scale In (Modals, Popovers)

```css
.scale-enter {
    opacity: 0;
    transform: scale(0.95);
    animation: scaleIn 200ms ease-out forwards;
}

@keyframes scaleIn {
    to {
        opacity: 1;
        transform: scale(1);
    }
}
```

---

## Exit Animations

### Fade Out

```css
.fade-exit {
    animation: fadeOut 200ms ease-in forwards;
}

@keyframes fadeOut {
    to { opacity: 0; }
}
```

### Slide Down + Fade (Reverse of entry)

```css
.slide-down-exit {
    animation: slideDown 200ms ease-in forwards;
}

@keyframes slideDown {
    to {
        opacity: 0;
        transform: translateY(12px);
    }
}
```

---

## Staggered List Reveals

Show list items one by one with increasing delay for a cascading effect.

```html
<template>
    <ul class="stagger-list">
        <template for:each={items} for:item="item" for:index="index">
            <li key={item.id} class="stagger-item" style={item.staggerStyle}>
                {item.name}
            </li>
        </template>
    </ul>
</template>
```

```javascript
get items() {
    return this._rawItems.map((item, index) => ({
        ...item,
        staggerStyle: `animation-delay: ${index * 50}ms`
    }));
}
```

```css
.stagger-item {
    opacity: 0;
    transform: translateY(8px);
    animation: slideUp 300ms ease-out forwards;
}

.stagger-list {
    display: flex;
    flex-direction: column;
    gap: var(--slds-g-spacing-2, 0.5rem);
}
```

---

## State Transitions

### Expand / Collapse

```css
.expandable {
    display: grid;
    grid-template-rows: 0fr;
    transition: grid-template-rows 200ms ease-out;
}

.expandable--open {
    grid-template-rows: 1fr;
}

.expandable__inner {
    overflow: hidden;
}
```

### Tab Content Transition

```css
.tab-panel {
    opacity: 0;
    transform: translateX(8px);
    transition: opacity 200ms ease-out, transform 200ms ease-out;
}

.tab-panel--active {
    opacity: 1;
    transform: translateX(0);
}
```

### Toggle / Switch

```css
.toggle-track {
    width: 40px;
    height: 22px;
    border-radius: var(--slds-g-radius-border-pill, 9999px);
    background: var(--slds-g-color-surface-container-3, #e5e5e5);
    transition: background-color 150ms ease;
    position: relative;
    cursor: pointer;
}

.toggle-track--active {
    background: var(--slds-g-color-accent-1, #0176d3);
}

.toggle-thumb {
    width: 18px;
    height: 18px;
    border-radius: var(--slds-g-radius-circle);
    background: var(--slds-g-color-surface-1, #ffffff);
    box-shadow: var(--slds-g-shadow-1);
    position: absolute;
    top: 2px;
    left: 2px;
    transition: transform 150ms ease-out;
}

.toggle-track--active .toggle-thumb {
    transform: translateX(18px);
}
```

---

## Loading Sequences

### Skeleton Pulse (from sf-lwc-ux)

```css
@keyframes pulse {
    0%, 100% { opacity: 1; }
    50% { opacity: 0.4; }
}

.skeleton {
    background: var(--slds-g-color-surface-container-2, #f3f3f3);
    border-radius: var(--slds-g-radius-border-1, 0.125rem);
    animation: pulse 1.5s ease-in-out infinite;
}
```

### Shimmer Effect

```css
@keyframes shimmer {
    0% { background-position: -200% 0; }
    100% { background-position: 200% 0; }
}

.skeleton-shimmer {
    background: linear-gradient(
        90deg,
        var(--slds-g-color-surface-container-2, #f3f3f3) 25%,
        var(--slds-g-color-surface-container-1, #f8f8f8) 50%,
        var(--slds-g-color-surface-container-2, #f3f3f3) 75%
    );
    background-size: 200% 100%;
    animation: shimmer 1.5s ease-in-out infinite;
    border-radius: var(--slds-g-radius-border-1, 0.125rem);
}
```

### Spinner with Context

```html
<template>
    <div class="loading-container" if:true={isLoading}>
        <lightning-spinner alternative-text="Loading" size="small"></lightning-spinner>
        <span class="loading-text">{loadingMessage}</span>
    </div>
</template>
```

```css
.loading-container {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: var(--slds-g-spacing-3, 0.75rem);
    padding: var(--slds-g-spacing-8, 2rem);
}

.loading-text {
    font-size: var(--slds-g-font-size-2, 0.75rem);
    color: var(--slds-g-color-on-surface-2, #444444);
    animation: fadeIn 300ms ease-out 500ms both;
}
```

---

## Anti-Patterns

| Do NOT | Do Instead |
|--------|------------|
| Animate `width`, `height`, `top`, `left` | Animate `transform` and `opacity` |
| Animation longer than 500ms | Keep 150-300ms for most transitions |
| Animate on page load with no trigger | Animate in response to user action or data arrival |
| Bouncing/pulsing attention-grabbers | Subtle one-shot transitions |
| Missing `prefers-reduced-motion` | Always include the media query |
| `animation-iteration-count: infinite` (except loading) | Use `forwards` fill mode for one-shot |

---

## Scoring Rubric (100 Points)

| Category | Points | Pass Criteria |
|----------|--------|---------------|
| **Reduced Motion** | 25 | `prefers-reduced-motion` media query present; all animations disabled |
| **Purpose** | 20 | Every animation communicates a state change, not decorative |
| **Performance** | 20 | Only `transform`/`opacity` animated; no layout thrashing |
| **Timing** | 15 | Durations within 100-500ms range; appropriate easing per use case |
| **SLDS Compliance** | 10 | All colors/sizes in animations use `--slds-g-*` hooks |
| **Consistency** | 10 | Same animation patterns used across the component suite |

---

## Cross-Skill Integration

| Skill | Relationship |
|-------|-------------|
| **sf-lwc-ux** | Skeleton/loading states use motion patterns defined here |
| **sf-lwc-mobile** | Mobile animations must be faster; reduced motion critical |
| **sf-lwc-styling** | Utility classes can include transition properties |
| **sf-lwc-design** | All animated colors/sizes must use SLDS 2 hooks |
