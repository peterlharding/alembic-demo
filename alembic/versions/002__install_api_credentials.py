#!/usr/bin/env python
# 
# -----------------------------------------------------------------------------
"""
  Install api_credentials table

  Revision ID: 002__install_api_credentials
      Revises: 001_set_when_modified
  Create Date: 2026-08-26 13:35:00
"""
# -----------------------------------------------------------------------------

from typing import Sequence, Union
from alembic import op

revision: str = '002__install_api_credentials'
down_revision: str = '001_set_when_modified'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.execute(open("db/create/api_credentials.sql").read())


def downgrade() -> None:
    op.execute("DROP TABLE IF EXISTS api_credentials")



