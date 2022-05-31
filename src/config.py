"""
Project configuration file.

"""

import os
from pathlib import Path

AWS_PROFILE = "3di"
AWS_PIECES = "s3://3di-data-mdb/clean/pieces"
AWS_PROJECT = "s3://3di-project-eval"

ROOTDIR = Path(__file__).parent.parent
FIGDIR = os.path.join(ROOTDIR, "output", "figures")
TABDIR = os.path.join(ROOTDIR, "output", "tables")


# Sample selection parameters
MIN_YEAR_INCOME = 5_000
MIN_PRE_MONTHS = 6
MIN_POST_MONTHS = 12
MIN_MONTH_SPEND = 200
MIN_MONTH_TXNS = 10
