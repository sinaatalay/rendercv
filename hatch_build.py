from typing import Any

from hatchling.builders.hooks.plugin.interface import BuildHookInterface
import subprocess


class CustomBuildHook(BuildHookInterface):
    def initialize(self, version: str, build_data: dict[str, Any]) -> None:
        super().initialize(version, build_data)
        print("Building translations")
        subprocess.call(["pybabel", "compile", "-d", "rendercv/locale"])
