#!/usr/bin/env bash
set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${HOME}/.cursor/skills"

mkdir -p "${TARGET_DIR}"

copied=0
for skill_dir in "${SRC_DIR}"/sf-service-*; do
  if [[ -d "${skill_dir}" ]]; then
    skill_name="$(basename "${skill_dir}")"
    rm -rf "${TARGET_DIR}/${skill_name}"
    cp -R "${skill_dir}" "${TARGET_DIR}/${skill_name}"
    copied=$((copied + 1))
  fi
done

echo "Installed ${copied} Service Cloud skills to ${TARGET_DIR}"
