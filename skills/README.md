# LWC UI/UX Skills for Cursor

A suite of 3 Cursor agent skills that improve the visual quality, user experience, and design system compliance of Lightning Web Components on the Salesforce platform. Built on SLDS 2 global styling hooks with design patterns inspired by Tailwind CSS and Shadcn.

---

## Skills Overview

| Skill | Purpose | Scoring |
|-------|---------|---------|
| **sf-lwc-design** | SLDS 2 design system foundation — styling hooks, dark mode, migration from SLDS 1 | 100 pts |
| **sf-lwc-ux** | UX patterns and accessibility — loading/empty/error states, WCAG 2.1 AA, keyboard nav | 100 pts |
| **sf-lwc-styling** | Utility-first CSS — Tailwind-to-SLDS mapping, reusable classes, component recipes | 100 pts |

Combined: **300-point UI/UX quality gate** that complements the existing [sf-lwc](https://github.com/Jaganpro/sf-skills) skill's 165-point scoring.

### How They Work Together

```
sf-lwc-design (SLDS 2 Foundation)
├── Provides → sf-lwc-styling (maps hooks to utility classes)
├── Provides → sf-lwc-ux (UX patterns consume design tokens)
└── Complements → sf-lwc (existing: JS logic, wire, Apex, Jest)
```

**sf-lwc-design** defines the design system rules. **sf-lwc-styling** maps those rules into reusable CSS patterns. **sf-lwc-ux** uses both to build accessible, well-structured user interfaces.

---

## Installation

### Quick Install (Recommended)

```bash
bash install.sh
```

This copies all 3 skills to `~/.cursor/skills/` and validates each SKILL.md before installing. Restart Cursor after installing.

### Manual Install

Copy each skill directory to your Cursor skills folder:

```bash
cp -R sf-lwc-design ~/.cursor/skills/
cp -R sf-lwc-ux ~/.cursor/skills/
cp -R sf-lwc-styling ~/.cursor/skills/
```

### Project-Level Install

To make skills available to anyone who clones your repository, copy the skill directories into your project:

```bash
cp -R sf-lwc-design /path/to/your/project/.cursor/skills/
cp -R sf-lwc-ux /path/to/your/project/.cursor/skills/
cp -R sf-lwc-styling /path/to/your/project/.cursor/skills/
```

---

## Usage Examples

### Prompts That Trigger sf-lwc-design

```
"Create an LWC card component that's SLDS 2 compliant"
"Migrate this component from SLDS 1 design tokens to SLDS 2"
"Make this component dark mode ready"
"What SLDS 2 styling hook should I use for a border color?"
"Review this LWC CSS for design system compliance"
```

### Prompts That Trigger sf-lwc-ux

```
"Add loading and empty states to this component"
"Make this LWC accessible with keyboard navigation"
"Build a dashboard layout with a card grid"
"Add error handling UI to this component"
"Review this component for accessibility issues"
"Create a master-detail split view layout"
```

### Prompts That Trigger sf-lwc-styling

```
"Create utility CSS classes for this LWC"
"What's the SLDS equivalent of Tailwind's bg-gray-50?"
"Build a badge component with status variants"
"Create a custom styled data table with hover states"
"Generate a card recipe with header, body, and footer"
"Style this form input with a focus ring"
```

---

## What Each Skill Covers

### sf-lwc-design

- Complete SLDS 2 global styling hooks reference (colors, typography, spacing, sizing, shadows, radii)
- Dark mode compliance rules and CSS patterns
- SLDS 1 to SLDS 2 migration table (10 common token mappings)
- Component structure patterns using `lightning-*` base components
- 100-point scoring rubric across 6 categories

### sf-lwc-ux

- Shadcn-inspired component composition with slot-based architecture
- Layout patterns: card grid, split view, stacked form
- Interaction patterns: skeleton loading, empty states, error boundaries, toasts, optimistic updates
- Micro-interactions: focus rings, hover/active states, transitions
- WCAG 2.1 AA accessibility: ARIA checklist, keyboard navigation, focus management
- Responsive design using CSS-only techniques (no JS resize observers)
- 100-point scoring rubric across 6 categories

### sf-lwc-styling

- Tailwind-to-SLDS mapping tables (colors, spacing, typography, radii, shadows)
- Reusable utility classes: `.util-stack`, `.util-cluster`, `.util-grid`, `.util-surface`, `.util-text`
- Component recipes: cards, badges/pills, data tables, form inputs, custom buttons, modals
- CSS composition patterns (layering hooks, gradient accents, status indicators)
- Anti-patterns reference (what to avoid and what to do instead)
- 100-point scoring rubric across 6 categories

---

## Deploy to GitHub

### Add to an Existing Repository

```bash
# Clone your repo (if not already cloned)
git clone https://github.com/sfdc-brendan/Demo-Lab.git
cd Demo-Lab

# Copy the skills folder
cp -R /path/to/skills .

# Commit and push
git add skills/
git commit -m "Add LWC UI/UX Cursor skills (sf-lwc-design, sf-lwc-ux, sf-lwc-styling)"
git push origin main
```

### Verify Deployment

After pushing, confirm the following structure exists in your repo:

```
Demo-Lab/
├── skills/
│   ├── README.md
│   ├── install.sh
│   ├── sf-lwc-design/
│   │   └── SKILL.md
│   ├── sf-lwc-ux/
│   │   └── SKILL.md
│   └── sf-lwc-styling/
│       └── SKILL.md
├── Agentforce/
├── LWCs/
├── Service Cloud/
└── ...
```

### Install From GitHub

Anyone can install the skills directly from your repo:

```bash
# Clone and install
git clone https://github.com/sfdc-brendan/Demo-Lab.git
cd Demo-Lab/skills
bash install.sh
```

---

## Requirements

- **Cursor** (latest version)
- **Salesforce org** with LWC support (API 45.0+)
- **SLDS 2** recommended (API 62.0+, Spring '25+) for full styling hook support
- **Salesforce Cosmos theme** enabled for dark mode features

These skills have no external dependencies. No Node.js, no Tailwind build step, no static resources.

---

## Compatibility

These skills are designed to work alongside the [sf-skills](https://github.com/Jaganpro/sf-skills) collection by Jag Valaiyapathy. They complement the existing `sf-lwc` skill by focusing exclusively on the visual/UX layer while `sf-lwc` handles JavaScript logic, wire service, Apex integration, and Jest testing.

---

## License

MIT License - Brendan Sheridan
