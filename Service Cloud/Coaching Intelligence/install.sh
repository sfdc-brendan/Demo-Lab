#!/usr/bin/env bash
#
# Coaching Intelligence installer.
# Deploys the channel-agnostic core to any Salesforce org, and optionally the
# Voice/Chat add-on (requires Service Cloud Voice + Enhanced Messaging).
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

TARGET_ORG=""
WITH_VOICE_CHAT=false
ASSIGN=true
TEST_LEVEL=""

usage() {
  cat <<'EOF'
Coaching Intelligence installer

Usage:
  ./install.sh [options]

Options:
  -o, --target-org <alias|username>  Target org (defaults to your sf default org)
      --with-voice-chat              Also deploy the Voice/Chat add-on (SCV + Enhanced Messaging)
      --no-assign                    Skip permission set assignment
  -l, --test-level <level>           Pass a deploy test level (e.g. RunLocalTests for production)
  -h, --help                         Show this help

Examples:
  ./install.sh --target-org MyOrg
  ./install.sh --target-org MyOrg --with-voice-chat
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -o|--target-org) TARGET_ORG="${2:-}"; shift 2 ;;
    --with-voice-chat) WITH_VOICE_CHAT=true; shift ;;
    --no-assign) ASSIGN=false; shift ;;
    -l|--test-level) TEST_LEVEL="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
done

# --- Preconditions -----------------------------------------------------------
if ! command -v sf >/dev/null 2>&1; then
  echo "ERROR: Salesforce CLI (sf) is not installed. See https://developer.salesforce.com/tools/salesforcecli" >&2
  exit 1
fi

ORG_ARGS=()
if [[ -n "${TARGET_ORG}" ]]; then
  ORG_ARGS=(--target-org "${TARGET_ORG}")
  ORG_LABEL="${TARGET_ORG}"
else
  ORG_LABEL="(default org)"
fi

echo "==> Verifying org connection: ${ORG_LABEL}"
if ! sf org display "${ORG_ARGS[@]}" >/dev/null 2>&1; then
  echo "ERROR: Could not connect to ${ORG_LABEL}. Authenticate first, e.g.:" >&2
  echo "       sf org login web --alias MyOrg" >&2
  exit 1
fi

DEPLOY_ARGS=()
[[ -n "${TEST_LEVEL}" ]] && DEPLOY_ARGS+=(--test-level "${TEST_LEVEL}")

# --- Core --------------------------------------------------------------------
echo "==> Deploying Coaching Intelligence core to ${ORG_LABEL}"
sf project deploy start --source-dir force-app "${ORG_ARGS[@]}" "${DEPLOY_ARGS[@]}"

if [[ "${ASSIGN}" == true ]]; then
  echo "==> Assigning permission set: Coaching_Intelligence_Access"
  sf org assign permset --name Coaching_Intelligence_Access "${ORG_ARGS[@]}" || \
    echo "    (permission set may already be assigned; continuing)"
fi

# --- Optional Voice/Chat add-on ---------------------------------------------
if [[ "${WITH_VOICE_CHAT}" == true ]]; then
  echo "==> Deploying Voice/Chat add-on (requires Service Cloud Voice + Enhanced Messaging)"
  sf project deploy start --source-dir optional/voice-chat/force-app "${ORG_ARGS[@]}" "${DEPLOY_ARGS[@]}"

  if [[ "${ASSIGN}" == true ]]; then
    echo "==> Assigning permission set: Coaching_Intelligence_VoiceChat_Access"
    sf org assign permset --name Coaching_Intelligence_VoiceChat_Access "${ORG_ARGS[@]}" || \
      echo "    (permission set may already be assigned; continuing)"
  fi
fi

cat <<EOF

==============================================================
 Coaching Intelligence installed.

 Next steps:
   1. In Lightning App Builder, add the "Coaching Insight Panel"
      component to your Case (and Voice Call / Messaging Session)
      record pages.
   2. Ensure Einstein Generative AI / Prompt Builder is enabled.
   3. Close a Case (or end a call/chat) and watch the panel update
      live within a few seconds.

 Channels active:
   - Case (core)$( [[ "${WITH_VOICE_CHAT}" == true ]] && echo "
   - Voice + Chat (add-on)" )
==============================================================
EOF
