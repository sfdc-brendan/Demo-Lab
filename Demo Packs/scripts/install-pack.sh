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
echo "  3) AI Case Generator Pack (Einstein-powered case, knowledge, and demo scenario generation)"
echo "  4) Intake Builder Pack (configurable intake builder + runtime + PDF)"
echo "  5) Real-Time Translation Pack (Virtual Customer chat: live translation + Agentforce route with escalation)"
echo "  6) All packs"
echo ""
read -r -p "Enter 1, 2, 3, 4, 5, or 6: " choice

deploy_pack1() {
  echo "Deploying Pack 1..."
  cd "$REPO_ROOT"
  sf project deploy start \
    --source-dir "LWCs/Incident Dashboard" \
    --source-dir "LWCs/Modern Account Card" \
    --source-dir "LWCs/Modern Contact Card" \
    --wait 15
}

deploy_service_cloud() {
  echo ""
  echo "*** DISCLAIMER: Salesforce Voice must be installed in your org before installing this pack. ***"
  echo "*** If Salesforce Voice is not installed, deployment of the Service Cloud Pack will fail.   ***"
  echo ""
  echo "Deploying Service Cloud Pack..."
  cd "$REPO_ROOT"
  sf project deploy start \
    --source-dir "Service Cloud/Incident Detection" \
    --source-dir "Service Cloud/Email OTP" \
    --source-dir "Service Cloud/Case Tagging" \
    --source-dir "Service Cloud/Similar Cases" \
    --source-dir "LWCs/Sentiment and Coaching" \
    --wait 15
}

deploy_ai_case_generator() {
  echo "Deploying AI Case Generator Pack..."
  cd "$DEMO_PACKS_DIR/AI Case Generator Pack"
  sf project deploy start \
    --source-dir force-app \
    --wait 15
}

deploy_intake_builder_pack() {
  echo "Deploying Intake Builder Pack..."
  cd "$DEMO_PACKS_DIR/Intake Builder Pack"
  sf project deploy start \
    --source-dir force-app \
    --wait 15
}

deploy_rtt_pack() {
  echo ""
  echo "*** NOTE: This pack needs Messaging for In-App & Web (an API/Custom Client deployment),       ***"
  echo "*** and—for the Agentforce route—an Agentforce Service Agent connected to a messaging channel. ***"
  echo "*** After deploy, edit getRoutes() in sdo_VirtualCustomerCtrl to match your org. See README.   ***"
  echo ""
  echo "Deploying Real-Time Translation Pack..."
  cd "$DEMO_PACKS_DIR/Real-Time Translation Pack"
  sf project deploy start \
    --source-dir force-app \
    --wait 15
}

case "$choice" in
  1)
    deploy_pack1
    ;;
  2)
    deploy_service_cloud
    ;;
  3)
    deploy_ai_case_generator
    ;;
  4)
    deploy_intake_builder_pack
    ;;
  5)
    deploy_rtt_pack
    ;;
  6)
    deploy_pack1
    echo ""
    deploy_service_cloud
    echo ""
    deploy_ai_case_generator
    echo ""
    deploy_intake_builder_pack
    echo ""
    deploy_rtt_pack
    ;;
  *)
    echo "Invalid choice. Exiting."
    exit 1
    ;;
esac

echo ""
echo "Deployment finished. See each pack's README for permission sets and post-deploy setup."
