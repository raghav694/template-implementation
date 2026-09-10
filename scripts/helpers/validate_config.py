#!/usr/bin/env python3
"""Validate that a cloned template has been configured."""

from __future__ import annotations

import re
import sys
from pathlib import Path

HELPERS = Path(__file__).resolve().parent
sys.path.insert(0, str(HELPERS))

from config import (  # noqa: E402
    is_deeplink_configured,
    is_ios_configured,
    is_placeholder,
    load_config,
    nested_get,
)

ROOT = Path(__file__).resolve().parents[2]
failures: list[tuple[str, str, str]] = []


def fail(title: str, expected: str, hint: str) -> None:
    failures.append((title, expected, hint))


def check_placeholder(label: str, value: str, hint: str) -> None:
    if not value or is_placeholder(value):
        fail(label, value or "(empty)", hint)


def check_package(label: str, value: str) -> None:
    if not re.fullmatch(r"[a-zA-Z][a-zA-Z0-9_]*(\.[a-zA-Z][a-zA-Z0-9_]*)+", value or ""):
        fail(
            label,
            value,
            "Use reverse-DNS form like com.company.app. Letters, digits, and underscores only.",
        )


def check_file(path: Path, title: str, hint: str) -> None:
    if not path.exists():
        fail(title, str(path.relative_to(ROOT)), hint)


def file_contains(path: Path, needle: str) -> bool:
    return path.exists() and needle in path.read_text()


