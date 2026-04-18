#!/usr/bin/env bash
# RadioPlayerV3 — full bootstrap for a new Linux VM (nothing installed yet).
# Tested targets: Ubuntu, Linux Mint, Debian, Fedora, Arch Linux (Manjaro uses Arch path).
#
# Installs: git, curl, ca-certificates, ffmpeg, (optional) Docker + Compose plugin,
#           Python 3.9 + venv for bare-metal (tgcalls Linux wheels are cp39-only).
#
# Usage:
#   One-line (clone + this script): see ../install.sh
#   bash scripts/bootstrap-fresh-vm.sh
#   bash scripts/bootstrap-fresh-vm.sh --local   # after clone; uses RADIOPLAYER_DIR
#
set -euo pipefail

REPO_DEFAULT="${REPO_DEFAULT:-https://github.com/OKiU-Network/RadioPlayerV3.git}"
INSTALL_DIR_DEFAULT="${INSTALL_DIR_DEFAULT:-$HOME/RadioPlayerV3}"

# --- helpers -----------------------------------------------------------------

die() { echo "Error: $*" >&2; exit 1; }

have_cmd() { command -v "$1" >/dev/null 2>&1; }

# curl | bash attaches stdin to a pipe, so plain `read` gets EOF. Prompt on the real tty.
# Usage: read_tty "prompt " varname   (varname is the name of the variable, no $)
read_tty() {
  local _prompt=$1
  local _var=$2
  if [[ -r /dev/tty ]]; then
    read -r -p "$_prompt" "$_var" < /dev/tty
  else
    read -r -p "$_prompt" "$_var"
  fi
}

# User to add to docker group (not root)
effective_user() {
  if [[ -n "${SUDO_USER:-}" ]]; then
    echo "$SUDO_USER"
  elif [[ $EUID -ne 0 ]]; then
    echo "${USER:-$(whoami)}"
  else
    logname 2>/dev/null || echo ""
  fi
}

need_root_or_sudo() {
  if [[ $EUID -eq 0 ]]; then
    SUDO=""
  elif have_cmd sudo; then
    SUDO="sudo"
  else
    die "Run as root or install sudo."
  fi
}

sudo_run() {
  if [[ -n "$SUDO" ]]; then
    $SUDO "$@"
  else
    "$@"
  fi
}

load_os_release() {
  if [[ ! -f /etc/os-release ]]; then
    die "Cannot read /etc/os-release — unsupported OS."
  fi
  # shellcheck source=/dev/null
  source /etc/os-release
  export OS_ID="${ID:-unknown}"
  export OS_ID_LIKE="${ID_LIKE:-}"
  export OS_VERSION_ID="${VERSION_ID:-}"
  export OS_PRETTY="${PRETTY_NAME:-$OS_ID}"
}

detect_family() {
  case "${OS_ID,,}" in
    ubuntu|pop|elementary|zorin) echo "apt" ;;
    linuxmint) echo "apt" ;;
    debian|devuan|raspbian) echo "apt" ;;
    fedora) echo "dnf" ;;
    rhel|centos|rocky|almalinux) echo "dnf" ;;
    arch|manjaro|endeavouros) echo "pacman" ;;
    *)
      if [[ "${OS_ID_LIKE,,}" == *debian* || "${OS_ID_LIKE,,}" == *ubuntu* ]]; then
        echo "apt"
      elif [[ "${OS_ID_LIKE,,}" == *rhel* || "${OS_ID_LIKE,,}" == *fedora* ]]; then
        echo "dnf"
      elif [[ "${OS_ID_LIKE,,}" == *arch* ]]; then
        echo "pacman"
      else
        echo "unknown"
      fi
      ;;
  esac
}

# --- package installs per family ---------------------------------------------

install_base_apt() {
  sudo_run apt-get update -y
  sudo_run apt-get install -y --no-install-recommends \
    git curl ca-certificates gnupg lsb-release ffmpeg \
    software-properties-common
}

install_base_dnf() {
  sudo_run dnf install -y git curl ca-certificates ffmpeg dnf-plugins-core
}

install_base_pacman() {
  sudo_run pacman -Sy --needed --noconfirm git curl ca-certificates ffmpeg base-devel
}

