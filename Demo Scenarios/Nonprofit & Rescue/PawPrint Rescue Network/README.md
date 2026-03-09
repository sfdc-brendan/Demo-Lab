# PawPrint Rescue Network — Animal Shelter & Rescue

> Coordinating foster care and adoptions across a network of animal rescue partners.

| | |
|---|---|
| **Industry** | Nonprofit & Rescue |
| **Difficulty** | Beginner |
| **Est. Time** | ~35 min |
| **Key Products** | Screen Flows, LWC, Record-Triggered Flows |

---

## The Challenge

Animal rescues struggle to track animals across multiple foster homes, coordinate veterinary care, and match adoptable pets with qualified families. Paper forms and spreadsheets lead to lost information and missed adoption opportunities.

## What We're Building

A system to track rescue animals, foster placements, medical records, and adoption applications with automated matching.

## Custom Objects

| Object | Purpose |
|--------|---------|
| `Rescue_Animal__c` | Animals in the network — species, breed, temperament, availability |
| `Foster_Home__c` | Foster families — capacity, experience, species preferences |
| `Adoption_Application__c` | Prospective adopter applications linked to specific animals |
| `Medical_Record__c` | Vet visits, vaccinations, procedures, and costs per animal |

## LWC Wow Moment

An interactive adoption gallery LWC showing available animals with photos, filtering by species/age/temperament, and quick-apply buttons with real-time availability status.

---

## Prerequisites

- A Salesforce scratch org or sandbox
- Salesforce CLI (`sf`) installed and authenticated
- Cursor IDE

---

## Step 00 — Project Scaffold (run in terminal before opening Cursor)

Run these commands in your terminal to create the SFDX project and set your target org:

```bash
sf project generate --name pawprint-rescue
cd pawprint-rescue
sf org list
sf config set target-org <your-org-alias>
```

Then open the `pawprint-rescue` folder in Cursor and proceed with Step 01.

---

## Step 01 — Custom Objects

Open Cursor Agent and paste:

```
Create four custom Salesforce objects for an animal rescue network: 1) Rescue_Animal__c with fields: Name (text), Species__c (picklist: Dog, Cat, Rabbit, Bird), Breed__c (text), Age_Years__c (number), Weight_Pounds__c (number), Temperament__c (picklist: Shy, Friendly, Energetic, Calm), Intake_Date__c (date), Status__c (picklist: In Foster, Available, Adopted, Medical Hold), Special_Needs__c (long text area), Photo_URL__c (URL). 2) Foster_Home__c with fields: Foster_Name__c (text), Address__c (text), Phone__c (phone), Email__c (email), Max_Animals__c (number), Preferred_Species__c (multi-select picklist: Dog, Cat, Rabbit, Bird), Experience_Level__c (picklist: Beginner, Intermediate, Advanced), Home_Type__c (picklist: Apartment, House, Farm). 3) Adoption_Application__c with fields: Applicant_Name__c (text), Email__c (email), Phone__c (phone), Home_Type__c (picklist: Apartment, House, Farm), Has_Yard__c (checkbox), Other_Pets__c (long text), Application_Date__c (date), Status__c (picklist: Submitted, Under Review, Approved, Denied), Animal__c (lookup to Rescue_Animal__c). 4) Medical_Record__c with fields: Animal__c (lookup to Rescue_Animal__c), Visit_Date__c (date), Veterinarian__c (text), Procedure__c (text), Vaccinations__c (multi-select picklist: Rabies, DHPP, FVRCP, Bordetella), Medications__c (long text), Follow_Up_Date__c (date), Cost__c (currency). Also create a lookup relationship from Rescue_Animal__c to Foster_Home__c called Current_Foster__c.
```

---

## Step 02 — Sample Data

```
Create realistic sample data for PawPrint Rescue Network: 1) Create 12 Rescue_Animal__c records with diverse names like 'Biscuit', 'Luna', 'Chester', 'Muffin', 'Shadow', 'Peanut', 'Oliver', 'Daisy', 'Max', 'Willow', 'Thumper', 'Tweety' spanning Dogs, Cats, Rabbits, and one Bird. Mix ages from 6 months to 8 years, weights appropriate to species, varied temperaments, and statuses (6 Available, 4 In Foster, 2 Adopted). Include realistic special needs for 3 animals like 'Needs daily medication for arthritis' or 'Must be only pet'. 2) Create 5 Foster_Home__c records with realistic foster parent names, addresses in various neighborhoods, mix of apartments and houses, different max animal capacities (1-4), and varied experience levels. 3) Create 8 Adoption_Application__c records with realistic applicant names and contact info, mix of home types, some with yards, some with other pets described. Link 6 applications to specific available animals, with statuses: 3 Submitted, 3 Under Review, 2 Approved. 4) Create 15 Medical_Record__c records distributed across the animals, with realistic vet visits from the past 3 months, common procedures like 'Spay/Neuter', 'Dental Cleaning', 'Vaccination Update', appropriate vaccinations for species, and costs ranging from $50-$350. Link the 4 'In Foster' animals to appropriate foster homes.
```

