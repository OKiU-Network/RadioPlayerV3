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

if [[ "${1:-}" == "--pull" ]]; then
  echo "git pull..."
  git pull --ff-only
fi

echo "Building and starting containers..."
docker compose up -d --build

echo "Done. Logs: docker compose logs -f"
