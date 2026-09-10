#!/usr/bin/env python3
"""Apply project_config.yaml to native, Dart, and env files."""

from __future__ import annotations

import datetime as dt
import json
import sys
from pathlib import Path

HELPERS = Path(__file__).resolve().parent
sys.path.insert(0, str(HELPERS))

from config import (  # noqa: E402
    dump_yaml,
    is_deeplink_configured,
    is_ios_configured,
    is_placeholder,
    is_truthy,
    load_config,
    nested_get,
    nested_set,
    suggest_firebase_project_id,
)
from replace import (  # noqa: E402
    ROOT,
    backup_files,
    load_state,
    replace_in_file,
    restore_backup,
    save_state,
)

CONFIG_PATH = ROOT / "project_config.yaml"

PROMPTS = [
    ("app.name", "App Name"),
    ("app.android_package", "Android Package Name (e.g. com.company.app)"),
    ("app.ios_bundle_id", "iOS Bundle Identifier (optional, Enter to skip)"),
    ("firebase.dev.project_id", "Firebase Dev Project ID"),
    ("firebase.prod.project_id", "Firebase Prod Project ID"),
    ("environment.dev.api_base_url", "Development API URL"),
    ("environment.prod.api_base_url", "Production API URL"),
    ("deeplink.scheme", "App Deep Link Scheme (optional, Enter skips, e.g. myapp)"),
    ("deeplink.host", "Deep Link Host (optional, Enter skips, e.g. links.myapp.com)"),
    ("app.support_email", "Support email"),
    ("app.terms_url", "Terms of Service URL"),
    ("app.privacy_url", "Privacy Policy URL"),
    ("app.refund_url", "Refund Policy URL"),
]

OPTIONAL_KEYS = {"app.ios_bundle_id", "deeplink.scheme", "deeplink.host"}
FIREBASE_ID_KEYS = {"firebase.dev.project_id", "firebase.prod.project_id"}

TARGET_FILES = [
    ROOT / "project_config.yaml",
    ROOT / "pubspec.yaml",
    ROOT / "lib/config/app_identity.dart",
    ROOT / "lib/main_dev.dart",
    ROOT / "lib/main_prod.dart",
    ROOT / "android/app/build.gradle.kts",
    ROOT / "android/app/src/main/AndroidManifest.xml",
    ROOT / "android/app/src/main/res/values/strings.xml",
    ROOT / "android/app/src/dev/google-services.json",
    ROOT / "android/app/src/prod/google-services.json",
    ROOT / "ios/Flutter/Flavor.xcconfig",
    ROOT / "ios/Runner.xcodeproj/project.pbxproj",
    ROOT / "ios/config/dev/GoogleService-Info.plist",
    ROOT / "ios/config/prod/GoogleService-Info.plist",
    ROOT / ".env.dev",
    ROOT / ".env.prod",
    ROOT / "lib/firebase_options_dev.dart",
    ROOT / "lib/firebase_options_prod.dart",
]


def ask_yes_no(question: str, default: bool = True) -> bool:
    suffix = " [Y/n]: " if default else " [y/N]: "
    entered = input(f"{question}{suffix}").strip().lower()
    if not entered:
        return default
    return entered in {"y", "yes"}


def prompt_required(label: str) -> str:
    while True:
        entered = input(f"{label}: ").strip()
        if entered:
            return entered
        print("  This value is required.")


