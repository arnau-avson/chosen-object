import json

from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from jose import JWTError

from app.core.security import decode_token
from app.db.session import SessionLocal
from app.repositories.message_repository import MessageRepository
from app.repositories.user_repository import UserRepository
from app.services.message_service import MessageService
from app.services.websocket_manager import ConnectionManager

router = APIRouter(tags=["websocket"])


def _authenticate_token(token: str) -> int | None:
    """Validate JWT and return user_id, or None."""
    try:
        payload = decode_token(token)
        user_id = payload.get("sub")
        if user_id is None:
            return None
        return int(user_id)
    except (JWTError, ValueError):
        return None


@router.websocket("/ws/{conversation_id}")
async def websocket_chat(ws: WebSocket, conversation_id: int, token: str = ""):
    # Authenticate
    user_id = _authenticate_token(token)
    if user_id is None:
        await ws.close(code=4001, reason="Unauthorized")
        return

    # Verify user exists and is active, and is a participant
    db = SessionLocal()
    try:
        user_repo = UserRepository(db)
        user = user_repo.get_by_id(user_id)
        if user is None or not user.is_active:
            await ws.close(code=4001, reason="Unauthorized")
            return

        msg_repo = MessageRepository(db)
        participant = msg_repo.get_participant(conversation_id, user_id)
        if participant is None:
            await ws.close(code=4003, reason="Not a participant")
            return
    finally:
        db.close()

    # Connect
    manager = ConnectionManager.get_instance()
    await manager.connect(conversation_id, user_id, ws)

    try:
        while True:
            raw = await ws.receive_text()
            try:
                data = json.loads(raw)
            except json.JSONDecodeError:
                continue

            msg_type = data.get("type", "message")

            if msg_type == "message":
                text = data.get("text", "").strip()
                if not text:
                    continue
                reply_to_id = data.get("reply_to_id")

                # Create message in DB
                db = SessionLocal()
                try:
                    msg_repo = MessageRepository(db)
                    user_repo = UserRepository(db)
                    user = user_repo.get_by_id(user_id)

                    conv = msg_repo.get_conversation_by_id(conversation_id)
                    if conv is None:
                        continue

                    msg = msg_repo.create_message(
                        conversation_id, user_id, text, reply_to_id
                    )
                    msg_repo.update_conversation_timestamp(conv)
                    msg_repo.commit()

                    # Build response payload
                    payload = {
                        "type": "message",
                        "data": {
                            "id": msg.id,
                            "conversation_id": msg.conversation_id,
                            "sender_id": msg.sender_id,
                            "sender_username": user.username if user else None,
                            "text": msg.text,
                            "reply_to_id": msg.reply_to_id,
                            "reaction": msg.reaction,
                            "created_at": msg.created_at.isoformat(),
                        },
                    }

                    # Broadcast to all participants (including sender for confirmation)
                    await manager.broadcast(conversation_id, payload)
                finally:
                    db.close()

            elif msg_type == "reaction":
                message_id = data.get("message_id")
                reaction = data.get("reaction")
                if message_id is None:
                    continue

                db = SessionLocal()
                try:
                    msg_repo = MessageRepository(db)
                    msg = msg_repo.get_message_by_id(message_id)
                    if msg is None or msg.conversation_id != conversation_id:
                        continue
                    msg = msg_repo.update_message_reaction(msg, reaction)

                    payload = {
                        "type": "reaction",
                        "data": {
                            "message_id": msg.id,
                            "reaction": msg.reaction,
                        },
                    }
                    await manager.broadcast(conversation_id, payload)
                finally:
                    db.close()

            elif msg_type == "read":
                db = SessionLocal()
                try:
                    msg_repo = MessageRepository(db)
                    msg_repo.mark_read(conversation_id, user_id)

                    payload = {
                        "type": "read",
                        "data": {"user_id": user_id},
                    }
                    await manager.broadcast(
                        conversation_id, payload, exclude_user_id=user_id
                    )
                finally:
                    db.close()

    except WebSocketDisconnect:
        manager.disconnect(conversation_id, user_id, ws)
    except Exception:
        manager.disconnect(conversation_id, user_id, ws)
