# Helion Forge Energy — Fusion Energy & Advanced Power Systems

> Building commercial-scale compact tokamak reactors to power cities with clean fusion energy.

| | |
|---|---|
| **Industry** | Energy |
| **Difficulty** | Advanced |
| **Est. Time** | ~55 min |
| **Key Products** | Record-Triggered Flows, Scheduled Flows, LWC (SVG/Chart.js), Master-Detail |

---

## The Challenge

Helion Forge manages hundreds of reactor components from global suppliers, each requiring precision certification and real-time status tracking during assembly. When a plasma containment coil fails quality checks or a cryogenic pump shipment delays, the entire $400M reactor build timeline is at risk.

## What We're Building

A Reactor Component Lifecycle Management system to track parts, supplier certifications, assembly milestones, and automated alerts when critical path items are delayed.

## Custom Objects

| Object | Purpose |
|--------|---------|
| `Reactor_Build__c` | Reactor projects — budget, phase, target plasma date, site |
| `Component__c` | Individual parts — type, status, criticality, delivery tracking |
| `Supplier_Certification__c` | Vendor certs — ISO/nuclear/cryo grades, expiration monitoring |
| `Assembly_Milestone__c` | Build phases — foundation through first plasma ignition |

## LWC Wow Moment

A real-time reactor assembly dashboard showing a 3D-style visual of the tokamak with color-coded component status (green=installed, yellow=in-transit, red=delayed), plus a live progress ring showing percentage completion toward first plasma ignition.

---

## Prerequisites

- A Salesforce scratch org or sandbox
- Salesforce CLI (`sf`) installed and authenticated
- Cursor IDE

---

## Step 00 — Project Scaffold (run in terminal before opening Cursor)

Run these commands in your terminal to create the SFDX project and set your target org:

```bash
sf project generate --name helion-forge
cd helion-forge
sf org list
sf config set target-org <your-org-alias>
```

Then open the `helion-forge` folder in Cursor and proceed with Step 01.

---

## Step 01 — Custom Objects

Open Cursor Agent and paste:

```
Create four custom Salesforce objects for Helion Forge Energy's fusion reactor tracking system:

1. Reactor_Build__c with fields: Build_Number__c (text, external ID), Target_First_Plasma_Date__c (date), Total_Budget__c (currency), Current_Phase__c (picklist: Design, Procurement, Assembly, Testing, Commissioning), Installation_Site__c (text), Project_Manager__c (lookup to User)

2. Component__c with fields: Component_ID__c (text, external ID), Component_Name__c (text), Component_Type__c (picklist: Plasma Containment Coil, Cryogenic Pump, Vacuum Chamber, Neutral Beam Injector, Divertor Plate, Magnetic Field Coil, Diagnostic Sensor), Reactor_Build__c (master-detail to Reactor_Build__c), Status__c (picklist: Ordered, In Transit, Quality Check, Passed, Failed, Installed), Estimated_Delivery_Date__c (date), Actual_Delivery_Date__c (date), Criticality_Level__c (picklist: Critical Path, High, Medium, Low), Unit_Cost__c (currency)

3. Supplier_Certification__c with fields: Certification_Number__c (text, external ID), Supplier_Name__c (text), Component__c (lookup to Component__c), Certification_Type__c (picklist: ISO 9001, Nuclear Grade, Cryogenic Systems, High Vacuum, Plasma Physics), Certification_Date__c (date), Expiration_Date__c (date), Certification_Status__c (formula: if expiration date is within 30 days return 'Expiring Soon', if expired return 'Expired', else 'Valid'), Inspector_Name__c (text)

4. Assembly_Milestone__c with fields: Milestone_Name__c (text), Reactor_Build__c (master-detail to Reactor_Build__c), Planned_Completion_Date__c (date), Actual_Completion_Date__c (date), Status__c (picklist: Not Started, In Progress, Completed, Delayed, Blocked), Required_Components__c (long text area - list component IDs), Lead_Engineer__c (lookup to User), Milestone_Type__c (picklist: Foundation, Vacuum Chamber Install, Magnet Integration, First Cooldown, First Plasma Test)

Create all objects with appropriate page layouts, set up the master-detail and lookup relationships, and include help text describing each field's purpose in the reactor build process.
```

---

## Step 02 — Sample Data

