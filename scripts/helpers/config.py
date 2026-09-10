#!/usr/bin/env python3
"""Parse and write the template's project_config.yaml without extra deps."""

from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any

PLACEHOLDER_PREFIX = "__"


def parse_yaml(text: str) -> dict[str, Any]:
    """Parse a restricted YAML subset: nested maps and quoted/plain scalars."""
    lines = []
    for raw in text.splitlines():
        stripped = raw.split("#", 1)[0].rstrip()
        if stripped.strip():
            lines.append(stripped)

    root: dict[str, Any] = {}
    stack: list[tuple[int, dict[str, Any]]] = [(-1, root)]

    for line in lines:
        indent = len(line) - len(line.lstrip(" "))
        content = line.strip()
        if ":" not in content:
            raise ValueError(f"Unsupported YAML line: {line}")
        key, value = content.split(":", 1)
        key = key.strip()
        value = value.strip()

        while stack and indent <= stack[-1][0]:
            stack.pop()
        parent = stack[-1][1]

        if value == "":
            child: dict[str, Any] = {}
            parent[key] = child
            stack.append((indent, child))
        else:
            parent[key] = _parse_scalar(value)
    return root


def _parse_scalar(value: str) -> Any:
    if (value.startswith('"') and value.endswith('"')) or (
        value.startswith("'") and value.endswith("'")
    ):
        return value[1:-1]
    if value.lower() in {"true", "false"}:
        return value.lower() == "true"
    if value.lower() in {"null", "~"}:
        return None
    return value


def dump_yaml(data: dict[str, Any], indent: int = 0) -> str:
    lines: list[str] = []
    prefix = "  " * indent
    for key, value in data.items():
        if isinstance(value, dict):
            lines.append(f"{prefix}{key}:")
            dumped = dump_yaml(value, indent + 1)
            if dumped:
                lines.append(dumped)
        elif isinstance(value, bool):
            lines.append(f"{prefix}{key}: {'true' if value else 'false'}")
        else:
            lines.append(f"{prefix}{key}: {json.dumps(str(value) if value is not None else '')}")
    return "\n".join(lines)


def load_config(path: Path) -> dict[str, Any]:
    return parse_yaml(path.read_text())


def is_placeholder(value: Any) -> bool:
    return isinstance(value, str) and value.startswith(PLACEHOLDER_PREFIX) and value.endswith(PLACEHOLDER_PREFIX)


def is_ios_configured(config: dict[str, Any]) -> bool:
    """iOS identity is optional until a real bundle ID is set."""
    bundle = nested_get(config, "app.ios_bundle_id")
    return bool(bundle) and not is_placeholder(bundle)


def is_deeplink_configured(config: dict[str, Any]) -> bool:
    """Custom scheme / App Links host are optional until both are set."""
    scheme = nested_get(config, "deeplink.scheme")
    host = nested_get(config, "deeplink.host")
    return bool(scheme) and not is_placeholder(scheme) and bool(host) and not is_placeholder(host)


def is_truthy(value: str, default: bool = False) -> bool:
    if not value:
        return default
    return value.strip().lower() in {"true", "yes", "1", "y"}


def suggest_firebase_project_id(android_package: str, flavor: str) -> str:
    parts = [p for p in android_package.lower().replace("_", "-").split(".") if p]
    base = "-".join(parts[-2:] if len(parts) >= 2 else parts)
    base = re.sub(r"[^a-z0-9-]", "", base).strip("-") or "app"
    suffix = f"-{flavor}"
    max_base = 30 - len(suffix)
    base = base[:max_base].strip("-")
    if len(base) < 4:
        base = f"app-{base}"[:max_base].strip("-")
    return f"{base}{suffix}"


def nested_get(data: dict[str, Any], dotted: str, default: str = "") -> str:
    current: Any = data
    for part in dotted.split("."):
        if not isinstance(current, dict) or part not in current:
            return default
        current = current[part]
    if current is None:
        return default
    return str(current)


def nested_set(data: dict[str, Any], dotted: str, value: str) -> None:
    parts = dotted.split(".")
    current = data
    for part in parts[:-1]:
        current = current.setdefault(part, {})
    current[parts[-1]] = value
