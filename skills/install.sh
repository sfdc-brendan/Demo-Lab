#!/usr/bin/env bash
set -euo pipefail

# ============================================================
#  LWC UI/UX Skills Installer
#
#  One-line install (copy/paste into Terminal):
#
#    curl -sSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/skills/install.sh | bash
#
#  Or with wget:
#
#    wget -qO- https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/skills/install.sh | bash
#
#  Supports: Cursor, Claude Code, Windsurf, or any IDE with
#  a ~/.cursor/skills/ or ~/.claude/skills/ directory.
# ============================================================

REPO="sfdc-brendan/Demo-Lab"
BRANCH="main"
BASE_URL="https://raw.githubusercontent.com/$REPO/$BRANCH/skills"

SKILL_NAMES=(
    "sf-lwc-design"
    "sf-lwc-ux"
    "sf-lwc-styling"
    "sf-lwc-dataviz"
    "sf-lwc-review"
    "sf-lwc-mobile"
    "sf-lwc-page-composition"
    "sf-lwc-motion"
    "sf-lwc-content"
    "sf-lwc-experience"
    "sf-lwc-theming"
)

# -----------------------------------------------------------
#  Detect IDE skills directories
# -----------------------------------------------------------
TARGETS=()

if [ -d "$HOME/.cursor" ]; then
    TARGETS+=("$HOME/.cursor/skills")
fi

if [ -d "$HOME/.claude" ]; then
    TARGETS+=("$HOME/.claude/skills")
fi

if [ -d "$HOME/.windsurf" ]; then
    TARGETS+=("$HOME/.windsurf/skills")
fi

if [ ${#TARGETS[@]} -eq 0 ]; then
    TARGETS+=("$HOME/.cursor/skills")
fi

# -----------------------------------------------------------
#  Determine download method
# -----------------------------------------------------------
download() {
    local url="$1"
    local dest="$2"
    if command -v curl &>/dev/null; then
        curl -sSL "$url" -o "$dest" 2>/dev/null
    elif command -v wget &>/dev/null; then
        wget -qO "$dest" "$url" 2>/dev/null
    else
        echo "  ERROR: Neither curl nor wget found. Install one and try again."
        exit 1
    fi
}

# -----------------------------------------------------------
#  Check if running from local clone or remote
# -----------------------------------------------------------
SCRIPT_DIR=""
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
    REAL_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [ -f "$REAL_PATH/sf-lwc-design/SKILL.md" ]; then
        SCRIPT_DIR="$REAL_PATH"
    fi
fi

MODE="remote"
if [ -n "$SCRIPT_DIR" ]; then
    MODE="local"
fi

# -----------------------------------------------------------
#  Install
# -----------------------------------------------------------
echo ""
echo "==========================================="
echo "  LWC UI/UX Skills Installer"
echo "  ${#SKILL_NAMES[@]} design skills for LWC development"
echo "==========================================="
echo ""
echo "  Source: $( [ "$MODE" = "local" ] && echo "local ($SCRIPT_DIR)" || echo "github.com/$REPO" )"
echo "  Target: ${TARGETS[*]}"
echo ""

installed=0
skipped=0
total=${#SKILL_NAMES[@]}

for skill in "${SKILL_NAMES[@]}"; do

    # ------ Get the SKILL.md content ------
    if [ "$MODE" = "local" ]; then
        src="$SCRIPT_DIR/$skill/SKILL.md"
        if [ ! -f "$src" ]; then
            echo "  WARN  $skill — SKILL.md not found locally, skipping"
            skipped=$((skipped + 1))
            continue
        fi
    else
        src_url="$BASE_URL/$skill/SKILL.md"
        tmp_file=$(mktemp)
        if ! download "$src_url" "$tmp_file" || [ ! -s "$tmp_file" ]; then
            echo "  WARN  $skill — could not download, skipping"
            rm -f "$tmp_file"
            skipped=$((skipped + 1))
            continue
        fi
        src="$tmp_file"
    fi

    # ------ Validate frontmatter ------
    if ! head -5 "$src" | grep -q "^name:"; then
        echo "  WARN  $skill — missing 'name:' in frontmatter, skipping"
        [ "$MODE" = "remote" ] && rm -f "$src"
        skipped=$((skipped + 1))
        continue
    fi

    # ------ Install to each target directory ------
    for target_dir in "${TARGETS[@]}"; do
        dest="$target_dir/$skill"
        mkdir -p "$dest"

        if [ "$MODE" = "local" ]; then
            cp -R "$SCRIPT_DIR/$skill/"* "$dest/"
        else
            cp "$src" "$dest/SKILL.md"
        fi
    done

    [ "$MODE" = "remote" ] && rm -f "$src"

    if [ -d "${TARGETS[0]}/$skill" ] 2>/dev/null; then
        echo "  OK    $skill"
    fi
    installed=$((installed + 1))
done

echo ""
echo "-------------------------------------------"
echo "  Installed: $installed / $total skills"
if [ $skipped -gt 0 ]; then
    echo "  Skipped:   $skipped"
fi
echo ""
echo "  Installed to:"
for target_dir in "${TARGETS[@]}"; do
    echo "    $target_dir"
done
echo "-------------------------------------------"
echo ""

if [ $installed -gt 0 ]; then
    echo "Skills installed:"
    for skill in "${SKILL_NAMES[@]}"; do
        for target_dir in "${TARGETS[@]}"; do
            if [ -f "$target_dir/$skill/SKILL.md" ]; then
                echo "  - $skill"
                break
            fi
        done
    done
    echo ""
    echo "Restart your IDE to activate the new skills."
fi
