#!/usr/bin/env python3
"""Create Firebase projects, register flavor apps, and write native/Dart config."""

from __future__ import annotations

import argparse
import json
import re
import shutil
import subprocess
import sys
import time
from pathlib import Path

HELPERS = Path(__file__).resolve().parent
sys.path.insert(0, str(HELPERS))

from config import (  # noqa: E402
    dump_yaml,
    is_ios_configured,
    is_placeholder,
    is_truthy,
    load_config,
    nested_get,
    nested_set,
    suggest_firebase_project_id,
)

ROOT = Path(__file__).resolve().parents[2]
CONFIG_PATH = ROOT / "project_config.yaml"


def run(cmd: list[str], *, check: bool = True, capture: bool = False) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        cmd,
        cwd=ROOT,
        check=check,
        text=True,
        capture_output=capture,
    )


def which_cmd(names: list[str]) -> list[str] | None:
    for name in names:
        path = shutil.which(name)
        if path:
            return [path]
    return None


def firebase_cmd() -> list[str]:
    found = which_cmd(["firebase"])
    if found:
        return found
    npx = shutil.which("npx")
    if npx:
        return [npx, "-y", "firebase-tools"]
    print(
        "Firebase CLI not found. Install it, then re-run:\n"
        "  npm install -g firebase-tools\n"
        "  # or: curl -sL https://firebase.tools | bash"
    )
    raise SystemExit(1)


def dart_cmd() -> list[str]:
    fvm = shutil.which("fvm")
    if fvm:
        return [fvm, "dart"]
    dart = shutil.which("dart")
    if dart:
        return [dart]
    print("Dart not found. Install Flutter / FVM, then re-run.")
    raise SystemExit(1)


def flutterfire_cmd() -> list[str]:
    found = which_cmd(["flutterfire"])
    if found:
        return found
    pub_bin = Path.home() / ".pub-cache" / "bin" / "flutterfire"
    if pub_bin.exists():
        return [str(pub_bin)]
    print("Installing flutterfire_cli (once)…")
    run(dart_cmd() + ["pub", "global", "activate", "flutterfire_cli"])
    if pub_bin.exists():
        return [str(pub_bin)]
    found = which_cmd(["flutterfire"])
    if found:
        return found
    print(
        "flutterfire is installed but not on PATH. Add this and re-run:\n"
        f"  export PATH=\"{Path.home() / '.pub-cache' / 'bin'}:$PATH\""
    )
    raise SystemExit(1)


def parse_projects_json(raw: str) -> set[str]:
    try:
        data = json.loads(raw)
    except json.JSONDecodeError:
        return {
            match.group(1)
            for match in re.finditer(r'"projectId"\s*:\s*"([^"]+)"', raw)
        }
    result: set[str] = set()

    def walk(node: object) -> None:
        if isinstance(node, dict):
            for key in ("projectId", "project_id"):
                value = node.get(key)
                if isinstance(value, str) and value:
                    result.add(value)
            for value in node.values():
                walk(value)
        elif isinstance(node, list):
            for item in node:
                walk(item)

    walk(data)
    return result


def listed_project_ids(firebase: list[str], *, strict: bool = True) -> set[str]:
    listed = run(firebase + ["projects:list", "--json"], check=False, capture=True)
    if listed.returncode == 0 and listed.stdout.strip():
        ids = parse_projects_json(listed.stdout)
        if ids:
            return ids
    listed = run(firebase + ["projects:list"], check=False, capture=True)
    if listed.returncode != 0:
        message = listed.stderr or listed.stdout or "firebase projects:list failed"
        if strict:
            print(message)
            raise SystemExit(1)
        print(message)
        return set()
    return {
        match.group(1)
        for match in re.finditer(r"│\s*([a-z0-9-]{6,30})\s*│", listed.stdout)
    }


def looks_like_auth_error(output: str) -> bool:
    lower = output.lower()
    return any(
        needle in lower
        for needle in (
            "not logged in",
            "authentication",
            "unauthenticated",
            "invalid refresh token",
            "token has been expired",
            "token expired",
            "login required",
            "http error 401",
            "failed to authenticate",
            "credentials are no longer valid",
        )
    )


