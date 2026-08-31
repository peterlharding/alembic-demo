#!/usr/bin/env python
# 
# -----------------------------------------------------------------------------
"""
  Install login_session table
"""
# -----------------------------------------------------------------------------

from typing import Sequence, Union
from alembic import op

revision: str      = '006__install_login_session'
down_revision: str = '005__install_token_blacklist'

branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.execute(open("db/create/login_session.sql").read())


def downgrade() -> None:
    op.execute("DROP TABLE IF EXISTS login_session")

