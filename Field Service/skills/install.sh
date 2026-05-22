#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$SCRIPT_DIR"

if [[ -d "$HOME/.cursor" ]]; then
  TARGET_BASE="$HOME/.cursor/skills"
elif [[ -d "$HOME/.claude" ]]; then
  TARGET_BASE="$HOME/.claude/skills"
elif [[ -d "$HOME/.windsurf" ]]; then
  TARGET_BASE="$HOME/.windsurf/skills"
else
  echo "No supported IDE skills directory found."
  echo "Expected one of: ~/.cursor, ~/.claude, ~/.windsurf"
  exit 1
fi

mkdir -p "$TARGET_BASE"

copied=0
while IFS= read -r -d '' skill_dir; do
  skill_name="$(basename "$skill_dir")"
  if [[ "$skill_name" == "README.md" ]]; then
    continue
  fi
  cp -R "$skill_dir" "$TARGET_BASE/"
  copied=$((copied + 1))
done < <(find "$SOURCE_DIR" -maxdepth 1 -mindepth 1 -type d -name "sf-field-*" -print0)

echo "Installed $copied Field Service skills to $TARGET_BASE"
echo "Restart your IDE to load new skills."
