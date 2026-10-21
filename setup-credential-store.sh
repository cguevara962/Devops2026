#!/usr/bin/env bash
# setup-credential-store.sh
# ──────────────────────────────────────────────────────────────────────────────
# Creates the SAP Credential Store service instance and seeds the demo secret
# that the BTP DevSecOps demo app reads at runtime.
#
# Pre-requisites:
#   • CF CLI logged in:  cf login -a <API> -o <ORG> -s <SPACE>
#   • curl + python3 available (standard on Linux/macOS)
#   • jq available: sudo apt-get install jq  (or brew install jq)
#
# Usage:
#   chmod +x setup-credential-store.sh
#   ./setup-credential-store.sh
# ──────────────────────────────────────────────────────────────────────────────

set -euo pipefail

# ── Configuration ─────────────────────────────────────────────────────────────
SERVICE_INSTANCE="devsecops-demo-credential-store"
SERVICE_KEY_NAME="${SERVICE_INSTANCE}-key"
NAMESPACE="pipeline-demo"
SECRET_NAME="db-password"
# Change this to a realistic-looking but fake password for the workshop demo:
SECRET_VALUE="D3m0-DB-Passw0rd-4-Workshop!"

# ── Step 1: Create Credential Store instance ──────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║  SAP Credential Store — DevSecOps Demo Setup             ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
echo "▶ Step 1/4 — Creating service instance '${SERVICE_INSTANCE}' (plan: proxy)..."

if cf service "${SERVICE_INSTANCE}" &>/dev/null; then
  echo "  ✓ Service instance already exists, skipping creation."
else
  cf create-service credstore proxy "${SERVICE_INSTANCE}"
  echo "  Waiting for provisioning (up to 60s)..."
  for i in {1..12}; do
    STATUS=$(cf service "${SERVICE_INSTANCE}" | grep -E "^status:" | awk '{print $2}')
    [[ "$STATUS" == "create" ]] && STATUS="in_progress"
    [[ "$STATUS" == "succeeded" ]] && break || sleep 5
  done
  echo "  ✓ Service instance ready."
fi

# ── Step 2: Create service key ────────────────────────────────────────────────
echo ""
echo "▶ Step 2/4 — Creating service key '${SERVICE_KEY_NAME}'..."
cf create-service-key "${SERVICE_INSTANCE}" "${SERVICE_KEY_NAME}" 2>/dev/null || \
  echo "  (key already exists)"
echo "  ✓ Service key ready."

# ── Step 3: Extract credentials ───────────────────────────────────────────────
echo ""
echo "▶ Step 3/4 — Extracting Credential Store connection details..."

SERVICE_KEY_JSON=$(cf service-key "${SERVICE_INSTANCE}" "${SERVICE_KEY_NAME}" | tail -n +3)

CS_URL=$(echo "${SERVICE_KEY_JSON}"      | python3 -c "import sys,json; print(json.load(sys.stdin)['url'])")
CS_USERNAME=$(echo "${SERVICE_KEY_JSON}" | python3 -c "import sys,json; print(json.load(sys.stdin)['username'])")
CS_PASSWORD=$(echo "${SERVICE_KEY_JSON}" | python3 -c "import sys,json; print(json.load(sys.stdin)['password'])")

echo "  ✓ Credential Store URL: ${CS_URL}"

# ── Step 4: Seed the demo secret ──────────────────────────────────────────────
echo ""
echo "▶ Step 4/4 — Creating secret '${SECRET_NAME}' in namespace '${NAMESPACE}'..."

HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
  -u "${CS_USERNAME}:${CS_PASSWORD}" \
  -X POST "${CS_URL}/api/v1/credentials" \
  -H "Content-Type: application/json" \
  -d "{
    \"name\":      \"${SECRET_NAME}\",
    \"value\":     \"${SECRET_VALUE}\",
    \"namespace\": \"${NAMESPACE}\",
    \"type\":      \"password\",
    \"metadata\":  {\"description\": \"Demo DB password for AD107102 workshop\"}
  }")

if [[ "${HTTP_STATUS}" == "200" || "${HTTP_STATUS}" == "201" ]]; then
  echo "  ✓ Secret '${NAMESPACE}/${SECRET_NAME}' created (HTTP ${HTTP_STATUS})."
elif [[ "${HTTP_STATUS}" == "409" ]]; then
  echo "  ✓ Secret already exists (HTTP 409 — no change needed)."
else
  echo "  ✗ Unexpected HTTP status ${HTTP_STATUS}. Check CF service key credentials."
  exit 1
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║  Setup complete!                                         ║"
echo "╠══════════════════════════════════════════════════════════╣"
echo "║  Service instance : ${SERVICE_INSTANCE}"
echo "║  Namespace        : ${NAMESPACE}"
echo "║  Secret key       : ${SECRET_NAME}"
echo "║                                                          ║"
echo "║  Next: bind the instance to your CF app via mta.yaml     ║"
echo "║  or:   cf bind-service <app> ${SERVICE_INSTANCE}         ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
