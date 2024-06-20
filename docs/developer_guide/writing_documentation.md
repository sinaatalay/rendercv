# Writing Documentation

The documentation's source files are located in the [`docs`](https://github.com/sinaatalay/rendercv/tree/main/docs) directory and it is built using the [MkDocs](https://github.com/mkdocs/mkdocs) package. To work on the documentation and see the changes in real-time, run the following command.

```bash
hatch run docs:serve
```

Once the changes are pushed to the `main` branch, the [`deploy-docs`](https://github.com/sinaatalay/rendercv/blob/main/.github/workflows/deploy-docs.yaml) workflow will be automatically triggered, and [docs.rendercv.com](https://docs.rendercv.com/) will be updated to the most recent version.


## Updating the [`examples`](https://github.com/sinaatalay/rendercv/tree/main/examples) folder

The `examples` folder includes example YAML files for all the built-in themes, along with their corresponding PDF outputs. Also, there are PNG files of the first pages of each theme in [`docs/assets/images`](https://github.com/sinaatalay/rendercv/tree/main/docs/assets/images). These examples are shown in [`README.md`](https://github.com/sinaatalay/rendercv/blob/main/README.md).

These files are generated using [`docs/update_examples.py`](https://github.com/sinaatalay/rendercv/blob/main/docs/update_examples.py). The contents of the examples are taken from the [`get_a_sample_data_model`](https://docs.rendercv.com/reference/data_models/#rendercv.data_models.get_a_sample_data_model) function from [`data_models.py`](https://docs.rendercv.com/reference/data_models/).

Run the following command to update the `examples` folder.

```bash
hatch run docs:update-examples
```

Once a new release is created on GitHub, the [`publish.yaml`](https://github.com/sinaatalay/rendercv/blob/main/.github/workflows/publish.yaml) workflow will be automatically triggered, and the `examples` folder will be updated to the most recent version.

## Updating figures of the entry types in the "[Structure of the YAML Input File](https://docs.rendercv.com/user_guide/structure_of_the_yaml_input_file/)"

There are example figures for each entry type for each theme in the "[Structure of the YAML Input File](https://docs.rendercv.com/user_guide/structure_of_the_yaml_input_file/)" page.

The figures are generated using [`docs/update_entry_figures.py`](https://github.com/sinaatalay/rendercv/blob/main/docs/update_entry_figures.py). 

Run the following command to update the figures.

```bash
hatch run docs:update-entry-figures
```

Once a new release is created on GitHub, the [`publish.yaml`](https://github.com/sinaatalay/rendercv/blob/main/.github/workflows/publish.yaml) workflow will be automatically triggered, and the figures will be updated to the most recent version.

## Updating the JSON Schema ([`schema.json`](https://github.com/sinaatalay/rendercv/blob/main/schema.json))

The schema of RenderCV's input file is defined using [Pydantic](https://docs.pydantic.dev/latest/). Pydantic allows automatic creation and customization of JSON schemas from Pydantic models.

The JSON Schema is also generated using [`docs/update_schema.py`](https://github.com/sinaatalay/rendercv/blob/main/docs/update_schema.py). It uses [`generate_json_schema`](https://docs.rendercv.com/reference/data_models/#rendercv.data_models.generate_json_schema) function from [`data_models.py`](https://docs.rendercv.com/reference/data_models/).

Run the following command to update the JSON Schema.

```bash
hatch run docs:update-schema
```

Once a new release is created on GitHub, the [`publish.yaml`](https://github.com/sinaatalay/rendercv/blob/main/.github/workflows/publish.yaml) workflow will be automatically triggered, and `schema.json` will be updated to the most recent version.