---
hide:
  - toc
---

# RenderCV

::: rendercv

In this section, you can find how RenderCV's components are structured and how they interact with each other. The flowchart below illustrates the general operations of RenderCV.

```mermaid
flowchart TD
    subgraph rendercv.data
    A[YAML Input File] --parsing with ruamel.yaml package--> B(Python Dictionary)
    B --validation with pydantic package--> C((Pydantic Object))
    end
    subgraph rendercv.renderer
    C --> AA
    E[Markdown File] --markdown package--> K[HTML FIle]
    D[LaTeX File] --TinyTeX--> L[PDF File]
    L --PyMuPDF package--> Z[PNG Files]
    AA[(Jinja2 Templates)] --> D
    AA[(Jinja2 Templates)] --> E
    end
```

- [`cli`](cli/index.md) package contains all the command-line interface (CLI) related code for RenderCV.
    - [`commands.py`](cli/commands.md) module contains all the CLI commands.
    - [`printer.py`](cli/printer.md) module contains all the functions and classes that are used to print nice-looking messages to the terminal.
    - [`utilities.py`](cli/utilities.md) module contains utility functions that are required by the CLI.
- [`data`](data/index.md) package contains classes and functions to parse and validate a YAML input file.
    - [`models`](data/models/index.md) package contains all the Pydantic data models, validators, and computed fields that are used in RenderCV.
        - [`computers.py`](data/models/computers.md) module contains functions that compute some properties based on the input data.
        - [`base.py`](data/models/base.md) module contains the base data model for all the other data models.
        - [`entry_types.py`](data/models/entry_types.md) module contains the data models of all the available entry types in RenderCV.
        - [`curriculum_vitae.py`](data/models/curriculum_vitae.md) module contains the data model of the `cv` field of the input file.
        - [`design.py`](data/models/design.md) module contains the data model of the `design` field of the input file.
        - [`locale_catalog.py`](data/models/locale_catalog.md) module contains the data model of the `locale_catalog` field of the input file.
        - [`rendercv_data_model.py`](data/models/rendercv_data_model.md) module contains the `RenderCVDataModel` data model, which is the main data model that defines the whole input file structure.
    - [`generator.py`](data/generator.md) module contains all the functions for generating the JSON Schema of the input data format and a sample YAML input file.
    - [`reader.py`](data/reader.md) module contains the functions that are used to read the input files. 
- [`renderer`](renderer/index.md) package contains utilities for generating the output files.
    - [`renderer.py`](renderer/renderer.md) module contains the necessary functions for rendering $\\LaTeX$, PDF, Markdown, HTML, and PNG files from the data model.
    - [`templater.py`](renderer/templater.md) module contains all the necessary classes and functions for templating the $\\LaTeX$ and Markdown files from the data model.
object.
- [`themes`](themes/index.md) package contains all the built-in themes of RenderCV.
    - [`classic`](themes/classic.md)
    - [`engineeringresumes`](themes/engineeringresumes.md)
    - [`sb2nov`](themes/sb2nov.md)
    - [`moderncv`](themes/moderncv.md)
