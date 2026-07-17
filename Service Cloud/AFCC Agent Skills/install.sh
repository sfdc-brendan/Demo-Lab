#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RAW_BASE_URL="https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/Service%20Cloud/AFCC%20Agent%20Skills"

SKILLS=(
  sf-afcc-build-orchestrator
  sf-afcc-voice-channel-setup
  sf-afcc-agentforce-voice-agent
  sf-afcc-ivr-flow
  sf-afcc-media-management
  sf-afcc-callbacks
  sf-afcc-agentforce-for-service
  sf-afcc-command-center
  sf-afcc-troubleshooting
)

# Skills that also ship a reference.md alongside SKILL.md.
HYBRID_SKILLS=(
  sf-afcc-ivr-flow
)

TARGETS=()
[[ -d "${HOME}/.cursor" ]] && TARGETS+=("${HOME}/.cursor/skills")
[[ -d "${HOME}/.claude" ]] && TARGETS+=("${HOME}/.claude/skills")
[[ -d "${HOME}/.windsurf" ]] && TARGETS+=("${HOME}/.windsurf/skills")

if [[ ${#TARGETS[@]} -eq 0 ]]; then
  TARGETS+=("${HOME}/.cursor/skills" "${HOME}/.claude/skills")
fi

is_hybrid() {
  local name="$1"
  for h in "${HYBRID_SKILLS[@]}"; do
    [[ "${h}" == "${name}" ]] && return 0
  done
  return 1
}

install_from_local() {
  local target_dir="$1"
  mkdir -p "${target_dir}"
  local copied=0

  for skill_dir in "${SCRIPT_DIR}"/sf-afcc-*; do
    if [[ -d "${skill_dir}" ]]; then
      local skill_name
      skill_name="$(basename "${skill_dir}")"
      rm -rf "${target_dir:?}/${skill_name}"
      cp -R "${skill_dir}" "${target_dir}/${skill_name}"
      copied=$((copied + 1))
    fi
  done

  echo "Installed ${copied} AFCC Agent skills to ${target_dir} (local copy)"
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
    if is_hybrid "${skill_name}"; then
      curl -fsSL "${RAW_BASE_URL}/${skill_name}/reference.md" -o "${skill_target}/reference.md" || true
    fi
    copied=$((copied + 1))
  done

  echo "Installed ${copied} AFCC Agent skills to ${target_dir} (GitHub download)"
}

if compgen -G "${SCRIPT_DIR}/sf-afcc-*" > /dev/null; then
  for target_dir in "${TARGETS[@]}"; do
    install_from_local "${target_dir}"
  done
else
  for target_dir in "${TARGETS[@]}"; do
    install_from_github "${target_dir}"
  done
fi

echo "Done. Restart your IDE to load updated skills."
