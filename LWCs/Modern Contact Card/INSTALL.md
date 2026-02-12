# Modern Contact Card - Installation Guide

A step-by-step guide for Salesforce Administrators to install and configure the Modern Contact Card component.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Installation](#installation)
3. [Post-Installation Setup](#post-installation-setup)
4. [Adding the Component to Record Pages](#adding-the-component-to-record-pages)
5. [Configuring the Component](#configuring-the-component)
6. [Populating Contact Data](#populating-contact-data)
7. [Optional: VoiceCall Configuration](#optional-voicecall-configuration)
8. [Troubleshooting](#troubleshooting)

---

## Prerequisites

Before installing, ensure you have:

- [ ] **Salesforce CLI (sf)** installed on your computer
  - Download: https://developer.salesforce.com/tools/salesforcecli
- [ ] **System Administrator** profile or equivalent permissions in your target org
- [ ] Your org authenticated with Salesforce CLI
  - Run: `sf org login web --alias my-org`

---

## Installation

### Step 1: Download the Package

Clone or download the repository:

```bash
git clone https://github.com/sfdc-brendan/Demo-Lab.git
cd Demo-Lab/LWCs/Modern\ Contact\ Card
```

Or download the ZIP from GitHub and extract it.

### Step 2: Deploy to Your Org

Deploy all components (LWC, custom fields, permission set) using the package manifest:

```bash
sf project deploy start --manifest manifest/package.xml --target-org YOUR_ORG_ALIAS
```

**Expected output:**
```
Deployed Source
- modernContactCard (LightningComponentBundle)
- Contact.ContactCardPicture__c (CustomField)
- Contact.ContactCardBackground__c (CustomField)
- Contact.ContactCardHealthScore__c (CustomField)
- Contact.ContactCardTags__c (CustomField)
- Contact.Metric_1__c through Metric_6__c (CustomField)
- Contact.Brand_1_Name__c through Brand_4_Name__c (CustomField)
- Contact.Brand_1_Image__c through Brand_4_Image__c (CustomField)
- Modern_Contact_Card_Access (PermissionSet)
```

### Step 3: Verify Deployment

Confirm the deployment succeeded:

```bash
sf project deploy report --target-org YOUR_ORG_ALIAS
```

---

## Post-Installation Setup

### Assign the Permission Set

The **Modern Contact Card Access** permission set grants users read/edit access to the custom fields used by the component.

#### Option A: Assign via Setup UI

1. Go to **Setup** → **Permission Sets**
2. Click **Modern Contact Card Access**
3. Click **Manage Assignments**
4. Click **Add Assignment**
5. Select the users who need access
6. Click **Next** → **Assign**

#### Option B: Assign via CLI

```bash
sf org assign permset --name Modern_Contact_Card_Access --target-org YOUR_ORG_ALIAS
```

To assign to specific users:

```bash
sf org assign permset --name Modern_Contact_Card_Access --on-behalf-of user@example.com --target-org YOUR_ORG_ALIAS
```

---

## Adding the Component to Record Pages

### Supported Record Pages

The component can be added to:
- **Contact** record pages
- **Case** record pages
- **Messaging Session** record pages
- **Voice Call** record pages (requires additional configuration)

### Steps to Add the Component

1. Navigate to a **Contact** record in your org
2. Click the **gear icon** (⚙️) → **Edit Page**
3. In Lightning App Builder, find **"Modern Contact Card"** in the Components panel (left side)
4. Drag the component onto the page layout
5. Configure the component properties in the right panel (see next section)
6. Click **Save**
7. If prompted, **Activate** the page:
   - Choose **Org Default** to apply to all users, or
   - Choose **App Default** or **App, Record Type, and Profile** for targeted activation
8. Click **Save** again

Repeat for Case, Messaging Session, or Voice Call pages as needed.

---

## Configuring the Component

After adding the component to a page, configure it using the properties panel on the right side of Lightning App Builder.

### Theme Settings

| Property | Description | Default |
|----------|-------------|---------|
| **Theme Mode** | Light or Dark theme | Light |

### Profile & Header Settings

| Property | Description | Default |
|----------|-------------|---------|
| **Profile Image Field** | Contact field API name for profile picture | `ContactCardPicture__c` |
| **Fallback Image URL** | URL if Contact field is empty | (blank) |
| **Background Image Field** | Contact field API name for header background | `ContactCardBackground__c` |
| **Default Background URL** | URL if Contact field is empty (leave blank for gradient) | (blank) |

### Health Score Settings

| Property | Description | Default |
|----------|-------------|---------|
| **Show Health Score** | Display the health pill | Checked |
| **Health Score Field** | Contact field API name | `ContactCardHealthScore__c` |
| **Health Score Label** | Label before the score | "Health" |
| **Health Score Fallback** | Value if field is empty | (blank) |

The health score color automatically adjusts:
- **0-30**: Red → Orange
- **31-50**: Orange → Yellow
- **51-70**: Yellow → Light Green
- **71-100**: Light Green → Green

### Tags Settings

| Property | Description | Default |
|----------|-------------|---------|
| **Show Tags** | Display tag pills | Checked |
| **Tags Field** | Contact field API name | `ContactCardTags__c` |
| **Fallback Tags** | Comma-separated tags if field is empty | (blank) |

### Brand Affinities Settings

| Property | Description | Default |
|----------|-------------|---------|
| **Show Brand Affinities** | Display brand tiles section | Unchecked |

When enabled, the component reads from these Contact fields:
- `Brand_1_Name__c` / `Brand_1_Image__c`
- `Brand_2_Name__c` / `Brand_2_Image__c`
- `Brand_3_Name__c` / `Brand_3_Image__c`
- `Brand_4_Name__c` / `Brand_4_Image__c`

### Metric Fields (1-6)

Each metric field can be configured:

| Property | Description | Example |
|----------|-------------|---------|
| **Show Field X** | Toggle visibility | Checked |
| **Field X Label** | Header text | "MEMBER ID" |
| **Field X Icon** | SLDS icon name | `utility:number_input` |
| **Field X Fallback** | Value if `Contact.Metric_X__c` is empty | "12345" |

**Common SLDS Icons:**
- `utility:user` - Person
- `utility:money` - Currency
- `utility:date_input` - Calendar
- `utility:ribbon` - Award/tier
- `utility:number_input` - ID number
- `utility:event` - Event/date

Full icon list: https://www.lightningdesignsystem.com/icons/

### Chart Settings

| Property | Description | Default |
|----------|-------------|---------|
| **Show CSAT Chart** | Toggle chart visibility | Checked |
| **Chart Title** | Title above the chart | "CSAT History" |
| **Engagement Data** | Comma-separated values (0-100) | Sample data |
| **Satisfaction Data** | Comma-separated values (0-100) | Sample data |
| **Chart Labels** | Comma-separated x-axis labels | "W14,W19,..." |
| **Engagement Line Color** | Hex color for line 1 | `#0176d3` |
| **Satisfaction Line Color** | Hex color for line 2 | `#1b96ff` |

---

## Populating Contact Data

For the component to display real data, populate the custom fields on Contact records.

### Manual Entry

1. Open a **Contact** record
2. Click **Edit**
3. Fill in the custom fields:
   - **Contact Card Picture**: URL to profile image
   - **Contact Card Background**: URL to header background image
   - **Contact Card Health Score**: Number 0-100
   - **Contact Card Tags**: Comma-separated values (e.g., "VIP, Premium, Enterprise")
   - **Metric 1-6**: Values for each metric field
   - **Brand 1-4 Name/Image**: Brand names and logo URLs

### Bulk Update via Data Loader

1. Export Contact records with their IDs
2. Add columns for the custom fields
3. Import using Salesforce Data Loader or Data Import Wizard

### Example Field Values

| Field | Example Value |
|-------|---------------|
| `ContactCardPicture__c` | `https://example.com/photos/john-smith.jpg` |
| `ContactCardBackground__c` | `https://example.com/banners/blue-gradient.jpg` |
| `ContactCardHealthScore__c` | `82` |
| `ContactCardTags__c` | `VIP, High Spender, Decision Maker` |
| `Metric_1__c` | `135425` |
| `Metric_2__c` | `Tier 5` |
| `Brand_1_Name__c` | `MARRIOTT` |
| `Brand_1_Image__c` | `https://example.com/logos/marriott.png` |

---

## Optional: VoiceCall Configuration

If you want to use this component on **Voice Call** record pages:

### Prerequisites

- Service Cloud Voice enabled in your org
- A **Contact lookup field** on the Voice Call object

### Configuration Steps

1. Open a Voice Call record page in Lightning App Builder
2. Add the **Modern Contact Card** component
3. In the component properties, find **"VoiceCall Contact Field"**
4. Enter the API name of your Contact lookup field (e.g., `Contact__c`)
5. Save and activate the page

**Note:** This field is left blank by default to avoid package dependencies. The component will only query VoiceCall contact data if this field is configured.

---

## Troubleshooting

### Component Not Appearing in Lightning App Builder

**Cause:** Deployment may have failed or component not exposed.

**Solution:**
1. Verify deployment succeeded: `sf project deploy report`
2. Check that `isExposed` is `true` in the component metadata
3. Clear browser cache and refresh Lightning App Builder

### Profile Image Not Displaying

**Cause:** Field not populated or URL inaccessible.

**Solution:**
1. Verify the Contact record has a value in `ContactCardPicture__c`
2. Ensure the image URL is publicly accessible (not behind authentication)
3. Check browser console for CORS errors
4. Try a different image hosting service if needed

### Custom Fields Not Visible

**Cause:** User doesn't have Field-Level Security access.

**Solution:**
1. Assign the **Modern Contact Card Access** permission set to the user
2. Or manually grant FLS via Profile or Permission Set

### Health Score Color Not Changing

**Cause:** Field value is not a number or is out of range.

**Solution:**
1. Ensure `ContactCardHealthScore__c` contains a numeric value
2. Value should be between 0 and 100

### Component Shows "Contact Name" / "Location" Placeholder

**Cause:** Contact ID not resolved from parent record.

**Solution:**
1. For **Case**: Ensure the Case has a Contact in the `ContactId` field
2. For **Messaging Session**: Ensure `EndUserContactId` is populated
3. For **Voice Call**: Configure the VoiceCall Contact Field property

### Chart Not Rendering

**Cause:** Canvas element not initialized or data format incorrect.

**Solution:**
1. Ensure **Show CSAT Chart** is checked
2. Verify data is comma-separated numbers (e.g., "55,60,65,70")
3. Refresh the page

---

## Support

For issues or feature requests, please open an issue on GitHub:
https://github.com/sfdc-brendan/Demo-Lab/issues

---

## Quick Reference Card

| Task | Action |
|------|--------|
| Deploy | `sf project deploy start --manifest manifest/package.xml --target-org ALIAS` |
| Assign Permission Set | `sf org assign permset --name Modern_Contact_Card_Access` |
| Add to Page | Setup → Edit Page → Drag "Modern Contact Card" |
| Configure | Click component → Edit properties in right panel |

---

*Last updated: February 2026*