---

## Step 03 — Permission Sets

```
Create a permission set named PawPrint_Admin that grants full CRUD (Create, Read, Edit, Delete) access to all four custom objects: Rescue_Animal__c, Foster_Home__c, Adoption_Application__c, and Medical_Record__c. Include field-level security granting read and edit access to all custom fields on these objects. Also grant View All and Modify All permissions on these objects so admins can see and manage all records across the organization.
```

---

## Step 04 — Flows & Automations

```
Create a Salesforce Screen Flow called 'Quick_Adoption_Application' that allows potential adopters to submit an application. The flow should: 1) Start with a screen collecting Applicant_Name__c, Email__c, Phone__c with validation that all fields are required. 2) Second screen with Home_Type__c (radio buttons), Has_Yard__c (checkbox), and Other_Pets__c (text area for description). 3) Third screen displaying a picklist of available Rescue_Animal__c records (where Status__c = 'Available') showing Name and Species, allowing user to select which animal they're interested in. 4) Create the Adoption_Application__c record with all collected data, Status__c set to 'Submitted', and Application_Date__c set to today. 5) Final screen confirming submission with the application number and message 'Thank you! We'll review your application within 3 business days.' Also create a Record-Triggered Flow called 'Animal_Status_Update' that runs when Adoption_Application__c Status__c changes to 'Approved' and automatically updates the related Rescue_Animal__c Status__c to 'Adopted'.
```

---

## Step 05 — Deploy to Org

```
Deploy all metadata to the Salesforce scratch org using SFDX CLI commands. First, verify the scratch org is active with 'sf org list'. Then deploy all custom objects, fields, permission sets, and flows using 'sf project deploy start --target-org [scratch-org-alias]'. After deployment succeeds, assign the PawPrint_Admin permission set to the current user with 'sf org assign permset --name PawPrint_Admin'. Finally, import the sample data by deploying the data folder with 'sf data import tree --plan data/plan.json'. Run 'sf org open' to verify deployment and view the org.
```

---

## Step 06 — Lightning Web Component

```
Create a Lightning Web Component called 'adoptionGallery' that displays an interactive grid of available rescue animals. The component should: 1) Use @wire to query Rescue_Animal__c records where Status__c = 'Available', retrieving Name, Species__c, Breed__c, Age_Years__c, Temperament__c, Special_Needs__c, and Photo_URL__c. 2) Display animals as cards in a responsive grid (3 columns on desktop, 2 on tablet, 1 on mobile) using lightning-card. Each card shows the animal's photo (or placeholder paw icon if no URL), name as the card title, species and breed as subtitle, age in years with a cake emoji, temperament with a heart emoji, and a 'Learn More' button. 3) Include filter buttons at the top for 'All', 'Dogs', 'Cats', and 'Other' that filter the displayed cards by species. Use lightning-button-group for filters with the active filter highlighted. 4) When 'Learn More' is clicked, show a modal with full details including special needs and a prominent 'Apply to Adopt' button that navigates to the Quick_Adoption_Application flow with the animal Id pre-filled. 5) Style the component with a warm color scheme (oranges and browns), rounded corners on cards, and smooth hover effects that slightly enlarge cards. Add an empty state with a friendly message and paw prints if no animals match the filter. Include the component's JS, HTML, XML meta file, and CSS with modern styling.
```

---

## Step 07 — Push to GitHub

```
Initialize a Git repository for the PawPrint Rescue Network Salesforce project and push to GitHub. First, run 'git init' in the project root directory. Create a .gitignore file that excludes: .sfdx/, .sf/, .vscode/, node_modules/, .DS_Store, *.log, .localdevserver/, and .eslintcache. Stage all files with 'git add .' and commit with message 'Initial commit: PawPrint Rescue Network - Animal rescue management system with custom objects, flows, and adoption gallery LWC'. Create a README.md with project title, description ('Salesforce application for animal rescue organizations to manage rescue animals, foster placements, medical records, and adoption applications'), setup instructions (scratch org creation, deployment commands), and key features list. Then create a new GitHub repository named 'pawprint-rescue-salesforce', set it as the remote origin with 'git remote add origin [repo-url]', and push with 'git push -u origin main'.
```

---

## Architecture Overview

```
Step 00: sf project generate          →  SFDX project scaffold
Step 01: Custom Objects               →  Rescue_Animal__c, Foster_Home__c, Adoption_Application__c, Medical_Record__c
Step 02: Sample Data                  →  12 animals, 5 foster homes, 8 applications, 15 medical records
Step 03: Permission Sets              →  PawPrint_Admin
Step 04: Flows                        →  Quick_Adoption_Application (screen), Animal_Status_Update (record-triggered)
Step 05: Deploy                       →  Metadata + data import + permission assignment
Step 06: LWC                          →  adoptionGallery (interactive animal card grid with filters)
Step 07: Git                          →  Push to GitHub
```

---

> **Disclaimer:** This scenario is for demonstration and educational purposes only. Do not deploy to production environments. Code is provided "as-is" without warranty.
