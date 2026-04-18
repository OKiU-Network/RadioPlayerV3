# 📻 Telegram Radio Player V3

[![Mentioned in Awesome Telegram Calls](https://awesome.re/mentioned-badge-flat.svg)](https://github.com/tgcalls/awesome-tgcalls)
[![Stars](https://img.shields.io/github/stars/AsmSafone/RadioPlayerV3?style=flat\&color=blue)](https://github.com/AsmSafone/RadioPlayerV3/stargazers)
[![Forks](https://img.shields.io/github/forks/AsmSafone/RadioPlayerV3?style=flat\&color=green)](https://github.com/AsmSafone/RadioPlayerV3/network/members)
[![Issues](https://img.shields.io/github/issues/AsmSafone/RadioPlayerV3)](https://github.com/AsmSafone/RadioPlayerV3/issues)
[![Closed Issues](https://img.shields.io/github/issues-closed/AsmSafone/RadioPlayerV3)](https://github.com/AsmSafone/RadioPlayerV3/issues?q=is%3Aissue+is%3Aclosed)
[![Pull Requests](https://img.shields.io/github/issues-pr/AsmSafone/RadioPlayerV3)](https://github.com/AsmSafone/RadioPlayerV3/pulls)
[![Contributors](https://img.shields.io/github/contributors/AsmSafone/RadioPlayerV3?style=flat)](https://github.com/AsmSafone/RadioPlayerV3/graphs/contributors)
[![Repo Size](https://img.shields.io/github/repo-size/AsmSafone/RadioPlayerV3?color=red)](https://github.com/AsmSafone/RadioPlayerV3)
[![Commit Activity](https://img.shields.io/github/commit-activity/m/AsmSafone/RadioPlayerV3)](https://github.com/AsmSafone/RadioPlayerV3/commits/main)
[![License](https://img.shields.io/github/license/AsmSafone/RadioPlayerV3)](LICENSE)
[![Security Rating](https://sonarcloud.io/api/project_badges/measure?project=LightYagami28_RadioPlayerV3\&metric=security_rating)](https://sonarcloud.io/summary/new_code?id=LightYagami28_RadioPlayerV3)
[![Updates](https://img.shields.io/badge/Updates-Telegram%20Channel-green)](https://t.me/AsmSafone)
[![Support](https://img.shields.io/badge/Support-Group-blue)](https://t.me/AsmSupport)

---

## 🎧 What is it?

A modern Telegram bot to stream nonstop Radio, Music, and YouTube Lives directly into Group or Channel Voice Chats.

Live in production at:

* 📡 [AsmSafone Channel](https://t.me/AsmSafone)
* 🎵 [AsmSupport Group](https://t.me/AsmSupport)

---

## 🚀 Features

* 🎶 Playlist with queuing and 24/7 radio support
* 🔴 YouTube Live stream support
* 🔁 Auto-fallback to radio when playlist ends
* 🔄 Persistent playback even after Heroku restarts
* ⏱️ Show current audio playback position
* 🕹️ Interactive controls via buttons and commands
* ⬇️ Download audio from YouTube
* 🏷️ Dynamic VC title updates with song name
* ⚡ Pre-download next tracks to ensure smooth playback

---

## ☁ Deploy Instantly

### 💜 Deploy to Heroku

[![Deploy to Heroku](https://img.shields.io/badge/Deploy%20To%20Heroku-blueviolet?style=for-the-badge\&logo=heroku)](https://deploy.safone.tech)

> **Note:** Set Heroku region to **Europe** for better stability.

### ⚡ Deploy to Railway

[![Deploy to Railway](https://img.shields.io/badge/Deploy%20To%20Railway-blueviolet?style=for-the-badge\&logo=railway)](https://railway.app/new/template?template=https%3A%2F%2Fgithub.com%2FAsmSafone%2FRadioPlayerV3&envs=API_ID%2CAPI_HASH%2CBOT_TOKEN%2CSESSION_STRING%2CCHAT_ID%2CLOG_GROUP%2CADMINS%2CADMIN_ONLY%2CMAXIMUM_DURATION%2CSTREAM_URL%2CREPLY_MESSAGE)

> Ensure a voice chat is **started in your group/channel** before deploying.

---

## 🔧 Configuration

### Required ENV Vars

```
API_ID, API_HASH, BOT_TOKEN, SESSION_STRING, CHAT_ID
```

### Optional ENV Vars

```
LOG_GROUP, AUTH_USERS, STREAM_URL, MAXIMUM_DURATION,
REPLY_MESSAGE, ADMIN_ONLY, HEROKU_API_KEY, HEROKU_APP_NAME
```

> [🔗 Live Stream URLs](https://telegra.ph/Live-Radio-Stream-Links-05-17)  |  [⚙️ Generate SESSION\_STRING](https://t.me/genStr_robot)

---

## 📦 Requirements

* Python >= 3.6
* FFmpeg Installed
* Telegram API + String Session
* User Account as Admin in VC

---

## 🖥️ Run Locally (VPS)

```bash
# Install dependencies
sudo apt install git curl python3-pip ffmpeg -y

# Clone & setup
git clone https://github.com/AsmSafone/RadioPlayerV3
cd RadioPlayerV3
pip3 install -r requirements.txt

# Set .env values
# Run the bot
python3 main.py
```

---

## 🐳 Docker (Linux server)

### Fresh VM (nothing installed yet)

**One URL — downloads nothing by hand:** installs **git + curl** if needed, **clones this repo**, then runs the full bootstrap (Docker vs bare-metal, ffmpeg, `.env`, optional wizards):

```bash
curl -fsSL https://raw.githubusercontent.com/OKiU-Network/RadioPlayerV3/master/install.sh | bash
```

Optional: `RADIOPLAYER_REPO=... RADIOPLAYER_DIR=/opt/radio bash` (or export those before the pipe). Same flow: **clone → enter repo → install step by step → done.**

If you already cloned the repo locally:

```bash
chmod +x scripts/bootstrap-fresh-vm.sh bootstrap-fresh-vm.sh
./bootstrap-fresh-vm.sh
```

Or: `bash scripts/bootstrap-fresh-vm.sh` — it installs **git, curl, ffmpeg**, optionally **Docker**, then clones/updates the repo and walks you through **Docker** vs **bare-metal Python 3.9**. The one-liner above avoids cloning first; it runs `install.sh` which then calls `scripts/bootstrap-fresh-vm.sh --local`.

Image uses **Python 3.9** (bookworm-slim), **FFmpeg**, and **git** (for the `downloader` pip dependency). Build from the repo root where `Dockerfile` and `docker-compose.yml` live.

**Why 3.9:** **`tgcalls==2.0.0`** publishes **Linux (`manylinux`) wheels only for Python 3.6–3.9** — there is no `cp310` Linux wheel. **Windows/macOS** have **`cp310`** wheels, so use **Python 3.10** there. On **Python 3.11+**, `tgcalls==2.0.0` has no wheels.

**Bare-metal Linux:** use **Python 3.9**, e.g. `sudo apt install python3.9 python3.9-venv` then `python3.9 -m venv venv && source venv/bin/activate && pip install -r requirements.txt`.

**Interactive wizard (same questions as `setup_env.py`)** — writes **`.env`**, then optionally runs **`docker compose up -d --build`**:

```bash
python3.9 setup_docker.py
```

Or use the shell helper (prefers **`python3.9`** on Linux; warns if `docker` is missing):

```bash
chmod +x setup_docker.sh scripts/setup_docker.sh
./setup_docker.sh
```

On Windows you can double-click **`setup_docker.bat`** (needs Docker Desktop and Python with `pip install -r requirements.txt` if you generate a session string).

**Manual:** copy **`.env.sample`** → **`.env`** and fill in values, then deploy (from repo root):

```bash
chmod +x scripts/deploy-docker.sh
./scripts/deploy-docker.sh
```

Optional: `./scripts/deploy-docker.sh --pull` runs **`git pull`** before **`docker compose up -d --build`**.

Or run Compose directly:

```bash
docker compose up -d --build
```

Logs: `docker compose logs -f` · Stop: `docker compose down`

**Without Compose** (plain Docker):

```bash
docker build -t radioplayerv3 .
docker run -d --name radioplayerv3 --restart unless-stopped --env-file .env radioplayerv3
```

Do **not** commit `.env`; mount or pass `--env-file` only on the server.

**If the container logs `API_ID` empty:** the file must live **next to `docker-compose.yml`** on the host (same folder you run `docker compose` from after `cd`), with real values — not `.env.sample` / placeholders. `docker compose` reads that file for variable substitution; rename or copy until `grep API_ID .env` shows your numeric id.

---

## 🪟 Windows & Pyrogram 2 (this tree)

This codebase includes fixes for **Pyrogram 2**, **Telegram API layer 158** (voice chat updates), and **Windows** (FFmpeg resolution, no FIFO, optional `CHAT_ID` as `@username`).

* Use **Python 3.10** on Windows. (**Linux** needs **3.9** for `tgcalls` wheels; see Docker/README.) **Python 3.11+** has no `tgcalls==2.0.0` wheels.
* Install deps: run **`install_deps.bat`** or `py -3.10 -m pip install -r requirements.txt`.
* Create `.env`: run **`setup.bat`** / `python setup_env.py`, or copy **`.env.sample`**.
* Run: **`run.bat`** or `py -3.10 main.py`.
* Install **FFmpeg** (e.g. `winget install Gyan.FFmpeg`) and ensure it is on `PATH`, or rely on WinGet’s install path (the bot tries to find it).

Do **not** commit `.env` or session files (see `.gitignore`).

---

## 📄 License

```text
GNU AGPLv3
Copyright (c) 2021  Asm Safone
```

---

## 🙌 Credits

* [@AsmSafone](https://github.com/AsmSafone)
* [@delivrance](https://github.com/delivrance) - Pyrogram
* [@MarshalX](https://github.com/MarshalX) - PyTgCalls
* [All Contributors](https://github.com/AsmSafone/RadioPlayerV3/graphs/contributors)

---

## Changelog (OKiU fork — maintenance & Windows)

### 2026-04 — Pyrogram 2, Telegram layer 158, local setup

* **`requirements.txt`** — Pin `tgcalls==2.0.0` and `pytgcalls==2.1.0` (Linux: **3.9** manylinux wheels; Windows/macOS: **3.10** `cp310` wheels; **3.11+**: no wheels).
* **`config.py`** — Optional `heroku3` import; regex fix for admin IDs; `CHAT_ID` can be numeric **or** public `@username`; trim env strings.
* **`user.py`** — Userbot uses `session_string=` so Pyrogram 2 string sessions work (no bogus SQLite path).
* **`utils.py`** — Resolve **FFmpeg** on Windows (PATH + WinGet install path); **no `os.mkfifo` on Windows** (plain PCM file for radio); **`Client.send` → `invoke`** compatibility for pytgcalls; raw **`invoke`** for VC title / `CreateGroupCall`; **`get_chat_members`** uses `async for` + `ChatMembersFilter.ADMINISTRATORS` (Pyrogram 2); radio FFmpeg: low-latency flags, reconnect on HTTP streams, flush packets.
* **`main.py`** — **`SetBotCommands`** via **`await bot.invoke(...)`** inside `async with bot`; optional `join_chat` / `get_chat` diagnostics for `CHAT_ID`.
* **`plugins/bot/private.py`** — Safe captions when `message.from_user` is missing; callback admin check if `from_user` is absent.
* **`pytgcalls_layer_patch.py`** — Patch for **Telegram layer 158**: `GroupCall` no longer has `.params`; handle **`UpdateGroupCallConnection`**; use `getattr(..., "params", None)` on `UpdateGroupCall`.
* **Scripts** — `setup_env.py` (interactive `.env` + optional session generation), `setup.bat`, `install_deps.bat`, `run.bat`.
* **`.gitignore`** — `__pycache__/`, `downloads/`, `ffmpeg.log`, etc.
* **Docker** — `Dockerfile` (Python **3.9**-slim + FFmpeg + git; `tgcalls` has no Linux cp310 wheel), `docker-compose.yml` (volume for `downloads`, `env_file: .env`), `.dockerignore`, **`setup_docker.py`** / **`setup_docker.sh`** (interactive `.env` + optional compose), **`scripts/deploy-docker.sh`** (optional `git pull` + compose up).

---
