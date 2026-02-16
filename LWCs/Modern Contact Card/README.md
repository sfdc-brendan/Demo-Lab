# Modern Card Components

A collection of modern, customizable Lightning Web Components for displaying record information with sleek designs following SLDS 2 standards.

## Components

| Component | Object | Use Case |
|-----------|--------|----------|
| **Modern Contact Card** | Contact, Case, MessagingSession, VoiceCall | Service Cloud, customer profiles |
| **Modern Account Card** | Account | Revenue Cloud, B2B sales |

---

## Modern Contact Card

A configurable contact card with profile information, health scores, tags, brand affinities, and CSAT charts.

### Preview

![Modern Contact Card Preview](assets/preview.png)

### Features

- **Header Background Banner**: Gradient background with optional custom image
- **Dynamic Contact Data**: Retrieves contact from related records (Case, MessagingSession, VoiceCall)
- **Health Score Pill**: Color-coded indicator (red/orange/yellow/green based on 0-100)
- **Contact Tags**: Comma-separated tags as colorful pills
- **Brand Affinities**: Up to 4 brand logos/badges
- **Light/Dark Theme**: Configurable theme mode
- **Customizable Metrics**: 6 configurable data fields
- **CSAT Chart**: Dual-line chart with customizable colors

### Supported Record Pages

- Contact
- Case (resolves Contact from `ContactId`)
- MessagingSession (resolves Contact from `EndUserContactId`)
- VoiceCall (configurable Contact lookup field)

---

## Modern Account Card

A Revenue Cloud-focused account card with real-time metrics from Quotes, Orders, Assets, and Invoices.

### Features

- **Account Header**: Logo, name, industry, type, location, employees
- **Real-Time Metrics**: Pulls live data from related records via Apex
- **Fallback Values**: Configurable defaults when no data exists
- **Revenue Trend Chart**: Dual-line chart for visualizing trends
- **Light/Dark Theme**: Configurable theme mode

### Revenue Cloud Metrics

| Metric | Data Source | Description |
|--------|-------------|-------------|
| Quote Count | `COUNT(Quote)` | Number of quotes for the account |
| Quote Value | `SUM(Quote.TotalPrice)` | Total value of all quotes |
| Active Assets | `COUNT(Asset)` | Number of assets for the account |
| Order Value | `SUM(Order.TotalAmount)` | Total value of all orders |
| Invoice Total | `SUM(Invoice.TotalAmount)` | Total invoiced amount |

### Standard Account Fields Displayed

- Name, Industry, Type
- Billing City/State (location)
- Number of Employees

---

## Installation

### Deploy Everything at Once (Recommended)

```bash
sf project deploy start --manifest manifest/package.xml --target-org YOUR_ORG_ALIAS
```

### Deploy Components Individually

**Contact Card only:**
```bash
sf project deploy start --source-dir "force-app/main/default/lwc/modernContactCard" --source-dir "force-app/main/default/objects" --source-dir "force-app/main/default/permissionsets" --target-org YOUR_ORG_ALIAS
```

**Account Card only:**
```bash
sf project deploy start --source-dir "force-app/main/default/lwc/modernAccountCard" --source-dir "force-app/main/default/classes" --target-org YOUR_ORG_ALIAS
```

### Post-Installation

1. **For Contact Card**: Assign the **Modern Contact Card Access** permission set
2. Add components to record pages via Lightning App Builder
3. Configure settings as needed

---

## Package Contents

| Component | Type | Description |
|-----------|------|-------------|
| `modernContactCard` | LWC | Contact card component |
| `modernAccountCard` | LWC | Account card component |
| `ModernAccountCardController` | Apex | Fetches aggregated metrics |
| `Modern_Contact_Card_Access` | Permission Set | FLS for Contact custom fields |
| 18 Custom Fields | CustomField | Fields on Contact object |

---

## Configuration

### Modern Contact Card Settings

| Category | Settings |
|----------|----------|
| **Theme** | Light/Dark mode |
| **Header** | Background image field/URL |
| **Profile** | Image field, fallback URL |
| **Health Score** | Field, label, fallback, show/hide |
| **Tags** | Field, fallback, show/hide |
| **Brand Affinities** | Show/hide (uses Brand_1-4 fields) |
| **Metrics** | 6 configurable fields with labels, icons, fallbacks |
| **Chart** | Show/hide, title, data, labels, colors |
| **VoiceCall** | Contact lookup field name |

### Modern Account Card Settings

| Category | Settings |
|----------|----------|
| **Theme** | Light/Dark mode |
| **Header** | Background image URL |
| **Logo** | Logo URL, fallback URL |
| **Metrics** | Show/hide each metric, custom labels, fallback values |
| **Chart** | Show/hide, title, data, labels, colors |

---

## Custom Fields (Contact)

| Field API Name | Type | Description |
|----------------|------|-------------|
| `ContactCardPicture__c` | URL | Profile image |
| `ContactCardBackground__c` | URL | Header background |
| `ContactCardHealthScore__c` | Number | Health score (0-100) |
| `ContactCardTags__c` | Text | Comma-separated tags |
| `Metric_1__c` - `Metric_6__c` | Text | Custom metric values |
| `Brand_1_Name__c` - `Brand_4_Name__c` | Text | Brand names |
| `Brand_1_Image__c` - `Brand_4_Image__c` | URL | Brand logos |

---

## File Structure

```
Modern Contact Card/
├── README.md
├── INSTALL.md
├── manifest/
│   └── package.xml
├── assets/
│   └── preview.png
└── force-app/
    └── main/
        └── default/
            ├── classes/
            │   ├── ModernAccountCardController.cls
            │   └── ModernAccountCardController.cls-meta.xml
            ├── lwc/
            │   ├── modernContactCard/
            │   │   ├── modernContactCard.css
            │   │   ├── modernContactCard.html
            │   │   ├── modernContactCard.js
            │   │   └── modernContactCard.js-meta.xml
            │   └── modernAccountCard/
            │       ├── modernAccountCard.css
            │       ├── modernAccountCard.html
            │       ├── modernAccountCard.js
            │       └── modernAccountCard.js-meta.xml
            ├── objects/
            │   └── Contact/
            │       └── fields/
            │           └── (18 custom field definitions)
            └── permissionsets/
                └── Modern_Contact_Card_Access.permissionset-meta.xml
```

---

## Requirements

- Salesforce org with Lightning Experience
- API version 62.0 or higher
- For Account Card metrics: Quote, Order, Asset, Invoice objects (Revenue Cloud)

---

## License

Provided as-is for demonstration purposes.
