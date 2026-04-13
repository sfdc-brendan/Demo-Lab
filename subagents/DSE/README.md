# Distinguished Solutions Engineer (DSE) Subagent

A strategic advisor skill for **Cursor** and **Claude Code** that operates at Distinguished Solutions Engineer altitude — the highest individual contributor level in the Salesforce SE org.

> "Luminaries of strategic, industry and architectural knowledge… They envision and convey next-generation solutions that provide exceptional business value to customers."

---

## Quick Install

### One-liner (no clone needed)

```bash
# Both Cursor and Claude Code
curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/DSE/install.sh | bash -s -- --both

# Cursor only
curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/DSE/install.sh | bash -s -- --cursor

# Claude Code only
curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/DSE/install.sh | bash -s -- --claude
```

### From a local clone

```bash
git clone https://github.com/sfdc-brendan/Demo-Lab.git
cd Demo-Lab/subagents/DSE
chmod +x install.sh
./install.sh --both
```

### Manual install

Copy the files to the appropriate directory:

| Platform | Path |
|---|---|
| Cursor | `~/.cursor/skills/sf-dse/` |
| Claude Code | `~/.claude/skills/sf-dse/` |

```bash
# Cursor
mkdir -p ~/.cursor/skills/sf-dse/references
cp SKILL.md ~/.cursor/skills/sf-dse/
cp references/* ~/.cursor/skills/sf-dse/references/

# Claude Code
mkdir -p ~/.claude/skills/sf-dse/references
cp SKILL.md ~/.claude/skills/sf-dse/
cp references/* ~/.claude/skills/sf-dse/references/
```

---

## What It Does

The DSE subagent approaches every task from a strategic, executive-level perspective. Instead of jumping straight to implementation, it:

- **Thinks in business outcomes** — maps Salesforce capabilities to measurable customer value
- **Architects across clouds** — considers the full platform (Sales, Service, Marketing, Commerce, Data Cloud, MuleSoft, Tableau, Agentforce, Industries)
- **Makes everything reusable** — every artifact is designed as a template for the broader team
- **Communicates at executive register** — crisp, outcome-oriented, situation-complication-resolution structure
- **Delegates implementation** — hands off to specialized skills (`sf-apex`, `sf-lwc`, `sf-datacloud`, etc.) when it's time to build

### Deliverables it creates

| Deliverable | Description |
|---|---|
| **POV / White Paper** | Strategic thesis with architecture, business value, and customer evidence |
| **Executive Briefing** | C-suite presentation with tailored insights and demo narrative |
| **Strategic Demo Script** | Narrative-arc demo with talk track, reusable sections, and setup notes |
| **GTM Play** | Segment-targeted play with discovery framework and competitive positioning |
| **SE Enablement Session** | Coaching content with demo annotations and practice exercises |
| **Voice of the Customer Brief** | Aggregated field signals for Product Management |

### Engagement patterns

| Pattern | When |
|---|---|
| **Must-Win Deal** | Deployed as "special forces" on Big Bet / CRO-priority accounts |
| **Territory Planning** | Co-owning OU/segment strategy with Sales leadership |
| **Product Partnership** | Synthesizing field feedback into PM-ready themes |

---

## Scoring

The skill includes a 100-point rubric for evaluating strategic deliverables:

| Category | Points |
|---|---|
| Strategic Framing | 25 |
| Architecture Breadth | 20 |
| Reusability | 20 |
| Executive Communication | 20 |
| Actionability | 15 |

Request a score with: *"Score this deliverable against the DSE rubric."*

---

## File Structure

```
sf-dse/
├── SKILL.md                              # Core skill (231 lines)
└── references/
    ├── deliverables-guide.md             # Templates for all 6 deliverable types
    └── engagement-patterns.md            # Must-win, territory planning, product partnership
```

---

## Example Prompts

- "Help me prepare an executive briefing for a Tier 1 telecom customer evaluating Data Cloud + Agentforce"
- "Design a GTM play for financial services firms moving from legacy case management to Service Cloud + AI"
- "I'm on a must-win competitive deal against ServiceNow — build me a strategic demo narrative"
- "Create an enablement session teaching SEs how to present at C-suite altitude"
- "Synthesize the top 3 field pain points around Data Cloud into a VoC brief for PM"

---

## Compatibility

| Platform | Version | Status |
|---|---|---|
| Cursor | Any version with skills support | Supported |
| Claude Code | Any version with skills support | Supported |

The `SKILL.md` format is identical for both platforms. Only the install directory differs.

---

## Uninstall

```bash
# Cursor
rm -rf ~/.cursor/skills/sf-dse

# Claude Code
rm -rf ~/.claude/skills/sf-dse
```
