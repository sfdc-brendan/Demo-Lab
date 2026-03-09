# BrewCycle — Craft Beer Distribution

> Connecting microbreweries with bars, restaurants, and bottle shops through smart keg tracking and route optimization.

| | |
|---|---|
| **Industry** | Food & Beverage |
| **Difficulty** | Intermediate |
| **Est. Time** | ~45 min |
| **Key Products** | LWC (lightning-map), Record-Triggered Flows, Standard Account integration |

---

## The Challenge

Craft breweries lose thousands monthly on unreturned kegs and struggle to track which accounts have what inventory. Distributors waste time on inefficient delivery routes and can't predict when accounts need restocking.

## What We're Building

A keg tracking system with automated reorder flows and a visual dashboard showing real-time keg locations and account inventory levels.

## Custom Objects

| Object | Purpose |
|--------|---------|
| `Brewery__c` | Microbreweries — production volume, active keg counts |
| `Keg__c` | Individual kegs — beer style, size, status, current location |
| `Account_Inventory__c` | Keg-to-Account assignments — fill levels, reorder triggers |
| `Delivery_Route__c` | Driver routes — stops, schedules, delivery counts |

## LWC Wow Moment

An interactive map-based LWC showing kegs scattered across the city with color-coded status (full/half/empty/overdue return), clickable to see beer style and days at location.

---

## Prerequisites

- A Salesforce scratch org or sandbox
- Salesforce CLI (`sf`) installed and authenticated
- Cursor IDE

---

## Step 00 — Project Scaffold (run in terminal before opening Cursor)

Run these commands in your terminal to create the SFDX project and set your target org:

```bash
sf project generate --name brewcycle
cd brewcycle
sf org list
sf config set target-org <your-org-alias>
```

Then open the `brewcycle` folder in Cursor and proceed with Step 01.

---

## Step 01 — Custom Objects

Open Cursor Agent and paste:

```
Create four custom Salesforce objects for a craft beer keg tracking system:

1. Brewery__c with fields: Brewery_Name__c (text), City__c (text), Annual_Barrel_Production__c (number), Primary_Contact_Email__c (email), Active_Keg_Count__c (number rollup)

2. Keg__c with fields: Keg_ID__c (auto-number, external ID), Beer_Style__c (picklist: IPA, Stout, Lager, Pilsner, Sour, Porter), Keg_Size__c (picklist: Half Barrel, Quarter Barrel, Sixth Barrel), Current_Status__c (picklist: At Brewery, In Transit, At Account, Empty, Lost), Brewery__c (lookup to Brewery__c), Current_Account__c (lookup to Account), Days_At_Current_Location__c (number formula), Last_Movement_Date__c (date)

3. Account_Inventory__c with fields: Account__c (lookup to Account), Keg__c (lookup to Keg__c), Delivery_Date__c (date), Expected_Empty_Date__c (date), Current_Fill_Level__c (picklist: Full, Three-Quarters, Half, Quarter, Empty), Reorder_Needed__c (checkbox formula)

4. Delivery_Route__c with fields: Route_Name__c (text), Delivery_Driver__c (lookup to User), Scheduled_Date__c (date), Total_Stops__c (number), Route_Status__c (picklist: Planned, In Progress, Completed), Total_Kegs_Delivered__c (number)

Create all these objects with proper relationships, validation rules for keg tracking, and set up field dependencies where appropriate.
```

---

## Step 02 — Sample Data

```
Create realistic sample data for BrewCycle's keg tracking system:

1. Create 5 Brewery records: 'Hopworks Urban Brewery' in Portland, 'Foam Brewers' in Burlington, 'Half Acre Beer' in Chicago, 'Modern Times' in San Diego, 'Trillium Brewing' in Boston. Give each realistic production numbers (500-5000 barrels annually) and contact emails.

2. Create 25 Keg records distributed across these breweries with varied beer styles (mix of IPAs, Stouts, Lagers, etc.), different keg sizes, and statuses. Include some kegs marked as 'Lost' (overdue >90 days), some 'At Account', some 'At Brewery'. Use realistic keg ID numbers.

3. Create 12 Account records representing bars and restaurants: mix of dive bars, upscale gastropubs, and bottle shops in the same cities as breweries. Include standard Account fields (Name, BillingCity, Phone).

4. Create 15 Account_Inventory records linking kegs to accounts with delivery dates ranging from 2 days ago to 45 days ago, varied fill levels, and ensure some trigger the Reorder_Needed checkbox.

5. Create 3 Delivery_Route records: one Completed from last week, one In Progress for today, one Planned for tomorrow, each with 4-6 stops and realistic driver assignments.

Make all data interconnected and tell a story of active beer distribution.
```

---

## Step 03 — Permission Sets

```
Create a permission set named BrewCycle_Admin that grants complete access to the keg tracking system:

- Grant Read, Create, Edit, Delete object permissions on Brewery__c, Keg__c, Account_Inventory__c, and Delivery_Route__c
- Grant Read and Edit access to all fields on these four custom objects including formulas and rollups
- Include View All and Modify All data permissions for these objects
- Add standard Account object Read and Edit permissions since we're using it for bar/restaurant tracking
- Include Tab Settings to make all custom object tabs visible
- Add 'View All Data' system permission for reporting purposes
- Create the permission set with a description: 'Full administrative access to BrewCycle keg tracking and distribution management system'
```

