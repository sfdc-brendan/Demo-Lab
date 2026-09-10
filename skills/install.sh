#!/usr/bin/env bash
set -euo pipefail
echo ""
echo " This pack moved to sfdc-brendan/Unofficial-Skills (ui/lwc)"
echo " Forwarding to the new installer…"
echo ""
curl -fsSL "https://raw.githubusercontent.com/sfdc-brendan/Unofficial-Skills/main/ui/lwc/install.sh" | bash -s -- "$@"
