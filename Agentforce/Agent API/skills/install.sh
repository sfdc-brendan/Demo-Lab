#!/usr/bin/env bash
# Demo-Lab · Agentforce Agent API Skills installer
# Installs all sf-agent-api-* skills into Cursor, Claude Code, and/or Windsurf.
#
# Usage:
#   curl -sSL "https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/Agentforce/Agent%20API/skills/install.sh" | bash
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RAW_BASE_URL="https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/Agentforce/Agent%20API/skills"

# skill-name : optional supporting files fetched alongside SKILL.md
SKILLS=(
  sf-agent-api-setup
  sf-agent-api-session-lifecycle
  sf-agent-api-messaging
  sf-agent-api-variables
  sf-agent-api-citations
  sf-agent-api-integration-patterns
  sf-agent-api-troubleshooting
  sf-agent-api-review
)

# Skills that ship a reference.md (fetched in the GitHub download path).
REFERENCE_SKILLS=(
  sf-agent-api-setup
  sf-agent-api-messaging
  sf-agent-api-variables
)

TARGETS=()
[[ -d "${HOME}/.cursor" ]] && TARGETS+=("${HOME}/.cursor/skills")
[[ -d "${HOME}/.claude" ]] && TARGETS+=("${HOME}/.claude/skills")
[[ -d "${HOME}/.windsurf" ]] && TARGETS+=("${HOME}/.windsurf/skills")

if [[ ${#TARGETS[@]} -eq 0 ]]; then
  TARGETS+=("${HOME}/.cursor/skills" "${HOME}/.claude/skills")
fi

has_reference() {
  local name="$1"
  for r in "${REFERENCE_SKILLS[@]}"; do
    [[ "$r" == "$name" ]] && return 0
  done
  return 1
}

install_from_local() {
  local target_dir="$1"
  mkdir -p "${target_dir}"
  local copied=0

  for skill_dir in "${SCRIPT_DIR}"/sf-agent-api-*; do
    if [[ -d "${skill_dir}" ]]; then
      local skill_name
      skill_name="$(basename "${skill_dir}")"
      rm -rf "${target_dir:?}/${skill_name}"
      cp -R "${skill_dir}" "${target_dir}/${skill_name}"
      copied=$((copied + 1))
    fi
  done

  echo "Installed ${copied} Agent API skills to ${target_dir} (local copy)"
}

install_from_github() {
  local target_dir="$1"
  mkdir -p "${target_dir}"
  local copied=0

  for skill_name in "${SKILLS[@]}"; do
    local skill_target="${target_dir}/${skill_name}"
    rm -rf "${skill_target}"
    mkdir -p "${skill_target}"

    curl -fsSL "${RAW_BASE_URL}/${skill_name}/SKILL.md" -o "${skill_target}/SKILL.md"
    if has_reference "${skill_name}"; then
      curl -fsSL "${RAW_BASE_URL}/${skill_name}/reference.md" -o "${skill_target}/reference.md"
    fi
    copied=$((copied + 1))
  done

  echo "Installed ${copied} Agent API skills to ${target_dir} (GitHub download)"
}

if compgen -G "${SCRIPT_DIR}/sf-agent-api-*" > /dev/null; then
  for target_dir in "${TARGETS[@]}"; do
    install_from_local "${target_dir}"
  done
else
  for target_dir in "${TARGETS[@]}"; do
    install_from_github "${target_dir}"
  done
fi

echo "Done. Restart your IDE to load updated skills."
