# LWC UI/UX Skills for Cursor

A suite of 11 Cursor agent skills that improve the visual quality, user experience, and design system compliance of Lightning Web Components on the Salesforce platform. Built on SLDS 2 global styling hooks with design patterns inspired by Tailwind CSS and Shadcn.

---

## Skills Overview

### Foundation (Core Design System)

| Skill | Purpose | Scoring |
|-------|---------|---------|
| **sf-lwc-design** | SLDS 2 design system foundation — styling hooks, dark mode, migration from SLDS 1 | 100 pts |
| **sf-lwc-styling** | Utility-first CSS — Tailwind-to-SLDS mapping, reusable classes, component recipes | 100 pts |
| **sf-lwc-theming** | Custom themes — brand tokens, multi-brand support, dark/light mode, Experience Cloud themes | 100 pts |

### User Experience

| Skill | Purpose | Scoring |
|-------|---------|---------|
| **sf-lwc-ux** | UX patterns and accessibility — loading/empty/error states, WCAG 2.1 AA, keyboard nav | 100 pts |
| **sf-lwc-content** | Microcopy and UI writing — error messages, empty states, button labels, help text, i18n | 100 pts |
| **sf-lwc-motion** | Animation and motion — transitions, entry/exit, staggered reveals, reduced motion support | 100 pts |

### Platform Integration

| Skill | Purpose | Scoring |
|-------|---------|---------|
| **sf-lwc-page-composition** | App Builder-aware design — column layouts, meta.xml config, LMS communication | 100 pts |
| **sf-lwc-experience** | Experience Cloud — DXP tokens, guest users, navigation, SEO, branding | 100 pts |
| **sf-lwc-mobile** | Mobile-first — touch targets, thumb zones, Salesforce Mobile, offline patterns | 100 pts |

### Specialized

| Skill | Purpose | Scoring |
|-------|---------|---------|
| **sf-lwc-dataviz** | Data visualization — metric cards, sparklines, gauges, accessible charts | 100 pts |
| **sf-lwc-review** | Design quality audit — 300-point combined rubric, issue detection, fix plans | 300 pts (combined) |

