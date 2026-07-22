# Agentforce Lightning Types Skill

Install this skill for Claude Code and Cursor with one command:

```bash
curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/Agentforce/Skills/agentforce-lightning-types/install.sh | bash
```

The installer downloads the complete skill, including its references and examples, to:

- Claude Code: `~/.claude/skills/agentforce-lightning-types`
- Cursor: `~/.cursor/skills/agentforce-lightning-types`

## Install for one tool

Claude Code only:

```bash
curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/Agentforce/Skills/agentforce-lightning-types/install.sh | bash -s -- --claude
```

Cursor only:

```bash
curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/Agentforce/Skills/agentforce-lightning-types/install.sh | bash -s -- --cursor
```

## Update an existing installation

```bash
curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/Agentforce/Skills/agentforce-lightning-types/install.sh | bash -s -- --force
```

The installer refuses to overwrite an existing installation unless `--force` is supplied. Use `--ref <branch-or-tag>` to install a specific revision.

If you prefer to inspect scripts before running them, download [`install.sh`](./install.sh), review it, and run it locally.

See [`SKILL.md`](./SKILL.md) for the complete Custom Lightning Types guidance.
