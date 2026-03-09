# Lunar Basecamp Outfitters — Extreme Environment Retail & Lunar Recreation

> Premium hiking gear engineered for lunar craters, lava tubes, and the most hostile terrain humanity has ever explored.

| | |
|---|---|
| **Industry** | Space & Recreation |
| **Difficulty** | Intermediate |
| **Est. Time** | ~45 min |
| **Key Products** | Screen Flows, LWC (lightning-map, Chart.js), Junction Objects |

---

## The Challenge

Managing complex inventory of pressure suits, oxygen systems, and specialized gear that requires strict compliance tracking, customer certification levels, and rental/purchase history. Each customer needs documented training records and equipment compatibility verification before any lunar expedition.

## What We're Building

A system to track customers, their certification levels, gear rentals/purchases, upcoming lunar expeditions, and automated safety compliance checks.

## Custom Objects

| Object | Purpose |
|--------|---------|
| `Lunar_Explorer__c` | Customers — EVA hours, certification level, medical clearance |
| `Gear_Item__c` | Equipment inventory — suits, O2 systems, boots, tethers, status |
| `Expedition_Booking__c` | Upcoming missions — landing site, dates, cost, compliance status |
| `Safety_Certification__c` | Training records — cert type, expiry, pass/fail per explorer |
| `Expedition_Gear__c` | Junction — links gear items to expeditions with quantities |

## LWC Wow Moment

An interactive mission control dashboard showing upcoming lunar expeditions with customer photos, gear manifests, and a visual moon map with landing coordinates.

---

## Prerequisites

- A Salesforce scratch org or sandbox
- Salesforce CLI (`sf`) installed and authenticated
- Cursor IDE

---

## Step 00 — Project Scaffold (run in terminal before opening Cursor)

Run these commands in your terminal to create the SFDX project and set your target org:

```bash
sf project generate --name lunar-basecamp
cd lunar-basecamp
sf org list
sf config set target-org <your-org-alias>
```

Then open the `lunar-basecamp` folder in Cursor and proceed with Step 01.

---

## Step 01 — Custom Objects

Open Cursor Agent and paste:

```
Create these Salesforce custom objects for Lunar Basecamp Outfitters: 1) Lunar_Explorer__c with fields: Full_Name__c (Text), Email__c (Email), EVA_Hours__c (Number for extravehicular activity experience), Certification_Level__c (Picklist: Novice Crater Walker, Advanced Lava Tube Explorer, Master Lunar Alpinist), Medical_Clearance_Date__c (Date), Emergency_Contact__c (Text). 2) Gear_Item__c with fields: Item_Name__c (Text), Category__c (Picklist: Pressure Suit, Oxygen System, Boots, Gloves, Tether Kit, Crater Anchor, Communication Device), Serial_Number__c (Text, Unique), Maintenance_Due_Date__c (Date), Status__c (Picklist: Available, Rented, Maintenance, Retired), Daily_Rental_Rate__c (Currency), Purchase_Price__c (Currency). 3) Expedition_Booking__c with fields: Expedition_Name__c (Text), Explorer__c (Lookup to Lunar_Explorer__c), Launch_Date__c (Date), Return_Date__c (Date), Landing_Site__c (Picklist: Tycho Crater, Shackleton Rim, Hadley Rille, Mare Tranquillitatis, Aristarchus Plateau), Status__c (Picklist: Planned, Confirmed, In Progress, Completed, Cancelled), Total_Cost__c (Currency). 4) Safety_Certification__c with fields: Explorer__c (Lookup to Lunar_Explorer__c), Certification_Type__c (Picklist: Basic EVA, Crater Navigation, Emergency Repair, Low-G Climbing, Solar Radiation Protocol), Issued_Date__c (Date), Expiry_Date__c (Date), Instructor_Name__c (Text), Pass_Status__c (Checkbox). Also create a junction object Expedition_Gear__c with master-detail relationships to both Expedition_Booking__c and Gear_Item__c, plus a Quantity__c (Number) field.
```

---

## Step 02 — Sample Data

```
Create realistic sample data for Lunar Basecamp Outfitters: 1) Create 5 Lunar_Explorer__c records with names like 'Sarah Chen', 'Marcus Rodriguez', 'Yuki Tanaka', 'Dmitri Volkov', 'Amara Okonkwo' with varying EVA_Hours__c (50-500), Certification_Level__c ranging from Novice to Master, and Medical_Clearance_Date__c within the last 6 months. 2) Create 15 Gear_Item__c records including items like 'Apollo Heritage Pressure Suit X7', 'CraterGrip Magnetic Boots', 'HorizonLink Comm Headset', 'TitanThread Tether Kit', 'LunarBreath O2 System', 'ShackletonPro Ice Anchor Set' with realistic serial numbers like LBO-2024-001, varying statuses, rental rates between $500-$5000/day, and purchase prices between $15000-$250000. 3) Create 8 Expedition_Booking__c records with expedition names like 'Tycho Shadow Traverse', 'Mare Tranquillitatis Heritage Walk', 'Shackleton Ice Core Expedition', with launch dates spread over the next 6 months, linking to the explorers created, and total costs between $50000-$500000. 4) Create 12 Safety_Certification__c records linking explorers to various certifications, with some expired and some current. 5) Create Expedition_Gear__c junction records linking gear items to expeditions with realistic quantities.
```

