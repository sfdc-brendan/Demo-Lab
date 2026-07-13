#!/usr/bin/env bash
# Demo-Lab · Agentforce Vision Skills installer
# Installs the Agentforce Vision skill(s) into Claude Code, Cursor, and/or Codex CLI.
# These skills teach an assistant how to give an Agentforce agent working vision —
# analyzing a customer-uploaded photo on-platform via a flex prompt template + vision model.
#
# Usage:
#   curl -sSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/Agentforce/Vision/install.sh | bash
#   curl -sSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/Agentforce/Vision/install.sh | bash -s -- --target=claude
#   curl -sSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/Agentforce/Vision/install.sh | bash -s -- --target=all
#
# Targets:
#   claude   → ~/.claude/skills/<skill>/     (auto-discovered by Claude Code)
#   cursor   → ~/.cursor/skills/<skill>/     (auto-discovered by Cursor)
#   codex    → ~/.codex/skills/<skill>/      (+ ~/.codex/AGENTS.md hint line)
#   all      → install into every supported target, even if not yet on disk
#   auto     → (default) install into each detected target

set -euo pipefail

REPO="sfdc-brendan/Demo-Lab"
BRANCH="main"
SUBFOLDER="Agentforce/Vision"
TARBALL_URL="https://codeload.github.com/${REPO}/tar.gz/${BRANCH}"

TARGET="auto"
for arg in "$@"; do
    case "$arg" in
        --target=*) TARGET="${arg#--target=}" ;;
        --help|-h)
            sed -n '2,20p' "$0" 2>/dev/null || true
            exit 0
            ;;
    esac
done

c_red()    { printf '\033[31m%s\033[0m' "$*"; }
c_green()  { printf '\033[32m%s\033[0m' "$*"; }
c_yellow() { printf '\033[33m%s\033[0m' "$*"; }
c_blue()   { printf '\033[34m%s\033[0m' "$*"; }
c_dim()    { printf '\033[2m%s\033[0m' "$*"; }

step() { printf "  %s %s\n" "$(c_blue "›")" "$*"; }
ok()   { printf "  %s %s\n" "$(c_green "✓")" "$*"; }
warn() { printf "  %s %s\n" "$(c_yellow "!")" "$*"; }
die()  { printf "  %s %s\n" "$(c_red "✗")" "$*" >&2; exit 1; }

# --- preflight ---------------------------------------------------------------

command -v curl >/dev/null 2>&1 || die "curl is required"
command -v tar  >/dev/null 2>&1 || die "tar is required"

printf "\n%s\n" "$(c_blue "Demo-Lab · Agentforce Vision Skills installer")"
printf "%s\n\n" "$(c_dim "Give your Agentforce agents the ability to see.")"

# --- detect targets ----------------------------------------------------------

DETECTED=()
[ -d "$HOME/.claude" ] && DETECTED+=("claude")
[ -d "$HOME/.cursor" ] && DETECTED+=("cursor")
[ -d "$HOME/.codex"  ] && DETECTED+=("codex")

case "$TARGET" in
    claude|cursor|codex)
        TARGETS=("$TARGET")
        ;;
    all)
        TARGETS=("claude" "cursor" "codex")
        ;;
    auto)
        if [ ${#DETECTED[@]} -eq 0 ]; then
            die "No supported tool found. Install Claude Code, Cursor, or Codex CLI first, or pass --target=claude|cursor|codex|all."
        fi
        TARGETS=("${DETECTED[@]}")
        step "Detected: ${TARGETS[*]}"
        ;;
    *)
        die "Unknown --target: $TARGET (expected claude|cursor|codex|all|auto)"
        ;;
esac

# --- fetch -------------------------------------------------------------------

WORKDIR="$(mktemp -d -t agentforce-vision-skills-XXXXXX)"
trap 'rm -rf "$WORKDIR"' EXIT

step "Fetching ${REPO}@${BRANCH} …"
curl -sSL "$TARBALL_URL" \
    | tar -xz -C "$WORKDIR" --strip-components=1 "Demo-Lab-${BRANCH}/${SUBFOLDER}" \
    || die "Failed to download or extract skills from ${TARBALL_URL}"

SRC_ROOT="${WORKDIR}/${SUBFOLDER}"
[ -d "$SRC_ROOT" ] || die "Downloaded bundle is missing ${SUBFOLDER}"

# Every direct subfolder that contains a SKILL.md is a skill to install.
SKILLS=()
for d in "$SRC_ROOT"/*/; do
    [ -f "${d}SKILL.md" ] && SKILLS+=("$(basename "$d")")
done
[ ${#SKILLS[@]} -gt 0 ] || die "No skills (folders with SKILL.md) found in ${SUBFOLDER}"
ok "Found ${#SKILLS[@]} skill(s): ${SKILLS[*]}"

# --- install per target ------------------------------------------------------

install_folder() {  # $1=tool label  $2=dest base dir  $3=skill name
    local label="$1" base="$2" name="$3"
    local dest="${base}/${name}"
    step "${label} → ${dest}"
    mkdir -p "$base"
    rm -rf "$dest"
    cp -R "${SRC_ROOT}/${name}" "$dest"
    ok "${name} installed"
}

install_claude() { local n="$1"; install_folder "Claude Code" "$HOME/.claude/skills" "$n"; }
install_cursor() { local n="$1"; install_folder "Cursor"      "$HOME/.cursor/skills" "$n"; }

install_codex() {
    local name="$1"
    install_folder "Codex CLI" "$HOME/.codex/skills" "$name"
    local dest="$HOME/.codex/skills/${name}"
    local agents_file="$HOME/.codex/AGENTS.md"
    local hint_line="@${dest}/SKILL.md  # ${name}"
    if [ -f "$agents_file" ] && grep -qF "$dest/SKILL.md" "$agents_file" 2>/dev/null; then
        printf "    %s\n" "$(c_dim "AGENTS.md already references ${name}")"
    else
        warn "Codex CLI has no native skill loader. Add this line to ~/.codex/AGENTS.md:"
        printf "      %s\n" "$hint_line"
    fi
}

for name in "${SKILLS[@]}"; do
    for t in "${TARGETS[@]}"; do
        case "$t" in
            claude) install_claude "$name" ;;
            cursor) install_cursor "$name" ;;
            codex)  install_codex  "$name" ;;
        esac
    done
done

printf "\n%s\n" "$(c_green "Done.")"
printf "%s\n"   "$(c_dim "Claude Code / Cursor auto-discover the skill. Restart or reload the window to pick it up.")"
printf "%s\n\n" "$(c_dim "Trigger it by asking to build an Agentforce agent that can analyze a photo / 'see'.")"
