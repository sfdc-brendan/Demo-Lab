# VineSense Analytics — Precision Viticulture & Wine Production

> AI-powered vineyard health monitoring and harvest optimization for boutique wineries.

| | |
|---|---|
| **Industry** | Agriculture |
| **Difficulty** | Intermediate |
| **Est. Time** | ~40 min |
| **Key Products** | Screen Flows, LWC, Chart.js |

---

## The Challenge

Boutique wineries struggle to track individual vineyard block performance, soil conditions, and optimal harvest timing across dozens of grape varietals. Manual tracking leads to suboptimal harvest decisions and lost revenue from timing mistakes.

## What We're Building

A vineyard management system that tracks blocks, grape varietals, soil sensors, and harvest predictions with automated quality scoring.

## Custom Objects

| Object | Purpose |
|--------|---------|
| `Vineyard_Block__c` | Individual vineyard blocks — acreage, slope, elevation, irrigation |
| `Grape_Varietal__c` | Grape types — brix targets, maturity, disease resistance, pricing |
| `Soil_Reading__c` | Sensor data — pH, moisture, nitrogen, temperature per block |
| `Harvest_Prediction__c` | AI-driven predictions — yield, quality score, harvest timing |

## LWC Wow Moment

An interactive vineyard map LWC showing real-time block health scores with color-coded tiles, hoverable sensor data, and harvest readiness indicators.

---

## Prerequisites

- A Salesforce scratch org or sandbox
- Salesforce CLI (`sf`) installed and authenticated
- Cursor IDE

---

## Step 00 — Project Scaffold (run in terminal before opening Cursor)

Run these commands in your terminal to create the SFDX project and set your target org:

```bash
sf project generate --name vinesense-analytics
cd vinesense-analytics
sf org list
sf config set target-org <your-org-alias>
```

Then open the `vinesense-analytics` folder in Cursor and proceed with Step 01.

---

## Step 01 — Custom Objects

Open Cursor Agent and paste:

```
Create four custom Salesforce objects for VineSense Analytics vineyard management: 1) Vineyard_Block__c with fields: Block_Name__c (text), Acres__c (number), Slope_Percentage__c (number), Elevation_Feet__c (number), Irrigation_Type__c (picklist: Drip, Sprinkler, None), Last_Inspection_Date__c (date). 2) Grape_Varietal__c with fields: Varietal_Name__c (text), Optimal_Brix_Level__c (number), Days_to_Maturity__c (number), Disease_Resistance__c (picklist: High, Medium, Low), Price_Per_Ton__c (currency). 3) Soil_Reading__c with fields: Reading_Date__c (datetime), pH_Level__c (number), Moisture_Percentage__c (number), Nitrogen_PPM__c (number), Temperature_Celsius__c (number), master-detail relationship to Vineyard_Block__c. 4) Harvest_Prediction__c with fields: Predicted_Date__c (date), Estimated_Yield_Tons__c (number), Quality_Score__c (number 1-100), Brix_Current__c (number), Recommendation__c (long text), lookup relationships to both Vineyard_Block__c and Grape_Varietal__c. Include proper field descriptions and help text for winemakers.
```

---

## Step 02 — Sample Data

```
Create realistic sample data for VineSense Analytics: 6 Vineyard_Block__c records with names like 'Hillside East Block A', 'River Valley Block C', 'Summit Block B' with varying acres (2.5-8.0), slopes (5-25%), and elevations (400-850 feet). Create 8 Grape_Varietal__c records including Cabernet Sauvignon (23 Brix, 150 days, $3200/ton), Pinot Noir (22 Brix, 135 days, $4100/ton), Chardonnay (21 Brix, 120 days, $2800/ton), Merlot, Syrah, Sauvignon Blanc, Zinfandel, and Riesling with realistic viticulture data. Create 20 Soil_Reading__c records spread across the blocks from the past 30 days with realistic pH (6.0-7.5), moisture (15-45%), nitrogen (20-80 PPM), and temperature values. Create 6 Harvest_Prediction__c records linking blocks to varietals with predicted dates in the next 2-8 weeks, quality scores 75-95, and detailed recommendations about optimal harvest timing.
```

---

## Step 03 — Permission Sets

```
Create a permission set named VineSense_Admin that grants full CRUD access (Create, Read, Edit, Delete) to all four custom objects: Vineyard_Block__c, Grape_Varietal__c, Soil_Reading__c, and Harvest_Prediction__c. Include read and edit permissions for all custom fields on these objects. Add View All and Modify All object permissions for each. Include the standard permissions: View Setup and Configuration, API Enabled, and Modify All Data. Set the license to Salesforce and add a description: 'Full administrative access for VineSense vineyard management system'.
```

