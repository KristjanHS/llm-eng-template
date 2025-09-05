# llm-eng-template

Template repo for LLM experimentation

---

## Prerequisites
- uv (https://astral.sh/uv) or pip
- Docker & Docker Compose
- Linux/WSL2

---

## Quick Start

# Create .venv and install dev/test toolchain (editable install): `./run_uv.sh`
# Run pre-commit via uv (uses the venv): `uv run pre-commit run --all-files`
# Quick integration test run: `make integration-local`
# Start Docker services (if needed): `docker compose -f docker/docker-compose.yml up -d --build`

# Fallback to pip/venv: 
- Generate requirements.txt based on uv.lock: `make export-reqs`

---

## AI Coding Agent Configs

- Gemini: `gemini.md` quickstart; settings in `.gemini/config.yaml` and `.gemini/settings.json` for Gemini CLI and Gemini Code Assist.
- Codex CLI: `.codex/` (use these configs in `~/.codex/`)  and `AGENTS.md` operational rules and guardrails for agents in this repo.
- Cursor: `.cursor/` and `.cursor/rules/*.mdc` to guide Cursor behavior; `.cursorignore` for noise filtering.
- Shared docs: `docs/` contains agent-focused references like `AI_instructions.md`, `CODEX_RULES.md`, and `testing_approach.md`.

---

## Checks & Automations

- Pre-commit: Ruff (lint+format), Pyright (backend), Yamlfmt, Actionlint, Hadolint, Bandit, Detect-secrets. Run: `uv run pre-commit run --all-files`. Config: `.pre-commit-config.yaml` (+ `.secrets.baseline`).
- Pre-push: Ruff format/check, Yamlfmt, Pyright, Unit tests; optional Semgrep + CodeQL via Act. Enable with `make setup-hooks`. Toggle via env: `SKIP_LINT=1 SKIP_PYRIGHT=1 SKIP_TESTS=1 SKIP_LOCAL_SEC_SCANS=0`.
- GitHub CI (+local CI: Act cli):
  - `python-lint-test.yml`: Lint, Unit tests, Pyright. Integration/E2E run under Act (schedule/manual).
  - `meta-linters.yml`: Actionlint, Yamlfmt, Hadolint on relevant changes.
  - `semgrep.yml`, `codeql.yml`: Security scans on PR/schedule/manual.
  - `trivy_pip-audit.yml`: pip-audit + Trivy on dep/Docker changes and schedule.
- Tests & coverage: `tests/unit`, `tests/integration`, `tests/e2e`. Fast path example: `.venv/bin/python -m pytest tests/unit -q`. Coverage HTML: `reports/coverage`.
- Logging: App logging in `backend/config.py` (level via `LOG_LEVEL`, Rich when TTY; optional file rotation via `APP_LOG_DIR`). Script logging helpers in `scripts/common.sh`. Unit tests cover both.

---

**CI/Act Environment Alignment**
- **Problem:** When running local CI with `act --bind`, the workspace is your real repo. The default checkout clean can delete untracked files like `.env`/`.venv`. In CI we also used a different venv name (`.venv-ci`) while Pyright’s config pointed at `.venv`, leading to missing imports in CI (e.g., `dotenv`, `rich`).
- **Current Solution:**
  - **Single Pyright config:** `pyrightconfig.json` no longer sets `venvPath`/`venv`; Makefile passes `--pythonpath` so Pyright analyzes against the active interpreter.
  - **Makefile honors CI env:** Targets (`pyright`, `unit-local`, `ruff-format`, `ruff-fix`) prefer `uv run` when `UV_PROJECT_ENVIRONMENT` is set (CI uses `.venv-ci`), otherwise use local `.venv`.
  - **Safe checkout under act:** Workflows set `clean: false` for `actions/checkout` so `--bind` doesn’t remove local files.
  - Result: Consistent type checking and tests across local, CI, and act without hard-coding venv names into Pyright.
- **Where to look:**
  - `Makefile` targets listed above; interpreter selection and `--pythonpath` wiring.
  - `.github/workflows/python-lint-test.yml` sets `UV_PROJECT_ENVIRONMENT: .venv-ci`.
- **Future Simplifications (planned to revisit):**
  - Standardize on `.venv` in CI and remove `UV_PROJECT_ENVIRONMENT`.
  - Always invoke tools via `uv run`/`uvx` (no direct `.venv/bin/...`).
  - Avoid `act --bind` or use a separate workspace to protect local `.env`/`.venv`.
  - Use a symlink `.venv -> .venv-ci` only inside CI containers if alignment is needed.


## License

MIT License - see [LICENSE](LICENSE) file.
