#!/usr/bin/env bash
set -euo pipefail

SKILLS_DIR="$HOME/.cursor/skills"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

echo "==========================================="
echo "  LWC UI/UX Skills Installer for Cursor"
echo "==========================================="
echo ""

mkdir -p "$SKILLS_DIR"

installed=0
skipped=0

for skill in "${SKILL_NAMES[@]}"; do
    src="$SCRIPT_DIR/$skill"
    dest="$SKILLS_DIR/$skill"

    if [ ! -d "$src" ]; then
        echo "  WARN: Source directory not found: $src — skipping"
        skipped=$((skipped + 1))
        continue
    fi

    if [ ! -f "$src/SKILL.md" ]; then
        echo "  WARN: $skill/SKILL.md not found — skipping"
        skipped=$((skipped + 1))
        continue
    fi

    if ! head -5 "$src/SKILL.md" | grep -q "^name:"; then
        echo "  WARN: $skill/SKILL.md missing 'name:' in frontmatter — skipping"
        skipped=$((skipped + 1))
        continue
    fi

    if ! head -10 "$src/SKILL.md" | grep -q "^description:"; then
        echo "  WARN: $skill/SKILL.md missing 'description:' in frontmatter — skipping"
        skipped=$((skipped + 1))
        continue
    fi

    if [ -d "$dest" ]; then
        echo "  Updating: $skill"
    else
        echo "  Installing: $skill"
    fi

    mkdir -p "$dest"
    cp -R "$src/"* "$dest/"
    installed=$((installed + 1))
done

echo ""
echo "-------------------------------------------"
echo "  Installed: $installed skill(s)"
if [ $skipped -gt 0 ]; then
    echo "  Skipped:   $skipped skill(s)"
fi
echo "  Location:  $SKILLS_DIR"
echo "-------------------------------------------"
echo ""

if [ $installed -gt 0 ]; then
    echo "Installed skills:"
    for skill in "${SKILL_NAMES[@]}"; do
        if [ -f "$SKILLS_DIR/$skill/SKILL.md" ]; then
            echo "  - $skill"
        fi
    done
    echo ""
    echo "Restart Cursor to activate the new skills."
fi
