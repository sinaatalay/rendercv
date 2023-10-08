r"""RenderCV package.

It parses the user input YAML/JSON file and validates the data (checks spelling mistakes, checks if the dates are consistent, etc.). Then, with the data, it creates a $\LaTeX$ file and renders it with [TinyTeX](https://yihui.org/tinytex/).
"""

# initialize logging:
import logging


class LoggingFormatter(logging.Formatter):
    """
    Logging formatter class
    """

    grey = "\x1b[38;20m"  # debug level
    white = "\x1b[37;20m"  # info level
    yellow = "\x1b[33;20m"  # warning level
    red = "\x1b[31;20m"  # error level
    bold_red = "\x1b[31;1m"  # critical level

    reset = "\x1b[0m"
    format = "%(levelname)s | %(message)s"

    FORMATS = {
        logging.DEBUG: grey + format + reset,
        logging.INFO: white + format + reset,
        logging.WARNING: yellow + format + reset,
        logging.ERROR: red + format + reset,
        logging.CRITICAL: bold_red + format + reset,
    }

    def format(self, record):
        log_fmt = self.FORMATS.get(record.levelno)
        formatter = logging.Formatter(log_fmt)
        return formatter.format(record)


logger = logging.getLogger()
stdout_handler = logging.StreamHandler()
stdout_handler.setLevel(logging.INFO)
stdout_handler.setFormatter(LoggingFormatter())
logger.addHandler(stdout_handler)