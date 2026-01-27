# sdo_ContactCard

A Lightning Web Component that displays a **Contact Card**—a compact, configurable card with the contact’s profile, key details, optional custom metrics, and a CSAT-style chart.

## What It Does

- **Shows contact context** – Name, location (city/state), email, phone, and an optional profile image.
- **Supports custom metrics** – Up to 5 configurable metric fields (labels, icons, and visibility controlled in App Builder).
- **Includes a CSAT chart** – Dual-line chart for engagement and satisfaction-style data, with configurable labels and data.
- **Adapts to the page** – On a **Contact** record it shows that contact; on **Case**, **Messaging Session**, or **Voice Call** it finds the related Contact and shows that.

## Where You Can Use It

The component is available on:

- **Record pages** for: Contact, Account, Lead, Case, MessagingSession, VoiceCall  
- **App** and **Home** pages  
- **Experience/Community** pages  

Add it via App Builder (Lightning App Builder or Experience Builder) and place it where you want the card to appear.

## How It Finds the Contact

| Page Type        | How the Contact is resolved                                  |
|------------------|---------------------------------------------------------------|
| **Contact**      | The current record (Contact record page).                     |
| **Case**         | `Case.ContactId` on the Case record.                          |
| **MessagingSession** | `MessagingSession.EndUserContactId` on the session.    |
| **Voice Call**   | `VoiceCall.Contact__c` (custom Contact lookup on Voice Call). |

On Contact pages the card uses the record’s Id. On other supported record types it loads the parent record, reads the Contact lookup field above, then loads and displays that Contact.

## Configuration (App Builder)

When you drop the component on a page, you can configure:

- **Theme** – Dark or Light.
- **Header color** – Hex color (e.g. `#0066CC`) for the header area.
- **Profile picture** – Show or hide.
- **Metrics 1–5** – Labels, SLDS icon names, and show/hide for each.
- **Chart** – Engagement data, satisfaction data, X-axis labels, and line labels (e.g. “Listening Score”, “Satisfaction Index”).

## Contact Fields Used

The card reads these Contact fields (custom ones must exist on Contact in your org):

- **Standard:** Name, Email, Phone, MailingCity, MailingState  
- **Custom (optional):**  
  - `ContactCardPicture__c` – URL for the profile image  
  - `Metric_1__c` … `Metric_5__c` – values for the 5 configurable metric rows  

If the custom fields are missing, the component still runs; those areas are simply empty or use defaults.

## Voice Call Requirement

For **Voice Call** record pages, the card uses the custom lookup **`Contact__c`** on the Voice Call object. Ensure that field exists and is populated when you want the card to show a contact on a Voice Call record.
