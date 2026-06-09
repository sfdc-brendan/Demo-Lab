#!/usr/bin/env bash
# Demo-Lab · Agentforce Skills installer
# Installs the agentforce-lightning-types skill into Claude Code, Cursor, and/or Codex CLI.
#
# Usage:
#   curl -sSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/Agentforce/Skills/install.sh | bash
#   curl -sSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/Agentforce/Skills/install.sh | bash -s -- --target=claude
#   curl -sSL https://raw.githubusercontent.com/sfdc-brendan/Demo-Lab/main/Agentforce/Skills/install.sh | bash -s -- --target=all
#
# Targets:
#   claude   → ~/.claude/skills/agentforce-lightning-types/
#   cursor   → ~/.cursor/rules/agentforce-lightning-types.mdc
#   codex    → ~/.codex/skills/agentforce-lightning-types/  (+ AGENTS.md hint)
#   all      → install into every detected target
#   auto     → (default) prompt if multiple detected, install detected if only one

set -euo pipefail

REPO="sfdc-brendan/Demo-Lab"
BRANCH="main"
SKILL_NAME="agentforce-lightning-types"
SKILL_PATH_IN_REPO="Agentforce/Skills/${SKILL_NAME}"
TARBALL_URL="https://codeload.github.com/${REPO}/tar.gz/${BRANCH}"

TARGET="auto"
for arg in "$@"; do
    case "$arg" in
        --target=*) TARGET="${arg#--target=}" ;;
        --help|-h)
            sed -n '2,15p' "$0" 2>/dev/null || true
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

printf "\n%s\n" "$(c_blue "Demo-Lab · Agentforce Skills installer")"
printf "%s\n\n" "$(c_dim "Skill: ${SKILL_NAME}")"

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

WORKDIR="$(mktemp -d -t demo-lab-skills-XXXXXX)"
trap 'rm -rf "$WORKDIR"' EXIT

step "Fetching ${REPO}@${BRANCH} …"
curl -sSL "$TARBALL_URL" \
    | tar -xz -C "$WORKDIR" --strip-components=1 "Demo-Lab-${BRANCH}/${SKILL_PATH_IN_REPO}" \
    || die "Failed to download or extract skill from ${TARBALL_URL}"

SRC="${WORKDIR}/${SKILL_PATH_IN_REPO}"
[ -f "${SRC}/SKILL.md" ] || die "Downloaded skill is missing SKILL.md"
ok "Fetched skill"

# --- install per target ------------------------------------------------------

install_claude() {
    local dest="$HOME/.claude/skills/${SKILL_NAME}"
    step "Installing for Claude Code → ${dest}"
    mkdir -p "$HOME/.claude/skills"
    rm -rf "$dest"
    cp -R "$SRC" "$dest"
    ok "Claude Code skill installed"
    printf "    %s\n" "$(c_dim "Restart Claude Code or run /skills to pick it up")"
}

install_cursor() {
    local dest="$HOME/.cursor/rules/${SKILL_NAME}.mdc"
    step "Installing for Cursor → ${dest}"
    mkdir -p "$HOME/.cursor/rules"
    if [ ! -f "${SRC}/${SKILL_NAME}.mdc" ]; then
        die "Cursor rule file missing in skill bundle"
    fi
    cp "${SRC}/${SKILL_NAME}.mdc" "$dest"
    ok "Cursor rule installed"
    printf "    %s\n" "$(c_dim "Reload Cursor (Cmd+Shift+P → 'Developer: Reload Window')")"
}

install_codex() {
    local dest="$HOME/.codex/skills/${SKILL_NAME}"
    step "Installing for Codex CLI → ${dest}"
    mkdir -p "$HOME/.codex/skills"
    rm -rf "$dest"
    cp -R "$SRC" "$dest"
    ok "Codex skill files installed"
    local agents_file="$HOME/.codex/AGENTS.md"
    local hint_line="@${dest}/SKILL.md  # agentforce-lightning-types · Agentforce CLT skill"
    if [ -f "$agents_file" ] && grep -qF "$dest/SKILL.md" "$agents_file" 2>/dev/null; then
        printf "    %s\n" "$(c_dim "AGENTS.md already references the skill")"
    else
        warn "Codex CLI doesn't auto-load skills. Add this line to ~/.codex/AGENTS.md:"
        printf "      %s\n" "$hint_line"
    fi
}

for t in "${TARGETS[@]}"; do
    case "$t" in
        claude) install_claude ;;
        cursor) install_cursor ;;
        codex)  install_codex ;;
    esac
done

printf "\n%s\n" "$(c_green "Done.")"
printf "%s\n" "$(c_dim "Trigger the skill by asking your assistant about Agentforce custom Lightning Types,")"
printf "%s\n\n" "$(c_dim "or by working in a lightningTypes/** folder.")"
