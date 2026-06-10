"""add notification category settings

Revision ID: 018
Revises: 017
Create Date: 2026-06-10
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "018"
down_revision: Union[str, None] = "017"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "user_settings",
        sa.Column("new_pieces", sa.Boolean, nullable=False, server_default=sa.text("TRUE")),
    )
    op.add_column(
        "user_settings",
        sa.Column("piece_updates", sa.Boolean, nullable=False, server_default=sa.text("TRUE")),
    )
    op.add_column(
        "user_settings",
        sa.Column("messages", sa.Boolean, nullable=False, server_default=sa.text("TRUE")),
    )
    op.add_column(
        "user_settings",
        sa.Column("rental_requests", sa.Boolean, nullable=False, server_default=sa.text("TRUE")),
    )
    op.add_column(
        "user_settings",
        sa.Column("rental_status_changes", sa.Boolean, nullable=False, server_default=sa.text("TRUE")),
    )


def downgrade() -> None:
    op.drop_column("user_settings", "rental_status_changes")
    op.drop_column("user_settings", "rental_requests")
    op.drop_column("user_settings", "messages")
    op.drop_column("user_settings", "piece_updates")
    op.drop_column("user_settings", "new_pieces")
