# Demo Scenarios

A collection of guided demo scenarios for Solutions Engineers. Each scenario presents a fictional company, an industry-specific business challenge, and step-by-step Cursor Agent prompts that build a complete Salesforce solution from scratch — custom objects, sample data, automations, LWCs, and deployment.

---

## How to Use

1. **Browse the scenarios** in the table below and pick one that fits your demo audience.
2. **Run Step 00** in your terminal to scaffold a new SFDX project and connect your target org.
3. **Open the new project folder in Cursor.**
4. **Copy/paste each prompt** (Steps 01 through 07) into Cursor Agent, one at a time, in order.
5. Each step builds on the previous — let Cursor finish, verify the output, then move to the next step.

---

## Scenarios

### Energy

| Scenario | Difficulty | Est. Time | Tagline | Key Products |
|----------|------------|-----------|---------|--------------|
| [Helion Forge Energy](./Energy/Helion%20Forge%20Energy/) | Advanced | ~55 min | Commercial-scale tokamak reactor component lifecycle management for a $400M fusion build | Record-Triggered Flows, Scheduled Flows, LWC (SVG/Chart.js) |

### Biotechnology

| Scenario | Difficulty | Est. Time | Tagline | Key Products |
|----------|------------|-----------|---------|--------------|
| [Verdant Genome Labs](./Biotechnology/Verdant%20Genome%20Labs/) | Intermediate | ~45 min | CRISPR-powered climate-resilient crop engineering with global field trial tracking | Scheduled Flows, LWC (lightning-map), Master-Detail, Geolocation |

### Consumer Electronics

| Scenario | Difficulty | Est. Time | Tagline | Key Products |
|----------|------------|-----------|---------|--------------|
| [Resonance Labs](./Consumer%20Electronics/Resonance%20Labs/) | Advanced | ~50 min | AI-powered acoustic systems that adapt to your space, music, and mood in real-time | Screen Flows, Einstein GenAI, LWC (Chart.js), Apex |

### Aviation

| Scenario | Difficulty | Est. Time | Tagline | Key Products |
|----------|------------|-----------|---------|--------------|
| [SkyLane Dynamics](./Aviation/SkyLane%20Dynamics/) | Intermediate | ~45 min | Electric VTOL air taxis connecting rooftop skyports across Miami in under 8 minutes | Service Cloud, LWC, Flows |

### Agriculture

| Scenario | Difficulty | Est. Time | Tagline | Key Products |
|----------|------------|-----------|---------|--------------|
| [VineSense Analytics](./Agriculture/VineSense%20Analytics/) | Intermediate | ~40 min | AI-powered vineyard health monitoring and harvest optimization for boutique wineries | Screen Flows, LWC, Chart.js |

### Food & Beverage

| Scenario | Difficulty | Est. Time | Tagline | Key Products |
|----------|------------|-----------|---------|--------------|
| [BrewCycle](./Food%20%26%20Beverage/BrewCycle/) | Intermediate | ~45 min | Smart keg tracking and route optimization connecting microbreweries with bars and bottle shops | LWC (lightning-map), Record-Triggered Flows |

### Manufacturing

| Scenario | Difficulty | Est. Time | Tagline | Key Products |
|----------|------------|-----------|---------|--------------|
| [TerraDyne Heavy Industries](./Manufacturing/TerraDyne%20Heavy%20Industries/) | Intermediate | ~45 min | Autonomous solar-hybrid excavator fleet management across remote global mining sites | Screen Flows, LWC, Field Service, Master-Detail |

### Nonprofit & Rescue

| Scenario | Difficulty | Est. Time | Tagline | Key Products |
|----------|------------|-----------|---------|--------------|
| [PawPrint Rescue Network](./Nonprofit%20%26%20Rescue/PawPrint%20Rescue%20Network/) | Beginner | ~35 min | Coordinating foster care and adoptions across a network of animal rescue partners | Screen Flows, LWC, Record-Triggered Flows |

### Space & Recreation

| Scenario | Difficulty | Est. Time | Tagline | Key Products |
|----------|------------|-----------|---------|--------------|
| [Lunar Basecamp Outfitters](./Space%20%26%20Recreation/Lunar%20Basecamp%20Outfitters/) | Intermediate | ~45 min | Premium lunar hiking gear with expedition booking, certification tracking, and safety compliance | Screen Flows, LWC (lightning-map, Chart.js), Junction Objects |

<!--
### Healthcare
| Scenario | Difficulty | Est. Time | Tagline | Key Products |
|----------|------------|-----------|---------|--------------|
| (coming soon) | | | | |

### Financial Services
| Scenario | Difficulty | Est. Time | Tagline | Key Products |
|----------|------------|-----------|---------|--------------|
| (coming soon) | | | | |
-->

---

## What Each Scenario Includes

Every scenario README follows the same structure:

| Section | What It Contains |
|---------|-----------------|
| **The Challenge** | Business context and pain points for the fictional company |
| **What We're Building** | Solution overview in one paragraph |
| **Custom Objects** | Table of objects and their purpose |
| **LWC Wow Moment** | The visual payoff — what the finished dashboard looks like |
| **Step 00** | Terminal commands to scaffold the SFDX project (run before Cursor) |
| **Steps 01–07** | Copy/paste prompts: objects, data, permissions, flows, deploy, LWC, git |
| **Architecture Overview** | Build-order summary showing what each step produces |

---

> **Disclaimer:** These scenarios are for demonstration and educational purposes only. Do not deploy to production environments. Code is provided "as-is" without warranty.