def main() -> int:
    config_path = ROOT / "project_config.yaml"
    if not config_path.exists():
        fail("project_config.yaml missing", "project_config.yaml", "Restore it from the template.")
        _print_failures()
        return 1

    config = load_config(config_path)
    check_placeholder("App name", nested_get(config, "app.name"), "Set app.name in project_config.yaml and re-run setup.")
    check_placeholder("Android package", nested_get(config, "app.android_package"), "Set app.android_package then ./scripts/setup_project.sh")
    check_placeholder("Dev API URL", nested_get(config, "environment.dev.api_base_url"), "Set environment.dev.api_base_url")
    check_placeholder("Prod API URL", nested_get(config, "environment.prod.api_base_url"), "Set environment.prod.api_base_url")
    check_placeholder(
        "Firebase Dev project",
        nested_get(config, "firebase.dev.project_id"),
        "Run ./scripts/setup_firebase.sh (or set firebase.dev.project_id)",
    )
    check_placeholder(
        "Firebase Prod project",
        nested_get(config, "firebase.prod.project_id"),
        "Run ./scripts/setup_firebase.sh (or set firebase.prod.project_id)",
    )
    check_package("Android package format", nested_get(config, "app.android_package"))
    ios_enabled = is_ios_configured(config)
    deeplink_enabled = is_deeplink_configured(config)
    if deeplink_enabled:
        check_placeholder("Deep link scheme", nested_get(config, "deeplink.scheme"), "Set deeplink.scheme")
        check_placeholder("Deep link host", nested_get(config, "deeplink.host"), "Set deeplink.host")
    if ios_enabled:
        check_placeholder("iOS bundle id", nested_get(config, "app.ios_bundle_id"), "Set app.ios_bundle_id then ./scripts/setup_project.sh")
        check_package("iOS bundle id format", nested_get(config, "app.ios_bundle_id"))

    gradle = (ROOT / "android/app/build.gradle.kts").read_text()
    if 'create("dev")' not in gradle or 'create("prod")' not in gradle:
        fail(
            "Android flavors missing",
            'productFlavors { create("dev") ... create("prod") }',
            "Restore android/app/build.gradle.kts flavor blocks from the template.",
        )
    if nested_get(config, "app.android_package") not in gradle and not is_placeholder(nested_get(config, "app.android_package")):
        fail(
            "Android applicationId not applied",
            nested_get(config, "app.android_package"),
            "Run ./scripts/setup_project.sh so Gradle picks up the package name.",
        )

    for flavor, placeholder in (("dev", "REPLACE_ME_DEV_ANDROID_API_KEY"), ("prod", "REPLACE_ME_PROD_ANDROID_API_KEY")):
        path = ROOT / f"android/app/src/{flavor}/google-services.json"
        check_file(
            path,
            f"Firebase {flavor.capitalize()} configuration missing",
            f"Run ./scripts/setup_firebase.sh (writes {path.relative_to(ROOT)})",
        )
        if path.exists() and placeholder in path.read_text():
            fail(
                f"Firebase {flavor.capitalize()} configuration is still a placeholder",
                str(path.relative_to(ROOT)),
                "Run ./scripts/setup_firebase.sh to register the Android app and write google-services.json.",
            )

    if ios_enabled:
        for flavor, placeholder in (("dev", "REPLACE_ME_DEV_IOS_API_KEY"), ("prod", "REPLACE_ME_PROD_IOS_API_KEY")):
            path = ROOT / f"ios/config/{flavor}/GoogleService-Info.plist"
            check_file(
                path,
                f"iOS Firebase {flavor.capitalize()} configuration missing",
                f"Run ./scripts/setup_firebase.sh (writes {path.relative_to(ROOT)})",
            )
            if path.exists() and placeholder in path.read_text():
                fail(
                    f"iOS Firebase {flavor.capitalize()} configuration is still a placeholder",
                    str(path.relative_to(ROOT)),
                    "Run ./scripts/setup_firebase.sh to register the iOS app and write GoogleService-Info.plist.",
                )

    for env in (".env.dev", ".env.prod"):
        path = ROOT / env
        check_file(path, f"{env} missing", f"Copy {env}.example to {env} or run ./scripts/setup_project.sh")
        if path.exists() and "__" in path.read_text() and "API_BASE_URL=__" in path.read_text():
            fail(f"{env} still has placeholder API URL", "API_BASE_URL=https://...", "Re-run setup after filling environment.*.api_base_url")

    identity = ROOT / "lib/config/app_identity.dart"
    if identity.exists() and "__APP_NAME__" in identity.read_text():
        fail(
            "Dart identity still has placeholders",
            "lib/config/app_identity.dart",
            "Run ./scripts/setup_project.sh to generate AppIdentity from project_config.yaml.",
        )

    if ios_enabled:
        if not (ROOT / "ios/Runner.xcodeproj/xcshareddata/xcschemes/dev.xcscheme").exists():
            fail(
                "iOS dev scheme missing",
                "ios/Runner.xcodeproj/xcshareddata/xcschemes/dev.xcscheme",
                "Restore the flavor schemes from the template so `flutter run --flavor dev` works on iOS.",
            )
        if not (ROOT / "ios/Runner.xcodeproj/xcshareddata/xcschemes/prod.xcscheme").exists():
            fail(
                "iOS prod scheme missing",
                "ios/Runner.xcodeproj/xcshareddata/xcschemes/prod.xcscheme",
                "Restore the flavor schemes from the template so `flutter run --flavor prod` works on iOS.",
            )

    _print_failures(ios_enabled=ios_enabled, deeplink_enabled=deeplink_enabled)
    return 1 if failures else 0


def _print_failures(*, ios_enabled: bool = True, deeplink_enabled: bool = True) -> None:
    if not failures:
        print("Configuration looks valid.")
        print("Firebase files still need real console downloads before a production build.")
        if not ios_enabled:
            print("iOS setup is skipped. Set app.ios_bundle_id and re-run setup when you need iOS.")
        if not deeplink_enabled:
            print("Deep links are skipped. Set deeplink.scheme and deeplink.host when you need App Links.")
        return
    for title, expected, hint in failures:
        print(f"\n❌ {title}")
        print(f"\nExpected:\n{expected}")
        print(f"\n{hint}")
    print(f"\n{len(failures)} check(s) failed.")


if __name__ == "__main__":
    raise SystemExit(main())
