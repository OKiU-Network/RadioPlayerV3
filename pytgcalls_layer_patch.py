"""
Pyrogram 2.x / Telegram layer 158: GroupCall no longer has .params; WebRTC JSON is sent
via UpdateGroupCallConnection. pytgcalls 2.1.x only reads update.call.params — patch handlers.
"""
from pyrogram import ContinuePropagation
from pyrogram.raw import types
from pyrogram.raw.types import GroupCallDiscarded as PyrogramGroupCallDiscarded

from pytgcalls.mtproto.data import GroupCallDiscardedWrapper, GroupCallWrapper
from pytgcalls.mtproto.data.update import UpdateGroupCallWrapper


def apply_pytgcalls_pyrogram_layer_patch() -> None:
    from pytgcalls.mtproto import pyrogram_bridge as pb

    async def _process_update_patched(self, _, update, users, chats):
        if isinstance(update, types.UpdateGroupCallConnection):
            if not self.group_call:
                raise ContinuePropagation
            call = GroupCallWrapper(self.group_call.id, update.params)
            wrapped = UpdateGroupCallWrapper(0, call)
            await self.group_call_update_callback(wrapped)
            return

        if type(update) not in self._update_to_handler.keys():
            raise ContinuePropagation

        if not self.group_call or not update.call or update.call.id != self.group_call.id:
            raise ContinuePropagation
        self.group_call = update.call

        await self._update_to_handler[type(update)](update)

    async def _process_group_call_update_patched(self, update):
        if isinstance(update.call, PyrogramGroupCallDiscarded):
            call = GroupCallDiscardedWrapper()
        else:
            params = getattr(update.call, "params", None)
            call = GroupCallWrapper(update.call.id, params)

        wrapped_update = UpdateGroupCallWrapper(update.chat_id, call)
        await self.group_call_update_callback(wrapped_update)

    # RawUpdateHandler passes (client, update, users, chats) — first arg is client
    pb.PyrogramBridge._process_update = _process_update_patched
    pb.PyrogramBridge._process_group_call_update = _process_group_call_update_patched
