#!/usr/bin/env bash
# RadioPlayerV3 — one URL full install (fresh Linux VM).
# Fetches nothing else by hand: installs git+curl if needed, clones repo, runs bootstrap.
#
#   curl -fsSL https://raw.githubusercontent.com/OKiU-Network/RadioPlayerV3/master/install.sh | bash
#
# Override defaults:
#   RADIOPLAYER_REPO=https://github.com/you/fork.git RADIOPLAYER_DIR=/opt/radio bash
#
set -euo pipefail

RADIOPLAYER_REPO="${RADIOPLAYER_REPO:-https://github.com/OKiU-Network/RadioPlayerV3.git}"
RADIOPLAYER_DIR="${RADIOPLAYER_DIR:-$HOME/RadioPlayerV3}"

die() { echo "install.sh: $*" >&2; exit 1; }
have_cmd() { command -v "$1" >/dev/null 2>&1; }

need_sudo() {
  if [[ $EUID -eq 0 ]]; then
    SUDO=""
  elif have_cmd sudo; then
    SUDO="sudo"
  else
    die "Need sudo or run as root to install git/curl."
  fi
}
run() { if [[ -n "${SUDO:-}" ]]; then $SUDO "$@"; else "$@"; fi; }

detect_pkg_family() {
  if [[ ! -f /etc/os-release ]]; then die "No /etc/os-release"; fi
  # shellcheck source=/dev/null
  source /etc/os-release
  local id="${ID:-}"
  local like="${ID_LIKE:-}"
  case "${id,,}" in
    ubuntu|debian|linuxmint|pop|zorin|elementary|raspbian) echo apt ;;
    fedora) echo dnf ;;
    arch|manjaro|endeavouros) echo pacman ;;
    *)
      if [[ "${like,,}" == *debian* || "${like,,}" == *ubuntu* ]]; then echo apt
      elif [[ "${like,,}" == *rhel* || "${like,,}" == *fedora* ]]; then echo dnf
      elif [[ "${like,,}" == *arch* ]]; then echo pacman
      else die "Unsupported distro: $id"
      fi
      ;;
  esac
}

ensure_git_curl() {
  have_cmd git && have_cmd curl && return 0
  need_sudo
  local fam
  fam=$(detect_pkg_family)
  echo "Installing git and curl ($fam)..."
  case "$fam" in
    apt)
      run apt-get update -y
      run apt-get install -y --no-install-recommends git curl ca-certificates
      ;;
    dnf)
      run dnf install -y git curl ca-certificates
      ;;
    pacman)
      run pacman -Sy --needed --noconfirm git curl ca-certificates
      ;;
    *) die "unknown family" ;;
  esac
  have_cmd git || die "git not available"
  have_cmd curl || die "curl not available"
}

main() {
  echo ""
  echo "RadioPlayerV3 — remote installer (clone + full bootstrap)"
  echo "Repository: $RADIOPLAYER_REPO"
  echo "Directory:  $RADIOPLAYER_DIR"
  echo ""

  ensure_git_curl

  if [[ -d "$RADIOPLAYER_DIR/.git" ]]; then
    echo "Updating existing clone..."
    git -C "$RADIOPLAYER_DIR" pull --ff-only
  else
    if [[ -e "$RADIOPLAYER_DIR" ]]; then
      die "Path exists and is not a git repo: $RADIOPLAYER_DIR — move it or set RADIOPLAYER_DIR"
    fi
    echo "Cloning..."
    git clone "$RADIOPLAYER_REPO" "$RADIOPLAYER_DIR"
  fi

  export RADIOPLAYER_DIR
  exec bash "$RADIOPLAYER_DIR/scripts/bootstrap-fresh-vm.sh" --local
}

main "$@"
