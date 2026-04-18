#!/usr/bin/env bash
# Interactive .env wizard + optional Docker Compose (same as setup_docker.py / setup_docker.bat).
# Run from repo root: ./scripts/setup_docker.sh   or: bash scripts/setup_docker.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "RadioPlayerV3 — Docker setup (interactive .env + optional deploy)"
echo "Requires: Docker with Compose v2 (docker compose); Python 3.9 (Linux) or 3.10 (Windows/macOS)"
echo "          with pip install -r requirements.txt if you generate a session string here."
echo ""

_pick_python() {
  if command -v python3.9 >/dev/null 2>&1; then
    echo "python3.9"
    return 0
  fi
  if command -v python3.10 >/dev/null 2>&1; then
    echo "python3.10"
    return 0
  fi
  if command -v python3 >/dev/null 2>&1; then
    ver=$(python3 -c "import sys; print('%d.%d' % sys.version_info[:2])" 2>/dev/null || true)
    if [[ "$ver" == "3.9" || "$ver" == "3.10" ]]; then
      echo "python3"
      return 0
    fi
  fi
  if command -v python >/dev/null 2>&1; then
    ver=$(python -c "import sys; print('%d.%d' % sys.version_info[:2])" 2>/dev/null || true)
    if [[ "$ver" == "3.9" || "$ver" == "3.10" ]]; then
      echo "python"
      return 0
    fi
  fi
  return 1
}

PYTHON="$(_pick_python)" || PYTHON=""

if [[ -z "$PYTHON" ]]; then
  echo "Error: Python 3.9 (Linux) or 3.10 (Windows/macOS) not found."
  echo "tgcalls==2.0.0: Linux manylinux wheels are cp39 max; use 3.9 on Linux."
  exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "Warning: docker not found in PATH. The wizard can still create .env."
  echo "Install Docker and add it to PATH to deploy with Compose at the end."
  echo ""
fi

exec "$PYTHON" "$ROOT/setup_docker.py" "$@"
