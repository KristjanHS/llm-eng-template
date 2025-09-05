# Declare phony targets (grouped for readability)
# Meta
.PHONY: help
# Setup
.PHONY: setup-hooks setup-uv export-reqs uv-export
# Lint / Type Check
.PHONY: ruff-format ruff-fix yamlfmt pyright pre-commit
# Tests
.PHONY: unit-local integration-local
# Security / CI linters
.PHONY: pip-audit semgrep-local actionlint
# CI helpers and Git
.PHONY: uv-sync-test pre-push

# Use bash with strict flags for recipes
SHELL := bash
.SHELLFLAGS := -euo pipefail -c

# Stable project/session handling
LOG_DIR := logs

help:
	@echo "Available targets:"
	@echo "  -- Setup --"
	@echo "  setup-hooks        - Configure Git hooks path"
	@echo "  setup-uv           - Create venv and sync dev/test via uv"
	@echo "  export-reqs        - Export requirements.txt from uv.lock"
	@echo ""
	@echo "  -- Lint & Type Check --"
	@echo "  ruff-format        - Auto-format code with Ruff"
	@echo "  ruff-fix           - Run Ruff lint with autofix"
	@echo "  yamlfmt            - Validate YAML formatting via pre-commit"
	@echo "  pyright            - Run Pyright type checking"
	@echo "  pre-commit         - Run all pre-commit hooks on all files"
	@echo ""
	@echo "  -- Tests --"
	@echo "  unit-local         - Run unit tests (local) and write reports"
	@echo "  integration-local  - Run integration tests (uv preferred)"
	@echo ""
	@echo "  -- Security / CI linters --"
	@echo "  pip-audit          - Export from uv.lock and audit prod/dev+test deps"
	@echo "  semgrep-local      - Run Semgrep locally via uvx (no metrics)"
	@echo "  actionlint         - Lint GitHub workflows using actionlint in Docker"
	@echo ""
	@echo "  -- CI helpers & Git --"
	@echo "  uv-sync-test       - uv sync test group (frozen) + pip check"
	@echo "  pre-push           - Run pre-push checks with all SKIP=0"

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
		echo "uv not found. Either install uv (https://astral.sh/uv) and run './run_uv.sh', or ensure your venv is set up then run '.venv/bin/python -m pytest tests/integration -q ${PYTEST_ARGS}'"; \
		exit 1; \
	fi

# Export a pip-compatible requirements.txt from uv.lock
export-reqs:
	@echo ">> Exporting requirements.txt from uv.lock (no dev/test groups)"
	@uv export --group dev --group test --format requirements-txt > requirements.txt

# --- CI helper targets (used by workflows) -----------------------------------

uv-sync-test:
	uv sync --group test --frozen
	uv pip check

# New canonical unit test target
unit-local:
	mkdir -p reports
	@if [ -x .venv/bin/python ]; then \
		.venv/bin/python -m pytest tests/unit -n auto --maxfail=1 -q --junitxml=reports/junit.xml ${PYTEST_ARGS}; \
	else \
		uv run -m pytest tests/unit -n auto --maxfail=1 -q --junitxml=reports/junit.xml ${PYTEST_ARGS}; \
	fi


pyright:
	@if [ -x .venv/bin/pyright ]; then \
		.venv/bin/pyright --project ./pyrightconfig.json; \
	else \
		uvx pyright --project ./pyrightconfig.json; \
	fi

pip-audit:
	@echo ">> Exporting prod requirements from uv.lock"
	uv export --format=requirements-txt --locked > requirements-ci.txt
	@echo ">> Exporting dev+test requirements from uv.lock"
	uv export --format=requirements-txt --locked --group dev --group test > requirements-dev-test-ci.txt
	@echo ">> Auditing prod requirements"
	PIP_EXTRA_INDEX_URL=${PIP_EXTRA_INDEX_URL} uvx --from pip-audit pip-audit -r requirements-ci.txt
	@echo ">> Auditing dev+test requirements"
	PIP_EXTRA_INDEX_URL=${PIP_EXTRA_INDEX_URL} uvx --from pip-audit pip-audit -r requirements-dev-test-ci.txt

yamlfmt:
	uv sync --group dev --frozen
	uv run pre-commit run yamlfmt -a

# Ruff targets (use uv-run to avoid global installs)
ruff-format:
	@if [ -x .venv/bin/ruff ]; then \
		.venv/bin/ruff format .; \
	else \
		uv run ruff format .; \
	fi

ruff-fix:
	@if [ -x .venv/bin/ruff ]; then \
		.venv/bin/ruff check --fix .; \
	else \
		uv run ruff check --fix .; \
	fi

# Run full pre-commit suite (dev deps required)
pre-commit:
	uv sync --group dev --frozen
	uv run pre-commit run --all-files

# Run the same checks as the Git pre-push hook, forcing all SKIP flags to 0
pre-push:
	SKIP_LOCAL_SEC_SCANS=0 SKIP_LINT=0 SKIP_PYRIGHT=0 SKIP_TESTS=0 scripts/git-hooks/pre-push

# Lint GitHub Actions workflows locally using official container
actionlint:
	@docker run --rm \
		--user "$(shell id -u):$(shell id -g)" \
		-v "$(CURDIR)":/repo \
		-w /repo \
		rhysd/actionlint:latest -color && echo "Actionlint: no issues found"

# Run Semgrep locally using uvx, mirroring the local workflow
semgrep-local:
	@if command -v uv >/dev/null 2>&1; then \
		uvx --from semgrep semgrep ci \
		  --config auto \
		  --metrics off \
		  --sarif \
		  --output semgrep_local.sarif; \
		echo "Semgrep SARIF written to semgrep_local.sarif"; \
		if command -v jq >/dev/null 2>&1; then \
		  COUNT=$$(jq '[.runs[0].results[]] | length' semgrep_local.sarif 2>/dev/null || echo 0); \
		  echo "Semgrep findings: $${COUNT} (see semgrep_local.sarif)"; \
		else \
		  COUNT=$$(grep -o '"ruleId"' -c semgrep_local.sarif 2>/dev/null || echo 0); \
		  echo "Semgrep findings: $${COUNT} (approx; no jq)"; \
		fi; \
	else \
		echo "uv not found. Install uv: https://astral.sh/uv"; \
		exit 1; \
	fi
