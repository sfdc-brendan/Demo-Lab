#!/usr/bin/env bash
set -euo pipefail

SKILL_NAME="sf-demo-engineer"
REPO_URL="https://github.com/sfdc-brendan/Demo-Lab.git"
REPO_SUBPATH="subagents/DemoEngineer"

CURSOR_DIR="$HOME/.cursor/skills/$SKILL_NAME"
CLAUDE_DIR="$HOME/.claude/skills/$SKILL_NAME"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

banner() {
  echo ""
  echo -e "${CYAN}╔════════════════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║  Salesforce Demo Engineer Subagent                    ║${NC}"
  echo -e "${CYAN}║  Demo environments, data & reliability               ║${NC}"
  echo -e "${CYAN}╚════════════════════════════════════════════════════════╝${NC}"
  echo ""
}

install_to() {
  local target_dir="$1"
  local platform="$2"

  if [ -d "$target_dir" ]; then
    echo -e "${YELLOW}  Existing install found at $target_dir — updating...${NC}"
    rm -rf "$target_dir"
  fi

  mkdir -p "$target_dir/references"

  local script_dir
  script_dir="$(cd "$(dirname "$0")" && pwd)"

  if [ -f "$script_dir/SKILL.md" ]; then
    cp "$script_dir/SKILL.md" "$target_dir/SKILL.md"
    cp "$script_dir/references/deliverables-guide.md" "$target_dir/references/deliverables-guide.md"
    cp "$script_dir/references/demo-data-patterns.md" "$target_dir/references/demo-data-patterns.md"
  else
    echo "  Fetching from GitHub..."
    local tmp_clone
    tmp_clone=$(mktemp -d)
    git clone --depth 1 --filter=blob:none --sparse "$REPO_URL" "$tmp_clone" 2>/dev/null
    (cd "$tmp_clone" && git sparse-checkout set "$REPO_SUBPATH" 2>/dev/null)
    cp "$tmp_clone/$REPO_SUBPATH/SKILL.md" "$target_dir/SKILL.md"
    cp "$tmp_clone/$REPO_SUBPATH/references/deliverables-guide.md" "$target_dir/references/deliverables-guide.md"
    cp "$tmp_clone/$REPO_SUBPATH/references/demo-data-patterns.md" "$target_dir/references/demo-data-patterns.md"
    rm -rf "$tmp_clone"
  fi

  echo -e "${GREEN}  ✓ Installed to $target_dir${NC} ($platform)"
}

banner

if [ "${1:-}" = "--cursor" ]; then
  install_to "$CURSOR_DIR" "Cursor"
elif [ "${1:-}" = "--claude" ]; then
  install_to "$CLAUDE_DIR" "Claude Code"
elif [ "${1:-}" = "--both" ]; then
  install_to "$CURSOR_DIR" "Cursor"
  install_to "$CLAUDE_DIR" "Claude Code"
else
  echo "Usage: ./install.sh [OPTION]"
  echo ""
  echo "Options:"
  echo "  --cursor    Install for Cursor IDE only"
  echo "  --claude    Install for Claude Code only"
  echo "  --both      Install for both Cursor and Claude Code"
  echo ""
  echo "One-liner (no clone required):"
  echo "  curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/DemoEngineer/install.sh | bash -s -- --both"
  echo ""
  exit 0
fi

echo ""
echo -e "${GREEN}Done!${NC} The Demo Engineer subagent will auto-activate when you:"
echo "  • Set up a demo org or generate sample data"
echo "  • Build demo reset procedures or environment runbooks"
echo "  • Create persona data packages or dependency maps"
echo "  • Ask for demo reliability review"
echo ""
