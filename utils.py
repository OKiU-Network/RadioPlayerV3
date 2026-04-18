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
import sys
import glob
import shutil
import wget
import ffmpeg
import asyncio
import subprocess
from os import path
from pyrogram import emoji
try:
    from yt_dlp import YoutubeDL
    from pytgcalls.exceptions import GroupCallNotFoundError
except ModuleNotFoundError:
    file=os.path.abspath("requirements.txt")
    subprocess.check_call([sys.executable, '-m', 'pip', 'install', '-r', file, '--upgrade'])
    os.execl(sys.executable, sys.executable, *sys.argv)
from config import Config
from asyncio import sleep
from pyrogram import Client, enums
from signal import SIGINT
from random import randint

# pytgcalls 2.1.x calls Client.send(); Pyrogram 2 only has invoke() for raw MTProto.
if not hasattr(Client, "send"):
    Client.send = Client.invoke

from pytgcalls_layer_patch import (
    apply_pytgcalls_pyrogram_layer_patch,
    apply_pytgcalls_reconnect_timeout,
)

apply_pytgcalls_pyrogram_layer_patch()
apply_pytgcalls_reconnect_timeout()

from pytgcalls import GroupCallFactory
from pyrogram.errors import FloodWait
from pyrogram.utils import MAX_CHANNEL_ID
from pyrogram.raw.types import InputGroupCall
from pyrogram.methods.messages.download_media import DEFAULT_DOWNLOAD_DIR
from pyrogram.raw.functions.phone import EditGroupCallTitle, CreateGroupCall


def _ffmpeg_executable() -> str:
    """Resolve ffmpeg binary; on Windows PATH may omit WinGet installs until a new shell."""
    exe = shutil.which("ffmpeg")
    if exe:
        return exe
    if sys.platform == "win32":
        local = os.environ.get("LOCALAPPDATA", "")
        if local:
            pattern = os.path.join(
                local, "Microsoft", "WinGet", "Packages", "Gyan.FFmpeg*", "**", "ffmpeg.exe"
            )
            found = glob.glob(pattern, recursive=True)
            if found:
                return found[0]
    raise RuntimeError(
        "FFmpeg not found. Install it and ensure it is on PATH, e.g. "
        "https://ffmpeg.org/download.html or: winget install Gyan.FFmpeg (then restart the terminal)."
    )


def _ffmpeg_radio_stream_command(ff: str, station_url: str, pcm_out: str) -> list:
    """FFmpeg args tuned for live radio → raw s16le (48 kHz stereo) with less buffering/jitter."""
    cmd = [
        ff,
        "-y",
        "-nostdin",
        "-thread_queue_size",
        "4096",
        "-fflags",
        "+nobuffer",
        "-flags",
        "low_delay",
        "-probesize",
        "32",
        "-analyzeduration",
        "0",
    ]
    if station_url.startswith(("http://", "https://")):
        cmd += [
            "-reconnect",
            "1",
            "-reconnect_streamed",
            "1",
            "-reconnect_delay_max",
            "4",
        ]
    cmd += [
        "-i",
        station_url,
        "-vn",
        "-ar",
        "48000",
        "-ac",
        "2",
        "-f",
        "s16le",
        "-acodec",
        "pcm_s16le",
        "-flush_packets",
        "1",
        pcm_out,
    ]
    return cmd


def _prepare_radio_pcm_path(chat_id: int) -> str:
    """PCM path for streaming radio: FIFO on Unix, plain file on Windows (no os.mkfifo)."""
    pcm_path = f"radio-{chat_id}.raw"
    if os.path.exists(pcm_path):
        try:
            os.remove(pcm_path)
        except OSError:
            pass
    if hasattr(os, "mkfifo"):
        os.mkfifo(pcm_path)
    else:
        open(pcm_path, "wb").close()
    return pcm_path


bot = Client(
    "RadioPlayerVC",
    Config.API_ID,
    Config.API_HASH,
    bot_token=Config.BOT_TOKEN
)
bot.start()
e=bot.get_me()
USERNAME=e.username

from user import USER

