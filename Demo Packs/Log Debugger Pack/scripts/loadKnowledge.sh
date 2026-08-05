#!/usr/bin/env bash
#
# Loads the troubleshooting library into Salesforce Knowledge.
#
#   ./scripts/loadKnowledge.sh [target-org-alias]
#
# With no argument the Salesforce CLI's default org is used.
#
# Articles are tagged with External_ID__c = KB-###, which is how the retrieval
# layer scopes its search away from whatever articles the org already has.
# Re-running is safe: articles already present are skipped.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

TARGET_ORG="${1:-}"
if [ -z "$TARGET_ORG" ]; then
  TARGET_ORG="$(sf org display --json 2>/dev/null \
    | python3 -c 'import json,sys; print(json.load(sys.stdin)["result"]["username"])' 2>/dev/null || true)"
fi
if [ -z "$TARGET_ORG" ]; then
  echo "No org given and no default org is set."
  echo "  Pass an alias:  ./scripts/loadKnowledge.sh my-org"
  echo "  Or set one:     sf config set target-org my-org"
  exit 1
fi
echo "==> Target org: $TARGET_ORG"

first_id() {
  python3 -c 'import json,sys
try:
    records = json.load(sys.stdin)["result"]["records"]
    print(records[0]["Id"] if records else "")
except Exception:
    print("")'
}

record_type_id() {
  sf data query --query "$1" --target-org "$TARGET_ORG" --json 2>/dev/null | first_id
}

echo "==> Resolving the Knowledge record type"
# SDO orgs ship a KCS Article record type; anywhere else, take whatever is active.
RECORD_TYPE_ID="$(record_type_id "SELECT Id FROM RecordType WHERE SObjectType='Knowledge__kav' AND IsActive=true AND DeveloperName='SDO_Knowledge_KCSArticle' LIMIT 1")"
if [ -z "$RECORD_TYPE_ID" ]; then
  RECORD_TYPE_ID="$(record_type_id "SELECT Id FROM RecordType WHERE SObjectType='Knowledge__kav' AND IsActive=true LIMIT 1")"
fi
if [ -n "$RECORD_TYPE_ID" ]; then
  echo "    $RECORD_TYPE_ID"
else
  echo "    none found, importing against the master record type"
fi

echo "==> Checking for articles already loaded"
EXISTING=$(sf data query \
  --query "SELECT COUNT() FROM Knowledge__kav WHERE External_ID__c LIKE 'KB-%' AND PublishStatus IN ('Online','Draft')" \
  --target-org "$TARGET_ORG" --json | python3 -c 'import json,sys; print(json.load(sys.stdin)["result"]["totalSize"])')

if [ "$EXISTING" -gt 0 ]; then
  echo "    $EXISTING already present, skipping import (run scripts/apex/deleteKnowledge.apex to reset)"
else
  echo "==> Building the import file"
  node scripts/generateKnowledgeCsv.js "$RECORD_TYPE_ID"

  echo "==> Importing articles as drafts"
  sf data import bulk \
    --file data/knowledge-articles.csv \
    --sobject Knowledge__kav \
    --line-ending LF \
    --wait 10 \
    --target-org "$TARGET_ORG"
fi

echo "==> Publishing drafts"
sf apex run --file scripts/apex/publishKnowledge.apex --target-org "$TARGET_ORG" \
  | grep -E 'PUBLISH>>>' || true

echo "==> Done"
sf data query \
  --query "SELECT External_ID__c, Title FROM Knowledge__kav WHERE External_ID__c LIKE 'KB-%' AND PublishStatus='Online' ORDER BY External_ID__c" \
  --target-org "$TARGET_ORG"
