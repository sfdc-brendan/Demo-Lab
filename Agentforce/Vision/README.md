# Agentforce Vision Skills

Reusable AI assistant skills that teach Claude Code, Cursor, or Codex how to give an **Agentforce agent the ability to see** — analyze a customer-uploaded photo (a device, an error screen, a blinking status light, a fault code) entirely on the Salesforce platform, behind the Einstein Trust Layer.

Distilled from a working reference implementation (the Agentforce Vision image-troubleshooting service agent), these skills encode the exact contracts, file layouts, and gotchas so an assistant can build vision into an agent consistently and correctly.

## One-line install

Auto-detects which tools you have (Claude Code, Cursor, Codex CLI) and installs every skill into each:

```bash
curl -sSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/Agentforce/Vision/install.sh | bash
```

Pick a specific tool:

```bash
# Claude Code only
curl -sSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/Agentforce/Vision/install.sh | bash -s -- --target=claude

# Cursor only
curl -sSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/Agentforce/Vision/install.sh | bash -s -- --target=cursor

# Codex CLI only
curl -sSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/Agentforce/Vision/install.sh | bash -s -- --target=codex

# Install into every supported tool, even ones not yet on disk
curl -sSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/Agentforce/Vision/install.sh | bash -s -- --target=all
```

### What the installer does

| Tool | Install location | How it loads |
|---|---|---|
| Claude Code | `~/.claude/skills/<skill-name>/` | Auto-discovered by Claude Code |
| Cursor | `~/.cursor/skills/<skill-name>/` | Auto-discovered by Cursor |
| Codex CLI | `~/.codex/skills/<skill-name>/` | Reference manually from `~/.codex/AGENTS.md` (Codex has no native skill loader yet — the installer prints the line to add) |

The installer is idempotent — re-running upgrades to the latest content from `main`. It auto-discovers every folder here that contains a `SKILL.md`, so new vision skills are picked up automatically.

## Available skills

| Skill | What it does |
|---|---|
| [`sf-ai-agentforce-vision`](./sf-ai-agentforce-vision/) | Full guidance for giving an Agentforce agent vision: the flex prompt template with a `ContentDocument` file input, the Apex orchestrator that resolves the uploaded image and calls the template via `ConnectApi.EinsteinLLM`, the Agent Script wiring (with the "only analyze real uploads" guardrail), permissions, an attachment-capable messaging channel, testing, and troubleshooting. |

## Triggering a skill

Skills auto-trigger when you ask your assistant about something matching the skill's description — you don't need to invoke them by name. For example:

> "Add photo analysis to my Agentforce agent so it can look at a customer's picture of a broken device and diagnose it."

> "How do I feed an uploaded image to a vision model from an Agentforce action?"

## Manual install

If you'd rather not pipe a script to bash:

```bash
git clone https://github.com/sfdc-brendan/Demo-Lab.git
cd Demo-Lab/Agentforce/Vision

# Claude Code
cp -R sf-ai-agentforce-vision ~/.claude/skills/

# Cursor
cp -R sf-ai-agentforce-vision ~/.cursor/skills/

# Codex CLI
cp -R sf-ai-agentforce-vision ~/.codex/skills/
echo "@$HOME/.codex/skills/sf-ai-agentforce-vision/SKILL.md" >> ~/.codex/AGENTS.md
```

## Disclaimer

These skills are demonstration accelerators, not official Salesforce products. Review and test before using anywhere production-adjacent.