def prompt_firebase(config: dict) -> None:
    print("\nFirebase is required. Use two projects (never share Dev and Prod).")
    create = ask_yes_no("Create new Firebase projects if they do not already exist?", True)
    nested_set(config, "firebase.create_if_missing", "true" if create else "false")
    android = nested_get(config, "app.android_package")
    for flavor, label in (("dev", "Dev"), ("prod", "Prod")):
        key = f"firebase.{flavor}.project_id"
        current = nested_get(config, key)
        existing = "" if is_placeholder(current) else current
        suggested = (
            suggest_firebase_project_id(android, flavor)
            if android and not is_placeholder(android)
            else ""
        )
        if create:
            hint = existing or suggested
            entered = input(f"Firebase {label} project ID [{hint}]: ").strip()
            value = entered or existing or suggested
            if not value:
                value = prompt_required(f"Firebase {label} project ID")
        else:
            hint = f" [{existing}]" if existing else ""
            entered = input(f"Existing Firebase {label} project ID{hint}: ").strip()
            value = entered or existing
            if not value:
                value = prompt_required(f"Existing Firebase {label} project ID")
        nested_set(config, key, value)
    if create:
        print("  setup_firebase.sh will create these projects if they are missing.\n")
    else:
        print("  setup_firebase.sh will only register apps on these existing projects.\n")


def prompt(config: dict) -> dict:
    print("\nFlutter App Template setup")
    print("Press Enter to keep the current value in brackets.")
    print("iOS bundle ID is optional — Enter skips iOS setup.")
    print("Deep-link scheme and host are optional — Enter skips App Links.")
    print("Firebase project IDs are required.\n")
    firebase_prompted = False
    for key, label in PROMPTS:
        if key in FIREBASE_ID_KEYS:
            if not firebase_prompted:
                prompt_firebase(config)
                firebase_prompted = True
            continue
        current = nested_get(config, key)
        display = "" if is_placeholder(current) else current
        entered = input(f"{label} [{display}]: ").strip()
        if entered:
            nested_set(config, key, entered)
        elif is_placeholder(current):
            extra = ""
            if key == "app.ios_bundle_id":
                extra = " — iOS setup will be skipped"
            elif key in {"deeplink.scheme", "deeplink.host"}:
                extra = " — deep links stay disabled"
            print(f"  skipped (still {current}){extra}")
    return config


def slug_dart_package(name: str) -> str:
    cleaned = "".join(ch.lower() if ch.isalnum() else "_" for ch in name)
    cleaned = "_".join(part for part in cleaned.split("_") if part)
    if cleaned and cleaned[0].isdigit():
        cleaned = f"app_{cleaned}"
    return cleaned or "app_template"


def write_identity(config: dict) -> None:
    path = ROOT / "lib/config/app_identity.dart"
    app_name = nested_get(config, "app.name")
    dart_package = nested_get(config, "app.dart_package") or "app_template"
    contents = f"""/// Compile-time app identity generated from [project_config.yaml].
///
/// Generated by ./scripts/setup_project.sh on {dt.date.today().isoformat()}.
class AppIdentity {{
  AppIdentity._();

  static const String appName = {json.dumps(app_name)};
  static const String dartPackage = {json.dumps(dart_package)};
  static const String androidPackage = {json.dumps(nested_get(config, "app.android_package"))};
  static const String iosBundleId = {json.dumps(nested_get(config, "app.ios_bundle_id"))};
  static const String supportEmail = {json.dumps(nested_get(config, "app.support_email"))};
  static const String termsUrl = {json.dumps(nested_get(config, "app.terms_url"))};
  static const String privacyUrl = {json.dumps(nested_get(config, "app.privacy_url"))};
  static const String refundUrl = {json.dumps(nested_get(config, "app.refund_url"))};
  static const String deeplinkScheme = {json.dumps(nested_get(config, "deeplink.scheme"))};
  static const String deeplinkHost = {json.dumps(nested_get(config, "deeplink.host"))};
}}
"""
    path.write_text(contents)


def _existing_env_value(path: Path, key: str) -> str:
    if not path.exists():
        return ""
    prefix = f"{key}="
    for line in path.read_text().splitlines():
        if line.startswith(prefix):
            return line[len(prefix) :]
    return ""