---

## Step 04 — Flows & Automations

```
Create a Salesforce Record-Triggered Flow named 'Keg_Reorder_Alert' that automates the reorder process:

Trigger: When an Account_Inventory__c record is created or updated
Conditions: Current_Fill_Level__c equals 'Quarter' OR 'Empty', AND Reorder_Needed__c equals TRUE

Actions:
1. Get the related Account and Keg records to retrieve Account owner and brewery information
2. Create a Task assigned to the Account owner with Subject: 'Reorder Needed: {Beer_Style__c} at {Account_Name}' and Due Date: today + 2 days
3. Send an email alert to the Brewery primary contact with details about which account needs restocking, what beer style, and estimated empty date
4. Update the Keg__c record's Current_Status__c to 'Reorder Scheduled'
5. Add a Decision element: if Days_At_Current_Location__c > 60, also create a high-priority Task for keg retrieval

Include error handling and make the flow active immediately. Add clear descriptions to each element explaining the business logic.
```

---

## Step 05 — Deploy to Org

```
Deploy the complete BrewCycle keg tracking system to the Salesforce scratch org:

1. First, verify the scratch org is created and active with: sf org list
2. Run a validation check on all metadata: sf project deploy validate --target-org [scratch-org-alias]
3. Deploy all custom objects, fields, flows, and permission sets: sf project deploy start --target-org [scratch-org-alias]
4. After successful deployment, assign the BrewCycle_Admin permission set to the scratch org user: sf org assign permset --name BrewCycle_Admin --target-org [scratch-org-alias]
5. Import the sample data using: sf data import tree --plan data/sample-data-plan.json --target-org [scratch-org-alias]
6. Verify deployment by opening the org: sf org open --target-org [scratch-org-alias]
7. If any errors occur, display the detailed deployment logs and suggest fixes

Provide clear status updates at each step and confirm successful deployment of all 4 custom objects, the flow, permission set, and sample data.
```

---

## Step 06 — Lightning Web Component

```
Create a Lightning Web Component named 'kegLocationMap' that displays an interactive visual dashboard:

Component requirements:
1. Use lightning-map to display all Keg__c records plotted by their Current_Account__c's BillingCity coordinates
2. Color-code map markers: Green (Full), Yellow (Half/Three-Quarters), Red (Quarter/Empty), Black (Lost - over 90 days)
3. Query Keg__c, Account_Inventory__c, and related Account data using @wire(getRecord) with proper field-level security
4. Create custom map marker icons showing beer mug emojis with status colors
5. On marker click, show a lightning-card popup with: Keg ID, Beer Style, Keg Size, Account Name, Days At Location, Current Fill Level, and Reorder Status
6. Add a filter panel with lightning-combobox to filter by: Beer Style, Brewery, Status, or show 'Overdue Returns Only'
7. Display summary statistics in lightning-card headers: Total Kegs Tracked, Kegs Needing Reorder, Lost Kegs Value, Average Days At Account
8. Style with SLDS design tokens, use a modern brewery color palette (amber, foam white, deep brown)
9. Make it responsive for desktop and mobile
10. Include a refresh button that re-queries data

Create the component with proper error handling, loading states, and accessibility features. Include the .js, .html, .js-meta.xml, and .css files with detailed comments explaining the beer distribution logic.
```

---

## Step 07 — Push to GitHub

```
Initialize a Git repository and push the BrewCycle project to GitHub:

1. Initialize git in the project root: git init
2. Create a comprehensive .gitignore file for Salesforce DX that excludes: .sfdx/, .sf/, node_modules/, coverage/, .vscode/, .idea/, *.log, .DS_Store, .localdevserver/, and any scratch org config files with sensitive data
3. Create a README.md with project title 'BrewCycle - Craft Beer Keg Tracking System', description of the system, setup instructions for scratch orgs, and a features list highlighting keg tracking, automated reorder flows, and the interactive map dashboard
4. Add all files: git add .
5. Create initial commit: git commit -m 'Initial commit: BrewCycle keg tracking system with custom objects, flows, sample data, and interactive map LWC'
6. Create a new GitHub repository named 'brewcycle-salesforce' with description: 'Salesforce DX project for craft beer keg tracking and distribution management'
7. Add the GitHub remote: git remote add origin [repository-url]
8. Push to main branch: git push -u origin main
9. Verify the push was successful and display the repository URL

Provide the complete sequence of commands and confirm each step completes successfully.
```

---

## Architecture Overview

```
Step 00: sf project generate          →  SFDX project scaffold
Step 01: Custom Objects               →  Brewery__c, Keg__c, Account_Inventory__c, Delivery_Route__c
Step 02: Sample Data                  →  5 breweries, 25 kegs, 12 accounts, 15 inventory records, 3 routes
Step 03: Permission Sets              →  BrewCycle_Admin
Step 04: Flows                        →  Keg_Reorder_Alert (record-triggered with reorder + retrieval logic)
Step 05: Deploy                       →  Validate + deploy + permission assignment + data import
Step 06: LWC                          →  kegLocationMap (interactive map with color-coded keg markers)
Step 07: Git                          →  Push to GitHub
```

---

> **Disclaimer:** This scenario is for demonstration and educational purposes only. Do not deploy to production environments. Code is provided "as-is" without warranty.
