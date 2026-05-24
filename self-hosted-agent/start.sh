#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${AZP_URL:-}" || -z "${AZP_TOKEN:-}" || -z "${AZP_POOL:-}" ]]; then
  echo "AZP_URL, AZP_TOKEN, and AZP_POOL must be provided."
  exit 1
fi

# Agent binary is pre-installed in the image at build time — no download needed.
cd /azp/agent

./config.sh --unattended \
  --agent "${AZP_AGENT_NAME:-ado-selfhosted-linux-01}" \
  --url "$AZP_URL" \
  --auth pat \
  --token "$AZP_TOKEN" \
  --pool "$AZP_POOL" \
  --work /azp/_work \
  --replace

cleanup() {
  ./config.sh remove --unattended --auth pat --token "$AZP_TOKEN"
}

trap cleanup EXIT

./run.sh