# Modern Contact Card - Installation Guide

## Prerequisites

1. **Salesforce CLI** - Install from [developer.salesforce.com/tools/salesforcecli](https://developer.salesforce.com/tools/salesforcecli)
2. **Git** - Install from [git-scm.com](https://git-scm.com/) (or download ZIP instead)
3. **Salesforce Org** - A Salesforce org where you have admin/deploy permissions

---

## Step 1: Download the Code

### Option A: Clone with Git
```bash
git clone https://github.com/sfdc-brendan/Demo-Lab.git
cd Demo-Lab/LWCs/Modern\ Contact\ Card
```

### Option B: Download ZIP
1. Go to [github.com/sfdc-brendan/Demo-Lab](https://github.com/sfdc-brendan/Demo-Lab)
2. Click the green **Code** button → **Download ZIP**
3. Extract the ZIP file
4. Open a terminal and navigate to the `LWCs/Modern Contact Card` folder

---

## Step 2: Authenticate to Your Salesforce Org

Open a terminal in the `Modern Contact Card` folder and run:

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

From the `Modern Contact Card` folder, run:

```bash
sf project deploy start --source-dir force-app --target-org my-org
```

You should see output like:
```
Deployed Source
 State    Name                            Type
 Created  modernContactCard               LightningComponentBundle
 Created  Contact.ContactCardPicture__c   CustomField
 Created  Contact.ContactCardHealthScore__c CustomField
 ...
```

---

## Step 4: Assign Permission Set

Grant yourself access to the custom fields:

```bash
sf org assign permset --name Modern_Contact_Card_Access --target-org my-org
```

---

## Step 5: Add to Record Pages

1. Go to any **Contact**, **Case**, **Messaging Session**, or **Voice Call** record
2. Click the **gear icon** → **Edit Page**
3. Drag **Modern Contact Card** from the Components panel onto the page
4. Configure the component settings as desired
5. Click **Save** → **Activate** (choose for Org, App, or Record Type)
6. Click **Back** to exit Lightning App Builder

---

## Quick Install (All Steps Combined)

```bash
# 1. Clone the repo
git clone https://github.com/sfdc-brendan/Demo-Lab.git
cd Demo-Lab/LWCs/Modern\ Contact\ Card

# 2. Login to your org (opens browser)
sf org login web --alias my-org --set-default

# 3. Deploy
sf project deploy start --source-dir force-app --target-org my-org

# 4. Assign permissions
sf org assign permset --name Modern_Contact_Card_Access --target-org my-org

# 5. Open org and add component to page
sf org open --target-org my-org
```

---

## Supported Record Pages

| Object | How Contact is Resolved |
|--------|------------------------|
| Contact | Direct - uses current record |
| Case | Via `ContactId` field |
| Messaging Session | Via `EndUserContactId` field |
| Voice Call | Via configurable lookup field (set in component settings) |

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

### Contact not showing on Voice Call
Configure the Voice Call Contact lookup field name in the component settings (e.g., `Contact__c`).

---

## Package Contents

| Component | Type | Description |
|-----------|------|-------------|
| `modernContactCard` | LWC | The contact card component |
| `ContactCardPicture__c` | Custom Field | Profile image URL |
| `ContactCardBackground__c` | Custom Field | Header background URL |
| `ContactCardHealthScore__c` | Custom Field | Health score (0-100) |
| `ContactCardTags__c` | Custom Field | Comma-separated tags |
| `Metric_1__c` - `Metric_6__c` | Custom Fields | Custom metric values |
| `Brand_1-4_Name__c` | Custom Fields | Brand affinity names |
| `Brand_1-4_Image__c` | Custom Fields | Brand affinity logos |
| `Modern_Contact_Card_Access` | Permission Set | Field-level security |

---

## Uninstall

To remove the component:
```bash
sf project delete source --source-dir force-app --target-org my-org
```

Or manually delete via Setup:
1. Delete the LWC: Setup → Lightning Components → Delete `modernContactCard`
2. Delete custom fields: Setup → Object Manager → Contact → Fields → Delete each field
3. Delete permission set: Setup → Permission Sets → Delete `Modern_Contact_Card_Access`
