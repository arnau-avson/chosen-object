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
        """Get total unread messages across all conversations. 1 query."""
        result = (
            self.db.query(func.count(Message.id))
            .join(
                ConversationParticipant,
                and_(
                    ConversationParticipant.conversation_id == Message.conversation_id,
                    ConversationParticipant.user_id == user_id,
                ),
            )
            .filter(
                Message.sender_id != user_id,
                or_(
                    ConversationParticipant.last_read_at.is_(None),
                    Message.created_at > ConversationParticipant.last_read_at,
                ),
            )
            .scalar()
        )
        return result or 0

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

    # ── Batch queries (N+1 elimination) ────────────────────────

    def get_other_participants_batch(
        self, conversation_ids: list[int], user_id: int
    ) -> dict[int, ConversationParticipant]:
        """Get other participants for multiple conversations. 1 query."""
        if not conversation_ids:
            return {}
        rows = (
            self.db.query(ConversationParticipant)
            .filter(
                ConversationParticipant.conversation_id.in_(conversation_ids),
                ConversationParticipant.user_id != user_id,
            )
            .all()
        )
        return {p.conversation_id: p for p in rows}

    def get_users_by_ids(self, user_ids: list[int]) -> dict[int, User]:
        """Load multiple users by ID. 1 query."""
        if not user_ids:
            return {}
        users = (
            self.db.query(User)
            .filter(User.id.in_(user_ids))
            .all()
        )
        return {u.id: u for u in users}

    def get_last_messages_batch(
        self, conversation_ids: list[int]
    ) -> dict[int, Message]:
        """Get last message for multiple conversations. 1 query."""
        if not conversation_ids:
            return {}
        from sqlalchemy import desc
        # Subquery to get max message id per conversation
        subq = (
            self.db.query(
                Message.conversation_id,
                func.max(Message.id).label("max_id"),
            )
            .filter(Message.conversation_id.in_(conversation_ids))
            .group_by(Message.conversation_id)
            .subquery()
        )
        rows = (
            self.db.query(Message)
            .join(subq, Message.id == subq.c.max_id)
            .all()
        )
        return {m.conversation_id: m for m in rows}

    def get_unread_counts_batch(
        self, conversation_ids: list[int], user_id: int
    ) -> dict[int, int]:
        """Get unread counts for multiple conversations. 1 query."""
        if not conversation_ids:
            return {}

        counts: dict[int, int] = {cid: 0 for cid in conversation_ids}

        # Single query: join messages with participant last_read_at
        rows = (
            self.db.query(
                Message.conversation_id,
                func.count(Message.id),
            )
            .join(
                ConversationParticipant,
                and_(
                    ConversationParticipant.conversation_id == Message.conversation_id,
                    ConversationParticipant.user_id == user_id,
                ),
            )
            .filter(
                Message.conversation_id.in_(conversation_ids),
                Message.sender_id != user_id,
                or_(
                    ConversationParticipant.last_read_at.is_(None),
                    Message.created_at > ConversationParticipant.last_read_at,
                ),
            )
            .group_by(Message.conversation_id)
            .all()
        )
        for conv_id, cnt in rows:
            counts[conv_id] = cnt

        return counts
