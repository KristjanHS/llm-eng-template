# Cookiecutter: LLM Engineering Template

This repository publishes a Cookiecutter template that scaffolds an opinionated Python 3.12 project for LLM experimentation (backend, frontend, Docker tooling, and agent-friendly docs).

## Generate a Project

```bash
pipx install cookiecutter          # or: pip install --user cookiecutter
cookiecutter gh:KristjanHS/llm-eng-template
```

You will be prompted for:

- `project_name` – human readable title (`My LLM Project`)
- `project_slug` – directory/package name (pre-filled from the name; accept the default unless you need something custom)
- `author_name` – used in licensing and docs

Cookiecutter writes the new project to `./<project_slug>/`. Follow the onboarding steps in that generated README (run `./run_uv.sh`, `uv run pre-commit run --all-files`, etc.).

## Developing the Template

- Edit files under `{{ cookiecutter.project_slug }}` to update the generated project.
- Regenerate a sample project during development to ensure the template stays healthy:

  ```bash
  cookiecutter --no-input . --output-dir /tmp
  ```

- Update `cookiecutter.json` when you add new templated variables.
- Keep secrets out of tracked files—use `.env.example` for placeholders.

## License

The template content ships under the MIT License (see `{{ cookiecutter.project_slug }}/LICENSE`). Generated projects inherit that license by default; adjust it after generation if your use case differs.
