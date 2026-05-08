#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RAW_BASE_URL="https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/Service%20Cloud/skills"

SKILLS=(
  sf-service-case-management
  sf-service-console-productivity
  sf-service-email-to-case
  sf-service-entitlements
  sf-service-field-service-handoff
  sf-service-incident-management
  sf-service-knowledge
  sf-service-messaging-conversation-toolkit
  sf-service-omnichannel-routing
  sf-service-review
  sf-service-voice-digital
)

TARGETS=()
[[ -d "${HOME}/.cursor" ]] && TARGETS+=("${HOME}/.cursor/skills")
[[ -d "${HOME}/.claude" ]] && TARGETS+=("${HOME}/.claude/skills")
[[ -d "${HOME}/.windsurf" ]] && TARGETS+=("${HOME}/.windsurf/skills")

if [[ ${#TARGETS[@]} -eq 0 ]]; then
  TARGETS+=("${HOME}/.cursor/skills" "${HOME}/.claude/skills")
fi

install_from_local() {
  local target_dir="$1"
  mkdir -p "${target_dir}"
  local copied=0

  for skill_dir in "${SCRIPT_DIR}"/sf-service-*; do
    if [[ -d "${skill_dir}" ]]; then
      local skill_name
      skill_name="$(basename "${skill_dir}")"
      rm -rf "${target_dir:?}/${skill_name}"
      cp -R "${skill_dir}" "${target_dir}/${skill_name}"
      copied=$((copied + 1))
    fi
  done

  echo "Installed ${copied} Service Cloud skills to ${target_dir} (local copy)"
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
    copied=$((copied + 1))
  done

  echo "Installed ${copied} Service Cloud skills to ${target_dir} (GitHub download)"
}

if compgen -G "${SCRIPT_DIR}/sf-service-*" > /dev/null; then
  for target_dir in "${TARGETS[@]}"; do
    install_from_local "${target_dir}"
  done
else
  for target_dir in "${TARGETS[@]}"; do
    install_from_github "${target_dir}"
  done
fi

echo "Done. Restart your IDE to load updated skills."