def firebase_login_reauth(firebase: list[str]) -> None:
    if not sys.stdin.isatty():
        print("Not logged in to Firebase. Run `firebase login --reauth` and retry.")
        raise SystemExit(1)
    print("Firebase login required (browser will open for --reauth)…")
    run(firebase + ["login", "--reauth"])


def ensure_logged_in(firebase: list[str]) -> None:
    probe = run(firebase + ["projects:list"], check=False, capture=True)
    output = f"{probe.stdout}\n{probe.stderr}"
    if probe.returncode == 0 and not looks_like_auth_error(output):
        return
    firebase_login_reauth(firebase)
    retry = run(firebase + ["projects:list"], check=False, capture=True)
    retry_out = f"{retry.stdout}\n{retry.stderr}"
    if retry.returncode != 0 or looks_like_auth_error(retry_out):
        print(retry.stderr or retry.stdout or "firebase projects:list failed after reauth")
        raise SystemExit(1)


def project_id_taken(output: str) -> bool:
    lower = output.lower()
    return "already a project with id" in lower or "already exists" in lower


def already_firebase_project(output: str) -> bool:
    lower = output.lower()
    return any(
        needle in lower
        for needle in (
            "already has firebase",
            "already a firebase project",
            "already associated with firebase",
            "already enabled for firebase",
        )
    )


def wait_until_listed(
    firebase: list[str],
    project_id: str,
    known_ids: set[str],
    *,
    attempts: int = 12,
    delay_s: float = 5,
) -> bool:
    for attempt in range(1, attempts + 1):
        ids = listed_project_ids(firebase, strict=False)
        known_ids.update(ids)
        if project_id in known_ids:
            return True
        if attempt < attempts:
            print(
                f"Waiting for {project_id} to appear in Firebase project list "
                f"({attempt}/{attempts})…"
            )
            time.sleep(delay_s)
    return project_id in known_ids


def add_firebase(firebase: list[str], project_id: str) -> bool:
    attached = run(
        firebase + ["projects:addfirebase", project_id],
        check=False,
        capture=True,
    )
    output = f"{attached.stdout}\n{attached.stderr}"
    if attached.returncode == 0:
        print(f"Attached Firebase to GCP project {project_id}")
        return True
    if already_firebase_project(output):
        print(f"{project_id} is already a Firebase project")
        return True
    print(output.strip())
    return False


def ensure_project(
    firebase: list[str],
    *,
    project_id: str,
    display_name: str,
    existing_only: bool,
    known_ids: set[str],
) -> str:
    if project_id in known_ids:
        print(f"Using existing Firebase project {project_id}")
        return project_id
    if existing_only:
        raise SystemExit(
            f"Firebase project {project_id} is not in this account. "
            "Create it in the console, or re-run setup and choose to create projects."
        )

    candidate = project_id
    for _ in range(5):
        created = run(
            firebase
            + [
                "projects:create",
                candidate,
                "--display-name",
                display_name[:30],
            ],
            check=False,
            capture=True,
        )
        output = f"{created.stdout}\n{created.stderr}"
        if created.returncode == 0:
            print(f"Created Firebase project {candidate}")
            if not wait_until_listed(firebase, candidate, known_ids):
                print(
                    f"{candidate} was created but is not visible in projects:list yet. "
                    "Continuing; flutterfire will retry."
                )
            known_ids.add(candidate)
            return candidate
        if project_id_taken(output):
            if add_firebase(firebase, candidate) and wait_until_listed(
                firebase, candidate, known_ids
            ):
                print(f"Using existing Firebase project {candidate}")
                return candidate
            listed = listed_project_ids(firebase)
            known_ids.update(listed)
            if candidate in known_ids:
                print(f"Using existing Firebase project {candidate}")
                return candidate
            print(f"{candidate} is already taken globally.")
            if sys.stdin.isatty():
                entered = input("Enter a different project ID: ").strip()
                if entered:
                    candidate = entered
                    continue
            raise SystemExit(
                f"Pick another ID for {project_id} and re-run ./scripts/setup_firebase.sh"
            )
        print(output.strip())
        raise SystemExit(f"Failed to create Firebase project {candidate}")
    raise SystemExit(f"Could not create Firebase project {project_id}")


