#!/usr/bin/env python
# 
# -----------------------------------------------------------------------------
"""
  Install application_user table
"""
# -----------------------------------------------------------------------------

from typing import Sequence, Union
from alembic import op

revision: str      = '004__install_application_user'
down_revision: str = '003__install_instance_metadata'

branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.execute(open("db/create/application_user.sql").read())


def downgrade() -> None:
    op.execute("DROP TABLE IF EXISTS application_user")