def write_env(path: Path, api_url: str, mixpanel: str, region: str) -> None:
    payments_base = _existing_env_value(path, "PAYMENTS_BASE_URL")
    payments_tenant = _existing_env_value(path, "PAYMENTS_TENANT_ID")
    auth_base = _existing_env_value(path, "AUTH_BASE_URL")
    auth_tenant = _existing_env_value(path, "AUTH_TENANT_ID")
    truecaller_client_id = _existing_env_value(path, "TRUECALLER_CLIENT_ID")
    growthbook_host = _existing_env_value(path, "GROWTHBOOK_HOST_URL")
    growthbook_key = _existing_env_value(path, "GROWTHBOOK_API_KEY")
    slack_token = _existing_env_value(path, "SLACK_API_TOKEN")
    slack_channel = _existing_env_value(path, "SLACK_CHANNEL_ID")
    path.write_text(
        "\n".join(
            [
                f"MIXPANEL_TOKEN={mixpanel}",
                "USE_FIREBASE_EMULATORS=false",
                "FIREBASE_EMULATOR_HOST=127.0.0.1",
                f"FIREBASE_FUNCTIONS_REGION={region}",
                f"API_BASE_URL={api_url}",
                f"PAYMENTS_BASE_URL={payments_base}",
                f"PAYMENTS_TENANT_ID={payments_tenant}",
                f"AUTH_BASE_URL={auth_base}",
                f"AUTH_TENANT_ID={auth_tenant}",
                f"TRUECALLER_CLIENT_ID={truecaller_client_id}",
                f"GROWTHBOOK_HOST_URL={growthbook_host or 'https://cdn.growthbook.io/'}",
                f"GROWTHBOOK_API_KEY={growthbook_key}",
                f"SLACK_API_TOKEN={slack_token}",
                f"SLACK_CHANNEL_ID={slack_channel}",
                "",
            ]
        )
    )


def _xml_escape(value: str) -> str:
    return (
        value.replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
        .replace('"', "&quot;")
        .replace("'", "&apos;")
    )


def write_truecaller_xml(path: Path, client_id: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        "\n".join(
            [
                '<?xml version="1.0" encoding="utf-8"?>',
                "<resources>",
                f'    <string name="truecaller_client_id">{_xml_escape(client_id)}</string>',
                "</resources>",
                "",
            ]
        )
    )


