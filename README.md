# llm-eng-template

Template for LLM experimentation

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
- Install dev/test toolchain with pip (no extra files): `make pip-dev-install`

---

## License

MIT License - see [LICENSE](LICENSE) file.
