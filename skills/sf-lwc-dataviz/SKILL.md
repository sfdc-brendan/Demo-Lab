---
name: sf-lwc-dataviz
description: >
  Data visualization patterns for Lightning Web Components. Builds metric cards,
  KPI displays, trend indicators, sparklines, progress gauges, comparison layouts,
  and accessible chart alternatives using SLDS 2 styling hooks. Use when creating
  dashboards, displaying metrics, building charts, showing KPIs, or when the user
  mentions data visualization, charts, metrics, gauges, sparklines, or dashboards.
license: MIT
metadata:
  version: "1.0.0"
  author: "Brendan Sheridan"
  scoring: "100 points across 6 categories"
---

# sf-lwc-dataviz: Data Visualization for LWC

Build data-rich Lightning Web Components that tell a story with numbers. Every visualization uses SLDS 2 hooks, is accessible, and degrades gracefully.

## Core Principles

1. **Data first, decoration second** — the number/trend is the hero, not the chart
2. **Accessible always** — every visual has a text alternative or data table fallback
3. **SLDS color semantics** — use feedback hooks (success/warning/error) for status, not arbitrary colors
4. **Responsive** — visualizations adapt to container width without JS

---

## Metric Card Pattern

The most common dataviz component: a single KPI with context.

### Visual Hierarchy

```
┌──────────────────────────────┐
│  Label (secondary text)      │  ← what this measures
│  VALUE (large, bold)         │  ← the number
│  ▲ +12% vs last period      │  ← trend context
│  ▔▔▔▁▁▔▔▔▔▁▔▔▔▔▔           │  ← sparkline (optional)
└──────────────────────────────┘
```

### HTML

```html
<template>
    <div class="metric-card">
        <span class="metric-label">{label}</span>
        <span class="metric-value">{formattedValue}</span>
        <div class="metric-trend" if:true={hasTrend}>
            <lightning-icon
                icon-name={trendIcon}
                size="xx-small"
                class={trendClass}>
            </lightning-icon>
            <span class={trendClass}>{trendText}</span>
        </div>
        <div class="metric-sparkline" if:true={hasSparkline}>
            <c-sparkline data={sparklineData} color={sparklineColor}></c-sparkline>
        </div>
    </div>
</template>
```

### CSS

```css
.metric-card {
    display: flex;
    flex-direction: column;
    gap: var(--slds-g-spacing-1, 0.25rem);
    padding: var(--slds-g-spacing-4, 1rem);
    background: var(--slds-g-color-surface-1, #ffffff);
    border: var(--slds-g-sizing-border-1) solid var(--slds-g-color-border-1, #e5e5e5);
    border-radius: var(--slds-g-radius-border-3, 0.5rem);
}

.metric-label {
    font-size: var(--slds-g-font-size-2, 0.75rem);
    font-weight: var(--slds-g-font-weight-5, 500);
    color: var(--slds-g-color-on-surface-2, #444444);
    text-transform: uppercase;
    letter-spacing: 0.05em;
}

.metric-value {
    font-size: var(--slds-g-font-size-9, 1.75rem);
    font-weight: var(--slds-g-font-weight-7, 700);
    color: var(--slds-g-color-on-surface-1, #181818);
    line-height: var(--slds-g-line-height-1, 1);
}

.metric-trend {
    display: flex;
    align-items: center;
    gap: var(--slds-g-spacing-1, 0.25rem);
    font-size: var(--slds-g-font-size-2, 0.75rem);
    font-weight: var(--slds-g-font-weight-5, 500);
}

.trend--positive { color: var(--slds-g-color-success-1, #2e844a); }
.trend--negative { color: var(--slds-g-color-error-1, #ea001e); }
.trend--neutral { color: var(--slds-g-color-on-surface-2, #444444); }
```

### JavaScript — Number Formatting

