import base64

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from ..models.user import User
from ..repositories.message_repository import MessageRepository
from ..repositories.settings_repository import SettingsRepository
from ..schemas.message import (
    ConversationOut,
    ConversationStartIn,
    MessageOut,
    ReactionIn,
    SendMessageIn,
)
from .notification_helper import notify


class MessageService:
    def __init__(self, db: Session) -> None:
        self.db = db
        self.repo = MessageRepository(db)

    def start_conversation(
        self, user: User, data: ConversationStartIn
    ) -> ConversationOut:
        if data.user_id == user.id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Cannot start conversation with yourself.",
            )

        other = self.repo.get_user_by_id(data.user_id)
        if other is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found.",
            )

        # Check if conversation already exists
        existing = self.repo.find_conversation_between(user.id, data.user_id)
        if existing:
            # If message provided, send it
            if data.text:
                self.repo.create_message(existing.id, user.id, data.text)
                self.repo.update_conversation_timestamp(existing)
                self.repo.commit()
            return self._build_conversation_out(existing, user)

        # Create new conversation
        conv = self.repo.create_conversation()
        self.repo.add_participant(conv.id, user.id, is_request=False, request_accepted=True)
        self.repo.add_participant(conv.id, data.user_id, is_request=True, request_accepted=False)

        if data.text:
            self.repo.create_message(conv.id, user.id, data.text)

        self.repo.commit()

        # Notify the other user (gated by messages setting)
        settings_repo = SettingsRepository(self.db)
        other_settings = settings_repo.get_by_user(data.user_id)
        if not other_settings or other_settings.messages:
            notify(
                self.db,
                user_id=data.user_id,
                type="message",
                title="New message request",
                body=f"{user.username} sent you a message.",
                reference_id=conv.id,
                reference_type="conversation",
            )

        return self._build_conversation_out(conv, user)

    def list_conversations(
        self, user: User, requests: bool = False, offset: int = 0, limit: int = 20
    ) -> list[ConversationOut]:
        results = self.repo.get_conversations(user.id, requests, offset, limit)
        outputs = []
        for conv, _ in results:
            outputs.append(self._build_conversation_out(conv, user))
        return outputs

    def get_messages(
        self, user: User, conversation_id: int, offset: int = 0, limit: int = 50
    ) -> list[MessageOut]:
        conv = self.repo.get_conversation_by_id(conversation_id)
        if conv is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Conversation not found.",
            )

        participant = self.repo.get_participant(conversation_id, user.id)
        if participant is None:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not a participant.",
            )

        messages = self.repo.get_messages(conversation_id, offset, limit)
        return [self._message_to_out(m) for m in messages]

    def send_message(
        self, user: User, conversation_id: int, data: SendMessageIn
    ) -> MessageOut:
        conv = self.repo.get_conversation_by_id(conversation_id)
        if conv is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Conversation not found.",
            )

        participant = self.repo.get_participant(conversation_id, user.id)
        if participant is None:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not a participant.",
            )

        msg = self.repo.create_message(
            conversation_id, user.id, data.text, data.reply_to_id
        )
        self.repo.update_conversation_timestamp(conv)
        self.repo.commit()

        # Notify other participant (gated by messages setting)
        other = self.repo.get_other_participant(conversation_id, user.id)
        if other:
            settings_repo = SettingsRepository(self.db)
            other_settings = settings_repo.get_by_user(other.user_id)
            if not other_settings or other_settings.messages:
                notify(
                    self.db,
                    user_id=other.user_id,
                    type="message",
                    title="New message",
                    body=f"{user.username}: {data.text[:50]}",
                    reference_id=conversation_id,
                    reference_type="conversation",
                )

        return self._message_to_out(msg)

    def mark_read(self, user: User, conversation_id: int) -> dict:
        participant = self.repo.get_participant(conversation_id, user.id)
        if participant is None:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not a participant.",
            )
        self.repo.mark_read(conversation_id, user.id)
        return {"read": True}

    def accept_request(self, user: User, conversation_id: int) -> dict:
        participant = self.repo.get_participant(conversation_id, user.id)
        if participant is None:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not a participant.",
            )
        self.repo.accept_request(conversation_id, user.id)
        return {"accepted": True}

    def decline_conversation(self, user: User, conversation_id: int) -> dict:
        conv = self.repo.get_conversation_by_id(conversation_id)
        if conv is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Conversation not found.",
            )

        participant = self.repo.get_participant(conversation_id, user.id)
        if participant is None:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not a participant.",
            )

        self.repo.delete_conversation(conv)
        return {"deleted": True}

    def set_reaction(
        self, user: User, message_id: int, data: ReactionIn
    ) -> MessageOut:
        msg = self.repo.get_message_by_id(message_id)
        if msg is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Message not found.",
            )

        # Verify user is in the conversation
        participant = self.repo.get_participant(msg.conversation_id, user.id)
        if participant is None:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not a participant.",
            )

        msg = self.repo.update_message_reaction(msg, data.reaction)
        return self._message_to_out(msg)

    def get_unread_count(self, user: User) -> dict:
        count = self.repo.get_total_unread_count(user.id)
        return {"unread_count": count}

    def _build_conversation_out(
        self, conv, current_user: User
    ) -> ConversationOut:
        other_participant = self.repo.get_other_participant(conv.id, current_user.id)
        other_user = None
        if other_participant:
            other_user = self.repo.get_user_by_id(other_participant.user_id)

        last_msg = self.repo.get_last_message(conv.id)
        unread = self.repo.get_unread_count(conv.id, current_user.id)

        my_participant = self.repo.get_participant(conv.id, current_user.id)

        avatar_b64 = None
        if other_user and other_user.avatar_image:
            avatar_b64 = base64.b64encode(other_user.avatar_image).decode("ascii")

        return ConversationOut(
            id=conv.id,
            other_user_id=other_user.id if other_user else 0,
            other_username=other_user.username if other_user else None,
            other_avatar_type=other_user.avatar_type if other_user else "color",
            other_avatar_color=other_user.avatar_color if other_user else "#2E2520",
            other_avatar_image_b64=avatar_b64,
            last_message=last_msg.text if last_msg else None,
            last_message_at=last_msg.created_at if last_msg else None,
            unread_count=unread,
            is_request=my_participant.is_request if my_participant else False,
            request_accepted=my_participant.request_accepted if my_participant else False,
            updated_at=conv.updated_at,
        )

    def _message_to_out(self, msg) -> MessageOut:
        sender = self.repo.get_user_by_id(msg.sender_id)
        return MessageOut(
            id=msg.id,
            conversation_id=msg.conversation_id,
            sender_id=msg.sender_id,
            sender_username=sender.username if sender else None,
            text=msg.text,
            reply_to_id=msg.reply_to_id,
            reaction=msg.reaction,
            created_at=msg.created_at,
        )
