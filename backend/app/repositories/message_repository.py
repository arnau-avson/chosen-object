from datetime import datetime, timezone

from sqlalchemy import and_, func, or_
from sqlalchemy.orm import Session

from ..models.message import Conversation, ConversationParticipant, Message
from ..models.user import User


class MessageRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def find_conversation_between(
        self, user1_id: int, user2_id: int
    ) -> Conversation | None:
        """Find an existing conversation between two users."""
        conv = (
            self.db.query(Conversation)
            .join(
                ConversationParticipant,
                ConversationParticipant.conversation_id == Conversation.id,
            )
            .filter(ConversationParticipant.user_id == user1_id)
            .all()
        )
        for c in conv:
            participants = (
                self.db.query(ConversationParticipant)
                .filter(ConversationParticipant.conversation_id == c.id)
                .all()
            )
            user_ids = {p.user_id for p in participants}
            if user2_id in user_ids:
                return c
        return None

    def create_conversation(self) -> Conversation:
        conv = Conversation()
        self.db.add(conv)
        self.db.flush()
        return conv

    def add_participant(
        self,
        conversation_id: int,
        user_id: int,
        is_request: bool = False,
        request_accepted: bool = False,
    ) -> ConversationParticipant:
        p = ConversationParticipant(
            conversation_id=conversation_id,
            user_id=user_id,
            is_request=is_request,
            request_accepted=request_accepted,
        )
        self.db.add(p)
        self.db.flush()
        return p

    def create_message(
        self,
        conversation_id: int,
        sender_id: int,
        text: str,
        reply_to_id: int | None = None,
    ) -> Message:
        msg = Message(
            conversation_id=conversation_id,
            sender_id=sender_id,
            text=text,
            reply_to_id=reply_to_id,
        )
        self.db.add(msg)
        self.db.flush()
        return msg

    def commit(self) -> None:
        self.db.commit()

    def get_conversations(
        self, user_id: int, requests: bool = False, offset: int = 0, limit: int = 20
    ) -> list[tuple[Conversation, ConversationParticipant]]:
        """Get conversations for a user, filtering by request status."""
        q = (
            self.db.query(Conversation, ConversationParticipant)
            .join(
                ConversationParticipant,
                ConversationParticipant.conversation_id == Conversation.id,
            )
            .filter(ConversationParticipant.user_id == user_id)
        )

        if requests:
            q = q.filter(
                ConversationParticipant.is_request == True,
                ConversationParticipant.request_accepted == False,
            )
        else:
            q = q.filter(
                or_(
                    ConversationParticipant.is_request == False,
                    ConversationParticipant.request_accepted == True,
                )
            )

        return (
            q.order_by(Conversation.updated_at.desc())
            .offset(offset)
            .limit(limit)
            .all()
        )

    def get_conversation_by_id(self, conversation_id: int) -> Conversation | None:
        return (
            self.db.query(Conversation)
            .filter(Conversation.id == conversation_id)
            .first()
        )

    def get_participant(
        self, conversation_id: int, user_id: int
    ) -> ConversationParticipant | None:
        return (
            self.db.query(ConversationParticipant)
            .filter(
                ConversationParticipant.conversation_id == conversation_id,
                ConversationParticipant.user_id == user_id,
            )
            .first()
        )

    def get_other_participant(
        self, conversation_id: int, user_id: int
    ) -> ConversationParticipant | None:
        return (
            self.db.query(ConversationParticipant)
            .filter(
                ConversationParticipant.conversation_id == conversation_id,
                ConversationParticipant.user_id != user_id,
            )
            .first()
        )

    def get_messages(
        self, conversation_id: int, offset: int = 0, limit: int = 50
    ) -> list[Message]:
        return (
            self.db.query(Message)
            .filter(Message.conversation_id == conversation_id)
            .order_by(Message.created_at.desc())
            .offset(offset)
            .limit(limit)
            .all()
        )

    def get_last_message(self, conversation_id: int) -> Message | None:
        return (
            self.db.query(Message)
            .filter(Message.conversation_id == conversation_id)
            .order_by(Message.created_at.desc())
            .first()
        )

    def get_unread_count(self, conversation_id: int, user_id: int) -> int:
        participant = self.get_participant(conversation_id, user_id)
        if participant is None or participant.last_read_at is None:
            return (
                self.db.query(func.count(Message.id))
                .filter(
                    Message.conversation_id == conversation_id,
                    Message.sender_id != user_id,
                )
                .scalar()
                or 0
            )
        return (
            self.db.query(func.count(Message.id))
            .filter(
                Message.conversation_id == conversation_id,
                Message.sender_id != user_id,
                Message.created_at > participant.last_read_at,
            )
            .scalar()
            or 0
        )

    def get_total_unread_count(self, user_id: int) -> int:
        """Get total unread messages across all conversations."""
        participants = (
            self.db.query(ConversationParticipant)
            .filter(ConversationParticipant.user_id == user_id)
            .all()
        )
        total = 0
        for p in participants:
            total += self.get_unread_count(p.conversation_id, user_id)
        return total

    def mark_read(self, conversation_id: int, user_id: int) -> None:
        participant = self.get_participant(conversation_id, user_id)
        if participant:
            participant.last_read_at = datetime.now(timezone.utc)
            self.db.commit()

    def accept_request(self, conversation_id: int, user_id: int) -> None:
        participant = self.get_participant(conversation_id, user_id)
        if participant:
            participant.request_accepted = True
            self.db.commit()

    def delete_conversation(self, conversation: Conversation) -> None:
        self.db.delete(conversation)
        self.db.commit()

    def get_message_by_id(self, message_id: int) -> Message | None:
        return self.db.query(Message).filter(Message.id == message_id).first()

    def update_message_reaction(
        self, message: Message, reaction: str | None
    ) -> Message:
        message.reaction = reaction
        self.db.commit()
        self.db.refresh(message)
        return message

    def get_user_by_id(self, user_id: int) -> User | None:
        return self.db.query(User).filter(User.id == user_id).first()

    def update_conversation_timestamp(self, conversation: Conversation) -> None:
        conversation.updated_at = datetime.now(timezone.utc)
        self.db.flush()
