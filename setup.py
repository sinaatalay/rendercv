from setuptools import setup, find_packages

setup(
    name="rendercv",
    version="1.0",
    author="Sina Atalay",
    description="A Python package to generate a CV as a PDF from a YAML or JSON file.",
    packages=find_packages(),
    entry_points={
        "console_scripts": [
            "rendercv = rendercv.cli:main",
        ]
    },
)
