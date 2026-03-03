---
name: sf-lwc-review
description: >
  Design quality audit and review for Lightning Web Components. Scores existing LWC
  code against SLDS 2 compliance, UX patterns, accessibility, styling quality, and
  visual hierarchy using a combined 300-point rubric across all design skills. Generates
  actionable fix lists and before/after improvement plans. Use when reviewing LWC code,
  auditing design quality, checking accessibility, or when the user mentions review,
  audit, score, lint, design debt, or quality check.
license: MIT
metadata:
  version: "1.0.0"
  author: "Brendan Sheridan"
  scoring: "300-point combined audit across 3 skill rubrics"
---

# sf-lwc-review: Design Quality Audit

Review and score existing Lightning Web Components against the full UI/UX design skills suite. This skill is the enforcement mechanism — it turns design guidelines into actionable feedback.

## When to Run

- Before deploying a new LWC component
- When refactoring existing components
- During code review of LWC pull requests
- When the user asks to "review", "audit", "check", or "score" a component
- Periodically across an LWC directory to measure design debt

---

## Audit Process

### Step 1: Identify Files

Read the component bundle: `.js`, `.html`, `.css`, and `.js-meta.xml`.

### Step 2: Run Three Scoring Passes

| Pass | Skill | Points | Focus |
|------|-------|--------|-------|
| **Design** | sf-lwc-design | 100 | SLDS 2 hooks, dark mode, migration, structure |
| **UX** | sf-lwc-ux | 100 | States, accessibility, layout, interactions |
| **Styling** | sf-lwc-styling | 100 | Utility patterns, composition, fallbacks |

### Step 3: Generate Report

```
Component: c-account-card
Total Score: 215 / 300

  Design:  78 / 100  ■■■■■■■■░░
  UX:      72 / 100  ■■■■■■■░░░
  Styling: 65 / 100  ■■■■■■░░░░

Issues Found: 12
  Critical (must fix): 3
  Warning (should fix): 5
  Info (nice to have): 4
```

---

## Design Pass Checklist (100 Points)

### SLDS 2 Hook Usage (25 pts)

Scan `.css` file for:

| Check | Points | How to Detect |
|-------|--------|---------------|
| All colors use `--slds-g-color-*` | 10 | Search for hex/rgb/hsl literals not inside `var()` fallbacks |
| All spacing uses `--slds-g-spacing-*` | 5 | Search for bare `px`/`rem`/`em` in padding/margin/gap |
| All font sizes use `--slds-g-font-size-*` | 5 | Search for bare `px`/`rem` in `font-size` |
| All radii use `--slds-g-radius-*` | 5 | Search for bare `px`/`rem` in `border-radius` |

**Flag pattern**: Any CSS property with a hardcoded value that has a `--slds-g-*` equivalent.

### Dark Mode Ready (20 pts)

| Check | Points | How to Detect |
|-------|--------|---------------|
| Zero hardcoded color values | 10 | Regex: `#[0-9a-fA-F]{3,8}` or `rgb\(` not inside `var()` fallback position |
| All `var()` have fallback values | 5 | Regex: `var\(--[^,)]+\)` (no comma = no fallback) |
| No inline color styles in HTML | 5 | Search `.html` for `style=` containing `color`, `background`, `border-color` |

### Migration Compliance (15 pts)

| Check | Points | How to Detect |
|-------|--------|---------------|
| No `--lwc-*` tokens | 10 | Search for `--lwc-` in `.css` |
| No deprecated SLDS 1 class names | 5 | Search `.html` for `slds-m-`, `slds-p-` utility classes |

### Component Structure (15 pts)

| Check | Points | How to Detect |
|-------|--------|---------------|
| Uses `lightning-*` base components where appropriate | 10 | Check if custom buttons/inputs/cards duplicate base components |
| Semantic HTML elements | 5 | Check for bare `<div>` where `<section>`, `<article>`, `<nav>` fits |

### Color Semantics (15 pts)

| Check | Points | How to Detect |
|-------|--------|---------------|
| Feedback colors match meaning | 10 | `error-*` used for errors, `success-*` for success, not mixed |
| Surface hierarchy is logical | 5 | `surface-1` for primary, `surface-container-*` for nested |

### Typography & Spacing (10 pts)

| Check | Points | How to Detect |
|-------|--------|---------------|
| Consistent spacing scale | 5 | No mixing of spacing hooks with pixel values |
| Typography follows scale | 5 | Font sizes from hook scale, not arbitrary values |

---

## UX Pass Checklist (100 Points)

### State Management (20 pts)

| Check | Points | How to Detect |
|-------|--------|---------------|
| Loading state exists | 5 | Search `.html` for `isLoading` or `loading` conditional |
| Empty state exists | 5 | Search `.html` for empty/no-data conditional with message |
| Error state exists | 5 | Search `.html` for error conditional with user-friendly message |
| Error has retry action | 5 | Error block contains a button/link for recovery |

### Accessibility (25 pts)

| Check | Points | How to Detect |
|-------|--------|---------------|
| Interactive elements have labels | 8 | All `<button>`, custom clickables have `aria-label` or visible label |
| Live regions announced | 5 | Dynamic content areas have `role="status"` or `role="alert"` |
| Keyboard navigation implemented | 7 | `onkeydown` handler on custom interactive widgets |
| Focus management on modals/popovers | 5 | Focus moves to opened element, returns on close |

### Layout Quality (15 pts)