**Total: 1,100-point design quality system** across all skills, complementing the existing [sf-lwc](https://github.com/Jaganpro/sf-skills) skill's 165-point scoring.

---

## How They Work Together

```
sf-lwc-design (SLDS 2 Foundation)
├── sf-lwc-styling (maps hooks to utility classes)
├── sf-lwc-theming (extends hooks with brand tokens)
├── sf-lwc-ux (UX patterns consume design tokens)
│   ├── sf-lwc-content (words inside the UX patterns)
│   └── sf-lwc-motion (animation for state changes)
├── sf-lwc-page-composition (App Builder layouts)
├── sf-lwc-experience (Experience Cloud theming)
├── sf-lwc-mobile (mobile viewport + touch)
├── sf-lwc-dataviz (data visualization components)
└── sf-lwc-review (audits all of the above)
```

**sf-lwc-design** is the foundation — every other skill references it. **sf-lwc-review** is the enforcement layer that scores components against all skills.

---

## Installation

### Quick Install (Recommended)

```bash
bash install.sh
```

This copies all 11 skills to `~/.cursor/skills/` and validates each SKILL.md before installing. Restart Cursor after installing.

### Manual Install

Copy each skill directory to your Cursor skills folder:

```bash
for skill in sf-lwc-design sf-lwc-ux sf-lwc-styling sf-lwc-dataviz sf-lwc-review \
    sf-lwc-mobile sf-lwc-page-composition sf-lwc-motion sf-lwc-content \
    sf-lwc-experience sf-lwc-theming; do
    cp -R "$skill" ~/.cursor/skills/
done
```

### Project-Level Install

To make skills available to anyone who clones your repository:

```bash
cp -R sf-lwc-* /path/to/your/project/.cursor/skills/
```

---

## Usage Examples

### Foundation Skills

```
"Create an LWC card component that's SLDS 2 compliant"
"Migrate this component from SLDS 1 to SLDS 2"
"Create utility CSS classes for this LWC"
"What's the SLDS equivalent of Tailwind's bg-gray-50?"
"Create a custom brand theme with dark mode support"
"Build a multi-brand component system"
```

### UX Skills

```
"Add loading, empty, and error states to this component"
"Make this LWC accessible with keyboard navigation"
"Write better error messages for this form"
"Add entry animations to this card list"
"Add a skeleton loading pattern with shimmer effect"
"Make this confirmation dialog more user-friendly"
```

### Platform Skills

```
"Make this component work in all App Builder column widths"
"Configure this component for Experience Cloud with guest user support"
"Optimize this component for the Salesforce Mobile App"
"Add App Builder properties to this component"
"Make this component SEO-friendly for an Experience Cloud site"
```

### Specialized Skills

```
"Build a KPI metric card with sparkline and trend indicator"
"Create a dashboard with radial gauge and progress bars"
"Review this LWC for design quality and accessibility"
"Audit all components in this directory for design debt"
"Score this component against design best practices"
```

---

## What Each Skill Covers

### sf-lwc-design
SLDS 2 global styling hooks reference (colors, typography, spacing, sizing, shadows, radii). Dark mode compliance rules. SLDS 1 to SLDS 2 migration table. Component structure patterns.

### sf-lwc-ux
Shadcn-inspired component composition. Layout patterns (card grid, split view, stacked form). Interaction patterns (skeleton loading, empty states, error boundaries, toasts, optimistic updates). WCAG 2.1 AA accessibility (ARIA, keyboard nav, focus management). Responsive CSS-only techniques.

### sf-lwc-styling
Tailwind-to-SLDS mapping tables. Reusable utility classes (`.util-stack`, `.util-cluster`, `.util-grid`). Component recipes (cards, badges, data tables, form inputs, custom buttons, modals). Anti-patterns reference.

### sf-lwc-dataviz
Metric cards with visual hierarchy. Number formatting (currency, percent, abbreviations). Sparkline SVG patterns. Progress bars and radial gauges. Color semantics for data. Accessible chart alternatives with data tables.

### sf-lwc-review
Combined 300-point audit across design, UX, and styling rubrics. Automated checklist for hardcoded values, missing states, accessibility gaps. Issue list with severity levels. Prioritized fix plans. Directory-wide design debt scoring.

### sf-lwc-mobile
Touch target sizing (48px minimum). Thumb-zone-aware layouts with bottom action bars. Salesforce Mobile App constraints. Responsive patterns (mobile-first CSS). Collapsible sections. Offline-capable UI patterns.

### sf-lwc-page-composition
App Builder column width adaptation. meta.xml configuration with `targetConfigs`. Card height consistency. Cross-component communication (LMS, events, URL params). Design-time preview with placeholder data.

### sf-lwc-motion
Entry/exit animations (fade, slide, scale). Staggered list reveals. State transitions (expand/collapse, tabs, toggles). Loading sequences (pulse, shimmer). Timing and easing reference. Mandatory `prefers-reduced-motion` support.

### sf-lwc-content
Error message structure (what/why/what to do). Empty state copy templates. Button label conventions (verb-first). Help text patterns. Confirmation dialog copy. Toast message formatting. Internationalization-ready string patterns.

### sf-lwc-experience
Experience Cloud vs internal Lightning differences. DXP theme token consumption with SLDS fallbacks. Guest user authentication-aware components. Community navigation patterns. Experience Builder meta.xml targets. SEO and performance for external sites.

### sf-lwc-theming
Brand token architecture (above SLDS hooks). Dark/light mode with system preference detection. Multi-brand support with runtime switching. Experience Cloud DXP integration. Component-level theme overrides via App Builder color picker. Contrast validation checklist.

---

## Deploy to GitHub

### Add to an Existing Repository

```bash
git clone https://github.com/sfdc-brendan/Demo-Lab.git
cd Demo-Lab
cp -R /path/to/skills .
git add skills/
git commit -m "Add LWC UI/UX Cursor skills (11 design skills)"
git push origin main
```

### Install From GitHub

```bash
git clone https://github.com/sfdc-brendan/Demo-Lab.git
cd Demo-Lab/skills
bash install.sh
```

---

## Requirements

- **Cursor** (latest version)
- **Salesforce org** with LWC support (API 45.0+)
- **SLDS 2** recommended (API 62.0+, Spring '25+) for full styling hook support
- **Salesforce Cosmos theme** for dark mode features
- **Experience Cloud** license for sf-lwc-experience skill

No external dependencies. No Node.js, no Tailwind build step, no static resources.

---

## Compatibility

These skills complement the [sf-skills](https://github.com/Jaganpro/sf-skills) collection by Jag Valaiyapathy. They focus exclusively on the visual/UX layer while `sf-lwc` handles JavaScript logic, wire service, Apex integration, and Jest testing.

---

## License

MIT License - Brendan Sheridan