def apply(config: dict, previous: dict) -> None:
    old_android = nested_get(previous, "app.android_package") or "com.example.app_template"
    new_android = nested_get(config, "app.android_package")
    old_ios = nested_get(previous, "app.ios_bundle_id") or "com.example.appTemplate"
    new_ios = nested_get(config, "app.ios_bundle_id")
    old_name = nested_get(previous, "app.name") or "App Template"
    new_name = nested_get(config, "app.name")
    old_scheme = nested_get(previous, "deeplink.scheme") or "__APP_SCHEME__"
    new_scheme = nested_get(config, "deeplink.scheme")
    old_host = nested_get(previous, "deeplink.host") or "__DEEPLINK_HOST__"
    new_host = nested_get(config, "deeplink.host")
    old_dart = nested_get(previous, "app.dart_package") or "app_template"
    new_dart = nested_get(config, "app.dart_package") or slug_dart_package(new_name)

    nested_set(config, "app.dart_package", new_dart)
    if not nested_get(config, "environment.dev.display_name"):
        nested_set(config, "environment.dev.display_name", f"{new_name} Dev")
    if not nested_get(config, "environment.prod.display_name"):
        nested_set(config, "environment.prod.display_name", new_name)

    dart_files = list((ROOT / "lib").rglob("*.dart")) + list((ROOT / "test").rglob("*.dart"))
    if old_dart != new_dart:
        for path in dart_files + [ROOT / "pubspec.yaml"]:
            replace_in_file(path, f"package:{old_dart}/", f"package:{new_dart}/")
        replace_in_file(ROOT / "pubspec.yaml", f"name: {old_dart}", f"name: {new_dart}")

    gradle = ROOT / "android/app/build.gradle.kts"
    replace_in_file(
        gradle,
        f'applicationId = "{old_android}"',
        f'applicationId = "{new_android}"',
    )
    replace_in_file(gradle, f'resValue("string", "app_name", "{old_name} Dev")', f'resValue("string", "app_name", "{new_name} Dev")')
    replace_in_file(gradle, f'resValue("string", "app_name", "{old_name}")', f'resValue("string", "app_name", "{new_name}")')

    replace_in_file(ROOT / "android/app/src/main/res/values/strings.xml", f">{old_name}<", f">{new_name}<")
    if new_scheme and not is_placeholder(new_scheme):
        replace_in_file(ROOT / "android/app/src/main/AndroidManifest.xml", old_scheme, new_scheme)
        replace_in_file(ROOT / "android/app/src/main/AndroidManifest.xml", "__APP_SCHEME__", new_scheme)
    if new_host and not is_placeholder(new_host):
        replace_in_file(ROOT / "android/app/src/main/AndroidManifest.xml", old_host, new_host)
        replace_in_file(ROOT / "android/app/src/main/AndroidManifest.xml", "__DEEPLINK_HOST__", new_host)

    replace_in_file(ROOT / "android/app/src/dev/google-services.json", f"{old_android}.dev", f"{new_android}.dev")
    replace_in_file(ROOT / "android/app/src/dev/google-services.json", old_android, new_android)
    replace_in_file(ROOT / "android/app/src/prod/google-services.json", old_android, new_android)
    replace_in_file(
        ROOT / "android/app/src/dev/google-services.json",
        nested_get(previous, "firebase.dev.project_id") or "__DEV_FIREBASE_PROJECT_ID__",
        nested_get(config, "firebase.dev.project_id"),
    )
    replace_in_file(
        ROOT / "android/app/src/prod/google-services.json",
        nested_get(previous, "firebase.prod.project_id") or "__PROD_FIREBASE_PROJECT_ID__",
        nested_get(config, "firebase.prod.project_id"),
    )

    flavor = ROOT / "ios/Flutter/Flavor.xcconfig"
    bundle_id = new_ios if is_ios_configured(config) else "com.example.appTemplate"
    flavor.write_text(
        "\n".join(
            [
                f"APP_DISPLAY_NAME = {new_name}",
                f"APP_URL_SCHEME = {new_scheme}",
                f"PRODUCT_BUNDLE_IDENTIFIER = {bundle_id}",
                "",
            ]
        )
    )
    if is_ios_configured(config):
        replace_in_file(ROOT / "ios/Runner.xcodeproj/project.pbxproj", old_ios, new_ios)
        replace_in_file(ROOT / "ios/config/dev/GoogleService-Info.plist", old_ios, new_ios)
        replace_in_file(ROOT / "ios/config/prod/GoogleService-Info.plist", old_ios, new_ios)
        replace_in_file(
            ROOT / "ios/config/dev/GoogleService-Info.plist",
            nested_get(previous, "firebase.dev.project_id") or "__DEV_FIREBASE_PROJECT_ID__",
            nested_get(config, "firebase.dev.project_id"),
        )
        replace_in_file(
            ROOT / "ios/config/prod/GoogleService-Info.plist",
            nested_get(previous, "firebase.prod.project_id") or "__PROD_FIREBASE_PROJECT_ID__",
            nested_get(config, "firebase.prod.project_id"),
        )

    for options, key in (
        (ROOT / "lib/firebase_options_dev.dart", "firebase.dev.project_id"),
        (ROOT / "lib/firebase_options_prod.dart", "firebase.prod.project_id"),
    ):
        old_id = nested_get(previous, key) or (
            "__DEV_FIREBASE_PROJECT_ID__" if "dev" in options.name else "__PROD_FIREBASE_PROJECT_ID__"
        )
        replace_in_file(options, old_id, nested_get(config, key))
        if is_ios_configured(config):
            replace_in_file(options, old_ios, new_ios)
            replace_in_file(options, "__IOS_BUNDLE_ID__", new_ios)

    region = nested_get(config, "firebase.functions_region") or "asia-south1"
    write_env(
        ROOT / ".env.dev",
        nested_get(config, "environment.dev.api_base_url"),
        nested_get(config, "analytics.mixpanel.dev_token"),
        region,
    )
    write_env(
        ROOT / ".env.prod",
        nested_get(config, "environment.prod.api_base_url"),
        nested_get(config, "analytics.mixpanel.prod_token"),
        region,
    )
    write_truecaller_xml(
        ROOT / "android/app/src/dev/res/values/truecaller.xml",
        _existing_env_value(ROOT / ".env.dev", "TRUECALLER_CLIENT_ID"),
    )
    write_truecaller_xml(
        ROOT / "android/app/src/prod/res/values/truecaller.xml",
        _existing_env_value(ROOT / ".env.prod", "TRUECALLER_CLIENT_ID"),
    )
    write_identity(config)


