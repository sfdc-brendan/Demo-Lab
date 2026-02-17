# Modern Contact Card

A configurable contact card Lightning Web Component with profile information, health scores, tags, brand affinities, and CSAT charts.

## Preview

![Modern Contact Card Preview](assets/preview.png)

## Features

- **Header Background Banner**: Gradient background with optional custom image
- **Dynamic Contact Data**: Retrieves contact from related records (Case, MessagingSession, VoiceCall)
- **Health Score Pill**: Color-coded indicator (red/orange/yellow/green based on 0-100)
- **Contact Tags**: Comma-separated tags as colorful pills
- **Brand Affinities**: Up to 4 brand logos/badges
- **Light/Dark Theme**: Configurable theme mode
- **Customizable Metrics**: 6 configurable data fields
- **CSAT Chart**: Dual-line chart with customizable colors

## Supported Record Pages

- Contact
- Case (resolves Contact from `ContactId`)
- MessagingSession (resolves Contact from `EndUserContactId`)
- VoiceCall (configurable Contact lookup field)

---

## Installation

### Deploy Everything at Once (Recommended)

```bash
sf project deploy start --manifest manifest/package.xml --target-org YOUR_ORG_ALIAS
```

### Post-Installation

1. Assign the **Modern Contact Card Access** permission set to users
2. Add the component to record pages via Lightning App Builder
3. Configure settings as needed

---

## Configuration

### Component Settings

| Category | Settings |
|----------|----------|
| **Theme** | Light/Dark mode |
| **Header** | Background image field/URL |
| **Profile** | Image field, fallback URL |
| **Health Score** | Field, label, fallback, show/hide |
| **Tags** | Field, fallback, show/hide |
| **Brand Affinities** | Show/hide (uses Brand_1-4 fields on Contact) |
| **Metrics** | 6 configurable fields with labels, icons, fallbacks |
| **Chart** | Show/hide, title, data, labels, colors |
| **VoiceCall** | Contact lookup field name |

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

## Package Contents

| Component | Type | Description |
|-----------|------|-------------|
| `modernContactCard` | LWC | Contact card component |
| `Modern_Contact_Card_Access` | Permission Set | FLS for Contact custom fields |
| 18 Custom Fields | CustomField | Fields on Contact object |

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
            ├── lwc/
            │   └── modernContactCard/
            │       ├── modernContactCard.css
            │       ├── modernContactCard.html
            │       ├── modernContactCard.js
            │       └── modernContactCard.js-meta.xml
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

---

## License

Provided as-is for demonstration purposes.
