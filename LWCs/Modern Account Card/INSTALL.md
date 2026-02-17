# Modern Account Card - Installation Guide

## Prerequisites

1. **Salesforce CLI** - Install from [developer.salesforce.com/tools/salesforcecli](https://developer.salesforce.com/tools/salesforcecli)
2. **Git** - Install from [git-scm.com](https://git-scm.com/) (or download ZIP instead)
3. **Salesforce Org** - A Salesforce org where you have admin/deploy permissions

---

## Step 1: Download the Code

### Option A: Clone with Git
```bash
git clone https://github.com/sfdc-brendan/Demo-Lab.git
cd Demo-Lab/LWCs/Modern\ Account\ Card
```

### Option B: Download ZIP
1. Go to [github.com/sfdc-brendan/Demo-Lab](https://github.com/sfdc-brendan/Demo-Lab)
2. Click the green **Code** button → **Download ZIP**
3. Extract the ZIP file
4. Open a terminal and navigate to the `LWCs/Modern Account Card` folder

---

## Step 2: Authenticate to Your Salesforce Org

Open a terminal in the `Modern Account Card` folder and run:

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

From the `Modern Account Card` folder, run:

```bash
sf project deploy start --source-dir force-app --target-org my-org
```

You should see output like:
```
Deployed Source
 State    Name                        Type
 Created  modernAccountCard           LightningComponentBundle
 Created  ModernAccountCardController ApexClass
 Created  Account.AccountCardLogo__c  CustomField
 ...
```

---

## Step 4: Assign Permission Set

Grant yourself access to the custom fields:

```bash
sf org assign permset --name Modern_Account_Card_Access --target-org my-org
```

---

## Step 5: Add to Account Record Page

1. Go to any **Account record** in your org
2. Click the **gear icon** → **Edit Page**
3. Drag **Modern Account Card** from the Components panel onto the page
4. Configure the component settings as desired
5. Click **Save** → **Activate** (choose for Org, App, or Record Type)
6. Click **Back** to exit Lightning App Builder

---

## Quick Install (All Steps Combined)

```bash
# Clone and navigate
git clone https://github.com/sfdc-brendan/Demo-Lab.git
cd Demo-Lab/LWCs/Modern\ Account\ Card

# Authenticate (opens browser)
sf org login web --alias my-org --set-default

# Deploy
sf project deploy start --source-dir force-app --target-org my-org

# Assign permission set
sf org assign permset --name Modern_Account_Card_Access --target-org my-org

# Open the org
sf org open --target-org my-org
```

---

## Troubleshooting

### "Not authorized" error
Re-authenticate:
```bash
sf org login web --alias my-org --set-default
```

### "Invalid sourceApiVersion" error
Your org may be on an older Salesforce release. Edit all `*-meta.xml` files and change the API version to match your org (e.g., `58.0` or `57.0`).

### "FIELD_CUSTOM_VALIDATION_EXCEPTION" error
You may not have permission to create custom fields. Contact your Salesforce admin.

### Permission set not found
Make sure the deployment completed successfully. Check with:
```bash
sf project deploy report --target-org my-org
```

---

## Package Contents

| Component | Type | Description |
|-----------|------|-------------|
| `modernAccountCard` | LWC | The account card component |
| `ModernAccountCardController` | Apex | Fetches metrics from related records |
| `AccountCardLogo__c` | Custom Field | Company logo URL |
| `Brand_1-4_Name__c` | Custom Fields | Sub-brand names |
| `Brand_1-4_Image__c` | Custom Fields | Sub-brand logo URLs |
| `Modern_Account_Card_Access` | Permission Set | Field-level security |

---

## Uninstall

To remove the component:
```bash
sf project delete source --source-dir force-app --target-org my-org
```

Or manually delete via Setup:
1. Delete the LWC: Setup → Lightning Components → Delete `modernAccountCard`
2. Delete the Apex: Setup → Apex Classes → Delete `ModernAccountCardController`
3. Delete custom fields: Setup → Object Manager → Account → Fields → Delete each field
4. Delete permission set: Setup → Permission Sets → Delete `Modern_Account_Card_Access`
