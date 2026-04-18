#!/usr/bin/env python3
"""
Interactive .env wizard (same questions as setup_env.py), then optional Docker Compose deploy.
Run from the project root. Requires Docker CLI + Compose v2 (`docker compose`).
Session generation needs: pip install -r requirements.txt (Pyrogram).
"""

from __future__ import annotations

import os
import shutil
import subprocess
import sys

from setup_env import interactive_collect, project_root, _write_env


def _backup_env(env_path: str) -> None:
    if os.path.isfile(env_path):
        bak = env_path + ".bak"
        try:
            shutil.copy2(env_path, bak)
            print(f"Existing .env copied to {os.path.basename(bak)}")
        except OSError as e:
            print(f"Warning: could not backup .env: {e}")
        print()


def _which_docker() -> str | None:
    return shutil.which("docker")


def _run_docker_compose(root: str) -> int:
    return subprocess.run(
        ["docker", "compose", "up", "-d", "--build"],
        cwd=root,
        env=os.environ.copy(),
    ).returncode


def main() -> None:
    root = project_root()
    env_path = os.path.join(root, ".env")

    print()
    print("RadioPlayerV3 — Docker setup (.env + deploy)")
    print("-" * 44)
    print()
    print("You will answer the same questions as setup_env.py, then we write .env")
    print("and optionally run: docker compose up -d --build")
    print()

    _backup_env(env_path)
    data = interactive_collect()
    _write_env(env_path, data, generated_by="setup_docker.py")
    print()
    print(f"Wrote {env_path}")

    if not _which_docker():
        print()
        print("Docker CLI not found in PATH. Install Docker, then run:")
        print(f"  cd {root}")
        print("  docker compose up -d --build")
        print()
        return

    print()
    ans = input("Deploy now with Docker Compose? [Y/n]: ").strip().lower()
    if ans and ans not in ("y", "yes"):
        print("Skipped deploy. Start later: docker compose up -d --build")
        print()
        return

    print()
    print("Running: docker compose up -d --build")
    rc = _run_docker_compose(root)
    if rc == 0:
        print()
        print("Deploy started. Logs: docker compose logs -f")
    else:
        print()
        print(f"docker compose exited with code {rc}. Fix errors above, then run again from:")
        print(f"  {root}")
    print()


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\nAborted.")
        sys.exit(130)
