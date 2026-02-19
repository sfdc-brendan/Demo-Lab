# Similar Cases & Articles

A Service Cloud Lightning Web Component for the **Case** record page that helps reps find similar cases and related Knowledge articles. Uses **Einstein Models API** (Gen AI) to score case similarity and dynamic SOSL for related articles, displayed in a compact 4-wide card grid with relevancy scores.

**Do not use in production.** For demos and evaluation only.

## Features

- **Similar Cases**: Candidate cases (same Account or Type) are sent to the Models API; the model returns case IDs and a relevancy score (0–100). Shown in a 4-wide card grid with Case Number, Type, Priority, Reason, Status, and “View case” link.
- **Status Filter**: Combobox to restrict similar cases by status (All, New, Working, Escalated, Closed).
- **Related Articles**: SOSL search on the case Subject against Knowledge (e.g. `Knowledge__kav`). Articles get a keyword-based relevance score and appear in the same card layout with “View article” link. Assumes the installation org has Knowledge configured; no package dependency on Knowledge.
- **Layout**: Responsive 4-column grid (2 on tablet, 1 on small screens). Compact cards for the middle column of a Case record page.

## What It Uses

| Capability | Description |
|------------|-------------|
| Similar cases | Einstein Models API `createGenerations` (prompt built in Apex) |
| Related articles | Dynamic SOSL via `Search.query()` (object name in code; no static Knowledge dependency) |
| Relevancy scores | Model returns 0–100 for cases; keyword overlap for articles |

---

## Installation

### Option 1: Package Install (Recommended when available)

```
https://login.salesforce.com/packaging/installPackage.apexp?p0=04tKj000000fTE0IAM
```

> **Note:** During Salesforce release windows, package installation may show "Mismatching Versions" if your org hasn't been upgraded yet. Use Option 2 below as an alternative.

### Option 2: Deploy via CLI

See **[INSTALL.md](INSTALL.md)** for detailed step-by-step instructions including:
- Installing Salesforce CLI
- Authenticating to your org
- Deploying the component
- Adding the component to the Case record page

**Quick deploy:**
```bash
git clone https://github.com/sfdc-brendan/Demo-Lab.git
cd Demo-Lab/Service\ Cloud/Similar\ Cases
sf org login web --alias my-org --set-default
sf project deploy start --source-dir force-app --target-org my-org
```

### Post-Installation

1. Add **Similar Cases & Articles** to the Case record page via Lightning App Builder (see [INSTALL.md](INSTALL.md) Step 4).
2. Open a Case record, choose an optional **Case status** filter, and click **Find Similar Cases**.
3. No permission set is required; Apex runs with sharing.

---

## Package Contents

| Component | Type | Description |
|-----------|------|-------------|
| `similarCasesAndArticles` | LWC | Case record page component (filter + cards) |
| `SimilarCasesController` | Apex | Exposes `getSimilarCasesWithScores(recordId, statusFilter)` |
| `SimilarCasesService` | Apex | Fetches candidates, calls Models API, runs SOSL for articles |
| `SimilarCasesServiceTest` | Apex | Test class |

---

## File Structure

```
Similar Cases/
├── README.md
├── INSTALL.md
├── sfdx-project.json
└── force-app/
    └── main/
        └── default/
            ├── classes/
            │   ├── SimilarCasesController.cls
            │   ├── SimilarCasesController.cls-meta.xml
            │   ├── SimilarCasesService.cls
            │   ├── SimilarCasesService.cls-meta.xml
            │   ├── SimilarCasesServiceTest.cls
            │   └── SimilarCasesServiceTest.cls-meta.xml
            └── lwc/
                └── similarCasesAndArticles/
                    ├── similarCasesAndArticles.html
                    ├── similarCasesAndArticles.js
                    ├── similarCasesAndArticles.js-meta.xml
                    └── similarCasesAndArticles.css
```

---

## Requirements

- Salesforce org with Lightning Experience, API 65.0+
- **Einstein / Gen AI**: Models API enabled (e.g. Einstein 1 Edition or add-on). The component uses `aiplatform.ModelsAPI.createGenerations()` with a default model (e.g. `sfdc_ai__DefaultGPT41`).
- **Case** object (standard).
- **Knowledge (optional)**: For related articles, the installation org should have Salesforce Knowledge configured. The code uses a configurable article type (default `Knowledge__kav`). No package dependency on Knowledge.

---

## License

Provided as-is for demonstration purposes.
