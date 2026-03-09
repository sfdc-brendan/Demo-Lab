# TerraDyne Heavy Industries — Advanced Mining & Agricultural Equipment Manufacturing

> Building the world's first fully autonomous, solar-hybrid excavators and tractors for extreme terrain operations.

| | |
|---|---|
| **Industry** | Manufacturing |
| **Difficulty** | Intermediate |
| **Est. Time** | ~45 min |
| **Key Products** | Screen Flows, Record-Triggered Flows, LWC, Field Service |

---

## The Challenge

TerraDyne's service teams struggle to track equipment performance across remote mining sites in Australia, Chile, and Mongolia. When a $2M autonomous excavator breaks down 400km from the nearest depot, they need instant visibility into diagnostic data, parts inventory, and dispatch scheduling.

## What We're Building

A unified system to track equipment deployments, monitor real-time diagnostics from IoT sensors, manage parts inventory, and automate field service dispatch for their global fleet.

## Custom Objects

| Object | Purpose |
|--------|---------|
| `Equipment_Unit__c` | Fleet units — serial numbers, GPS, battery, operational hours |
| `Diagnostic_Alert__c` | IoT sensor alerts — type, severity, resolution tracking |
| `Field_Service_Request__c` | Dispatch requests — technician, parts, ETA, status |
| `Parts_Inventory__c` | Warehouse stock — quantities, pricing, model compatibility |

## LWC Wow Moment

A real-time equipment health dashboard showing a map of deployed units with live battery levels, operational hours, and alert status — click any unit to see diagnostic history and auto-generate service requests.

---

## Prerequisites

- A Salesforce scratch org or sandbox
- Salesforce CLI (`sf`) installed and authenticated
- Cursor IDE

---

## Step 00 — Project Scaffold (run in terminal before opening Cursor)

Run these commands in your terminal to create the SFDX project and set your target org:

```bash
sf project generate --name terradyne
cd terradyne
sf org list
sf config set target-org <your-org-alias>
```

Then open the `terradyne` folder in Cursor and proceed with Step 01.

---

## Step 01 — Custom Objects

Open Cursor Agent and paste:

```
Create four custom Salesforce objects for TerraDyne Heavy Industries manufacturing company: 1) Equipment_Unit__c with fields: Unit_Serial_Number__c (text, external ID), Model_Name__c (picklist: TD-9000 Autonomous Excavator, TD-5000 Solar Tractor, TD-3000 Hybrid Dozer), Deployment_Site__c (text), Battery_Level__c (percent), Operational_Hours__c (number), Status__c (picklist: Active, Maintenance, Offline, Deployed), GPS_Coordinates__c (geolocation), Last_Sync__c (datetime). 2) Diagnostic_Alert__c with fields: Alert_Type__c (picklist: Battery Warning, Hydraulic Failure, Sensor Malfunction, Overheating, Critical Stop), Severity__c (picklist: Low, Medium, High, Critical), Alert_Timestamp__c (datetime), Resolution_Status__c (picklist: Open, In Progress, Resolved), Equipment_Unit__c (master-detail to Equipment_Unit__c). 3) Field_Service_Request__c with fields: Request_Number__c (auto-number FSR-{0000}), Priority__c (picklist: Urgent, High, Medium, Low), Technician_Assigned__c (text), Estimated_Arrival__c (datetime), Parts_Required__c (long text area), Request_Status__c (picklist: New, Dispatched, In Transit, On Site, Completed), Equipment_Unit__c (lookup to Equipment_Unit__c), Related_Alert__c (lookup to Diagnostic_Alert__c). 4) Parts_Inventory__c with fields: Part_Number__c (text, external ID), Part_Name__c (text), Quantity_Available__c (number), Warehouse_Location__c (picklist: Sydney, Santiago, Ulaanbaatar, Denver), Unit_Price__c (currency), Compatible_Models__c (multi-select picklist: TD-9000, TD-5000, TD-3000), Reorder_Threshold__c (number). Ensure all objects have proper relationships and enable reports and activities.
```

---

## Step 02 — Sample Data

```
Create realistic sample data for TerraDyne Heavy Industries: 1) Create 8 Equipment_Unit__c records with serial numbers like TDX-2024-AU-0147, TDX-2024-CL-0089, etc., distributed across sites like 'Mt. Whaleback Iron Ore Mine - Australia', 'Escondida Copper Mine - Chile', 'Oyu Tolgoi - Mongolia', 'Powder River Basin - Wyoming'. Mix models (4 excavators, 2 tractors, 2 dozers) with varying battery levels (45-98%), operational hours (1200-8500), and statuses. Include realistic GPS coordinates for each site. 2) Create 12 Diagnostic_Alert__c records linked to various equipment units - include 3 Critical alerts (Hydraulic Failure, Critical Stop), 4 High severity (Battery Warning, Overheating), and 5 Medium/Low alerts. Use timestamps from the past 30 days. Set 7 as Resolved, 5 as Open or In Progress. 3) Create 6 Field_Service_Request__c records linked to equipment and alerts, with technician names like 'Sarah Chen', 'Marcus Rodriguez', 'Yuki Tanaka'. Include realistic parts requirements like 'Hydraulic pump assembly, 12x hydraulic seals, filter kit'. Mix statuses from New to Completed. 4) Create 15 Parts_Inventory__c records for components like 'Solar Panel Array - 500W', 'Lithium Battery Module - 100kWh', 'Hydraulic Pump Assembly', 'Autonomous Navigation Sensor Suite', 'Track Roller Assembly', etc. Distribute inventory across warehouses with realistic quantities (0-45 units) and prices ($500-$85,000).
```