install_python39_apt() {
  sudo_run apt-get update -y
  if sudo_run apt-get install -y python3.9 python3.9-venv python3.9-dev; then
    return 0
  fi
  case "${OS_ID,,}" in
    ubuntu|linuxmint|pop|zorin|elementary)
      echo "Adding deadsnakes PPA for Python 3.9 (Ubuntu-family)..."
      sudo_run add-apt-repository -y ppa:deadsnakes/ppa
      sudo_run apt-get update -y
      sudo_run apt-get install -y python3.9 python3.9-venv python3.9-dev
      ;;
    debian)
      echo "python3.9 not in default Debian mirrors for this release."
      die "Use Docker deployment (option 1), or enable bookworm/oldstable python3.9, or install from source."
      ;;
    *)
      die "Could not install python3.9 via apt. Use Docker deployment (option 1)."
      ;;
  esac
}

install_python39_dnf() {
  sudo_run dnf install -y python3.9 python3.9-devel || die "dnf could not install python3.9 — try Docker deployment."
}

install_python39_pacman() {
  if sudo_run pacman -S --needed --noconfirm python39 2>/dev/null; then
    return 0
  fi
  die "Could not install package python39 from repos. Install Docker (option 1) or: yay -S python39"
}

ensure_python39() {
  local fam
  fam=$(detect_family)
  echo "Installing Python 3.9 (required for tgcalls wheels on Linux)..."
  case "$fam" in
    apt) install_python39_apt ;;
    dnf) install_python39_dnf ;;
    pacman) install_python39_pacman ;;
    *) die "Unknown distro family — use Docker deployment." ;;
  esac
  have_cmd python3.9 || die "python3.9 not available after install."
}

# Docker CLI + Compose v2 (`docker compose`) — what our deploy scripts use.
docker_compose_ready() {
  have_cmd docker || return 1
  docker compose version >/dev/null 2>&1
}

_docker_ensure_user_group_and_service() {
  local u
  u="$(effective_user)"
  if [[ -n "$u" && "$u" != "root" ]]; then
    if id -nG "$u" 2>/dev/null | tr ' ' '\n' | grep -qx docker; then
      echo "User '$u' is already in the 'docker' group."
    else
      sudo_run usermod -aG docker "$u" || true
      echo ""
      echo "Added user '$u' to the 'docker' group. Log out and back in (or: newgrp docker) before using docker without sudo."
    fi
  fi
  sudo_run systemctl enable --now docker 2>/dev/null || true
}

install_docker_engine() {
  if docker_compose_ready; then
    echo "Docker is already installed with Compose v2 (\`docker compose\`) — skipping Docker install."
    _docker_ensure_user_group_and_service
    return 0
  fi

  local fam
  fam=$(detect_family)
  echo "Installing Docker Engine + Compose plugin..."
  case "$fam" in
    apt|dnf)
      if ! have_cmd curl; then
        case "$fam" in
          apt) sudo_run apt-get install -y curl ;;
          dnf) sudo_run dnf install -y curl ;;
        esac
      fi
      curl -fsSL https://get.docker.com | sudo_run sh
      ;;
    pacman)
      sudo_run pacman -S --needed --noconfirm docker docker-compose-plugin
      sudo_run systemctl enable --now docker
      ;;
    *)
      die "Unknown family for Docker install."
      ;;
  esac

  _docker_ensure_user_group_and_service
}

clone_or_update_repo() {
  local url="$1" dir="$2"
  if [[ -d "$dir/.git" ]]; then
    echo "Repo exists at $dir — pulling..."
    git -C "$dir" pull --ff-only
  else
    if [[ -e "$dir" ]]; then
      die "Path exists but is not a git repo: $dir"
    fi
    git clone "$url" "$dir"
  fi
}

# --- main --------------------------------------------------------------------

