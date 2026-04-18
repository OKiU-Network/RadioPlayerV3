#!/usr/bin/env bash
# Wrapper — full script: scripts/bootstrap-fresh-vm.sh
exec "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/scripts/bootstrap-fresh-vm.sh" "$@"
