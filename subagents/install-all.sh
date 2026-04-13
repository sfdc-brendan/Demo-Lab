#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/sfdc-brendan/Demo-Lab.git"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

SUBAGENTS=(
  "sf-dse|DSE|Distinguished Solutions Engineer|Strategic advisor & executive engagement"
  "sf-ba|BA|Business Analyst|Requirements, process analysis & adoption"
  "sf-sa|SA|Solution Architect|Technical design & platform architecture"
  "sf-se|SE|Solutions Engineer|Deal-level technical win management"
  "sf-demo-engineer|DemoEngineer|Demo Engineer|Demo environments, data & reliability"
  "sf-industry-advisor|IndustryAdvisor|Industry Advisor|Vertical expertise & regulatory context"
  "sf-value-engineer|ValueEngineer|Value Engineer|ROI, TCO & business case quantification"
  "sf-release-manager|ReleaseManager|Release Manager|CI/CD, environments & change management"
  "sf-customer-success|CustomerSuccess|Customer Success|Adoption, health & expansion"
)

banner() {
  echo ""
  echo -e "${CYAN}╔════════════════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║  Salesforce Subagent Library                          ║${NC}"
  echo -e "${CYAN}║  Complete AI skill suite for solutions selling        ║${NC}"
  echo -e "${CYAN}╚════════════════════════════════════════════════════════╝${NC}"
  echo ""
}

install_subagent() {
  local skill_name="$1"
  local folder="$2"
  local display_name="$3"
  local tagline="$4"
  local target_dir="$5"
  local source_dir="$6"

  mkdir -p "$target_dir/references"
  cp "$source_dir/SKILL.md" "$target_dir/SKILL.md"
  for ref in "$source_dir/references/"*.md; do
    [ -f "$ref" ] && cp "$ref" "$target_dir/references/"
  done

  echo -e "  ${GREEN}✓${NC} $display_name ${CYAN}($skill_name)${NC} — $tagline"
}

install_all_to() {
  local base_dir="$1"
  local platform="$2"
  local source_base="$3"

  echo -e "${CYAN}Installing to $platform ($base_dir)...${NC}"
  echo ""

  local count=0
  for entry in "${SUBAGENTS[@]}"; do
    IFS='|' read -r skill_name folder display_name tagline <<< "$entry"
    local target="$base_dir/$skill_name"
    local source="$source_base/$folder"

    if [ -d "$target" ]; then
      rm -rf "$target"
    fi

    if [ -d "$source" ] && [ -f "$source/SKILL.md" ]; then
      install_subagent "$skill_name" "$folder" "$display_name" "$tagline" "$target" "$source"
      count=$((count + 1))
    else
      echo -e "  ${RED}✗${NC} $display_name — source not found at $source"
    fi
  done

  echo ""
  echo -e "  ${GREEN}$count subagents installed to $platform${NC}"
  echo ""
}

banner

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ -f "$SCRIPT_DIR/DSE/SKILL.md" ]; then
  SOURCE_BASE="$SCRIPT_DIR"
else
  echo "Fetching from GitHub..."
  SOURCE_BASE=$(mktemp -d)
  git clone --depth 1 "$REPO_URL" "$SOURCE_BASE/repo" 2>/dev/null
  SOURCE_BASE="$SOURCE_BASE/repo/subagents"
fi

if [ "${1:-}" = "--cursor" ]; then
  install_all_to "$HOME/.cursor/skills" "Cursor" "$SOURCE_BASE"
elif [ "${1:-}" = "--claude" ]; then
  install_all_to "$HOME/.claude/skills" "Claude Code" "$SOURCE_BASE"
elif [ "${1:-}" = "--both" ]; then
  install_all_to "$HOME/.cursor/skills" "Cursor" "$SOURCE_BASE"
  install_all_to "$HOME/.claude/skills" "Claude Code" "$SOURCE_BASE"
else
  echo "Usage: ./install-all.sh [OPTION]"
  echo ""
  echo "Options:"
  echo "  --cursor    Install all subagents for Cursor IDE"
  echo "  --claude    Install all subagents for Claude Code"
  echo "  --both      Install all subagents for both platforms"
  echo ""
  echo "Subagents included:"
  for entry in "${SUBAGENTS[@]}"; do
    IFS='|' read -r skill_name folder display_name tagline <<< "$entry"
    printf "  %-24s %s\n" "$display_name" "$tagline"
  done
  echo ""
  echo "One-liner (no clone required):"
  echo "  curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/subagents/install-all.sh | bash -s -- --both"
  echo ""
  exit 0
fi

echo -e "${GREEN}Done!${NC} All subagents are now available. They activate automatically based on your prompts."
echo ""
echo "Quick test — try one of these:"
echo "  • \"Prepare an executive briefing for a telecom CIO\"        (DSE)"
echo "  • \"Write user stories for case escalation\"                  (BA)"
echo "  • \"Design the data model for a quoting process\"             (SA)"
echo "  • \"Prep me for a discovery call with a retail CTO\"          (SE)"
echo "  • \"Set up a demo org for financial services\"                (Demo Engineer)"
echo "  • \"What HIPAA requirements affect our Service Cloud build?\" (Industry Advisor)"
echo "  • \"Build an ROI model for Agentforce replacing IVR\"         (Value Engineer)"
echo "  • \"Design a CI/CD pipeline for bi-weekly releases\"          (Release Manager)"
echo "  • \"Create a success plan for a post-go-live customer\"       (Customer Success)"
echo ""
