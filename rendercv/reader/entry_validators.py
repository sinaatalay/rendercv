"""
The `rendercv.data_models.validators` module contains all the functions used to validate
the data models of RenderCV, in addition to Pydantic inner validation.
"""

import re
from datetime import date as Date
from typing import Optional

import pydantic

from . import utilities as util

from .entry_types import StartDate, EndDate, ArbitraryDate