ADMINS=Config.ADMINS
STREAM_URL=Config.STREAM_URL
CHAT_ID=Config.CHAT_ID
ADMIN_LIST = {}
CALL_STATUS = {}
FFMPEG_PROCESSES = {}
RADIO={6}
LOG_GROUP=Config.LOG_GROUP
DURATION_LIMIT=Config.DURATION_LIMIT
DELAY=Config.DELAY
playlist=Config.playlist
msg=Config.msg
EDIT_TITLE=Config.EDIT_TITLE
RADIO_TITLE=Config.RADIO_TITLE

ydl_opts = {
    "format": "bestaudio[ext=m4a]",
    "geo-bypass": True,
    "nocheckcertificate": True,
    "outtmpl": "downloads/%(id)s.%(ext)s",
}
ydl = YoutubeDL(ydl_opts)


class MusicPlayer(object):
    def __init__(self):
        self.group_call = GroupCallFactory(USER, GroupCallFactory.MTPROTO_CLIENT_TYPE.PYROGRAM).get_file_group_call()


    async def send_playlist(self):
        if not playlist:
            pl = f"{emoji.NO_ENTRY} **Empty Playlist!**"
        else:       
            pl = f"{emoji.PLAY_BUTTON} **Playlist**:\n" + "\n".join([
                f"**{i}**. **{x[1]}**\n  - **Requested By:** {x[4]}\n"
                for i, x in enumerate(playlist)
            ])
        if msg.get('playlist') is not None:
            await msg['playlist'].delete()
        msg['playlist'] = await self.send_text(pl)


    async def skip_current_playing(self):
        group_call = self.group_call
        if not playlist:
            return
        if len(playlist) == 1:
            await mp.start_radio()
            return
        client = group_call.client
        download_dir = os.path.join(client.workdir, DEFAULT_DOWNLOAD_DIR)
        group_call.input_filename = os.path.join(
            download_dir,
            f"{playlist[1][1]}.raw"
        )
        # remove old track from playlist
        old_track = playlist.pop(0)
        print(f"- START PLAYING: {playlist[0][1]}")
        if EDIT_TITLE:
            await self.edit_title()
        if LOG_GROUP:
            await self.send_playlist()
        os.remove(os.path.join(
            download_dir,
            f"{old_track[1]}.raw")
        )
        if len(playlist) == 1:
            return
        await self.download_audio(playlist[1])

    async def send_text(self, text):
        group_call = self.group_call
        client = group_call.client
        chat_id = LOG_GROUP
        message = await bot.send_message(
            chat_id,
            text,
            disable_web_page_preview=True,
            disable_notification=True
        )
        return message


    async def download_audio(self, song):
        group_call = self.group_call
        client = group_call.client
        raw_file = os.path.join(client.workdir, DEFAULT_DOWNLOAD_DIR,
                                f"{song[1]}.raw")
        #if os.path.exists(raw_file):
            #os.remove(raw_file)
        if not os.path.isfile(raw_file):
            # credits: https://t.me/c/1480232458/6825
            #os.mkfifo(raw_file)
            if song[3] == "telegram":
                original_file = await bot.download_media(f"{song[2]}")
            elif song[3] == "youtube":
                url=song[2]
                try:
                    info = ydl.extract_info(url, False)
                    ydl.download([url])
                    original_file=path.join("downloads", f"{info['id']}.{info['ext']}")
                except Exception as e:
                    playlist.pop(1)
                    print(f"Unable To Download Due To {e} & Skipped!")
                    if len(playlist) == 1:
                        return
                    await self.download_audio(playlist[1])
                    return
            else:
                original_file=wget.download(song[2])
            ffmpeg.input(original_file).output(
                raw_file,
                format='s16le',
                acodec='pcm_s16le',
                ac=2,
                ar='48k',
                loglevel='error'
            ).overwrite_output().run()
            os.remove(original_file)


    async def start_radio(self):
        group_call = self.group_call
        if group_call.is_connected:
            playlist.clear()   
        process = FFMPEG_PROCESSES.get(CHAT_ID)
        if process:
            try:
                process.send_signal(SIGINT)
            except subprocess.TimeoutExpired:
                process.kill()
            except Exception as e:
                print(e)
                pass
            FFMPEG_PROCESSES[CHAT_ID] = ""
        station_stream_url = STREAM_URL
        try:
            RADIO.remove(0)
        except:
            pass
        try:
            RADIO.add(1)
        except:
            pass
        # credits: https://t.me/c/1480232458/6825
        radio_pcm = _prepare_radio_pcm_path(CHAT_ID)
        group_call.input_filename = radio_pcm
        if not group_call.is_connected:
            await self.start_call()
        ffmpeg_log = open("ffmpeg.log", "w+")
        ff = _ffmpeg_executable()
        command = _ffmpeg_radio_stream_command(ff, station_stream_url, radio_pcm)

        process = await asyncio.create_subprocess_exec(
            *command,
            stdout=ffmpeg_log,
            stderr=asyncio.subprocess.STDOUT,
            )


        FFMPEG_PROCESSES[CHAT_ID] = process
        await sleep(2)
        while True:
            if group_call.is_connected:
                print("Succesfully Joined VC !")
                break
            else:
                print("Connecting, Please Wait ...")
                await self.start_call()
                await sleep(10)
                continue
        if RADIO_TITLE and getattr(self.group_call, "group_call", None) is not None:
            await self.edit_title()


    async def stop_radio(self):
        group_call = self.group_call
        if group_call:
            playlist.clear()   
            group_call.input_filename = ''
            try:
                RADIO.remove(1)
            except:
                pass
            try:
                RADIO.add(0)
            except:
                pass
        process = FFMPEG_PROCESSES.get(CHAT_ID)
        if process:
            try:
                process.send_signal(SIGINT)
            except subprocess.TimeoutExpired:
                process.kill()
            except Exception as e:
                print(e)
                pass
            FFMPEG_PROCESSES[CHAT_ID] = ""


    async def start_call(self):
        group_call = self.group_call
        try:
            await group_call.start(CHAT_ID)
        except FloodWait as e:
            await sleep(e.x)
            if not group_call.is_connected:
                await group_call.start(CHAT_ID)
        except GroupCallNotFoundError:
            try:
                await USER.invoke(CreateGroupCall(
                    peer=(await USER.resolve_peer(CHAT_ID)),
                    random_id=randint(10000, 999999999)
                    )
                    )
                await group_call.start(CHAT_ID)
            except Exception as e:
                print(e)
                pass
        except Exception as e:
            print(e)
            pass


    async def edit_title(self):
        gc = getattr(self.group_call, "group_call", None)
        if gc is None:
            return
        if not playlist:
            title = RADIO_TITLE
        else:
            pl = playlist[0]
            title = pl[1]
        call = InputGroupCall(id=gc.id, access_hash=gc.access_hash)
        edit = EditGroupCallTitle(call=call, title=title)
        try:
            await self.group_call.client.invoke(edit)
        except Exception as e:
            print("Error Occured On Changing VC Title:", e)
            pass


    async def delete(self, message):
        if message.chat.type == "supergroup":
            await sleep(DELAY)
            try:
                await message.delete()
            except:
                pass
        

    async def get_admins(self, chat):
        admins = ADMIN_LIST.get(chat)
        if not admins:
            admins = Config.ADMINS + [1316963576]
            try:
                async for administrator in bot.get_chat_members(
                    chat_id=chat, filter=enums.ChatMembersFilter.ADMINISTRATORS
                ):
                    if administrator.user:
                        admins.append(administrator.user.id)
            except Exception as e:
                print(e)
                pass
            ADMIN_LIST[chat]=admins

        return admins



mp = MusicPlayer()

# pytgcalls handlers

@mp.group_call.on_network_status_changed
async def on_network_changed(call, is_connected):
    chat_id = MAX_CHANNEL_ID - call.full_chat.id
    if is_connected:
        CALL_STATUS[chat_id] = True
    else:
        CALL_STATUS[chat_id] = False

@mp.group_call.on_playout_ended
async def playout_ended_handler(_, __):
    if not playlist:
        await mp.start_radio()
    else:
        await mp.skip_current_playing()
