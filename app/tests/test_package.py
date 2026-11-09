"""Smoke test: the package and its placeholder modules import cleanly."""

import importlib

import liken_benchmark


def test_package_imports() -> None:
    assert liken_benchmark is not None


def test_placeholder_modules_import() -> None:
    for name in ("schema", "generate", "harness", "cli"):
        module = importlib.import_module(f"liken_benchmark.{name}")
        assert module is not None
