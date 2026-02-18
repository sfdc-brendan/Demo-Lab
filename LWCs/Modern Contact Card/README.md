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

### Quick Install (5 Steps)

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

# 5. Open org and add component to Contact/Case/MessagingSession page
sf org open --target-org my-org
```

See **[INSTALL.md](INSTALL.md)** for detailed step-by-step instructions including troubleshooting.

### Post-Installation

1. Assign the **Modern Contact Card Access** permission set to users
2. Add the component to record pages via Lightning App Builder (Contact, Case, Messaging Session, or Voice Call)
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
├── sfdx-project.json
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
