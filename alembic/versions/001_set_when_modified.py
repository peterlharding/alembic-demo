#!/usr/bin/env python
#
# -----------------------------------------------------------------------------
"""install instance_metadata

Revision ID: 001_set_when_modified
Revises: 
Create Date: 2026-08-26 13:35:00
"""
# -----------------------------------------------------------------------------

from typing import Sequence, Union
from alembic import op

revision: str = '001_set_when_modified'
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.execute(open("db/create/set_when_modified.sql").read())


def downgrade() -> None:
    op.execute("DROP FUNCTION IF EXISTS set_when_modified")


