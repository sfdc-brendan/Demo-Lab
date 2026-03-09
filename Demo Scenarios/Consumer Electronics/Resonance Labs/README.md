# Resonance Labs — Premium Audio Technology

> AI-powered acoustic systems that adapt to your space, music, and mood in real-time.

| | |
|---|---|
| **Industry** | Consumer Electronics |
| **Difficulty** | Advanced |
| **Est. Time** | ~50 min |
| **Key Products** | Screen Flows, Einstein GenAI, LWC (Chart.js), Apex |

---

## The Challenge

Each customer's listening environment is unique — room acoustics, furniture placement, and personal preferences dramatically affect sound quality. Resonance Labs needs to track custom tuning profiles, manage white-glove installation appointments, and coordinate post-installation acoustic optimization sessions.

## What We're Building

A system to manage customer acoustic profiles, track high-value installation projects, and automate personalized tuning recommendations.

## Custom Objects

| Object | Purpose |
|--------|---------|
| `Speaker_System__c` | Product catalog — models, pricing, driver configs, AI chip versions |
| `Acoustic_Profile__c` | Per-customer room analysis — dimensions, materials, sound preferences |
| `Installation_Project__c` | White-glove installs — scheduling, staging, value tracking |
| `Tuning_Session__c` | Post-install optimization — before/after scores, adjustments, satisfaction |

## LWC Wow Moment

A visual 3D room acoustic heatmap showing frequency response across different zones, with real-time tuning adjustments and customer satisfaction scores.

---

## Prerequisites

- A Salesforce scratch org or sandbox with Einstein GenAI enabled (API 60.0+)
- Salesforce CLI (`sf`) installed and authenticated
- Cursor IDE

---

## Step 00 — Project Scaffold (run in terminal before opening Cursor)

Run these commands in your terminal to create the SFDX project and set your target org:

```bash
sf project generate --name resonance-labs
cd resonance-labs
sf org list
sf config set target-org <your-org-alias>
```

Then open the `resonance-labs` folder in Cursor and proceed with Step 01.

---

## Step 01 — Custom Objects

Open Cursor Agent and paste:

```
Create these custom Salesforce objects for Resonance Labs audiophile speaker company:

1. Speaker_System__c with fields: System_Name__c (text), Model_Series__c (picklist: Phantom, Ethereal, Apex), Price__c (currency), Driver_Configuration__c (text), Frequency_Range__c (text), AI_Chip_Version__c (text), Status__c (picklist: In Stock, Backordered, Discontinued)

2. Acoustic_Profile__c with fields: Profile_Name__c (text), Account__c (lookup to Account), Room_Dimensions__c (text), Wall_Materials__c (multi-picklist: Drywall, Brick, Concrete, Wood, Glass), Furniture_Density__c (picklist: Minimal, Moderate, Dense), Preferred_Sound_Signature__c (picklist: Neutral, Warm, Bright, Bass-Heavy), AI_Tuning_Complete__c (checkbox), Last_Calibration_Date__c (date)

3. Installation_Project__c with fields: Project_Name__c (text), Account__c (lookup to Account), Speaker_System__c (lookup to Speaker_System__c), Acoustic_Profile__c (lookup to Acoustic_Profile__c), Installation_Date__c (date), Lead_Technician__c (text), Project_Value__c (currency), Stage__c (picklist: Quoted, Scheduled, In Progress, Testing, Completed), Room_Type__c (picklist: Home Theater, Living Room, Studio, Outdoor), Special_Requirements__c (long text area)

4. Tuning_Session__c with fields: Session_Name__c (text), Installation_Project__c (lookup to Installation_Project__c), Session_Date__c (datetime), Duration_Minutes__c (number), Technician_Notes__c (long text area), Before_Score__c (number 1-10), After_Score__c (number 1-10), Adjustments_Made__c (long text area), Customer_Satisfaction__c (picklist: Exceptional, Satisfied, Needs Follow-up)

Make sure all objects have proper plural labels and are set up with all standard Salesforce features enabled.
```

---

## Step 02 — Sample Data

