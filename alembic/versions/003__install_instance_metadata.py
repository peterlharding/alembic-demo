#!/usr/bin/env python
# 
# -----------------------------------------------------------------------------
"""
  Install token_blacklist table

  Revision ID: 003__install_instance_metadata
      Revises: 002__install_api_credentials
  Create Date: 2026-08-26 13:35:00
"""
# -----------------------------------------------------------------------------

from typing import Sequence, Union
from alembic import op

revision: str      = '003__install_instance_metadata'
down_revision: str = '002__install_api_credentials'

branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.execute(open("db/create/instance_metadata.sql").read())


def downgrade() -> None:
    op.execute("DROP TABLE IF EXISTS instance_metadata")


