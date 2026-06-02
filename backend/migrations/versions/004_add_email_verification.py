"""add email_verified and verification_pin to users

Revision ID: 004
Revises: 003
Create Date: 2026-06-02
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "004"
down_revision: Union[str, None] = "003"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "users",
        sa.Column(
            "email_verified",
            sa.Boolean(),
            nullable=False,
            server_default=sa.text("0"),
        ),
    )
    op.add_column(
        "users",
        sa.Column("verification_pin", sa.String(6), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("users", "verification_pin")
    op.drop_column("users", "email_verified")