| Check | Points | How to Detect |
|-------|--------|---------------|
| Uses CSS Grid or Flexbox | 5 | No `float`, no `position: absolute` for layout |
| No fixed pixel widths | 5 | No `width: 300px` on content containers |
| Spacing uses SLDS scale | 5 | Gap/padding/margin from `--slds-g-spacing-*` |

### Interaction Design (15 pts)

| Check | Points | How to Detect |
|-------|--------|---------------|
| Hover states on interactive elements | 5 | `:hover` rules in CSS for clickable items |
| Focus-visible styles | 5 | `:focus-visible` or `:focus` with outline in CSS |
| Feedback on actions (toast/inline) | 5 | `ShowToastEvent` or inline success/error message after mutations |

### Component Composition (15 pts)

| Check | Points | How to Detect |
|-------|--------|---------------|
| Uses `<slot>` for composition | 5 | Slots in `.html` for extensibility |
| Consistent `@api` conventions | 5 | Props follow `variant`, `size`, `label`, `disabled` pattern |
| Emits CustomEvents (not direct DOM) | 5 | `this.dispatchEvent(new CustomEvent(...))` for child-to-parent |

### Responsive (10 pts)

| Check | Points | How to Detect |
|-------|--------|---------------|
| Grid/flex with auto-fill or flex-wrap | 5 | `auto-fill`, `auto-fit`, or `flex-wrap: wrap` in CSS |
| No horizontal overflow at narrow widths | 5 | No fixed-width elements larger than mobile viewport |

---

## Styling Pass Checklist (100 Points)

### SLDS Hook Usage (25 pts)

Same checks as Design pass — reinforces zero tolerance for hardcoded values.

### Utility Class Quality (20 pts)

| Check | Points | How to Detect |
|-------|--------|---------------|
| Reusable class names (`.util-*`, `.recipe-*`, or semantic) | 10 | No single-use classes like `.thing1`, `.wrapper2` |
| No deeply nested selectors (max 2 levels) | 5 | Count selector depth in CSS |
| No `!important` | 5 | Search for `!important` in CSS |

### Composition (20 pts)

| Check | Points | How to Detect |
|-------|--------|---------------|
| Classes combine cleanly in HTML | 10 | Multiple utility classes on elements |
| CSS file is organized (grouped by purpose) | 5 | Related rules are adjacent |
| No duplicate property declarations | 5 | Same property on same selector |

### Fallback Values (15 pts)

Same check as Design dark mode fallbacks — every `var()` includes a fallback.

### Dark Mode Safe (10 pts)

Confirmed through Design pass. Cross-reference score.

### Performance (10 pts)

| Check | Points | How to Detect |
|-------|--------|---------------|
| No `*` wildcard selectors | 5 | Search for `* {` in CSS |
| No redundant declarations | 5 | Same property set multiple times on same element |

---

## Report Format

### Summary Block

```
=========================================
  LWC Design Audit: c-my-component
=========================================

  Score:    215 / 300
  Grade:    B (Good — minor issues)

  Design:   78 / 100
  UX:       72 / 100
  Styling:  65 / 100

=========================================
```

### Grade Scale

| Score | Grade | Meaning |
|-------|-------|---------|
| 270-300 | A | Production-ready, exemplary design |
| 220-269 | B | Good — minor issues to address |
| 150-219 | C | Needs improvement — several gaps |
| 100-149 | D | Significant design debt |
| Below 100 | F | Major redesign required |

### Issue List

Each issue includes:

```
[CRITICAL] CSS line 42: Hardcoded color #333333
  Fix: Replace with var(--slds-g-color-on-surface-1, #181818)

[WARNING] HTML line 15: No loading state
  Fix: Add template if:true={isLoading} with skeleton or spinner

[INFO] CSS line 78: Missing var() fallback
  Fix: Change var(--slds-g-spacing-4) to var(--slds-g-spacing-4, 1rem)
```

### Improvement Plan

After listing issues, generate a prioritized fix plan:

```
Priority Fixes (do first — biggest score impact):
1. Replace 5 hardcoded colors in CSS (+15 pts)
2. Add loading state to template (+5 pts)
3. Add empty state with guidance message (+5 pts)

Quick Wins (easy fixes):
4. Add fallback values to 8 var() calls (+5 pts)
5. Add aria-label to icon buttons (+3 pts)

Polish (nice to have):
6. Add hover states to list items (+3 pts)
7. Refactor to utility class pattern (+5 pts)
```

---

## Directory Audit

When reviewing multiple components, generate a summary:

```
=========================================
  LWC Design Audit: force-app/main/default/lwc/
=========================================

  Components Reviewed: 12

  Average Score: 198 / 300 (C+)
  Highest:  c-metric-card        267 / 300 (A)
  Lowest:   c-case-list          112 / 300 (D)

  Most Common Issues:
  1. Hardcoded colors (9/12 components)
  2. Missing loading states (7/12 components)
  3. No empty state UI (6/12 components)
  4. Missing var() fallbacks (8/12 components)

  Design Debt Estimate: ~4 hours to reach B average
=========================================
```

---

## Cross-Skill Integration

| Skill | Relationship |
|-------|-------------|
| **sf-lwc-design** | Provides the 100-point design rubric |
| **sf-lwc-ux** | Provides the 100-point UX rubric |
| **sf-lwc-styling** | Provides the 100-point styling rubric |
| **sf-lwc-dataviz** | Additional checks for data visualization components |
| **sf-lwc-mobile** | Additional checks for mobile-targeted components |
