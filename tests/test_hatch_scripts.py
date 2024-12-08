import subprocess
import sys

import pytest


@pytest.mark.parametrize(
    "script_name",
    [
        "format",
        "lint",
        "sort-imports",
        "check-types",
        "docs:build",
        "docs:update-schema",
        "docs:update-examples",
        "docs:update-entry-figures",
        # "docs:serve",
        # "test:run",
        # "test:run-and-report",
    ],
)
def test_default_format(script_name):
    subprocess.run([sys.executable, "-m", "hatch", "run", script_name], check=False)
