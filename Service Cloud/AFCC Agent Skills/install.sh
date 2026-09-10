#!/usr/bin/env bash
set -euo pipefail
echo ""
echo " This pack moved to sfdc-brendan/Unofficial-Skills (agentforce/contact-center)"
echo " Forwarding to the new installer…"
echo ""
curl -fsSL "https://raw.githubusercontent.com/sfdc-brendan/Unofficial-Skills/main/agentforce/contact-center/install.sh" | bash -s -- "$@"