```
Create realistic sample data for Helion Forge Energy's reactor tracking system:

1. Create 2 Reactor_Build__c records:
   - Build_Number__c: 'HFE-TR-001', Target_First_Plasma_Date__c: 8 months from today, Total_Budget__c: 385000000, Current_Phase__c: 'Assembly', Installation_Site__c: 'Richland, Washington Facility', Project_Manager__c: assign to current user
   - Build_Number__c: 'HFE-TR-002', Target_First_Plasma_Date__c: 14 months from today, Total_Budget__c: 420000000, Current_Phase__c: 'Procurement', Installation_Site__c: 'Oak Ridge, Tennessee Facility', Project_Manager__c: assign to current user

2. Create 12 Component__c records for HFE-TR-001 with realistic component names:
   - 4 Plasma Containment Coils (Status: 2 Installed, 1 Quality Check, 1 In Transit)
   - 2 Cryogenic Pumps (Status: 1 Passed, 1 Ordered)
   - 2 Vacuum Chambers (Status: both Installed)
   - 2 Neutral Beam Injectors (Status: 1 In Transit, 1 Quality Check)
   - 1 Divertor Plate (Status: Failed - needs attention)
   - 1 Magnetic Field Coil Array (Status: Installed)
   Mix Criticality_Levels with 4 Critical Path items, use realistic costs between $500K-$15M per component

3. Create 8 Component__c records for HFE-TR-002 with Status mostly 'Ordered' or 'In Transit'

4. Create 6 Supplier_Certification__c records linking to various components:
   - Mix of certification types (Nuclear Grade, Cryogenic Systems, High Vacuum)
   - Include 1 certification expiring within 30 days and 1 expired to demonstrate alerts
   - Use supplier names like 'Oxford Cryogenics Ltd', 'Tokyo Vacuum Technologies', 'CERN Advanced Materials'

5. Create 5 Assembly_Milestone__c records for HFE-TR-001:
   - 'Foundation & Support Structure' (Completed, actual date 3 months ago)
   - 'Primary Vacuum Chamber Installation' (Completed, actual date 1 month ago)
   - 'Magnetic Confinement System Integration' (In Progress, planned date 2 weeks from now)
   - 'Cryogenic Cooling System Activation' (Not Started, planned date 3 months from now)
   - 'First Plasma Ignition Test' (Not Started, planned date 8 months from now)

Use realistic names for Lead_Engineers and make the data tell a story of a complex reactor build with some challenges.
```

---

## Step 03 — Permission Sets

```
Create a permission set called 'Helion_Forge_Admin' that grants full access to Helion Forge Energy's custom objects and fields. The permission set should include:

1. Object permissions for Reactor_Build__c, Component__c, Supplier_Certification__c, and Assembly_Milestone__c with Read, Create, Edit, Delete, View All, and Modify All enabled

2. Field-level security set to visible and editable for all custom fields on all four objects

3. Tab visibility set to Available for any custom tabs created for these objects

4. System permissions: View Setup and Configuration, API Enabled, Modify All Data (for admin testing)

5. Set the permission set label to 'Helion Forge Energy - Full Admin Access' with description 'Complete access to reactor build tracking system for project managers and system administrators'

Generate the permission set metadata XML file and deploy it to the scratch org.
```

---

## Step 04 — Flows & Automations

```
Create a Salesforce Flow called 'Component_Delay_Alert' that automates critical path monitoring for Helion Forge Energy:

Trigger: Record-triggered flow on Component__c when a record is created or updated

Entry Criteria: 
- Status__c changes to 'Failed' OR
- Status__c equals 'In Transit' AND Estimated_Delivery_Date__c is less than TODAY() (meaning it's overdue) AND
- Criticality_Level__c equals 'Critical Path'

Flow Actions:
1. Get the related Reactor_Build__c record to retrieve Project_Manager__c and Build_Number__c
2. Create a Task assigned to the Project_Manager__c with:
   - Subject: 'URGENT: Critical Component Delay - {Component_Name__c}'
   - Description: 'Component {Component_ID__c} for Reactor Build {Build_Number__c} is delayed or failed. Current Status: {Status__c}. This is a CRITICAL PATH item. Estimated delivery was {Estimated_Delivery_Date__c}. Immediate action required.'
   - Priority: High
   - Status: Not Started
   - Related To: the Reactor_Build__c record
3. Send email alert to Project_Manager__c with subject 'Critical Reactor Component Alert' and body including component details
4. Update the Reactor_Build__c record's Current_Phase__c to 'Delayed' if any critical path component is delayed

Also create a scheduled flow called 'Certification_Expiration_Check' that runs daily:
- Query all Supplier_Certification__c records where Expiration_Date__c is within the next 30 days and Certification_Status__c equals 'Expiring Soon'
- For each record, create a task for the Project Manager of the related Reactor Build
- Email summary of all expiring certifications to a distribution list

Build these flows using Flow Builder best practices with clear descriptions and error handling.
```

---

## Step 05 — Deploy to Org

```
Deploy all Helion Forge Energy metadata to the scratch org using Salesforce DX. Execute the following sequence:

1. First, verify the scratch org is active and authenticated:
   sfdx force:org:display --targetusername [scratch-org-alias]

2. Run pre-flight validation to check for any metadata issues:
   sfdx force:source:status --targetusername [scratch-org-alias]

3. Deploy all metadata in the force-app/main/default directory:
   sfdx force:source:push --targetusername [scratch-org-alias] --forceoverwrite

4. Assign the Helion_Forge_Admin permission set to the default user:
   sfdx force:user:permset:assign --permsetname Helion_Forge_Admin --targetusername [scratch-org-alias]

5. Import the sample data using the Salesforce CLI:
   sfdx force:data:tree:import --plan data/sample-data-plan.json --targetusername [scratch-org-alias]

6. Activate the flows:
   sfdx force:apex:execute --targetusername [scratch-org-alias] --apexcodefile scripts/activate-flows.apex

7. Open the org to verify deployment:
   sfdx force:org:open --targetusername [scratch-org-alias] --path /lightning/o/Reactor_Build__c/list

8. Run a quick validation query to confirm data loaded:
   sfdx force:data:soql:query --query "SELECT COUNT() FROM Component__c" --targetusername [scratch-org-alias]

Create any necessary data plan JSON files and Apex scripts referenced above. Handle any deployment errors gracefully and provide clear error messages if metadata conflicts occur.
```

