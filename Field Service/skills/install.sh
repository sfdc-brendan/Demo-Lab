#!/usr/bin/env bash
set -euo pipefail
echo ""
echo " This pack moved to sfdc-brendan/Unofficial-Skills (service-cloud/field-service)"
echo " Forwarding to the new installer…"
echo ""
curl -fsSL "https://raw.githubusercontent.com/sfdc-brendan/Unofficial-Skills/main/service-cloud/field-service/install.sh" | bash -s -- "$@"
