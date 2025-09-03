##########
# Two-stage build: builder (Python deps) → runtime (OS deps + app)
##########

# ---------- Builder stage: resolve and install Python deps + package into a venv ----------
# Use uv's official image (includes uv + Python)
FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim AS builder

ENV VENV_PATH=/opt/venv
WORKDIR /app

COPY pyproject.toml uv.lock ./

ENV UV_PROJECT_ENVIRONMENT=${VENV_PATH}
ENV PATH="${VENV_PATH}/bin:${PATH}"

RUN uv sync --frozen --no-install-project
# Install full environment (includes dev + test) in one step
# Requires project sources to be present so uv can install the package
COPY backend/ /app/backend/
COPY frontend/ /app/frontend/
RUN uv sync --frozen --group dev --group test

# ---------- Final runtime stage: minimal runtime with only what we need ----------
FROM python:3.12.3-slim AS runtime

# Install OS runtime dependencies (unpinned to avoid snapshot churn)
# hadolint ignore=DL3008
RUN apt-get update \
    && apt-get install -y --no-install-recommends wget \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ENV VENV_PATH=/opt/venv
ENV PATH="${VENV_PATH}/bin:${PATH}"

WORKDIR /app

# Bring in the prebuilt virtualenv from the builder stage
COPY --from=builder ${VENV_PATH} ${VENV_PATH}

# Model caching configuration
ENV HF_HOME=/data/hf

# Container-native healthcheck for Streamlit readiness
HEALTHCHECK --interval=5s --timeout=3s --start-period=30s --retries=30 \
  CMD wget -q --spider http://localhost:8501/_stcore/health || exit 1

# Create non-root user and directories, and set permissions
RUN useradd -ms /bin/bash appuser \
    && mkdir -p backend frontend logs /data/hf \
    && chown -R appuser:appuser /app

USER appuser

CMD ["python", "-m", "backend.main"]
