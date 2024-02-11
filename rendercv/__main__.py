"""
`__main__.py` file is the file that gets executed when the RenderCV package itself is
invoked directly from the command line with `python -m rendercv`. That's why we have it
here so that we can invoke the CLI from the command line with `python -m rendercv`.
"""

from .cli import app

if __name__ == "__main__":
    app()
