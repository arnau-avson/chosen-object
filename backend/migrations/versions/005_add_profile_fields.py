"""add profile, studio, invoicing and image fields to users

Revision ID: 005
Revises: 004
Create Date: 2026-06-07
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "005"
down_revision: Union[str, None] = "004"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # ── Studio info ──────────────────────────────────────────
    op.add_column("users", sa.Column("handle", sa.String(50), nullable=True, unique=True))
    op.add_column("users", sa.Column("studio_name", sa.String(100), nullable=True))
    op.add_column("users", sa.Column("discipline", sa.String(50), nullable=True))
    op.add_column("users", sa.Column("bio", sa.Text(), nullable=True))

    # ── Online presence ──────────────────────────────────────
    op.add_column("users", sa.Column("website", sa.String(255), nullable=True))
    op.add_column("users", sa.Column("instagram", sa.String(100), nullable=True))
    op.add_column("users", sa.Column("portfolio", sa.String(255), nullable=True))

    # ── Invoicing ────────────────────────────────────────────
    op.add_column("users", sa.Column("legal_entity", sa.String(150), nullable=True))
    op.add_column("users", sa.Column("vat_id", sa.String(50), nullable=True))
    op.add_column("users", sa.Column("iban", sa.String(50), nullable=True))
    op.add_column("users", sa.Column("invoice_prefix", sa.String(50), nullable=True))

    # ── Avatar ───────────────────────────────────────────────
    op.add_column(
        "users",
        sa.Column("avatar_type", sa.String(10), nullable=False, server_default=sa.text("'color'")),
    )
    op.add_column(
        "users",
        sa.Column("avatar_color", sa.String(7), nullable=False, server_default=sa.text("'#2E2520'")),
    )
    op.add_column("users", sa.Column("avatar_image", sa.LargeBinary(length=2**24 - 1), nullable=True))

    # ── Banner ───────────────────────────────────────────────
    op.add_column(
        "users",
        sa.Column("banner_type", sa.String(10), nullable=False, server_default=sa.text("'color'")),
    )
    op.add_column(
        "users",
        sa.Column("banner_color", sa.String(7), nullable=False, server_default=sa.text("'#4A3F35'")),
    )
    op.add_column("users", sa.Column("banner_image", sa.LargeBinary(length=2**24 - 1), nullable=True))


def downgrade() -> None:
    op.drop_column("users", "banner_image")
    op.drop_column("users", "banner_color")
    op.drop_column("users", "banner_type")
    op.drop_column("users", "avatar_image")
    op.drop_column("users", "avatar_color")
    op.drop_column("users", "avatar_type")
    op.drop_column("users", "invoice_prefix")
    op.drop_column("users", "iban")
    op.drop_column("users", "vat_id")
    op.drop_column("users", "legal_entity")
    op.drop_column("users", "portfolio")
    op.drop_column("users", "instagram")
    op.drop_column("users", "website")
    op.drop_column("users", "bio")
    op.drop_column("users", "discipline")
    op.drop_column("users", "studio_name")
    op.drop_column("users", "handle")
