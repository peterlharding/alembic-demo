#!/usr/bin/env python
# 
# -----------------------------------------------------------------------------
"""
  Install audit_log table
"""
# -----------------------------------------------------------------------------

from typing import Sequence, Union
from alembic import op

revision: str      = '009__add_admin_user'
down_revision: str = '008__add_api_credentials_user'

branch_labels: Union[str, Sequence[str], None] = None
depends_on:    Union[str, Sequence[str], None] = None


# -----------------------------------------------------------------------------

def upgrade() -> None:
    op.execute(open("db/data/application_user.sql").read())


# -----------------------------------------------------------------------------

def downgrade() -> None:
    op.execute("TRUNCATE application_user RESTART IDENTITY")


# -----------------------------------------------------------------------------

