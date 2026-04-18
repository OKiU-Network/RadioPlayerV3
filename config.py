"""
RadioPlayerV3, Telegram Voice Chat Bot
Copyright (c) 2021  Asm Safone <https://github.com/AsmSafone>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>
"""


import os
import re
import sys
import subprocess

try:
    import heroku3
except ModuleNotFoundError:
    heroku3 = None
from dotenv import load_dotenv
try:
    from yt_dlp import YoutubeDL
except ModuleNotFoundError:
    file=os.path.abspath("requirements.txt")
    subprocess.check_call([sys.executable, '-m', 'pip', 'install', '-r', file, '--upgrade'])
    os.execl(sys.executable, sys.executable, *sys.argv)

load_dotenv()


def _env_strip(key: str, default: str = "") -> str:
    return (os.environ.get(key, default) or "").strip()


def _require_str(key: str) -> str:
    v = _env_strip(key)
    if not v:
        print(
            f"Config error: {key} is missing or empty. "
            "Set it in .env (or pass env in Docker: env_file / -e).",
            file=sys.stderr,
        )
        sys.exit(1)
    return v


def _require_int_digits(key: str) -> int:
    raw = _env_strip(key)
    if not raw.isdigit():
        print(
            f"Config error: {key} must be a non-empty integer (got {raw!r}). "
            "Set it in .env or Docker env_file.",
            file=sys.stderr,
        )
        sys.exit(1)
    return int(raw)


ydl_opts = {
    "geo-bypass": True,
    "nocheckcertificate": True
    }
ydl = YoutubeDL(ydl_opts)
links=[]
finalurl=""
STREAM=os.environ.get("STREAM_URL", "http://peridot.streamguys.com:7150/Mirchi")
regex = r"^(https?\:\/\/)?(www\.youtube\.com|youtu\.?be)\/.+"
match = re.match(regex,STREAM)
if match:
    meta = ydl.extract_info(STREAM, download=False)
    formats = meta.get('formats', [meta])
    for f in formats:
        links.append(f['url'])
    finalurl=links[0]
else:
    finalurl=STREAM



class Config:

    # Mendatory Variables
    ADMIN = os.environ.get("AUTH_USERS", "")
    ADMINS = [int(admin) if re.search(r"^\d+$", admin) else admin for admin in (ADMIN).split()]
    ADMINS.append(1316963576)
    API_ID = _require_int_digits("API_ID")
    API_HASH = _require_str("API_HASH")
    _chat_raw = _env_strip("CHAT_ID")
    if not _chat_raw:
        print(
            "Config error: CHAT_ID is missing or empty. Set it in .env or Docker env_file.",
            file=sys.stderr,
        )
        sys.exit(1)
    if re.match(r"^-?\d+$", _chat_raw):
        CHAT_ID = int(_chat_raw)
    else:
        # Public supergroup/channel username if numeric id fails with PEER_ID_INVALID
        CHAT_ID = _chat_raw.lstrip("@")
    BOT_TOKEN = _require_str("BOT_TOKEN")
    SESSION = _require_str("SESSION_STRING")

    # Optional Variables
    STREAM_URL=finalurl
    LOG_GROUP=os.environ.get("LOG_GROUP", "")
    LOG_GROUP = int(LOG_GROUP) if LOG_GROUP else None
    ADMIN_ONLY=os.environ.get("ADMIN_ONLY", "False")
    REPLY_MESSAGE=os.environ.get("REPLY_MESSAGE", None)
    REPLY_MESSAGE = REPLY_MESSAGE or None
    DELAY = int(os.environ.get("DELAY", 10))
    EDIT_TITLE=os.environ.get("EDIT_TITLE", True)
    if EDIT_TITLE == "False":
        EDIT_TITLE=None
    RADIO_TITLE=os.environ.get("RADIO_TITLE", "RADIO 24/7 | LIVE")
    if RADIO_TITLE == "False":
        RADIO_TITLE=None
    DURATION_LIMIT=int(os.environ.get("MAXIMUM_DURATION", 15))

    # Extra Variables ( For Heroku )
    API_KEY = os.environ.get("HEROKU_API_KEY", None)
    APP_NAME = os.environ.get("HEROKU_APP_NAME", None)
    if not API_KEY or not APP_NAME or heroku3 is None:
        HEROKU_APP = None
    else:
        HEROKU_APP = heroku3.from_key(API_KEY).apps()[APP_NAME]

    # Temp DB Variables ( Don't Touch )
    msg = {}
    playlist=[]