```
Create realistic sample data for Resonance Labs:

1. Create 3 Speaker_System__c records:
   - Phantom Pro 9.2 (Phantom series, $45,000, 9.2.4 configuration, 15Hz-50kHz, AI Chip v3.2, In Stock)
   - Ethereal Soundbar Ultra (Ethereal series, $12,500, 5.1.2 configuration, 20Hz-40kHz, AI Chip v3.1, In Stock)
   - Apex Studio Reference (Apex series, $89,000, 11.4.6 configuration, 10Hz-60kHz, AI Chip v3.5, Backordered)

2. Create 4 Account records with realistic wealthy customer names and luxury addresses in areas like Beverly Hills, Tribeca, Pacific Heights, and Aspen

3. Create 4 Acoustic_Profile__c records, one for each Account:
   - Mix of room types with varied dimensions (e.g., "28x18x12 feet", "45x32x16 feet")
   - Different wall materials and furniture densities
   - Varied sound preferences
   - 2 should have AI_Tuning_Complete__c checked with recent calibration dates

4. Create 5 Installation_Project__c records:
   - Link to the Accounts, Speaker Systems, and Acoustic Profiles
   - Varied stages (2 Completed, 1 In Progress, 1 Scheduled, 1 Quoted)
   - Project values matching speaker system prices plus 15-30% for installation
   - Realistic installation dates spanning last 3 months to next month
   - Creative project names like "Malibu Cliffside Theater", "Manhattan Penthouse Audio Suite"

5. Create 6 Tuning_Session__c records:
   - Link to various Installation_Projects (multiple sessions per project for completed ones)
   - Realistic before/after scores showing improvement (e.g., before: 6.5, after: 9.2)
   - Detailed technician notes about specific adjustments (EQ curves, room correction, sweet spot optimization)
   - Session dates matching project timelines
   - Mix of customer satisfaction levels, mostly Exceptional
```

---

## Step 03 — Permission Sets

```
Create a Salesforce permission set called Resonance_Labs_Admin that grants full CRUD access (Read, Create, Edit, Delete) to these custom objects: Speaker_System__c, Acoustic_Profile__c, Installation_Project__c, and Tuning_Session__c. Also grant View All and Modify All permissions on these objects. Include permissions to view and edit all standard fields and all custom fields on these objects. Add the System Administrator profile level access for these custom objects.
```

---

## Step 04 — Flows & Automations

```
Create a Salesforce Screen Flow called 'Generate_AI_Tuning_Recommendation' that does the following:

1. Triggered when a Tuning_Session__c record is created or when manually launched from an Installation_Project__c record page

2. Screen 1: Display the related Acoustic_Profile__c details (Room_Dimensions__c, Wall_Materials__c, Furniture_Density__c, Preferred_Sound_Signature__c) in a read-only format

3. Use an Apex Action or Einstein Prompt Template called 'Analyze_Room_Acoustics' that takes the acoustic profile data as input and generates a personalized tuning recommendation. The prompt should say: 'Based on a room with dimensions {Room_Dimensions__c}, wall materials of {Wall_Materials__c}, {Furniture_Density__c} furniture density, and a preference for {Preferred_Sound_Signature__c} sound, generate specific speaker placement recommendations, EQ adjustments (by frequency band), and room treatment suggestions. Format as: PLACEMENT: (details), EQ: (frequency adjustments), TREATMENT: (acoustic panel recommendations).'

4. Screen 2: Display the AI-generated recommendations in a formatted text area

5. Create a new Task assigned to the Lead_Technician__c with Subject 'Review AI Tuning Plan for {Project_Name__c}' and Description containing the recommendations

6. Update the Installation_Project__c Stage__c to 'Testing' if it was 'In Progress'

7. Add a success confirmation screen

Make the flow available for installation project record pages and the App Launcher.
```

---

## Step 05 — Deploy to Org

```
Deploy all Salesforce metadata to the scratch org using these commands:

1. First verify the scratch org is authenticated: sfdx force:org:display

2. Push all metadata: sfdx force:source:push

3. Assign the permission set: sfdx force:user:permset:assign -n Resonance_Labs_Admin

4. Import the sample data (if in data/ folder): sfdx force:data:tree:import -p data/sample-data-plan.json

5. Open the org to verify: sfdx force:org:open

If any errors occur during push, run: sfdx force:source:status to see conflicts, then resolve and retry. Ensure all custom objects, fields, the permission set, and the flow are successfully deployed before proceeding.
```