main() {
  local local_mode=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --local) local_mode=1; shift ;;
      -h|--help)
        echo "Usage: $0 [--local]"
        echo "  --local  Repo already cloned; RADIOPLAYER_DIR or INSTALL_DIR_DEFAULT points at it (used by install.sh)."
        exit 0
        ;;
      *) die "Unknown option: $1 (try --help)" ;;
    esac
  done

  need_root_or_sudo
  load_os_release
  local FAMILY
  FAMILY=$(detect_family)
  [[ "$FAMILY" != "unknown" ]] || die "Unsupported distro: $OS_ID (ID_LIKE=$OS_ID_LIKE)"

  echo ""
  echo "RadioPlayerV3 — fresh VM bootstrap"
  echo "Detected: $OS_PRETTY (family: $FAMILY)"
  echo ""

  local repo dest mode
  if [[ "$local_mode" -eq 1 ]]; then
    dest="${RADIOPLAYER_DIR:-${INSTALL_DIR_DEFAULT}}"
    [[ -d "$dest/.git" ]] || die "Not a git repo (or missing): $dest — run install.sh or clone first."
    repo="$REPO_DEFAULT"
    echo "Using existing clone: $dest (--local)"
  else
    read_tty "Git clone URL [$REPO_DEFAULT]: " repo
    repo=${repo:-$REPO_DEFAULT}
    read_tty "Install directory [$INSTALL_DIR_DEFAULT]: " dest
    dest=${dest:-$INSTALL_DIR_DEFAULT}
  fi

  echo ""
  echo "How do you want to run the bot?"
  echo "  1) Docker (recommended — matches Dockerfile Python 3.9, easiest on fresh VMs)"
  echo "  2) Bare-metal — Python 3.9 venv (no Docker; you run main.py directly)"
  read_tty "Choice [1]: " mode
  mode=${mode:-1}

  echo ""
  echo "Installing base packages (git, curl, ffmpeg, ...)..."
  case "$FAMILY" in
    apt) install_base_apt ;;
    dnf) install_base_dnf ;;
    pacman) install_base_pacman ;;
    *) die "internal: family" ;;
  esac

  if [[ "$mode" == "1" ]]; then
    install_docker_engine
  else
    ensure_python39
  fi

  echo ""
  if [[ "$local_mode" -eq 1 ]]; then
    echo "Updating repo in $dest ..."
    git -C "$dest" pull --ff-only || true
  else
    clone_or_update_repo "$repo" "$dest"
  fi
  cd "$dest"

  if [[ ! -f .env ]]; then
    if [[ -f .env.sample ]]; then
      cp .env.sample .env
      echo "Created .env from .env.sample — edit it with real API_ID, BOT_TOKEN, etc."
    fi
  fi

  echo ""
  if [[ "$mode" == "1" ]]; then
    echo "--- Docker next steps ---"
    echo "1) Edit: $dest/.env (same folder as docker-compose.yml)"
    echo "2) Deploy:"
    echo "     cd $dest && ./scripts/deploy-docker.sh"
    echo "   or:   cd $dest && docker compose up -d --build"
    echo ""
    read_tty "Run interactive setup wizard (writes .env + optional compose)? [y/N]: " wiz
    if [[ "${wiz,,}" == "y" || "${wiz,,}" == "yes" ]]; then
      if [[ -r /dev/tty ]]; then
        if [[ -x ./setup_docker.sh ]]; then
          ./setup_docker.sh </dev/tty
        else
          bash scripts/setup_docker.sh </dev/tty
        fi
      else
        [[ -x ./setup_docker.sh ]] && ./setup_docker.sh || bash scripts/setup_docker.sh
      fi
    fi
  else
    echo "--- Bare-metal next steps ---"
    python3.9 -m venv venv
    ./venv/bin/pip install -U pip wheel
    ./venv/bin/pip install -r requirements.txt
    echo ""
    echo "Activate and configure:"
    echo "  cd $dest"
    echo "  source venv/bin/activate"
    echo "  python setup_env.py    # interactive .env"
    echo "  python main.py"
    echo ""
    read_tty "Run interactive .env wizard now? [y/N]: " wiz
    if [[ "${wiz,,}" == "y" || "${wiz,,}" == "yes" ]]; then
      if [[ -r /dev/tty ]]; then
        ./venv/bin/python setup_env.py </dev/tty
      else
        ./venv/bin/python setup_env.py
      fi
    fi
  fi

  echo ""
  echo "Done."
}

main "$@"
