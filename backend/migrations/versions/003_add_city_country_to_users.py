"""add first_name, last_name, city and country to users

Revision ID: 003
Revises: 002
Create Date: 2026-06-02
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "003"
down_revision: Union[str, None] = "002"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "users",
        sa.Column("first_name", sa.String(100), nullable=True),
    )
    op.add_column(
        "users",
        sa.Column("last_name", sa.String(100), nullable=True),
    )
    op.add_column(
        "users",
        sa.Column("city", sa.String(100), nullable=True),
    )
    op.add_column(
        "users",
        sa.Column("country", sa.String(100), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("users", "country")
    op.drop_column("users", "city")
    op.drop_column("users", "last_name")
    op.drop_column("users", "first_name")