---

## Step 06 — Lightning Web Component

```
Build a Lightning Web Component called 'reactorAssemblyDashboard' that creates an impressive visual display of Helion Forge Energy's reactor build status:

Component Structure:
1. Top section: Large circular progress ring (using SVG or Chart.js) showing overall reactor completion percentage calculated from installed components vs total components
   - Display percentage in center with label 'Days to First Plasma: X'
   - Color gradient from orange (0%) to electric blue (100%)

2. Middle section: 3D-style tokamak reactor visualization (can be simplified SVG cross-section) with component positions marked
   - Each component type has a position on the reactor diagram
   - Color-code each component position: green circle = Installed, yellow = In Transit, red = Failed/Delayed, gray = Ordered
   - Make components clickable to show detail card

3. Bottom section: Three metric cards displaying:
   - 'Critical Path Items': count with status breakdown
   - 'Budget Status': total spent vs budget with progress bar
   - 'Certifications Expiring': count of certifications expiring within 30 days

4. Right panel: Live activity feed showing recent component status changes and milestone completions

Data Queries:
- Query Reactor_Build__c records with related Component__c, Assembly_Milestone__c, and Supplier_Certification__c child records
- Use @wire to reactively load data
- Calculate completion percentage: (components with Status='Installed' / total components) * 100
- Filter and display only Critical Path components in the alert section

Styling:
- Use Salesforce Lightning Design System (SLDS) for base styling
- Custom CSS for the reactor diagram and progress ring
- Dark theme with electric blue accents (#00D4FF) and orange alerts (#FF6B35)
- Smooth animations when components change status
- Responsive layout that works on desktop and tablet

Make the component visually striking and immediately convey the status of this complex $400M reactor build. Include error handling for when no data is available and a loading spinner during data fetch.
```

---

## Step 07 — Push to GitHub

```
Initialize a Git repository for the Helion Forge Energy Salesforce project and push to GitHub:

1. Initialize git in the project root directory:
   git init

2. Create a comprehensive .gitignore file for Salesforce DX projects that excludes:
   - .sfdx/
   - .sf/
   - .vscode/
   - node_modules/
   - .DS_Store
   - *.log
   - .localdevserver/
   - .org-metadata/
   - config/
   - coverage/
   - .eslintcache

3. Create a detailed README.md file with:
   - Project title: 'Helion Forge Energy - Reactor Component Lifecycle Management'
   - Description: Overview of the fusion reactor tracking system
   - Installation instructions for setting up a scratch org
   - Object model documentation listing all custom objects and their relationships
   - Component overview describing the reactorAssemblyDashboard LWC
   - Demo data instructions
   - Screenshots section (placeholder for future screenshots)
   - Technology stack: Salesforce DX, Lightning Web Components, Flow Builder
   - License: MIT

4. Stage all files:
   git add .

5. Create initial commit:
   git commit -m "Initial commit: Helion Forge Energy reactor tracking system with custom objects, flows, sample data, and reactor assembly dashboard LWC"

6. Create a new GitHub repository using GitHub CLI (or provide manual instructions):
   gh repo create helion-forge-reactor-management --public --description "Salesforce-based reactor component lifecycle management system for fusion energy startup Helion Forge Energy. Tracks tokamak components, supplier certifications, and assembly milestones with real-time visualization."

7. Add remote and push:
   git remote add origin https://github.com/[username]/helion-forge-reactor-management.git
   git branch -M main
   git push -u origin main

8. Create a LICENSE file (MIT License)

9. Add GitHub repository topics: salesforce, salesforce-dx, lwc, fusion-energy, reactor-management, demo

Provide clear terminal commands and explain each step for developers unfamiliar with Git or GitHub CLI.
```

---

## Architecture Overview

```
Step 00: sf project generate          →  SFDX project scaffold
Step 01: Custom Objects               →  Reactor_Build__c, Component__c, Supplier_Certification__c, Assembly_Milestone__c
Step 02: Sample Data                  →  2 reactor builds, 20 components, 6 certifications, 5 milestones
Step 03: Permission Sets              →  Helion_Forge_Admin
Step 04: Flows                        →  Component_Delay_Alert (record-triggered), Certification_Expiration_Check (scheduled)
Step 05: Deploy                       →  Validate + deploy + permissions + data import + flow activation
Step 06: LWC                          →  reactorAssemblyDashboard (progress ring, tokamak diagram, metrics)
Step 07: Git                          →  Push to GitHub
```

---

> **Disclaimer:** This scenario is for demonstration and educational purposes only. Do not deploy to production environments. Code is provided "as-is" without warranty.