---

## Step 03 — Permission Sets

```
Create a permission set called TerraDyne_Admin that grants full CRUD (Create, Read, Edit, Delete) permissions to all four custom objects: Equipment_Unit__c, Diagnostic_Alert__c, Field_Service_Request__c, and Parts_Inventory__c. Include View All and Modify All permissions for each object. Grant access to all custom fields on these objects. Add 'View All Data' and 'Modify All Data' system permissions. Label it 'TerraDyne Administrator Access' with description 'Full access to all TerraDyne equipment management objects and fields for admin users and service managers.'
```

---

## Step 04 — Flows & Automations

```
Create a Salesforce Screen Flow called 'Emergency_Service_Dispatch' that triggers when a Diagnostic_Alert__c record is created with Severity__c = 'Critical'. The flow should: 1) Query the related Equipment_Unit__c to get deployment site and GPS coordinates. 2) Automatically create a Field_Service_Request__c record with Priority__c set to 'Urgent', Request_Status__c set to 'New', and populate the Equipment_Unit__c and Related_Alert__c lookups. 3) Query Parts_Inventory__c to check if critical parts (hydraulic components, battery modules) are available at the nearest warehouse. 4) Display a screen showing the created service request details, estimated distance to site, and parts availability status. 5) Send an email alert to the service dispatch team (use a hardcoded email for demo) with subject 'CRITICAL: Equipment Down at {Site_Name}' including equipment serial number, alert type, GPS coordinates, and parts availability. Include decision elements for parts availability and assign different technicians based on warehouse location.
```

---

## Step 05 — Deploy to Org

```
Deploy all TerraDyne metadata to the Salesforce scratch org using SFDX commands. First, authenticate to the scratch org with 'sf org login web --alias TerraOrg'. Verify connection with 'sf org display --target-org TerraOrg'. Push all source metadata with 'sf project deploy start --target-org TerraOrg'. After successful deployment, assign the TerraDyne_Admin permission set to the default user with 'sf org assign permset --name TerraDyne_Admin --target-org TerraOrg'. Finally, import the sample data using 'sf data tree import --plan data/sample-data-plan.json --target-org TerraOrg'. Verify deployment by listing custom objects with 'sf sobject list --sobject-type custom --target-org TerraOrg' and confirm all four objects appear.
```

---

## Step 06 — Lightning Web Component

```
Create a Lightning Web Component called 'equipmentHealthDashboard' for TerraDyne that displays a visually impressive real-time equipment monitoring interface. The component should query all Equipment_Unit__c records using @wire and display them as interactive cards in a responsive grid layout. Each card shows: equipment model name with custom icons (excavator/tractor/dozer), serial number, deployment site, a circular progress indicator for battery level (green >70%, yellow 40-70%, red <40%), operational hours with a small bar chart, and current status badge with color coding. Include a summary header showing total fleet count, units needing attention (battery <50% or status=Maintenance), and average battery level across fleet. Add a filter dropdown to show only specific models or sites. When a card is clicked, display a modal with full equipment details, recent Diagnostic_Alert__c history (last 5 alerts with timestamps and severity), and a 'Create Service Request' button that navigates to the Field_Service_Request__c creation form with Equipment_Unit__c pre-populated. Use Lightning Design System styling, lightning-card, lightning-badge, lightning-icon, and custom CSS for the battery level rings and status indicators. Make it look like a modern industrial IoT dashboard with dark mode aesthetics, sharp borders, and data visualization.
```

---

## Step 07 — Push to GitHub

```
Initialize a new Git repository for the TerraDyne Salesforce project and push to GitHub. First, run 'git init' in the project root. Create a comprehensive .gitignore file for Salesforce DX projects that excludes: .sfdx/, .sf/, .localdevserver/, .vscode/, node_modules/, coverage/, *.log, .DS_Store, .org metadata, and any scratch org config files with credentials. Stage all files with 'git add .' and commit with message 'Initial commit: TerraDyne Heavy Industries equipment management system - custom objects, flows, sample data, and LWC dashboard'. Create a new GitHub repository named 'terradyne-equipment-mgmt' (make it public for demo purposes). Add remote with 'git remote add origin https://github.com/[username]/terradyne-equipment-mgmt.git' and push with 'git push -u origin main'. Add a README.md file with project description: 'TerraDyne Heavy Industries - Salesforce Equipment Management System. Tracks autonomous mining equipment fleet with real-time diagnostics, IoT sensor integration, automated service dispatch, and parts inventory management. Built with custom objects, flows, and Lightning Web Components.' Include setup instructions for scratch org creation and deployment.
```

---

## Architecture Overview

```
Step 00: sf project generate          →  SFDX project scaffold
Step 01: Custom Objects               →  Equipment_Unit__c, Diagnostic_Alert__c, Field_Service_Request__c, Parts_Inventory__c
Step 02: Sample Data                  →  8 equipment units, 12 alerts, 6 service requests, 15 parts
Step 03: Permission Sets              →  TerraDyne_Admin
Step 04: Flows                        →  Emergency_Service_Dispatch (screen flow with parts check + email)
Step 05: Deploy                       →  Metadata + permissions + data import + verification
Step 06: LWC                          →  equipmentHealthDashboard (IoT-style fleet cards with battery rings)
Step 07: Git                          →  Push to GitHub
```

---

> **Disclaimer:** This scenario is for demonstration and educational purposes only. Do not deploy to production environments. Code is provided "as-is" without warranty.
