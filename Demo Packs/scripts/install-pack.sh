#!/usr/bin/env bash
#
# Demo Packs installer: authenticate to a Salesforce org, choose a pack, and deploy.
# Run from the Demo Packs directory (or from the Demo-Lab repo root).
# Requires: Git, Salesforce CLI (sf)
#

set -e

# Repo root = parent of "Demo Packs"; script lives in Demo Packs/scripts/
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
DEMO_PACKS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$DEMO_PACKS_DIR/.." && pwd)"

echo "Demo-Lab repo root: $REPO_ROOT"
echo ""

# Check Salesforce CLI
if ! command -v sf &> /dev/null; then
  echo "Salesforce CLI (sf) is not installed or not on PATH."
  echo "Install it from: https://developer.salesforce.com/tools/sfdxcli"
  exit 1
fi

# Step 4: Log in (opens browser)
echo "Opening browser to log in to your Salesforce org (will be set as default)..."
sf org login web --set-default

# Step 5: Choose pack and deploy
echo ""
echo "Which pack do you want to deploy?"
echo "  1) Pack 1 – LWC Cards & Dashboard (Incident Dashboard, Modern Account Card, Modern Contact Card)"
echo "  2) Service Cloud Pack (full Service Cloud + Sentiment and Coaching)"
echo "  3) Both packs"
echo ""
read -r -p "Enter 1, 2, or 3: " choice

cd "$REPO_ROOT"

case "$choice" in
  1)
    echo "Deploying Pack 1..."
    sf project deploy start \
      --source-dir "LWCs/Incident Dashboard" \
      --source-dir "LWCs/Modern Account Card" \
      --source-dir "LWCs/Modern Contact Card" \
      --wait 15
    ;;
  2)
    echo ""
    echo "*** DISCLAIMER: Salesforce Voice must be installed in your org before installing this pack. ***"
    echo "*** If Salesforce Voice is not installed, deployment of the Service Cloud Pack will fail.   ***"
    echo ""
    echo "Deploying Service Cloud Pack..."
    sf project deploy start \
      --source-dir "Service Cloud/Incident Detection" \
      --source-dir "Service Cloud/Email OTP" \
      --source-dir "Service Cloud/Case Tagging" \
      --source-dir "Service Cloud/Similar Cases" \
      --source-dir "LWCs/Sentiment and Coaching" \
      --wait 15
    ;;
  3)
    echo "Deploying Pack 1..."
    sf project deploy start \
      --source-dir "LWCs/Incident Dashboard" \
      --source-dir "LWCs/Modern Account Card" \
      --source-dir "LWCs/Modern Contact Card" \
      --wait 15
    echo ""
    echo "*** DISCLAIMER: Salesforce Voice must be installed in your org before installing this pack. ***"
    echo "*** If Salesforce Voice is not installed, deployment of the Service Cloud Pack will fail.   ***"
    echo ""
    echo "Deploying Service Cloud Pack..."
    sf project deploy start \
      --source-dir "Service Cloud/Incident Detection" \
      --source-dir "Service Cloud/Email OTP" \
      --source-dir "Service Cloud/Case Tagging" \
      --source-dir "Service Cloud/Similar Cases" \
      --source-dir "LWCs/Sentiment and Coaching" \
      --wait 15
    ;;
  *)
    echo "Invalid choice. Exiting."
    exit 1
    ;;
esac

echo ""
echo "Deployment finished. See each pack's README for permission sets and post-deploy setup."
