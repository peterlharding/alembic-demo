#!/usr/bin/env python
# 
# -----------------------------------------------------------------------------
"""
  Install token_blacklist table
"""
# -----------------------------------------------------------------------------

from typing import Sequence, Union
from alembic import op

revision: str      = '005__install_token_blacklist'
down_revision: str = '004__install_application_user'

branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.execute(open("db/create/token_blacklist.sql").read())


def downgrade() -> None:
    op.execute("DROP TABLE IF EXISTS token_blacklist")