---

## Step 06 — Lightning Web Component

```
Create a Lightning Web Component called 'acousticDashboard' for Resonance Labs that displays:

1. Component Structure:
   - Top section: Card showing key metrics (Total Active Projects, Avg Customer Satisfaction, Systems Installed This Quarter)
   - Middle section: A horizontal bar chart showing Installation_Project__c records by Stage__c with color coding (Quoted=gray, Scheduled=blue, In Progress=orange, Testing=purple, Completed=green)
   - Bottom section: A data table showing recent Tuning_Session__c records with columns: Session Date, Project Name, Technician, Before Score, After Score, Improvement (calculated), Customer Satisfaction

2. Data Queries:
   - Use @wire to query Installation_Project__c with fields: Id, Project_Name__c, Stage__c, Project_Value__c, Account__r.Name
   - Use @wire to query Tuning_Session__c with fields: Id, Session_Name__c, Session_Date__c, Technician_Notes__c, Before_Score__c, After_Score__c, Customer_Satisfaction__c, Installation_Project__r.Project_Name__c
   - Calculate metrics from the queried data

3. Styling:
   - Use lightning-card for containers
   - Use Chart.js or lightning-chart for the bar chart visualization
   - Use lightning-datatable for the tuning sessions table
   - Add a gradient background (dark blue to purple) and white text for a premium audio brand feel
   - Include the speaker emoji and 'Resonance Labs' branding in the header

4. Features:
   - Make the table sortable by clicking column headers
   - Add a refresh button to reload data
   - Show 'Improvement' as a calculated field (After_Score__c - Before_Score__c) with color coding (green if positive, red if negative)
   - Add hover tooltips showing full technician notes

5. Make it deployable to the Home page as a dashboard component with appropriate metadata XML files.
```

---

## Step 07 — Push to GitHub

```
Initialize a Git repository and push to GitHub:

1. Create a .gitignore file for Salesforce DX with these entries:
   .sfdx/
   .sf/
   .vscode/
   node_modules/
   .DS_Store
   *.log
   coverage/
   .nyc_output/

2. Initialize git: git init

3. Add all files: git add .

4. Create initial commit: git commit -m "Initial commit: Resonance Labs Salesforce acoustic system management"

5. Create a new GitHub repository called 'resonance-labs-salesforce' with description: 'Salesforce org for managing AI-tuned audiophile speaker installations, acoustic profiles, and customer tuning sessions for Resonance Labs premium audio systems.'

6. Add GitHub remote: git remote add origin [GITHUB_URL]

7. Push to main branch: git branch -M main && git push -u origin main

8. Create a README.md with:
   - Project title and description
   - Setup instructions for scratch org creation
   - Description of custom objects and their relationships
   - Instructions for deploying metadata
   - Component overview (LWC dashboard)
   - Tech stack (Salesforce DX, LWC, Apex, Flows)

Ensure the repository is public and includes proper Salesforce project structure (force-app/main/default/).
```

---

## Architecture Overview

```
Step 00: sf project generate          →  SFDX project scaffold
Step 01: Custom Objects               →  Speaker_System__c, Acoustic_Profile__c, Installation_Project__c, Tuning_Session__c
Step 02: Sample Data                  →  3 speaker systems, 4 accounts, 4 acoustic profiles, 5 projects, 6 tuning sessions
Step 03: Permission Sets              →  Resonance_Labs_Admin
Step 04: Flows                        →  Generate_AI_Tuning_Recommendation (screen flow + Einstein GenAI)
Step 05: Deploy                       →  Metadata + data import + permission assignment
Step 06: LWC                          →  acousticDashboard (metrics, stage chart, tuning session table)
Step 07: Git                          →  Push to GitHub
```

---

> **Disclaimer:** This scenario is for demonstration and educational purposes only. Do not deploy to production environments. Code is provided "as-is" without warranty.
