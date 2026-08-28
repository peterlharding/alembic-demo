#!/usr/bin/env python
# 
# -----------------------------------------------------------------------------
"""
  Install audit_log table
"""
# -----------------------------------------------------------------------------

from typing import Sequence, Union
from alembic import op

revision: str      = '007__install_audit_log'
down_revision: str = '006__install_login_session'

branch_labels: Union[str, Sequence[str], None] = None
depends_on:    Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.execute(open("db/create/audit_log.sql").read())


def downgrade() -> None:
    op.execute("DROP TABLE IF EXISTS audit_log")

