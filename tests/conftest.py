#!/usr/bin/env python3
"""Root-level pytest configuration and fixtures."""

from __future__ import annotations
import logging
from pathlib import Path
from rich.console import Console
import pytest

REPORTS_DIR = Path("reports")
LOGS_DIR = REPORTS_DIR / "logs"


def pytest_sessionstart(session: pytest.Session) -> None:  # noqa: D401
    """Ensure report directories exist; preserve service URLs in local runs."""
    REPORTS_DIR.mkdir(parents=True, exist_ok=True)
    LOGS_DIR.mkdir(parents=True, exist_ok=True)


# Set up a logger for this module
logger = logging.getLogger(__name__)
console = Console()