```javascript
get formattedValue() {
    if (this.value == null) return '—';
    if (this.format === 'currency') {
        return new Intl.NumberFormat('en-US', {
            style: 'currency', currency: 'USD',
            minimumFractionDigits: 0, maximumFractionDigits: 0
        }).format(this.value);
    }
    if (this.format === 'percent') {
        return new Intl.NumberFormat('en-US', {
            style: 'percent', minimumFractionDigits: 1
        }).format(this.value / 100);
    }
    if (Math.abs(this.value) >= 1e6) {
        return (this.value / 1e6).toFixed(1) + 'M';
    }
    if (Math.abs(this.value) >= 1e3) {
        return (this.value / 1e3).toFixed(1) + 'K';
    }
    return this.value.toLocaleString();
}

get trendIcon() {
    if (this.trendValue > 0) return 'utility:arrowup';
    if (this.trendValue < 0) return 'utility:arrowdown';
    return 'utility:dash';
}

get trendClass() {
    if (this.trendValue > 0) return 'trend--positive';
    if (this.trendValue < 0) return 'trend--negative';
    return 'trend--neutral';
}
```

---

## Sparkline Pattern

A minimal inline chart using SVG polyline, no external libraries.

```javascript
get sparklinePath() {
    if (!this.data || this.data.length < 2) return '';
    const width = 120;
    const height = 32;
    const max = Math.max(...this.data);
    const min = Math.min(...this.data);
    const range = max - min || 1;
    const step = width / (this.data.length - 1);

    return this.data
        .map((val, i) => {
            const x = i * step;
            const y = height - ((val - min) / range) * height;
            return `${x},${y}`;
        })
        .join(' ');
}
```

```html
<template>
    <svg class="sparkline" viewBox="0 0 120 32"
         preserveAspectRatio="none"
         role="img" aria-label={sparklineLabel}>
        <polyline
            points={sparklinePath}
            fill="none"
            stroke={strokeColor}
            stroke-width="2"
            stroke-linecap="round"
            stroke-linejoin="round">
        </polyline>
    </svg>
</template>
```

```css
.sparkline {
    width: 100%;
    height: var(--slds-g-sizing-4, 2rem);
    display: block;
}
```

---

## Progress / Gauge Patterns

### Linear Progress Bar

```html
<template>
    <div class="progress-bar" role="progressbar"
         aria-valuenow={value} aria-valuemin="0" aria-valuemax="100"
         aria-label={label}>
        <div class="progress-bar__fill" style={fillStyle}></div>
    </div>
    <span class="progress-label">{value}%</span>
</template>
```

```css
.progress-bar {
    height: var(--slds-g-spacing-2, 0.5rem);
    background: var(--slds-g-color-surface-container-2, #f3f3f3);
    border-radius: var(--slds-g-radius-border-pill, 9999px);
    overflow: hidden;
}

.progress-bar__fill {
    height: 100%;
    border-radius: var(--slds-g-radius-border-pill, 9999px);
    transition: width 400ms ease;
}
```

```javascript
get fillStyle() {
    const color = this.value >= 80
        ? 'var(--slds-g-color-success-1, #2e844a)'
        : this.value >= 50
            ? 'var(--slds-g-color-warning-1, #dd7a01)'
            : 'var(--slds-g-color-error-1, #ea001e)';
    return `width: ${Math.min(100, Math.max(0, this.value))}%; background: ${color}`;
}
```

### Radial Gauge (CSS conic-gradient)

```css
.radial-gauge {
    --gauge-value: 0;
    --gauge-color: var(--slds-g-color-accent-1, #0176d3);
    --gauge-bg: var(--slds-g-color-surface-container-2, #f3f3f3);
    --gauge-size: 80px;

    width: var(--gauge-size);
    height: var(--gauge-size);
    border-radius: var(--slds-g-radius-circle);
    background: conic-gradient(
        var(--gauge-color) calc(var(--gauge-value) * 1%),
        var(--gauge-bg) 0
    );
    display: flex;
    align-items: center;
    justify-content: center;
    position: relative;
}

.radial-gauge__inner {
    width: calc(var(--gauge-size) - 12px);
    height: calc(var(--gauge-size) - 12px);
    border-radius: var(--slds-g-radius-circle);
    background: var(--slds-g-color-surface-1, #ffffff);
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: var(--slds-g-font-size-4, 0.875rem);
    font-weight: var(--slds-g-font-weight-7, 700);
    color: var(--slds-g-color-on-surface-1, #181818);
}
```

