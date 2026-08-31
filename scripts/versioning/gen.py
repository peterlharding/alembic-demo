#!/usr/bin/env python
#
#
# -----------------------------------------------------------------------------

import os


# =============================================================================

TEMPLATE = """
#!/usr/bin/env python
# 
# -----------------------------------------------------------------------------
\"\"\"
  Install {next_table} table
\"\"\"
# -----------------------------------------------------------------------------

from typing import Sequence, Union
from alembic import op

revision: str      = '{next_revision_name}'
down_revision: str = '{last_revision_name}'

branch_labels: Union[str, Sequence[str], None] = None
depends_on:    Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.execute(open("db/create/{next_table}.sql").read())


def downgrade() -> None:
    op.execute("{last_revision_command}")

"""
# =============================================================================

os.makedirs("./versions", exist_ok=True)

VERSION = 10

last_revision_name    = "009__add_admin_user"
last_revision_command = "TRUNCATE application_user RESTART IDENTITY"

TODO    = ["iso_country", "iso_subdivision", "locality"]


version = VERSION

for next_table in TODO:
    next_revision_name = f"{version:03d}__install_{next_table}"

    print(f"{next_table:20} - {next_revision_name}")

    script = TEMPLATE.format(**{
        "next_table"            : next_table,
        "last_revision_name"    : last_revision_name,
        "last_revision_command" : last_revision_command,
        "next_revision_name"    : next_revision_name,
    })

    script_file = f"versions/{next_revision_name}.py"

    with open(script_file, "w+") as f_out:
        f_out.write(script)
        os.chmod(script_file, 0o755) 

    version += 1
    last_revision_name    = next_revision_name
    last_revision_command = f"DROP TABLE IF EXISTS {next_table}"