def configure_flavor(
    flutterfire: list[str],
    firebase: list[str],
    *,
    flavor: str,
    project_id: str,
    android_package: str,
    ios_bundle_id: str | None,
    known_ids: set[str],
) -> None:
    platforms = "android,ios" if ios_bundle_id else "android"
    cmd = [
        *flutterfire,
        "configure",
        "--yes",
        "--project",
        project_id,
        "--platforms",
        platforms,
        "--out",
        f"lib/firebase_options_{flavor}.dart",
        "--android-package-name",
        android_package,
        "--android-out",
        f"android/app/src/{flavor}/google-services.json",
    ]
    if ios_bundle_id:
        cmd.extend(
            [
                "--ios-bundle-id",
                ios_bundle_id,
                "--ios-out",
                f"ios/config/{flavor}/GoogleService-Info.plist",
            ]
        )
    print(f"Registering {flavor} apps on {project_id} ({platforms})…")
    attempts = 8
    last_code = 1
    for attempt in range(1, attempts + 1):
        wait_until_listed(firebase, project_id, known_ids, attempts=1, delay_s=0)
        configured = run(cmd, check=False)
        last_code = configured.returncode
        if configured.returncode == 0:
            break
        if attempt < attempts:
            print(
                f"flutterfire configure could not see {project_id} yet "
                f"({attempt}/{attempts}); retrying…"
            )
            time.sleep(5)
    if last_code != 0:
        raise SystemExit(f"flutterfire configure failed for {flavor}")

    stray_android = ROOT / "android/app/google-services.json"
    if stray_android.exists():
        stray_android.unlink()


def write_project_ids(config: dict, updates: dict[str, str]) -> None:
    for flavor, project_id in updates.items():
        nested_set(config, f"firebase.{flavor}.project_id", project_id)
    CONFIG_PATH.write_text(
        "# Central project identity for this Flutter app template.\n"
        "# Generated by ./scripts/setup_project.sh / ./scripts/setup_firebase.sh\n"
        "# iOS is optional: leave app.ios_bundle_id as __IOS_BUNDLE_ID__ to skip.\n\n"
        + dump_yaml(config)
        + "\n"
    )


def create_if_missing_enabled(config: dict, existing_flag: bool) -> bool:
    if existing_flag:
        return False
    return is_truthy(nested_get(config, "firebase.create_if_missing"), default=True)


def ask_yes_no(question: str, default: bool = True) -> bool:
    suffix = " [Y/n]: " if default else " [y/N]: "
    entered = input(f"{question}{suffix}").strip().lower()
    if not entered:
        return default
    return entered in {"y", "yes"}


def yaml_ids_present(config: dict, flavors: list[str]) -> bool:
    for flavor in flavors:
        value = nested_get(config, f"firebase.{flavor}.project_id")
        if not value or is_placeholder(value):
            return False
    return True


