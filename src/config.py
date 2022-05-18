"""
Project configuration file.

"""

import os
from pathlib import Path

AWS_PROFILE = "3di"
AWS_DATA= "s3://3di-data-mdb/clean"
AWS_PROJECT = "s3://3di-project-eval"

ROOTDIR = Path(__file__).parent.parent
FIGDIR = os.path.join(ROOTDIR, "output", "figures")
TABDIR = os.path.join(ROOTDIR, "output", "tables")

