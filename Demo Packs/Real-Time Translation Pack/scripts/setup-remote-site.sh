#!/usr/bin/env bash
#
# Creates the Remote Site Setting for the target org's MIAW SCRT2 messaging host,
# so the Virtual Customer's inbound callouts are authorized. Run this once per org
# after deploying the pack (it fixes the "Unauthorized endpoint ... salesforce-scrt.com"
# error).
#
# Usage:
#   ./scripts/setup-remote-site.sh [ORG_ALIAS_OR_USERNAME]
# If no org is given, your default org is used.
#
set -e

PACK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." && pwd)"

ORG_ARG=()
if [ -n "${1:-}" ]; then
  ORG_ARG=(--target-org "$1")
fi

if ! command -v sf &> /dev/null; then
  echo "Salesforce CLI (sf) is not installed or not on PATH." >&2
  exit 1
fi

# Resolve the org's instance host and derive the SCRT2 messaging host.
HOST=$(sf org display "${ORG_ARG[@]}" --json \
  | python3 -c "import sys,json;u=json.load(sys.stdin)['result']['instanceUrl'];print(u.split('://')[1].rstrip('/'))")

if [ -z "$HOST" ]; then
  echo "Could not determine the org's instance URL. Are you authenticated?" >&2
  exit 1
fi

SCRT_HOST=$(echo "$HOST" | sed -E 's/\.my\.salesforce\.com$/.my.salesforce-scrt.com/; s/\.lightning\.force\.com$/.my.salesforce-scrt.com/')
URL="https://${SCRT_HOST}"
echo "Org host:           $HOST"
echo "MIAW SCRT endpoint: $URL"

# Generate the Remote Site Setting in the pack source, deploy it, then clean up
# so no org-specific URL is left in the repo.
RSS_DIR="$PACK_DIR/force-app/main/default/remoteSiteSettings"
RSS_FILE="$RSS_DIR/VirtualCustomer_MIAW_SCRT.remoteSite-meta.xml"
mkdir -p "$RSS_DIR"
trap 'rm -f "$RSS_FILE"; rmdir "$RSS_DIR" 2>/dev/null || true' EXIT

cat > "$RSS_FILE" <<XML
<?xml version="1.0" encoding="UTF-8"?>
<RemoteSiteSetting xmlns="http://soap.sforce.com/2006/04/metadata">
    <description>MIAW (Messaging for In-App and Web) SCRT2 endpoint used by the Virtual Customer component.</description>
    <disableProtocolSecurity>false</disableProtocolSecurity>
    <isActive>true</isActive>
    <url>${URL}</url>
</RemoteSiteSetting>
XML

echo "Deploying Remote Site Setting..."
sf project deploy start --source-dir "$RSS_DIR" "${ORG_ARG[@]}" --wait 10

echo ""
echo "Done. The Virtual Customer can now reach the messaging endpoint."
