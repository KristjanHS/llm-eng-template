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

## License

MIT License - see [LICENSE](LICENSE) file.
