r"""RenderCV package.

It parses the user input YAML/JSON file and validates the data (checking spelling
mistakes, whether the dates are consistent, etc.). Then, with the data, it creates a
$\LaTeX$ file and renders it with [TinyTeX](https://yihui.org/tinytex/).
"""
import logging
import os
import sys


class LoggingFormatter(logging.Formatter):
    grey = "\x1b[38;20m"  # debug level
    white = "\x1b[37;20m"  # info level
    yellow = "\x1b[33;20m"  # warning level
    red = "\x1b[31;20m"  # error level
    bold_red = "\x1b[31;1m"  # critical level

    reset = "\x1b[0m"
    format = "%(levelname)s | %(message)s"  # type: ignore

    FORMATS = {
        logging.DEBUG: grey + format + reset,  # type: ignore
        logging.INFO: white + format + reset,  # type: ignore
        logging.WARNING: yellow + format + reset,  # type: ignore
        logging.ERROR: red + format + reset,  # type: ignore
        logging.CRITICAL: bold_red + format + reset,  # type: ignore
    }

    def format(self, record):
        log_fmt = self.FORMATS.get(record.levelno)
        formatter = logging.Formatter(log_fmt)
        return formatter.format(record)


# Initialize logger with colors
if sys.platform == "win32":
    os.system("COLOR 0")  # enable colors in Windows terminal
logger = logging.getLogger()
logger.setLevel(logging.DEBUG)
stdout_handler = logging.StreamHandler()
stdout_handler.setFormatter(LoggingFormatter())
logger.addHandler(stdout_handler)