def resolve_project_id(
    config: dict,
    flavor: str,
    android_package: str,
    *,
    yes: bool,
    creating: bool,
) -> str:
    current = nested_get(config, f"firebase.{flavor}.project_id")
    if current and not is_placeholder(current):
        print(f"Using {flavor} project ID from project_config.yaml: {current}")
        return current
    if yes or not sys.stdin.isatty():
        raise SystemExit(
            f"firebase.{flavor}.project_id is missing. Run ./scripts/setup_project.sh "
            "and enter Dev/Prod project IDs."
        )
    suggested = (
        suggest_firebase_project_id(android_package, flavor)
        if creating and android_package and not is_placeholder(android_package)
        else ""
    )
    label = "Dev" if flavor == "dev" else "Prod"
    if creating:
        hint = f" [{suggested}]" if suggested else ""
        entered = input(f"Firebase {label} project ID{hint}: ").strip()
        value = entered or suggested
    else:
        entered = input(f"Existing Firebase {label} project ID: ").strip()
        value = entered
    if not value:
        raise SystemExit(f"Firebase {label} project ID is required.")
    return value


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Create Firebase projects and register Android/iOS apps for each flavor.",
    )
    parser.add_argument(
        "--existing",
        action="store_true",
        help="Do not create projects; only register apps on IDs in project_config.yaml.",
    )
    parser.add_argument("--dev", action="store_true", help="Only configure the dev flavor.")
    parser.add_argument("--prod", action="store_true", help="Only configure the prod flavor.")
    parser.add_argument("--yes", "-y", action="store_true", help="Do not prompt; require project IDs already in YAML.")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    flavors = ["dev", "prod"]
    if args.dev or args.prod:
        flavors = [flavor for flavor, wanted in (("dev", args.dev), ("prod", args.prod)) if wanted]

    if not CONFIG_PATH.exists():
        print("project_config.yaml missing. Run ./scripts/setup_project.sh first.")
        return 1

    config = load_config(CONFIG_PATH)
    android_package = nested_get(config, "app.android_package")
    if not android_package or is_placeholder(android_package):
        print("Set app.android_package and run ./scripts/setup_project.sh first.")
        return 1

    ios_enabled = is_ios_configured(config)
    ios_bundle = nested_get(config, "app.ios_bundle_id") if ios_enabled else ""
    app_name = nested_get(config, "app.name") or "App"
    android_suffix = nested_get(config, "environment.dev.android_application_id_suffix") or ".dev"
    ios_suffix = nested_get(config, "environment.dev.ios_bundle_id_suffix") or ".dev"

    firebase = firebase_cmd()
    flutterfire = flutterfire_cmd()
    ensure_logged_in(firebase)
    known_ids = listed_project_ids(firebase)

    if args.existing:
        creating = False
    elif yaml_ids_present(config, flavors):
        creating = create_if_missing_enabled(config, False)
    elif args.yes or not sys.stdin.isatty():
        print("Firebase project IDs are required in project_config.yaml.")
        print("Run ./scripts/setup_project.sh first.")
        return 1
    else:
        print("No Firebase project IDs in project_config.yaml.")
        creating = ask_yes_no("Create new Firebase projects if they do not already exist?", True)
        nested_set(config, "firebase.create_if_missing", "true" if creating else "false")
    if not creating:
        print("Registering apps on existing projects only (nothing new is created).")

    chosen: dict[str, str] = {}
    for flavor in flavors:
        chosen[flavor] = resolve_project_id(
            config,
            flavor,
            android_package,
            yes=args.yes,
            creating=creating,
        )

    display_names = {
        "dev": f"{app_name} Dev"[:30],
        "prod": app_name[:30],
    }
    android_packages = {
        "dev": f"{android_package}{android_suffix}",
        "prod": android_package,
    }
    ios_bundles = {
        "dev": f"{ios_bundle}{ios_suffix}" if ios_enabled else None,
        "prod": ios_bundle if ios_enabled else None,
    }

    for flavor in flavors:
        chosen[flavor] = ensure_project(
            firebase,
            project_id=chosen[flavor],
            display_name=display_names[flavor],
            existing_only=not creating,
            known_ids=known_ids,
        )
        configure_flavor(
            flutterfire,
            firebase,
            flavor=flavor,
            project_id=chosen[flavor],
            android_package=android_packages[flavor],
            ios_bundle_id=ios_bundles[flavor],
            known_ids=known_ids,
        )

    write_project_ids(config, chosen)

    print("\nFirebase apps registered.")
    print("Wrote google-services.json, flavor firebase_options_*.dart, and project IDs.")
    if ios_enabled:
        print("Wrote ios/config/{dev,prod}/GoogleService-Info.plist.")
    else:
        print("iOS apps skipped (no bundle ID). Re-run after setting app.ios_bundle_id.")
    print("Still in the Firebase console (both projects):")
    print("  - Enable Analytics, Crashlytics, Cloud Messaging, Remote Config")
    print("  - Publish the keys in remoteconfig.template.json")
    print("  - Add SHA-1 / SHA-256 from the upload keystore")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
