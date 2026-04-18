# Telegram Radio Player V3

[![Mentioned in Awesome Telegram Calls](https://awesome.re/mentioned-badge-flat.svg)](https://github.com/tgcalls/awesome-tgcalls)
[![License](https://img.shields.io/github/license/AsmSafone/RadioPlayerV3)](LICENSE)
[![Updates](https://img.shields.io/badge/Updates-Telegram%20Channel-green)](https://t.me/AsmSafone)
[![Support](https://img.shields.io/badge/Support-Group-blue)](https://t.me/AsmSupport)

A Telegram **bot + userbot** stack that streams **radio**, **music**, and **YouTube Live** into **group or channel voice chats**, with playlists, queueing, and on-screen controls.

**This repository (OKiU fork)** extends the upstream project with maintained **Pyrogram 2** support, **Docker** and **installer scripts**, **Windows** fixes, and clearer deployment docs. Upstream: [AsmSafone/RadioPlayerV3](https://github.com/AsmSafone/RadioPlayerV3).

---

## What you need first

| Requirement | Notes |
|-------------|--------|
| **Telegram API credentials** | [my.telegram.org/apps](https://my.telegram.org/apps) → `API_ID` (number) and `API_HASH` |
| **Bot token** | From [@BotFather](https://t.me/BotFather) → `BOT_TOKEN` |
| **User session** | Pyrogram **string session** for the account that joins the voice chat (often generated once via `setup_env.py`) → `SESSION_STRING` |
| **Target chat** | Group or channel ID, or public `@username` → `CHAT_ID` |
| **Voice chat** | A voice chat must be **available** (or startable) in that chat; the bot needs appropriate **admin** rights where applicable |
| **FFmpeg** | Required on the machine or inside the Docker image (installer/Dockerfile handle Linux) |

Do **not** commit `.env` or session secrets. Use `.gitignore` and keep secrets only on the server or your PC.

---

## Choose how to run it

| If you are… | Use this path |
|-------------|----------------|
| **New Linux VM** (Ubuntu, Debian, Mint, Fedora, Arch, etc.) | [One-line installer](#automated-install-on-linux) — installs tools, optional Docker, clone, wizards |
| **Linux server with Docker already** | [Docker Compose](#docker-compose) + `.env` next to `docker-compose.yml` |
| **Linux without Docker** | [Bare metal](#bare-metal-linux) — Python **3.9** + venv (required for voice libraries on Linux) |
| **Windows (development or local run)** | [Windows](#windows) — Python **3.10**, `install_deps.bat`, `setup_env.py`, `run.bat` |
| **Heroku / Railway** | [Cloud deploy](#cloud-deploy) buttons below |

---

## Automated install on Linux

Use this on a **fresh or minimal** system: it installs **git** and **curl** if needed, **clones** this repo, then runs an interactive **bootstrap** (system packages, **Docker** if you choose it, FFmpeg, optional `.env` wizards).

**Default clone location:** `~/RadioPlayerV3`  
**Default repository:** `https://github.com/OKiU-Network/RadioPlayerV3.git`

```bash
curl -fsSL https://raw.githubusercontent.com/OKiU-Network/RadioPlayerV3/master/install.sh | bash
```

**Customization** (optional):

```bash
export RADIOPLAYER_REPO=https://github.com/yourfork/RadioPlayerV3.git
export RADIOPLAYER_DIR=/opt/RadioPlayerV3
curl -fsSL https://raw.githubusercontent.com/OKiU-Network/RadioPlayerV3/master/install.sh | bash
```

**What happens during bootstrap**

1. Installs base packages (including **FFmpeg**).
2. Asks: **Docker** (recommended) or **bare-metal** Python.
3. If you pick **Docker** and Docker is **not** already usable (`docker compose` missing), it installs Docker Engine + Compose; if Docker is already installed, that step is **skipped**.
4. Ensures the clone is up to date, creates `.env` from `.env.sample` if missing, and can run **`setup_docker.py`** / **`setup_env.py`** interactively.

**If you already cloned the repo manually:**

```bash
cd /path/to/RadioPlayerV3
chmod +x bootstrap-fresh-vm.sh scripts/bootstrap-fresh-vm.sh
./bootstrap-fresh-vm.sh
```

Piped installs (`curl | bash`) use the terminal for prompts (`/dev/tty`), so menus still work.

**Ubuntu:** tested on **22.04 / 24.04 LTS**. On 24.04 the default system Python is **not** 3.9 — prefer **Docker**, or let the bootstrap install **Python 3.9** (e.g. via deadsnakes) for bare-metal.

---

## Docker Compose

**Prerequisites:** Docker Engine with **Compose v2** (`docker compose ...`), and a filled **`.env`** in the **same directory** as `docker-compose.yml`.

1. Copy `.env.sample` to `.env` and set at least: `API_ID`, `API_HASH`, `BOT_TOKEN`, `SESSION_STRING`, `CHAT_ID` (see [Configuration](#configuration)).
2. From the repo root:

```bash
chmod +x scripts/deploy-docker.sh
./scripts/deploy-docker.sh
```

Optional: `./scripts/deploy-docker.sh --pull` runs `git pull` before building.

Or directly:

```bash
docker compose up -d --build
```

**Logs:** `docker compose logs -f` — **Stop:** `docker compose down`

**Interactive Docker wizard** (writes `.env`, then optional `docker compose up -d --build`):

```bash
python3.9 setup_docker.py
# or
chmod +x setup_docker.sh && ./setup_docker.sh
```

On Windows use **`setup_docker.bat`** (Docker Desktop + Python for session generation).

**Image details:** `Dockerfile` uses **Python 3.9** (Debian bookworm-slim) plus FFmpeg and git, matching `tgcalls` Linux wheels. See [Python versions](#python-versions-and-tgcalls) below.

**If the container exits with missing `API_ID`:** your **`.env` must sit beside `docker-compose.yml`** on the host, with real values (not placeholders). Compose passes variables into the container; verify with `grep API_ID .env` before deploying.

---

## Bare-metal Linux

Voice libraries (`tgcalls`) ship **manylinux** wheels for **Python 3.6–3.9** only — not for 3.10+ on Linux. Use **Python 3.9**:

```bash
python3.9 -m venv venv
source venv/bin/activate
pip install -U pip wheel
pip install -r requirements.txt
python setup_env.py    # interactive .env
python main.py
```

Do **not** use `py -3.10` on Linux — that command targets the **Windows** launcher; on Linux use `python3.9` or `python` inside the venv.

---

## Windows

- **Python 3.10** (matches `tgcalls` wheels on Windows).
- Install dependencies: **`install_deps.bat`** or `py -3.10 -m pip install -r requirements.txt`
- Configure: **`setup.bat`** or `python setup_env.py`
- Run: **`run.bat`** or `py -3.10 main.py`
- Install **FFmpeg** (e.g. `winget install Gyan.FFmpeg`) so it is on `PATH`.

---

## Configuration

### Required variables

`API_ID`, `API_HASH`, `BOT_TOKEN`, `SESSION_STRING`, `CHAT_ID`

### Common optional variables

`LOG_GROUP`, `AUTH_USERS`, `STREAM_URL`, `MAXIMUM_DURATION`, `REPLY_MESSAGE`, `ADMIN_ONLY`, `HEROKU_API_KEY`, `HEROKU_APP_NAME`

### Optional: voice-chat reconnect timeout

If you see `TimeoutError` during voice chat reconnect, you can raise the wait (seconds):

```text
PYTGCALLS_ASYNCIO_TIMEOUT=45
```

(Default in code is **45**; range clamped between 10 and 300.)

See `.env.sample` for a starting template.

Useful links: [Live stream URLs (Telegra.ph)](https://telegra.ph/Live-Radio-Stream-Links-05-17) · Session string tools (e.g. bots) as noted in upstream docs.

---

## Python versions and tgcalls

The pinned **`tgcalls==2.0.0`** / **`pytgcalls==2.1.0`** pair depends on **prebuilt wheels** from PyPI:

| Platform | Use this Python |
|----------|------------------|
| **Linux** (bare metal) | **3.9** (manylinux wheels up to cp39) |
| **Docker** (this repo) | **3.9** in the image |
| **Windows / macOS** | **3.10** wheels exist for `tgcalls` 2.0.0 |
| **3.11+** | No `tgcalls` 2.0.0 wheels — use Docker on Linux or stay on 3.9/3.10 as above |

---

## Cloud deploy

### Heroku

[![Deploy to Heroku](https://img.shields.io/badge/Deploy%20To%20Heroku-blueviolet?style=for-the-badge&logo=heroku)](https://deploy.safone.tech)

Set Heroku region to **Europe** if you want best stability for Telegram.

### Railway

[![Deploy to Railway](https://img.shields.io/badge/Deploy%20To%20Railway-blueviolet?style=for-the-badge&logo=railway)](https://railway.app/new/template?template=https%3A%2F%2Fgithub.com%2FAsmSafone%2FRadioPlayerV3&envs=API_ID%2CAPI_HASH%2CBOT_TOKEN%2CSESSION_STRING%2CCHAT_ID%2CLOG_GROUP%2CADMINS%2CADMIN_ONLY%2CMAXIMUM_DURATION%2CSTREAM_URL%2CREPLY_MESSAGE)

Start a **voice chat** in the target group/channel before relying on production playback.

---

## Plain Docker (without Compose)

```bash
docker build -t radioplayerv3 .
docker run -d --name radioplayerv3 --restart unless-stopped --env-file .env radioplayerv3
```

---

## Troubleshooting

| Symptom | What to check |
|---------|----------------|
| **`API_ID` empty in container** | `.env` next to `docker-compose.yml`, real values, `docker compose config` / `grep API_ID .env` |
| **`pip` cannot install `tgcalls`** | Wrong Python on Linux — use **3.9** or Docker |
| **Voice chat `TimeoutError`** | Network latency; try `PYTGCALLS_ASYNCIO_TIMEOUT=60` or higher in `.env` |
| **Installer exits at prompts** | Use `curl ... \| bash` from a real terminal; script reads from `/dev/tty` |

---

## License

```text
GNU AGPLv3
Copyright (c) 2021  Asm Safone
```

---

## Credits

- [@AsmSafone](https://github.com/AsmSafone) — original project
- [@delivrance](https://github.com/delivrance) — Pyrogram
- [@MarshalX](https://github.com/MarshalX) — PyTgCalls / tgcalls
- [Contributors](https://github.com/AsmSafone/RadioPlayerV3/graphs/contributors)

---

## OKiU fork — maintenance changelog (summary)

- **Pyrogram 2**, Telegram **layer 158** (`pytgcalls_layer_patch.py`), Windows FFmpeg/path and FIFO fixes, `config.py` / `utils.py` / plugins updates.
- **Docker:** `Dockerfile`, `docker-compose.yml`, `deploy-docker.sh`, `setup_docker.py` / `.sh` / `.bat`.
- **Install:** `install.sh`, `bootstrap-fresh-vm.sh`, interactive `.env` wizards, Compose env interpolation for required keys.
- **Requirements:** pinned `tgcalls` / `pytgcalls`; Python matrix per platform as in [Python versions](#python-versions-and-tgcalls).

For full badge links and upstream repo metrics, see [AsmSafone/RadioPlayerV3](https://github.com/AsmSafone/RadioPlayerV3) on GitHub.
