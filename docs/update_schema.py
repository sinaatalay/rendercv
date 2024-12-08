"""This script generates the JSON schema (schema.json) in the repository root."""

import pathlib

import rendercv.data as data

repository_root = pathlib.Path(__file__).parent.parent


def generate_schema():
    """Generate the schema."""
    json_schema_file_path = repository_root / "schema.json"
    data.generate_json_schema_file(json_schema_file_path)


if __name__ == "__main__":
    generate_schema()
    print("Schema generated successfully.")  # NOQA: T201