---

## Color Semantics for Data

Always use SLDS feedback colors semantically. Never assign arbitrary colors to data states.

| Data Meaning | SLDS Hook | Use |
|-------------|-----------|-----|
| Positive / on-track | `--slds-g-color-success-1` | Revenue up, target met, healthy |
| Negative / at-risk | `--slds-g-color-error-1` | Revenue down, overdue, critical |
| Caution / approaching limit | `--slds-g-color-warning-1` | Nearing quota, expiring soon |
| Neutral / informational | `--slds-g-color-accent-1` | Baseline, selected, highlighted |
| Inactive / not applicable | `--slds-g-color-disabled-1` | No data, unavailable |

For categorical data (multiple series), use the accessible color palette:

```css
.series-1 { color: var(--slds-g-color-blue-60, #0176d3); }
.series-2 { color: var(--slds-g-color-purple-60, #9050e9); }
.series-3 { color: var(--slds-g-color-teal-60, #0b827c); }
.series-4 { color: var(--slds-g-color-orange-60, #dd7a01); }
```

---

## Comparison Layouts

### Side-by-Side Metrics

```css
.metric-row {
    display: flex;
    flex-wrap: wrap;
    gap: var(--slds-g-spacing-4, 1rem);
}

.metric-row > .metric-card {
    flex: 1 1 200px;
    min-width: 0;
}
```

### Before/After Comparison

```css
.comparison {
    display: grid;
    grid-template-columns: 1fr auto 1fr;
    gap: var(--slds-g-spacing-3, 0.75rem);
    align-items: center;
}

.comparison__divider {
    width: var(--slds-g-sizing-border-2);
    height: 100%;
    background: var(--slds-g-color-border-1, #e5e5e5);
}
```

---

## Accessibility for Data Visualization

### Every Chart Needs a Text Alternative

```html
<div class="chart-container">
    <svg role="img" aria-label={chartSummary}>
        <!-- visual chart -->
    </svg>
    <details class="sr-data-table">
        <summary>View data table</summary>
        <table>
            <thead><tr><th>Month</th><th>Revenue</th></tr></thead>
            <tbody>
                <template for:each={tableData} for:item="row">
                    <tr key={row.id}>
                        <td>{row.month}</td>
                        <td>{row.revenue}</td>
                    </tr>
                </template>
            </tbody>
        </table>
    </details>
</div>
```

### Screen Reader Summary

```javascript
get chartSummary() {
    const trend = this.trendValue > 0 ? 'increased' : 'decreased';
    return `${this.label}: ${this.formattedValue}, ${trend} ${Math.abs(this.trendValue)}% compared to previous period`;
}
```

---

## Scoring Rubric (100 Points)

| Category | Points | Pass Criteria |
|----------|--------|---------------|
| **Visual Hierarchy** | 20 | Clear label/value/context ordering; value is prominent |
| **SLDS Color Semantics** | 20 | Feedback colors used correctly; no arbitrary colors for status |
| **Accessibility** | 20 | Text alternatives, aria attributes, data table fallbacks |
| **Number Formatting** | 15 | Proper locale formatting, abbreviations, currency/percent |
| **Responsive Layout** | 15 | Metrics reflow at narrow widths; no horizontal overflow |
| **Performance** | 10 | No external chart libraries; CSS/SVG only; efficient rendering |

---

## Cross-Skill Integration

| Skill | Relationship |
|-------|-------------|
| **sf-lwc-design** | Provides the SLDS 2 hooks used for all data viz colors and spacing |
| **sf-lwc-ux** | Loading/empty/error states wrap around data viz components |
| **sf-lwc-styling** | Utility classes used for layout composition around metrics |
| **sf-lwc-page-composition** | Metric cards must work in App Builder column layouts |