def main() -> int:
    non_interactive = "--yes" in sys.argv or "-y" in sys.argv
    config = load_config(CONFIG_PATH)
    previous = load_state() or {
        "app": {
            "name": "App Template",
            "dart_package": "app_template",
            "android_package": "com.example.app_template",
            "ios_bundle_id": "com.example.appTemplate",
        },
        "deeplink": {"scheme": "__APP_SCHEME__", "host": "__DEEPLINK_HOST__"},
        "firebase": {
            "create_if_missing": True,
            "dev": {"project_id": "__DEV_FIREBASE_PROJECT_ID__"},
            "prod": {"project_id": "__PROD_FIREBASE_PROJECT_ID__"},
        },
    }

    if not non_interactive and sys.stdin.isatty():
        config = prompt(config)

    missing = [
        key
        for key, _ in PROMPTS
        if key not in OPTIONAL_KEYS and is_placeholder(nested_get(config, key))
    ]
    if missing:
        print("Setup did not finish: placeholders remain in project_config.yaml:")
        for key in missing:
            print(f"  - {key} = {nested_get(config, key)}")
        print("\nEdit project_config.yaml or re-run ./scripts/setup_project.sh")
        return 1

    if not nested_get(config, "app.dart_package"):
        nested_set(config, "app.dart_package", slug_dart_package(nested_get(config, "app.name")))
    if not nested_get(config, "firebase.create_if_missing"):
        nested_set(config, "firebase.create_if_missing", "true")

    files_to_backup = list(TARGET_FILES)
    files_to_backup.extend((ROOT / "lib").rglob("*.dart"))
    files_to_backup.extend((ROOT / "test").rglob("*.dart"))
    backup_files(files_to_backup)
    try:
        apply(config, previous)
        CONFIG_PATH.write_text(
            "# Central project identity for this Flutter app template.\n"
            "# Generated by ./scripts/setup_project.sh\n"
            "# iOS is optional: leave app.ios_bundle_id as __IOS_BUNDLE_ID__ to skip.\n"
            "# Deep links are optional: leave deeplink.scheme / host placeholders to skip.\n\n"
            + dump_yaml(config)
            + "\n"
        )
        save_state(config)
    except Exception as error:  # noqa: BLE001
        restore_backup()
        print(f"Setup failed and was rolled back from .setup_backup: {error}")
        return 1

    print("\nProject configured.")
    if not is_ios_configured(config):
        print("iOS setup skipped. Re-run ./scripts/setup_project.sh and set the bundle ID when you need iOS.")
    if not is_deeplink_configured(config):
        print("Deep links skipped. Re-run setup and set scheme + host when you need App Links.")
    create = is_truthy(nested_get(config, "firebase.create_if_missing"), default=True)
    print("Next: ./scripts/setup_firebase.sh (required — uses the Firebase project IDs above).")
    if create:
        print("  Missing projects will be created.")
    else:
        print("  Apps will be registered on the existing projects; nothing new is created.")
    if not non_interactive and sys.stdin.isatty() and ask_yes_no("Run Firebase setup now?", True):
        import subprocess

        result = subprocess.run([str(ROOT / "scripts/setup_firebase.sh")], cwd=ROOT)
        if result.returncode != 0:
            print("Firebase setup did not finish. Re-run ./scripts/setup_firebase.sh")
            return result.returncode
    else:
        print("  1. ./scripts/setup_firebase.sh")
        print("  2. ./scripts/validate_config.sh")
        print("  3. flutter run --flavor dev -t lib/main_dev.dart")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
