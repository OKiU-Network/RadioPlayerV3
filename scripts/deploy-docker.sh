#!/usr/bin/env bash
# Deploy RadioPlayerV3 with Docker Compose (run from repo root, or any path: bash scripts/deploy-docker.sh)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [[ ! -f .env ]]; then
  echo "Error: .env not found in $ROOT"
  echo "Copy .env.sample to .env and fill in values, then re-run."
  exit 1
fi

# Reject placeholders / empty required keys (Compose needs real values in .env beside docker-compose.yml)
if ! (grep -E '^[[:space:]]*API_ID=' .env | head -1 | grep -qE '[0-9]{3,}'); then
  echo "Error: .env must set API_ID to your numeric app id (from https://my.telegram.org/apps)."
  echo "       Example: API_ID=12345678 or API_ID=\"12345678\""
  exit 1
fi

if [[ "${1:-}" == "--pull" ]]; then
  echo "git pull..."
  git pull --ff-only
fi

echo "Building and starting containers..."
docker compose up -d --build

echo "Done. Logs: docker compose logs -f"
