#!/usr/bin/env bash
# Interactive .env wizard + optional Docker Compose (same as setup_docker.py / setup_docker.bat).
# Run from repo root: ./scripts/setup_docker.sh   or: bash scripts/setup_docker.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "RadioPlayerV3 — Docker setup (interactive .env + optional deploy)"
echo "Requires: Docker with Compose v2 (docker compose); Python 3.10 with"
echo "          pip install -r requirements.txt if you generate a session string here."
echo ""

_pick_python() {
  if command -v python3.10 >/dev/null 2>&1; then
    echo "python3.10"
    return 0
  fi
  if command -v python3 >/dev/null 2>&1; then
    if python3 -c "import sys; sys.exit(0 if sys.version_info[:2] == (3, 10) else 1)" 2>/dev/null; then
      echo "python3"
      return 0
    fi
  fi
  if command -v python >/dev/null 2>&1; then
    if python -c "import sys; sys.exit(0 if sys.version_info[:2] == (3, 10) else 1)" 2>/dev/null; then
      echo "python"
      return 0
    fi
  fi
  return 1
}

PYTHON="$(_pick_python)" || PYTHON=""

if [[ -z "$PYTHON" ]]; then
  echo "Error: Python 3.10 not found (e.g. apt install python3.10 python3.10-venv)."
  echo "tgcalls==2.0.0 requires Python 3.6–3.10 for PyPI wheels; 3.11+ will not install."
  exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "Warning: docker not found in PATH. The wizard can still create .env."
  echo "Install Docker and add it to PATH to deploy with Compose at the end."
  echo ""
fi

exec "$PYTHON" "$ROOT/setup_docker.py" "$@"