---

## Step 04 — Flows & Automations

```
Create a Salesforce Screen Flow named 'Harvest_Readiness_Calculator' that helps winemakers determine if a vineyard block is ready for harvest. The flow should: 1) Start with a screen asking the user to select a Vineyard_Block__c (lookup field) and enter Current_Brix_Reading (number input). 2) Query the related Grape_Varietal__c to get Optimal_Brix_Level__c. 3) Use a Decision element to compare current vs optimal brix: if within 0.5 points, set readiness to 'Ready - Harvest Now', if within 1.5 points set to 'Monitor - Check in 3 days', otherwise 'Not Ready - Check in 7 days'. 4) Create a new Harvest_Prediction__c record with the calculated recommendation, estimated yield based on block acres, quality score (85-95 if ready, 70-84 if monitoring, below 70 if not ready), and predicted date. 5) Show a final screen displaying the recommendation with color-coded messaging and next steps for the winemaker.
```

---

## Step 05 — Deploy to Org

```
Deploy all VineSense Analytics metadata to the Salesforce scratch org using SFDX commands. First, verify the scratch org is active with 'sfdx force:org:display'. Then push all source: 'sfdx force:source:push --forceoverwrite'. After successful deployment, assign the VineSense_Admin permission set to the default user: 'sfdx force:user:permset:assign --permsetname VineSense_Admin'. Finally, verify deployment by listing all custom objects: 'sfdx force:schema:sobject:list --sobjecttypecategory custom'. Include error handling to check if each command succeeds before proceeding to the next.
```

---

## Step 06 — Lightning Web Component

```
Create a Lightning Web Component called 'vineyardHealthDashboard' that displays an interactive vineyard overview. The component should: 1) Query all Vineyard_Block__c records with their related Grape_Varietal__c and latest Soil_Reading__c data using @wire with a custom Apex controller. 2) Display blocks as color-coded cards in a responsive grid layout - green for optimal health (moisture 25-40%, pH 6.5-7.0), yellow for monitoring needed, red for issues. 3) Each card shows: block name, varietal, acres, current moisture %, pH level, and a health score calculated from sensor data. 4) Add hoverable tooltips showing detailed soil readings when user hovers over a card. 5) Include a mini chart (use Chart.js) showing moisture trend over the past 7 days for each block. 6) Add filter buttons at the top to show 'All Blocks', 'Ready to Harvest', 'Needs Attention'. Style with SLDS design tokens, use smooth animations for card transitions, and make it look polished and professional for a winemaker's dashboard.
```

---

## Step 07 — Push to GitHub

```
Initialize a Git repository for the VineSense Analytics Salesforce project and push to GitHub. Steps: 1) Run 'git init' in the project root. 2) Create a comprehensive .gitignore file for Salesforce DX that excludes: .sfdx/, .sf/, .vscode/, node_modules/, .DS_Store, *.log, .localdevserver/, and scratch org config files. 3) Create a README.md with project title 'VineSense Analytics - Vineyard Management System', description of the custom objects and LWC dashboard, setup instructions for scratch org creation, and a screenshot placeholder. 4) Stage all files: 'git add .'. 5) Commit with message: 'Initial commit: VineSense vineyard management system with custom objects, flows, and health dashboard LWC'. 6) Create a new GitHub repository named 'vinesense-salesforce' with description 'Precision viticulture management system built on Salesforce with AI-powered harvest predictions'. 7) Add the GitHub remote and push: 'git remote add origin [repo-url]' and 'git push -u origin main'.
```

---

## Architecture Overview

```
Step 00: sf project generate          →  SFDX project scaffold
Step 01: Custom Objects               →  Vineyard_Block__c, Grape_Varietal__c, Soil_Reading__c, Harvest_Prediction__c
Step 02: Sample Data                  →  6 blocks, 8 varietals, 20 soil readings, 6 harvest predictions
Step 03: Permission Sets              →  VineSense_Admin
Step 04: Flows                        →  Harvest_Readiness_Calculator (screen flow)
Step 05: Deploy                       →  Metadata + permission assignment + verification
Step 06: LWC                          →  vineyardHealthDashboard (interactive vineyard map)
Step 07: Git                          →  Push to GitHub
```

---

> **Disclaimer:** This scenario is for demonstration and educational purposes only. Do not deploy to production environments. Code is provided "as-is" without warranty.
