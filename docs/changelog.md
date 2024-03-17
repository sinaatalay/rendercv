---
toc_depth: 1
---
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

[Click here to see the unreleased changes.](https://github.com/sinaatalay/rendercv/compare/v1.4...HEAD)

<!--
### Fixed
### Changed
### Removed
### Added
-->

## [1.4] - 2024-03-10

### Added
- A new entry type is added: `BulletEntry`

### Changed
- `OneLineEntry`'s `name` field has been changed to `label`. This was required to generalize the entry validations.
- `moderncv`'s highlights are now bullet points.
- `moderncv`'s `TextEntries` don't have bullet points anymore.
- `sb2nov`'s `TextEntries` don't have bullet points anymore.


## [1.3] - 2024-03-09

### Fixed
- The `journal` is now displayed in the `PublicationEntry` of the `sb2nov` theme.

### Changed
- Future dates are now allowed.
- Authors' first names are no longer abbreviated in `PublicationEntry`.
- Markdown is now supported in the `authors` field of `PublicationEntry`.
- `doi` field is now optional for `PublicationEntry`.

### Added
- CLI documentation has been added to the user guide.


## [1.2] - 2024-02-27

### Fixed

- Fixed Markdown `TextEntry`, where all the paragraphs were concatenated into a single paragraph.
- Fixed Markdown `OneLineEntry`, where all the one-line entries were concatenated into a single line.
- Fixed the `classic` theme's `PublicationEntry`, where blank parentheses were rendered when the `journal` field was not provided.
- Fixed a bug where an email with special characters caused a LaTeX error.
- Fixed Unicode error when `rendercv new` is called with a name with special characters.


## [1.1] - 2024-02-25

### Added

- RenderCV is now a $\LaTeX$ CV framework. Users can move their $\LaTeX$ CV themes to RenderCV to produce their CV from RenderCV's YAML input.
- RenderCV now generates Markdown and HTML versions of the CV to allow users to paste the content of the CV to another software (like [Grammarly](https://www.grammarly.com/)) for spell checking.
- A new theme has been added: `moderncv`.
- A new theme has been added: `sb2nov`.

### Changed

- The data model is changed to be more flexible. All the sections are now under the `sections` field. All the keys are arbitrary and rendered as section titles. The entry types can be any of the six built-in entry types, and they will be detected by RenderCV for each section.
- The templating system has been changed completely.
- The command-line interface (CLI) is improved.
- The validation error messages are improved.
- TinyTeX has been moved to [another repository](https://github.com/sinaatalay/tinytex-release), and it is being pulled as a Git submodule. It is still pushed to PyPI, but it's not a part of the repository anymore.
- Tests are improved, and it uses `pytest` instead of `unittest`.
- The documentation has been rewritten.
- The reference has been rewritten.
- The build system has been changed from `setuptools` to `hatchling`.

## [0.10] - 2023-11-29

### Fixed
- Author highlighting issue is fixed in PublicationEntry.

## [0.9] - 2023-11-29

### Added
- Page numbering is added.
- Text alignment options are added (left-aligned or justified).
- Header options are added (margins and header font size).
- `university_projects` field is added.

## [0.8] - 2023-11-17

### Fixed
- YYYY date issue has been solved ([#5](https://github.com/sinaatalay/rendercv/issues/5)).

## [0.7] - 2023-11-03

### Changed
- The date type is improved. It supports `YYYY-MM-DD`, `YYYY-MM`, and `YYYY` formats now.

### Fixed
- Custom sections' error messages fixed.

## [0.6] - 2023-10-28

### Added
- New fields are added: `experience`, `projects`, `awards`, `interests`, and `programming_skills`.

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

- Fixed colors of CLI output.
- Fixed encoding problem.

## [0.2] - 2023-10-17

### Fixed

- Fixed MacOS compatibility issues.

## [0.1] - 2023-10-15

The first release of RenderCV.

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
