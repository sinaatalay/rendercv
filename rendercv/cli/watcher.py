"""
The `rendercv.cli.watcher` module contains all the functions and classes that are used to watch files and emit callbacks.
"""

import os
import pathlib
import time
from hashlib import sha256
from typing import Callable

from watchdog.events import FileModifiedEvent, FileSystemEventHandler
from watchdog.observers import Observer
from typer import Exit


class ModifiedCVEventHandler(FileSystemEventHandler):
    """This class handles the file changes and triggers a specified `callback` ignoring duplicate changes.

    Args:
        file_path (pathlib.Path): The path of the file to watch for.
        callback (Callable[..., None]): The function to be called on file modification. *CALLBACK MUST BE NON-BLOCKING*
    """

    file_path: pathlib.Path
    callback: Callable[..., None]
    previous_hash: str = ""

    def __init__(self, file_path: pathlib.Path, callback: Callable[..., None]):
        self.callback = callback
        self.file_path = file_path

        # Handle an initial pass manually
        self.on_modified(FileModifiedEvent(src_path=str(self.file_path)))

    def on_modified(self, event: FileModifiedEvent) -> None:
        if event.src_path != str(self.file_path):
            # Ignore any events that aren't our file.
            return

        file_hash = sha256(open(event.src_path).read().encode("utf-8")).hexdigest()

        if file_hash == self.previous_hash:
            # Exit if file hash has not changed.
            return

        self.previous_hash = file_hash

        try:
            self.callback()
        except Exit:
            ...  # Suppress typer Exit so we can continue watching even if we see errors.


def watch_file(file_path: pathlib.Path, callback: Callable[..., None]):
    """Watch file located at `file_path` and trigger callback on file modification.

    Args:
        file_path (pathlib.Path): The path of the file to watch for.
        callback (Callable[..., None]): The function to be called on file modification. *CALLBACK MUST BE NON-BLOCKING*
    """
    event_handler = ModifiedCVEventHandler(file_path, callback)
    observer = Observer()

    # If on windows we have to poll the parent directory instead of the file.
    if os.name == "nt":
        observer.schedule(event_handler, str(file_path.parent), recursive=False)
    else:
        observer.schedule(event_handler, str(file_path), recursive=False)

    observer.start()
    try:
        while True:
            time.sleep(1)
    finally:
        observer.stop()
        observer.join()
