from typing import Annotated

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.deps import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.message import (
    ConversationOut,
    ConversationStartIn,
    MessageOut,
    ReactionIn,
    SendMessageIn,
)
from app.services.message_service import MessageService

router = APIRouter(prefix="/messages", tags=["messages"])


@router.post(
    "/conversations",
    response_model=ConversationOut,
    status_code=201,
    summary="Start or get conversation with user",
)
def start_conversation(
    data: ConversationStartIn,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> ConversationOut:
    return MessageService(db).start_conversation(current_user, data)


@router.get(
    "/conversations",
    response_model=list[ConversationOut],
    summary="List conversations",
)
def list_conversations(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
    requests: bool = Query(default=False),
    offset: int = Query(default=0, ge=0),
    limit: int = Query(default=20, ge=1, le=100),
) -> list[ConversationOut]:
    return MessageService(db).list_conversations(
        current_user, requests=requests, offset=offset, limit=limit
    )


@router.get(
    "/conversations/{conversation_id}",
    response_model=list[MessageOut],
    summary="Get messages in conversation",
)
def get_messages(
    conversation_id: int,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
    offset: int = Query(default=0, ge=0),
    limit: int = Query(default=50, ge=1, le=100),
) -> list[MessageOut]:
    return MessageService(db).get_messages(
        current_user, conversation_id, offset, limit
    )


@router.post(
    "/conversations/{conversation_id}",
    response_model=MessageOut,
    status_code=201,
    summary="Send message",
)
def send_message(
    conversation_id: int,
    data: SendMessageIn,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> MessageOut:
    return MessageService(db).send_message(current_user, conversation_id, data)


@router.patch(
    "/conversations/{conversation_id}/read",
    summary="Mark conversation as read",
)
def mark_read(
    conversation_id: int,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> dict:
    return MessageService(db).mark_read(current_user, conversation_id)


@router.patch(
    "/conversations/{conversation_id}/accept",
    summary="Accept message request",
)
def accept_request(
    conversation_id: int,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> dict:
    return MessageService(db).accept_request(current_user, conversation_id)


@router.delete(
    "/conversations/{conversation_id}",
    summary="Decline/delete conversation",
)
def decline_conversation(
    conversation_id: int,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> dict:
    return MessageService(db).decline_conversation(current_user, conversation_id)


@router.patch(
    "/{message_id}/reaction",
    response_model=MessageOut,
    summary="Set reaction on message",
)
def set_reaction(
    message_id: int,
    data: ReactionIn,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> MessageOut:
    return MessageService(db).set_reaction(current_user, message_id, data)


@router.get(
    "/unread-count",
    summary="Get total unread message count",
)
def get_unread_count(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> dict:
    return MessageService(db).get_unread_count(current_user)
