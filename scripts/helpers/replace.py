#!/usr/bin/env python3
"""Targeted, idempotent identifier replacements for the Flutter template."""

from __future__ import annotations

import json
import shutil
from pathlib import Path
from typing import Iterable

ROOT = Path(__file__).resolve().parents[2]
STATE_PATH = ROOT / ".setup_state.json"
BACKUP_DIR = ROOT / ".setup_backup"


def load_state() -> dict:
    if STATE_PATH.exists():
        return json.loads(STATE_PATH.read_text())
    return {}


def save_state(state: dict) -> None:
    STATE_PATH.write_text(json.dumps(state, indent=2) + "\n")


def backup_files(paths: Iterable[Path]) -> Path:
    if BACKUP_DIR.exists():
        shutil.rmtree(BACKUP_DIR)
    BACKUP_DIR.mkdir(parents=True)
    copied = []
    for path in paths:
        if not path.exists() or not path.is_file():
            continue
        rel = path.relative_to(ROOT)
        dest = BACKUP_DIR / rel
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(path, dest)
        copied.append(str(rel))
    (BACKUP_DIR / "manifest.json").write_text(json.dumps(copied, indent=2))
    return BACKUP_DIR


def restore_backup() -> None:
    if not BACKUP_DIR.exists():
        return
    manifest = json.loads((BACKUP_DIR / "manifest.json").read_text())
    for rel in manifest:
        src = BACKUP_DIR / rel
        dest = ROOT / rel
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dest)


def replace_in_file(path: Path, old: str, new: str) -> int:
    if not old or old == new or not path.exists():
        return 0
    original = path.read_text()
    if old not in original:
        return 0
    updated = original.replace(old, new)
    path.write_text(updated)
    return original.count(old)


def replace_once_line(path: Path, key_prefix: str, new_line: str) -> None:
    """Replace a single assignment/line that starts with key_prefix."""
    if not path.exists():
        return
    lines = path.read_text().splitlines()
    found = False
    for i, line in enumerate(lines):
        stripped = line.lstrip()
        if stripped.startswith(key_prefix):
            indent = line[: len(line) - len(stripped)]
            lines[i] = f"{indent}{new_line}"
            found = True
            break
    if found:
        path.write_text("\n".join(lines) + "\n")