---

## Step 03 — Permission Sets

```
Create a permission set called Lunar_Basecamp_Admin that grants full CRUD (Create, Read, Edit, Delete) access to all custom objects: Lunar_Explorer__c, Gear_Item__c, Expedition_Booking__c, Safety_Certification__c, and Expedition_Gear__c. Include View All and Modify All permissions for each object. Also grant access to all custom fields on these objects including all picklist values, lookups, and master-detail relationships.
```

---

## Step 04 — Flows & Automations

```
Create a Salesforce Screen Flow called 'Pre_Expedition_Safety_Check' that runs when an Expedition_Booking__c Status changes to 'Confirmed'. The flow should: 1) Query all Safety_Certification__c records for the linked Lunar_Explorer__c. 2) Check if they have valid (non-expired) certifications for Basic EVA, Crater Navigation, and Solar Radiation Protocol. 3) Check if their Medical_Clearance_Date__c is within the last 90 days. 4) If any checks fail, send an email alert to the expedition coordinator with details of missing/expired certifications and update a custom field Compliance_Status__c (Picklist: Cleared, Pending, Blocked) on the Expedition_Booking__c to 'Blocked'. 5) If all checks pass, set Compliance_Status__c to 'Cleared' and create a Task for gear assignment. Make sure to add the Compliance_Status__c field to Expedition_Booking__c as part of this prompt.
```

---

## Step 05 — Deploy to Org

```
Deploy all metadata to the Salesforce scratch org using these SFDX commands: First run 'sfdx force:source:status' to verify all local changes are tracked. Then run 'sfdx force:source:deploy -p force-app/main/default -u [scratch-org-alias] --wait 10' to deploy all custom objects, fields, flows, and permission sets. After successful deployment, run 'sfdx force:data:tree:import -p data/sample-data-plan.json -u [scratch-org-alias]' to load the sample data. Finally run 'sfdx force:user:permset:assign -n Lunar_Basecamp_Admin -u [scratch-org-alias]' to assign the permission set to the current user. Include error handling to check deployment status and rollback if needed.
```

---

## Step 06 — Lightning Web Component

```
Create a Lightning Web Component called 'lunarExpeditionDashboard' that displays an interactive mission control view. The component should: 1) Query and display all Expedition_Booking__c records with Status 'Confirmed' or 'In Progress' in a visually striking card layout. 2) Each expedition card shows: expedition name, explorer name with photo placeholder, launch date with countdown timer, landing site with a small moon surface icon, compliance status badge (green/yellow/red), and total gear items assigned. 3) Include a lightning-map component showing landing coordinates for each expedition (use approximate coordinates for lunar locations). 4) Add a chart using Chart.js or Lightning Charts showing expedition bookings by month and by landing site. 5) Use Salesforce Lightning Design System (SLDS) with a dark space-themed color scheme (dark blues, silvers, accent orange for alerts). 6) Make it responsive for desktop and tablet. 7) Add a refresh button and auto-refresh every 30 seconds. Include the HTML, JavaScript, and meta.xml files with proper API version and exposure settings for Lightning App Builder.
```

---

## Step 07 — Push to GitHub

```
Initialize a git repository in the current Salesforce DX project directory with these steps: 1) Run 'git init' to create the repo. 2) Create a .gitignore file that excludes: .sfdx/, .sf/, .vscode/, node_modules/, coverage/, .DS_Store, *.log, .localdevserver/, and any scratch org config files. 3) Run 'git add .' to stage all project files. 4) Create an initial commit with message 'Initial commit: Lunar Basecamp Outfitters Salesforce org with custom objects, flows, and expedition dashboard LWC'. 5) Create a new repository on GitHub called 'lunar-basecamp-outfitters-sfdc' with description 'Salesforce implementation for Lunar Basecamp Outfitters - managing lunar hiking expeditions, gear inventory, and explorer certifications'. 6) Add the GitHub remote with 'git remote add origin [repository-url]'. 7) Push to GitHub with 'git push -u origin main'. Include a README.md file with project overview, setup instructions for scratch org creation, and deployment steps.
```

---

## Architecture Overview

```
Step 00: sf project generate          →  SFDX project scaffold
Step 01: Custom Objects               →  Lunar_Explorer__c, Gear_Item__c, Expedition_Booking__c, Safety_Certification__c, Expedition_Gear__c (junction)
Step 02: Sample Data                  →  5 explorers, 15 gear items, 8 expeditions, 12 certifications, junction records
Step 03: Permission Sets              →  Lunar_Basecamp_Admin
Step 04: Flows                        →  Pre_Expedition_Safety_Check (compliance validation on booking confirmation)
Step 05: Deploy                       →  Metadata + data import + permission assignment
Step 06: LWC                          →  lunarExpeditionDashboard (mission control with moon map & countdown timers)
Step 07: Git                          →  Push to GitHub
```

---

> **Disclaimer:** This scenario is for demonstration and educational purposes only. Do not deploy to production environments. Code is provided "as-is" without warranty.
