# Similar Cases & Articles - Installation Guide

## Prerequisites

1. **Salesforce CLI** - Install from [developer.salesforce.com/tools/salesforcecli](https://developer.salesforce.com/tools/salesforcecli)
2. **Git** - Install from [git-scm.com](https://git-scm.com/) (or download ZIP instead)
3. **Salesforce Org** - A Salesforce org where you have admin/deploy permissions
4. **Einstein / Gen AI** - Models API enabled in the org (e.g. Einstein 1 Edition or add-on)

---

## Step 1: Download the Code

### Option A: Clone with Git
```bash
git clone https://github.com/sfdc-brendan/Demo-Lab.git
cd Demo-Lab/Service\ Cloud/Similar\ Cases
```

### Option B: Download ZIP
1. Go to [github.com/sfdc-brendan/Demo-Lab](https://github.com/sfdc-brendan/Demo-Lab)
2. Click the green **Code** button → **Download ZIP**
3. Extract the ZIP file
4. Open a terminal and navigate to the `Service Cloud/Similar Cases` folder

---

## Step 2: Authenticate to Your Salesforce Org

Open a terminal in the `Similar Cases` folder and run:

```bash
sf org login web --alias my-org --set-default
```

This will:
1. Open a browser window
2. Log in with your Salesforce credentials
3. Click **Allow** to authorize the CLI

**For Sandbox orgs**, add the instance URL:
```bash
sf org login web --alias my-org --set-default --instance-url https://test.salesforce.com
```

**Verify connection:**
```bash
sf org display --target-org my-org
```

---

## Step 3: Deploy the Component

From the `Similar Cases` folder, run:

```bash
sf project deploy start --source-dir force-app --target-org my-org
```

You should see output like:
```
Deployed Source
 State    Name                        Type
 Created  similarCasesAndArticles    LightningComponentBundle
 Created  SimilarCasesController      ApexClass
 Created  SimilarCasesService        ApexClass
 Created  SimilarCasesServiceTest    ApexClass
 ...
```

---

## Step 4: Add to Case Record Page

1. Go to any **Case record** in your org (or Setup → Object Manager → Case → Lightning Record Pages)
2. Open the Case record page you use (e.g. **Case Record Page**) and click **Edit**
3. Drag **Similar Cases & Articles** from the Components panel onto the page (e.g. main column)
4. Click **Save** → **Activate** (choose for Org, App, or Record Type)
5. Click **Back** to exit Lightning App Builder

---

## Step 5: Try It

1. Open a **Case** record
2. (Optional) Choose a **Case status** filter (e.g. Closed)
3. Click **Find Similar Cases**
4. Similar cases and related articles appear in the card grids with relevancy scores

---

## Quick Install (All Steps Combined)

```bash
# Clone and navigate
git clone https://github.com/sfdc-brendan/Demo-Lab.git
cd Demo-Lab/Service\ Cloud/Similar\ Cases

# Authenticate (opens browser)
sf org login web --alias my-org --set-default

# Deploy
sf project deploy start --source-dir force-app --target-org my-org

# Open the org
sf org open --target-org my-org
```

Then add the component to the Case record page (Step 4 above).

---

## Troubleshooting

### "Not authorized" error
Re-authenticate:
```bash
sf org login web --alias my-org --set-default
```

### "Invalid type: aiplatform.ModelsAPI" or similar
Your org may not have Einstein Models API enabled. Ensure the org has Gen AI / Einstein 1 and a model (e.g. `sfdc_ai__DefaultGPT41`) configured in Einstein Studio.

### "Invalid sourceApiVersion" error
Your org may be on an older Salesforce release. Edit all `*-meta.xml` files and change the API version to match your org (e.g. `62.0` or `60.0`).

### No similar cases or articles returned
- **Similar cases**: Ensure you have other Cases (same Account or same Type). The Models API must be enabled and have capacity.
- **Related articles**: Ensure Salesforce Knowledge is enabled and you have published articles. The code searches by case Subject; if your org uses a different article type than `Knowledge__kav`, update the article type in `SimilarCasesService.cls` (e.g. the `kavType` variable in `getRelatedKnowledgeArticles`).

### Permission set not found
This package does not include a permission set. Access follows the running user’s Case and Knowledge permissions.

---

## Package Contents

| Component | Type | Description |
|-----------|------|-------------|
| `similarCasesAndArticles` | LWC | Case record page component |
| `SimilarCasesController` | Apex | Controller for the LWC |
| `SimilarCasesService` | Apex | Similarity + article logic |
| `SimilarCasesServiceTest` | Apex | Test class |

---

## Uninstall

To remove the component via CLI:
```bash
sf project delete source --source-dir force-app --target-org my-org
```

Or manually in Setup:
1. Edit the Case record page and remove the **Similar Cases & Articles** component; Save and Activate
2. Delete the LWC: Setup → Lightning Components → Delete `similarCasesAndArticles`
3. Delete the Apex classes: Setup → Apex Classes → Delete `SimilarCasesController`, `SimilarCasesService`, and `SimilarCasesServiceTest`
