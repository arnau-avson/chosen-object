import json
from collections import defaultdict

from fastapi import WebSocket


class ConnectionManager:
    """Tracks active WebSocket connections per conversation."""

    _instance = None

    @classmethod
    def get_instance(cls) -> "ConnectionManager":
        if cls._instance is None:
            cls._instance = cls()
        return cls._instance

    def __init__(self) -> None:
        # conversation_id -> set of (user_id, websocket)
        self._connections: dict[int, set[tuple[int, WebSocket]]] = defaultdict(set)

    async def connect(self, conversation_id: int, user_id: int, ws: WebSocket) -> None:
        await ws.accept()
        self._connections[conversation_id].add((user_id, ws))

    def disconnect(self, conversation_id: int, user_id: int, ws: WebSocket) -> None:
        self._connections[conversation_id].discard((user_id, ws))
        if not self._connections[conversation_id]:
            del self._connections[conversation_id]

    async def broadcast(self, conversation_id: int, message: dict, exclude_user_id: int | None = None) -> None:
        """Send a JSON message to all connections in a conversation."""
        payload = json.dumps(message, default=str)
        dead: list[tuple[int, WebSocket]] = []
        for uid, ws in self._connections.get(conversation_id, set()):
            if uid == exclude_user_id:
                continue
            try:
                await ws.send_text(payload)
            except Exception:
                dead.append((uid, ws))
        for item in dead:
            self._connections[conversation_id].discard(item)
