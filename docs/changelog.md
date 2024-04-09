---
toc_depth: 1
---
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

[Click here to see the unreleased changes.](https://github.com/sinaatalay/rendercv/compare/v1.7...HEAD)

<!--
### Added
### Changed
### Fixed
### Removed
-->

## [1.7] - 2024-04-08

### Added
- The new theme, `engineeringresumes`, is ready to be used now.
- The `education_degree_width` design option has been added for the `classic` theme.
- `last_updated_date_style` design option has been added for all the themes except `moderncv`.

### Fixed
- Highlights can now be broken into multiple pages in the `classic` theme (#47).
- Some JSON Schema bugs have been fixed.

## [1.6] - 2024-03-31

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

### Added
- A new entry type has been added: `BulletEntry`

### Changed
- `OneLineEntry`'s `name` field has been changed to `label`. This was required to generalize the entry validations.
- `moderncv`'s highlights are now bullet points.
- `moderncv`'s `TextEntries` don't have bullet points anymore.
- `sb2nov`'s `TextEntries` don't have bullet points anymore.


## [1.3] - 2024-03-09


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

### Fixed

- Markdown `TextEntry`, where all the paragraphs were concatenated into a single paragraph, has been fixed.
- Markdown `OneLineEntry`, where all the one-line entries were concatenated into a single line, has been fixed.
- The `classic` theme's `PublicationEntry`, where blank parentheses were rendered when the `journal` field was not provided, has been fixed.
- A bug, where an email with special characters caused a LaTeX error, has been fixed.
- Unicode error, when `rendercv new` is called with a name with special characters, has been fixed.


## [1.1] - 2024-02-25

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

### Fixed
- Author highlighting issue has been fixed in `PublicationEntry`.

## [0.9] - 2023-11-29

### Added
- Page numbering has been added.
- Text alignment options have been added (left-aligned or justified).
- Header options have been added (margins and header font size).
- `university_projects` field has been added.

## [0.8] - 2023-11-17

### Fixed
- YYYY date issue has been solved ([#5](https://github.com/sinaatalay/rendercv/issues/5)).

## [0.7] - 2023-11-03

### Changed
- The date type has been improved. It supports `YYYY-MM-DD`, `YYYY-MM`, and `YYYY` formats now.

### Fixed
- Custom sections' error messages have been fixed.

## [0.6] - 2023-10-28

### Added
- New fields have been added: `experience`, `projects`, `awards`, `interests`, and `programming_skills`.

### Fixed
- DOI validation bug has been fixed by [@LabAsim](https://github.com/LabAsim) in [#3](https://github.com/sinaatalay/rendercv/pull/3)/


## [0.5] - 2023-10-27

### Added

- Orcid support has been added.

### Fixed

- Special $\LaTeX$ characters' escaping has been fixed.


## [0.4] - 2023-10-22

### Changed

- CLI has been improved for more intuitive validation error messages.

## [0.3] - 2023-10-20

### Fixed

- The colors of CLI output have been fixed.
- Encoding problems have been fixed.

## [0.2] - 2023-10-17

### Fixed

- MacOS compatibility issues have been fixed.

## [0.1] - 2023-10-15

The first release of RenderCV.

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
