#!/usr/bin/env bash

set -Eeuo pipefail

readonly REPOSITORY="sfdc-brendan/Demo-Lab"
readonly SKILL_NAME="agentforce-lightning-types"
readonly SKILL_PATH="Agentforce/Skills/${SKILL_NAME}"

install_claude=false
install_cursor=false
force=false
ref="${SKILL_REF:-main}"

usage() {
    cat <<'EOF'
Install the Agentforce Lightning Types skill for Claude Code and/or Cursor.

Usage:
  ./install.sh [options]

Options:
  --claude       Install for Claude Code only
  --cursor       Install for Cursor only
  --all          Install for both (default)
  --force        Replace an existing installation
  --ref REF      Install from a branch, tag, or commit (default: main)
  -h, --help     Show this help

Environment:
  CLAUDE_CONFIG_DIR  Claude config directory (default: ~/.claude)
  CURSOR_CONFIG_DIR  Cursor config directory (default: ~/.cursor)
  SKILL_REF          Default Git branch, tag, or commit

Examples:
  ./install.sh
  ./install.sh --cursor
  ./install.sh --all --force
EOF
}

die() {
    printf 'Error: %s\n' "$*" >&2
    exit 1
}

while (($# > 0)); do
    case "$1" in
        --claude)
            install_claude=true
            ;;
        --cursor)
            install_cursor=true
            ;;
        --all)
            install_claude=true
            install_cursor=true
            ;;
        --force)
            force=true
            ;;
        --ref)
            (($# >= 2)) || die "--ref requires a value"
            ref="$2"
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            die "Unknown option: $1 (use --help for usage)"
            ;;
    esac
    shift
done

if [[ "$install_claude" == false && "$install_cursor" == false ]]; then
    install_claude=true
    install_cursor=true
fi

command -v curl >/dev/null 2>&1 || die "curl is required"
command -v tar >/dev/null 2>&1 || die "tar is required"

claude_config_dir="${CLAUDE_CONFIG_DIR:-${HOME}/.claude}"
cursor_config_dir="${CURSOR_CONFIG_DIR:-${HOME}/.cursor}"
destinations=()

if [[ "$install_claude" == true ]]; then
    destinations+=("${claude_config_dir}/skills/${SKILL_NAME}")
fi
if [[ "$install_cursor" == true ]]; then
    destinations+=("${cursor_config_dir}/skills/${SKILL_NAME}")
fi

if [[ "$force" == false ]]; then
    for destination in "${destinations[@]}"; do
        if [[ -e "$destination" || -L "$destination" ]]; then
            die "${destination} already exists; rerun with --force to replace it"
        fi
    done
fi

temp_dir="$(mktemp -d "${TMPDIR:-/tmp}/${SKILL_NAME}.XXXXXX")"
cleanup() {
    rm -rf "$temp_dir"
}
trap cleanup EXIT

archive="${temp_dir}/repository.tar.gz"
archive_url="https://api.github.com/repos/${REPOSITORY}/tarball/${ref}"

printf 'Downloading %s from %s (%s)...\n' "$SKILL_NAME" "$REPOSITORY" "$ref"
curl --fail --location --silent --show-error --retry 3 \
    --output "$archive" "$archive_url"
tar -xzf "$archive" -C "$temp_dir"

skill_source=""
for candidate in "${temp_dir}"/*/"${SKILL_PATH}"; do
    if [[ -f "${candidate}/SKILL.md" ]]; then
        skill_source="$candidate"
        break
    fi
done

[[ -n "$skill_source" ]] || die "Downloaded archive does not contain ${SKILL_PATH}/SKILL.md"

install_skill() {
    local destination="$1"
    local parent
    local staging
    local backup=""

    parent="$(dirname "$destination")"
    mkdir -p "$parent"
    staging="$(mktemp -d "${parent}/.${SKILL_NAME}.install.XXXXXX")"
    cp -R "${skill_source}/." "$staging/"

    if [[ -e "$destination" || -L "$destination" ]]; then
        backup="${destination}.backup.$$"
        mv "$destination" "$backup"
    fi

    if mv "$staging" "$destination"; then
        [[ -z "$backup" ]] || rm -rf "$backup"
    else
        [[ -z "$backup" ]] || mv "$backup" "$destination"
        die "Failed to install to ${destination}"
    fi

    printf 'Installed: %s\n' "$destination"
}

for destination in "${destinations[@]}"; do
    install_skill "$destination"
done

printf '\nDone. Restart Claude Code or Cursor to ensure the skill is discovered.\n'
