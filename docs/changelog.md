---
toc_depth: 1
---
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

[Click here to see the unreleased changes.](https://github.com/sinaatalay/rendercv/compare/v1.11...HEAD)

<!--
### Added
### Changed
### Fixed
### Removed
-->

## [1.11] - 2024-06-19

> **Full Changelog**: [v1.10...v1.11]

### Added
- CLI options now have short versions. See the [CLI documentation](https://docs.rendercv.com/user_guide/cli/) for more information.
- CLI now notifies the user when a new version is available ([#89](https://github.com/sinaatalay/rendercv/issues/89)).
- `Google Scholar` has been added as a social network type ([#85](https://github.com/sinaatalay/rendercv/issues/85)).
- Two new design options have been added to the `classic`, `sb2nov`, and `engineeringresumes` themes: `seperator_between_connections` and `use_icons_for_connections`.

### Changed
- The punctuation of "ORCID" has been changed to uppercase, which was previously "Orcid" ([#90](https://github.com/sinaatalay/rendercv/issues/90)).
- HTML output has been improved with better CSS ([#96](https://github.com/sinaatalay/rendercv/discussions/96)).
- More complex section titles are now supported ([#106](https://github.com/sinaatalay/rendercv/issues/106)).
- Month abbreviations are not using dots anymore.
- Date ranges are now displayed as "Month Year - Month Year" instead of "Month Year to Month Year."
- DOI validator in the `PublicationEntry` has been disabled.
- `url` field has been added to the `PublicationEntry` as an alternative to the `doi` field ([#105](https://github.com/sinaatalay/rendercv/issues/105))
- `YouTube` username should be given without `@` now.

### Fixed
- The error related to the `validation_error_cause` flag of Pydantic has been fixed ([#66](https://github.com/sinaatalay/rendercv/issues/66)).
- `rendercv render` with relative input file paths has been fixed ([#95](https://github.com/sinaatalay/rendercv/issues/95)).

### Removed
- `Twitter` has been removed as a social network type ([#109](https://github.com/sinaatalay/rendercv/issues/109)).


## [1.10] - 2024-05-25

> **Full Changelog**: [v1.9...v1.10]

### Added
- `rendercv --version` command has been added to show the version of RenderCV.
- `StackOverflow` ([#77](https://github.com/sinaatalay/rendercv/pull/77)), `GitLab` ([#78](https://github.com/sinaatalay/rendercv/pull/78)), `ResearchGate`, and `YouTube` has been added to the available social network types.

### Fixed
- Authors in `PublicationEntry` are now displayed correctly in `engineeringresumes` and `sb2nov` themes.
- `justify-with-no-hyphenation` text alignment has been fixed.


## [1.9] - 2024-05-19

> **Full Changelog**: [v1.8...v1.9]

### Added
- RenderCV is now a multilingual tool. English strings can be overridden with `locale_catalog` section in the YAML input file ([#26](https://github.com/sinaatalay/rendercv/issues/26), [#20](https://github.com/sinaatalay/rendercv/pull/20)). See the [documentation](https://docs.rendercv.com/user_guide/structure_of_the_yaml_input_file/#locale_catalog-section-of-the-yaml-input) for more information.
- PNG files for each page can be generated now ([#57](https://github.com/sinaatalay/rendercv/issues/57)).
- `rendercv new` command now generates Markdown and $\LaTeX$ source files in addition to the YAML input file so that the default templates can be modified easily.
- A new CLI command has been added, `rendercv create-theme`, to allow users to create their own themes easily.
    ```bash
    rendercv create-theme "customtheme" --based-on "classic"
    ```
- [A developer guide](https://docs.rendercv.com/developer_guide/) has been written.
- New options have been added to the `rendercv render` command: 
    - `--output-folder-name "OUTPUT_FOLDER_NAME"`: Generates the output files in a folder with the given name. By default, the output folder name is `rendercv_output`. The output folder will be created in the current working directory. ([#58](https://github.com/sinaatalay/rendercv/issues/58))
    - `--latex-path LATEX_PATH`: Copies the generated $\LaTeX$ source code from the output folder and pastes it to the specified path.
    - `--pdf-path PDF_PATH`: Copies the generated PDF file from the output folder and pastes it to the specified path.
    - `--markdown-path MARKDOWN_PATH`: Copies the generated Markdown file from the output folder and pastes it to the specified path.
    - `--html-path HTML_PATH`: Copies the generated HTML file from the output folder and pastes it to the specified path.
    - `--png-path PNG_PATH`: Copies the generated PNG files from the output folder and pastes them to the specified path.
    - `--dont-generate-markdown`: Prevents the generation of the Markdown file.
    - `--dont-generate-html`: Prevents the generation of the HTML file.
    - `--dont-generate-png`: Prevents the generation of the PNG files.
    - `--ANY.LOCATION.IN.THE.YAML.FILE "VALUE"`: Overrides the value of `ANY.LOCATION.IN.THE.YAML.FILE` with `VALUE`. This option can be used to avoid storing sensitive information in the YAML file. Sensitive information, like phone numbers, can be passed as a command-line argument with environment variables. This method is also beneficial for creating multiple CVs using the same YAML file by changing only a few values.
- New options have been added to the `rendercv new` command: 
    - `--dont-create-theme-source-files`: Prevents the creation of the theme source files. By default, the theme source files are created.
    - `--dont-create-markdown-source-files`: Prevents the creation of the Markdown source files. By default, the Markdown source files are created.

### Changed
- Package size has been reduced by removing unnecessary TinyTeX files.
- `date` field is now optional in `PublicationEntry`.
- [README.md](https://github.com/sinaatalay/rendercv) and the [documentation](https://docs.rendercv.com/) have been rewritten.

### Fixed
- `ExperienceEntry` and `NormalEntry` without location and dates have been fixed in the `engineeringresumes`, `classic`, and `sb2nov` themes.
- $\LaTeX$ templates have been polished.
- Bugs related to the special characters in email addresses have been fixed ([#64](https://github.com/sinaatalay/rendercv/issues/64)).

## [1.8] - 2024-04-16

> **Full Changelog**: [v1.7...v1.8]

### Added
- Horizontal space has been added between entry titles and dates in the `engineeringresumes` theme.
- The `date_and_location_width` option has been added to the `engineeringresumes` theme.
- A new design option, `disable_external_link_icons`, has been added.

    
### Changed
- `sb2nov` theme's $\LaTeX$ code has been changed completly. There are slight changes in the looks.
- `classic`, `sb2nov`, and `engineeringresumes` use the same $\LaTeX$ code base now.
- The design option `show_last_updated_date` has been renamed to `disable_last_updated_date` for consistency.
- Mastodon links now use the original hostnames instead of `https://mastodon.social/`.

### Fixed
- The location is now shown in the header (#54).
- The `education_degree_width` option of the `classic` theme has been fixed.
- Lualatex and xelatex rendering problems have been fixed (#52).

## [1.7] - 2024-04-08

> **Full Changelog**: [v1.6...v1.7]

### Added
- The new theme, `engineeringresumes`, is ready to be used now.
- The `education_degree_width` design option has been added for the `classic` theme.
- `last_updated_date_style` design option has been added for all the themes except `moderncv`.

### Fixed
- Highlights can now be broken into multiple pages in the `classic` theme (#47).
- Some JSON Schema bugs have been fixed.

## [1.6] - 2024-03-31

> **Full Changelog**: [v1.5...v1.6]

### Added
- A new theme has been added: `engineeringresumes`. It hasn't been tested fully yet.
- A new text alignment option has been added to `classic` and `sb2nov`: `justified-with-no-hyphenation` ([#34](https://github.com/sinaatalay/rendercv/issues/34))
- Users are now allowed to run local `lualatex`, `xelatex`, `latexmk` commands in addition to `pdflatex` ([#48](https://github.com/sinaatalay/rendercv/issues/48)).

### Changed
- Orcid is now displayed in the header like other social media links.


### Fixed
- Decoding issues have been fixed ([#29](https://github.com/sinaatalay/rendercv/issues/29)).
- Classic theme's `ExperienceEntry` has been fixed ([#49](https://github.com/sinaatalay/rendercv/issues/49)).


## [1.5] - 2024-03-27

> **Full Changelog**: [v1.4...v1.5]

### Added
- Users can now make bold or italic texts normal with Markdown syntax.

### Changed
- The `moderncv` theme doesn't italicize any text by default now.

### Fixed
- The `moderncv` theme's PDF title issue has been fixed.
- The ordering of the data models' keys in JSON Schema has been fixed.
- The unhandled exception when a custom theme's `__init__.py` file is invalid has been fixed.
- The `sb2nov` theme's `PublicationEntry` without `journal` and `doi` fields is now rendered correctly.
- The `sb2nov` theme's `OneLineEntry`'s colon issue has been fixed.

## [1.4] - 2024-03-10

> **Full Changelog**: [v1.3...v1.4]

### Added
- A new entry type has been added: `BulletEntry`

### Changed
- `OneLineEntry`'s `name` field has been changed to `label`. This was required to generalize the entry validations.
- `moderncv`'s highlights are now bullet points.
- `moderncv`'s `TextEntries` don't have bullet points anymore.
- `sb2nov`'s `TextEntries` don't have bullet points anymore.


## [1.3] - 2024-03-09

> **Full Changelog**: [v1.2...v1.3]

### Added
- CLI documentation has been added to the user guide.

### Changed
- Future dates are now allowed.
- Authors' first names are no longer abbreviated in `PublicationEntry`.
- Markdown is now supported in the `authors` field of `PublicationEntry`.
- `doi` field is now optional for `PublicationEntry`.

### Fixed
- The `journal` is now displayed in the `PublicationEntry` of the `sb2nov` theme.


## [1.2] - 2024-02-27

> **Full Changelog**: [v1.1...v1.2]

### Fixed

- Markdown `TextEntry`, where all the paragraphs were concatenated into a single paragraph, has been fixed.
- Markdown `OneLineEntry`, where all the one-line entries were concatenated into a single line, has been fixed.
- The `classic` theme's `PublicationEntry`, where blank parentheses were rendered when the `journal` field was not provided, has been fixed.
- A bug, where an email with special characters caused a $\LaTeX$ error, has been fixed.
- Unicode error, when `rendercv new` is called with a name with special characters, has been fixed.


## [1.1] - 2024-02-25

> **Full Changelog**: [v0.10...v1.1]

### Added

- RenderCV is now a $\LaTeX$ CV framework. Users can move their $\LaTeX$ CV themes to RenderCV to produce their CV from RenderCV's YAML input.
- RenderCV now generates Markdown and HTML versions of the CV to allow users to paste the content of the CV to another software (like [Grammarly](https://www.grammarly.com/)) for spell checking.
- A new theme has been added: `moderncv`.
- A new theme has been added: `sb2nov`.

### Changed

- The data model has been changed to be more flexible. All the sections are now under the `sections` field. All the keys are arbitrary and rendered as section titles. The entry types can be any of the six built-in entry types, and they will be detected by RenderCV for each section.
- The templating system has been changed completely.
- The command-line interface (CLI) has been improved.
- The validation error messages have been improved.
- TinyTeX has been moved to [another repository](https://github.com/sinaatalay/tinytex-release), and it is being pulled as a Git submodule. It is still pushed to PyPI, but it's not a part of the repository anymore.
- Tests have been improved, and it uses `pytest` instead of `unittest`.
- The documentation has been rewritten.
- The reference has been rewritten.
- The build system has been changed from `setuptools` to `hatchling`.

## [0.10] - 2023-11-29

> **Full Changelog**: [v0.9...v0.10]

### Fixed
- Author highlighting issue has been fixed in `PublicationEntry`.

## [0.9] - 2023-11-29

> **Full Changelog**: [v0.8...v0.9]

### Added
- Page numbering has been added.
- Text alignment options have been added (left-aligned or justified).
- Header options have been added (margins and header font size).
- `university_projects` field has been added.

## [0.8] - 2023-11-17

> **Full Changelog**: [v0.7...v0.8]

### Fixed
- YYYY date issue has been solved ([#5](https://github.com/sinaatalay/rendercv/issues/5)).

## [0.7] - 2023-11-03

> **Full Changelog**: [v0.6...v0.7]

### Changed
- The date type has been improved. It supports `YYYY-MM-DD`, `YYYY-MM`, and `YYYY` formats now.

### Fixed
- Custom sections' error messages have been fixed.

## [0.6] - 2023-10-28

> **Full Changelog**: [v0.5...v0.6]

### Added
- New fields have been added: `experience`, `projects`, `awards`, `interests`, and `programming_skills`.

### Fixed
- DOI validation bug has been fixed by [@LabAsim](https://github.com/LabAsim) in [#3](https://github.com/sinaatalay/rendercv/pull/3)/


## [0.5] - 2023-10-27

> **Full Changelog**: [v0.4...v0.5]

### Added

- Orcid support has been added.

### Fixed

- Special $\LaTeX$ characters' escaping has been fixed.


## [0.4] - 2023-10-22

> **Full Changelog**: [v0.3...v0.4]

### Changed

- CLI has been improved for more intuitive validation error messages.

## [0.3] - 2023-10-20

> **Full Changelog**: [v0.2...v0.3]

### Fixed

- The colors of CLI output have been fixed.
- Encoding problems have been fixed.

## [0.2] - 2023-10-17

> **Full Changelog**: [v0.1...v0.2]

### Fixed

- MacOS compatibility issues have been fixed.

## [0.1] - 2023-10-15

The first release of RenderCV.

[v1.10...v1.11]: https://github.com/sinaatalay/rendercv/compare/v1.10...v1.11
[v1.9...v1.10]: https://github.com/sinaatalay/rendercv/compare/v1.9...v1.10
[v1.8...v1.9]: https://github.com/sinaatalay/rendercv/compare/v1.8...v1.9
[v1.7...v1.8]: https://github.com/sinaatalay/rendercv/compare/v1.7...v1.8
[v1.6...v1.7]: https://github.com/sinaatalay/rendercv/compare/v1.6...v1.7
[v1.5...v1.6]: https://github.com/sinaatalay/rendercv/compare/v1.5...v1.6
[v1.4...v1.5]: https://github.com/sinaatalay/rendercv/compare/v1.4...v1.5
[v1.3...v1.4]: https://github.com/sinaatalay/rendercv/compare/v1.3...v1.4
[v1.2...v1.3]: https://github.com/sinaatalay/rendercv/compare/v1.2...v1.3
[v1.1...v1.2]: https://github.com/sinaatalay/rendercv/compare/v1.1...v1.2
[v0.10...v1.1]: https://github.com/sinaatalay/rendercv/compare/v0.10...v1.1
[v0.9...v0.10]: https://github.com/sinaatalay/rendercv/compare/v0.9...v0.10
[v0.8...v0.9]: https://github.com/sinaatalay/rendercv/compare/v0.8...v0.9
[v0.7...v0.8]: https://github.com/sinaatalay/rendercv/compare/v0.7...v0.8
[v0.6...v0.7]: https://github.com/sinaatalay/rendercv/compare/v0.6...v0.7
[v0.5...v0.6]: https://github.com/sinaatalay/rendercv/compare/v0.5...v0.6
[v0.4...v0.5]: https://github.com/sinaatalay/rendercv/compare/v0.4...v0.5
[v0.3...v0.4]: https://github.com/sinaatalay/rendercv/compare/v0.3...v0.4
[v0.2...v0.3]: https://github.com/sinaatalay/rendercv/compare/v0.2...v0.3
[v0.1...v0.2]: https://github.com/sinaatalay/rendercv/compare/v0.1...v0.2

[1.11]: https://github.com/sinaatalay/rendercv/releases/tag/v1.11
[1.10]: https://github.com/sinaatalay/rendercv/releases/tag/v1.10
[1.9]: https://github.com/sinaatalay/rendercv/releases/tag/v1.9
[1.8]: https://github.com/sinaatalay/rendercv/releases/tag/v1.8
[1.7]: https://github.com/sinaatalay/rendercv/releases/tag/v1.7
[1.6]: https://github.com/sinaatalay/rendercv/releases/tag/v1.6
[1.5]: https://github.com/sinaatalay/rendercv/releases/tag/v1.5
[1.4]: https://github.com/sinaatalay/rendercv/releases/tag/v1.4
[1.3]: https://github.com/sinaatalay/rendercv/releases/tag/v1.3
[1.2]: https://github.com/sinaatalay/rendercv/releases/tag/v1.2
[1.1]: https://github.com/sinaatalay/rendercv/releases/tag/v1.1
[0.10]: https://github.com/sinaatalay/rendercv/releases/tag/v0.10
[0.9]: https://github.com/sinaatalay/rendercv/releases/tag/v0.9
[0.8]: https://github.com/sinaatalay/rendercv/releases/tag/v0.8
[0.7]: https://github.com/sinaatalay/rendercv/releases/tag/v0.7
[0.6]: https://github.com/sinaatalay/rendercv/releases/tag/v0.6
[0.5]: https://github.com/sinaatalay/rendercv/releases/tag/v0.5
[0.4]: https://github.com/sinaatalay/rendercv/releases/tag/v0.4
[0.3]: https://github.com/sinaatalay/rendercv/releases/tag/v0.3
[0.2]: https://github.com/sinaatalay/rendercv/releases/tag/v0.2
[0.1]: https://github.com/sinaatalay/rendercv/releases/tag/v0.1
