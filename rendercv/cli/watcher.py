"""
The `rendercv.cli.watcher` module contains logic for watching files 
and emit callback functions.
"""

import sys
import pathlib
import time
from hashlib import sha256
from typing import Callable

from watchdog.events import FileModifiedEvent, FileSystemEventHandler
from watchdog.observers import Observer
from typer import Exit


class ModifiedCVEventHandler(FileSystemEventHandler):
    """This class handles the file changes and triggers a specified `function` 
    ignoring duplicate changes.

    Args:
        file_path (pathlib.Path): The path of the file to watch for.
        function (Callable): The function to be called on file modification.
    """

    file_path: pathlib.Path
    function: Callable[..., None]
    previous_hash: str = ""

    def __init__(self, file_path: pathlib.Path, function: Callable):
        self.function = function
        self.file_path = file_path

        # Handle an initial pass manually
        self.on_modified(FileModifiedEvent(src_path=str(self.file_path)))

    def on_modified(self, event: FileModifiedEvent) -> None:
        if event.src_path != str(self.file_path):
            # Ignore any events that aren't our file.
            return
        with open(event.src_path) as f:
            file_hash = sha256(f.read().encode("utf-8")).hexdigest()

        if file_hash == self.previous_hash:
            # Exit if file hash has not changed.
            return

        self.previous_hash = file_hash

        try:
            self.function()
        except Exit:
            ...  # Suppress Exit so we can continue watching.


def run_a_function_if_a_file_changes(
    file_path: pathlib.Path, function: Callable
):
    """Watch file located at `file_path` and trigger callback on file modification.

    Args:
        file_path (pathlib.Path): The path of the file to watch for.
        function (Callable): The function to be called on file modification.
    """
    event_handler = ModifiedCVEventHandler(file_path, function)
    observer = Observer()


    if sys.platform == "linux":
        observer.schedule(event_handler, str(file_path), recursive=False)
    # In non linux machines we have to poll the parent directory instead of the file.
    else:
        observer.schedule(event_handler, str(file_path.parent), recursive=False)

    observer.start()
    try:
        while True:
            time.sleep(1)
    finally:
        observer.stop()
        observer.join()
