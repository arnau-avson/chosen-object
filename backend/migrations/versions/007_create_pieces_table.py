"""create pieces and piece_images tables

Revision ID: 007
Revises: 006
Create Date: 2026-06-07
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "007"
down_revision: Union[str, None] = "006"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "pieces",
        sa.Column("id", sa.Integer, primary_key=True, autoincrement=True),
        sa.Column(
            "user_id",
            sa.Integer,
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
            index=True,
        ),
        sa.Column("title", sa.String(200), nullable=False),
        sa.Column("discipline", sa.String(50), nullable=True),
        sa.Column("year", sa.String(10), nullable=True),
        sa.Column("edition", sa.String(50), nullable=True),
        sa.Column("price_cents", sa.Integer, nullable=False),
        sa.Column("old_price_cents", sa.Integer, nullable=True),
        sa.Column("cost_price_cents", sa.Integer, nullable=True),
        sa.Column(
            "rental",
            sa.Boolean,
            nullable=False,
            server_default=sa.text("FALSE"),
        ),
        sa.Column(
            "stock",
            sa.Integer,
            nullable=False,
            server_default=sa.text("1"),
        ),
        sa.Column("ships_to", sa.Text, nullable=True),
        sa.Column("packaging", sa.String(50), nullable=True),
        sa.Column(
            "status",
            sa.String(20),
            nullable=False,
            server_default="active",
        ),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
            onupdate=sa.func.now(),
        ),
    )

    op.create_table(
        "piece_images",
        sa.Column("id", sa.Integer, primary_key=True, autoincrement=True),
        sa.Column(
            "piece_id",
            sa.Integer,
            sa.ForeignKey("pieces.id", ondelete="CASCADE"),
            nullable=False,
            index=True,
        ),
        sa.Column(
            "position",
            sa.Integer,
            nullable=False,
            server_default=sa.text("0"),
        ),
        sa.Column("image_data", sa.LargeBinary(length=2**24 - 1), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
    )


def downgrade() -> None:
    op.drop_table("piece_images")
    op.drop_table("pieces")
