#!/usr/bin/env bash
# Wrapper — full script lives in scripts/setup_docker.sh
exec "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/scripts/setup_docker.sh" "$@"
