#!/usr/bin/env bash
set -euo pipefail
echo ""
echo " This pack moved to sfdc-brendan/Unofficial-Skills (platform/subagents/DSE)"
echo " Forwarding to the new installer…"
echo ""
curl -fsSL "https://raw.githubusercontent.com/sfdc-brendan/Unofficial-Skills/main/platform/subagents/DSE/install.sh" | bash -s -- "$@"
