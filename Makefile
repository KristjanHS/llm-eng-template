.PHONY: help setup-hooks setup-uv integration-local export-reqs pip-dev-install

# Use bash with strict flags for recipes
SHELL := bash
.SHELLFLAGS := -euo pipefail -c

# Stable project/session handling
LOG_DIR := logs

help:
	@echo "Available targets:"
	@echo "  setup-hooks        - Configure Git hooks path"
	@echo "  setup-uv           - Create venv and sync dev/test via uv"
	@echo "  integration-local  - Run integration tests (uv preferred)"
	@echo "  export-reqs        - Export runtime requirements.txt from uv.lock"
	@echo "  pip-dev-install    - pip install base + editable + dev/test (via uv export)"

setup-hooks:
	@echo "Configuring Git hooks path..."
	@git config core.hooksPath scripts/git-hooks
	@echo "Done."

# uv-based setup
setup-uv:
	@./run_uv.sh

# Run local integration tests; prefer uv if available
integration-local:
	@if command -v uv >/dev/null 2>&1; then \
		uv run -m pytest tests/integration -q ${PYTEST_ARGS}; \
	else \
		echo "uv not found. Either install uv (https://astral.sh/uv) and run './run_uv.sh', or run 'make pip-dev-install' then '.venv/bin/python -m pytest tests/integration -q ${PYTEST_ARGS}'"; \
		exit 1; \
	fi

# Export a pip-compatible requirements.txt from uv.lock (runtime only)
export-reqs:
	@echo ">> Exporting requirements.txt from uv.lock (no dev/test groups)"
	@uv export --format requirements-txt > requirements.txt

# Installs: uv dev+test groups, base runtime (-r requirements.txt), editable project (-e .)
pip-dev-install: export-reqs
	@echo ">> pip installing base + editable + dev/test (via uv export)"
	@uv export --group dev --group test --format requirements-txt | pip install -r requirements.txt -e . -r /dev/stdin
