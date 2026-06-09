# Agentforce Skills

Reusable AI assistant skills for building Agentforce demos. Each skill encodes a working Salesforce pattern (contracts, file layouts, gotchas) so Claude Code, Cursor, or Codex can apply it consistently.

## One-line install

Auto-detects which tools you have installed (Claude Code, Cursor, Codex CLI) and installs all skills into each:

```bash
curl -sSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/Agentforce/Skills/install.sh | bash
```

Pick a specific tool:

```bash
# Claude Code only
curl -sSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/Agentforce/Skills/install.sh | bash -s -- --target=claude

# Cursor only
curl -sSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/Agentforce/Skills/install.sh | bash -s -- --target=cursor

# Codex CLI only
curl -sSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/Agentforce/Skills/install.sh | bash -s -- --target=codex

# Install into every supported tool, even ones not yet on disk
curl -sSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/Agentforce/Skills/install.sh | bash -s -- --target=all
```

### What the installer does

| Tool | Install location | How it loads |
|---|---|---|
| Claude Code | `~/.claude/skills/<skill-name>/` | Auto-discovered by Claude Code |
| Cursor | `~/.cursor/rules/<skill-name>.mdc` | Auto-loaded when matching `globs:` |
| Codex CLI | `~/.codex/skills/<skill-name>/` | Reference manually from `~/.codex/AGENTS.md` (Codex has no native skill loader yet — installer prints the line to add) |

The installer is idempotent — re-running upgrades to the latest content from `main`.

## Available skills

| Skill | What it does |
|---|---|
| [`agentforce-lightning-types`](./agentforce-lightning-types/) | Build custom Lightning Types (CLTs) that render rich UI inside an Agentforce chat window — Service Agent (Enhanced Chat v2), Employee Agent (LEX assist panel), and Mobile. Includes a runnable `HighlightCard` scaffold and a catalog of 8 reference patterns (carousel, item selector, add-to-cart, embedded form, file upload v1/v2, formatted URL, article cards, embedded screen flow). |

## Triggering a skill

Skills auto-trigger when you ask the assistant about something that matches the skill's description, or when you work in a matching folder (e.g., `lightningTypes/**`). You don't need to invoke them by name — just describe what you want to build:

> "I want to build a custom Lightning Type that shows a product carousel inside the agent chat."

## Manual install

If you'd rather not pipe a script to bash:

```bash
git clone https://github.com/sfdc-brendan/Demo-Lab.git
cd Demo-Lab/Agentforce/Skills

# Claude Code
cp -R agentforce-lightning-types ~/.claude/skills/

# Cursor
cp agentforce-lightning-types/agentforce-lightning-types.mdc ~/.cursor/rules/

# Codex CLI
cp -R agentforce-lightning-types ~/.codex/skills/
echo "@$HOME/.codex/skills/agentforce-lightning-types/SKILL.md" >> ~/.codex/AGENTS.md
```

## Disclaimer

These skills are demonstration accelerators, not official Salesforce products. Review and test before using anywhere production-adjacent.
