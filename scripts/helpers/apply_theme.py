#!/usr/bin/env python3
"""Optionally apply an app logo, brand colors, and text theme font.

Every field is optional. Press Enter to skip a prompt.
"""

from __future__ import annotations

import argparse
import json
import re
import shutil
import subprocess
import sys
from pathlib import Path

HELPERS = Path(__file__).resolve().parent
sys.path.insert(0, str(HELPERS))

from config import load_config, nested_get  # noqa: E402
from replace import ROOT  # noqa: E402

CONFIG_PATH = ROOT / "project_config.yaml"
APP_COLORS = ROOT / "lib/core/theme/app_colors.dart"
APP_TYPOGRAPHY = ROOT / "lib/core/theme/app_typography.dart"
LAUNCHER_YAML = ROOT / "flutter_launcher_icons.yaml"
ANDROID_COLORS = ROOT / "android/app/src/main/res/values/colors.xml"
ANDROID_SPLASH = ROOT / "android/app/src/main/res/drawable/splash_logo.png"
IOS_STORYBOARD = ROOT / "ios/Runner/Base.lproj/LaunchScreen.storyboard"
LOGO_DEST = ROOT / "assets/logo/logo.png"
FOREGROUND_DEST = ROOT / "assets/logo/foreground.png"
LAUNCH_IMAGES = [
    ROOT / "ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png",
    ROOT / "ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@2x.png",
    ROOT / "ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png",
]
SPLASH_XML = [
    ROOT / "android/app/src/main/res/drawable/launch_background.xml",
    ROOT / "android/app/src/main/res/drawable-v21/launch_background.xml",
]

IMAGE_SUFFIXES = {".png", ".jpg", ".jpeg", ".webp"}


def parse_hex(value: str) -> tuple[int, int, int]:
    raw = value.strip()
    if raw.lower().startswith("0x"):
        raw = raw[2:]
    raw = raw.lstrip("#")
    if len(raw) == 8:
        raw = raw[2:]
    if len(raw) == 3:
        raw = "".join(ch * 2 for ch in raw)
    if not re.fullmatch(r"[0-9A-Fa-f]{6}", raw or ""):
        raise ValueError(f"Expected a hex color like #1E88E5, got {value!r}")
    return int(raw[0:2], 16), int(raw[2:4], 16), int(raw[4:6], 16)


def rgb_hex(rgb: tuple[int, int, int]) -> str:
    return f"#{rgb[0]:02X}{rgb[1]:02X}{rgb[2]:02X}"


def dart_color(rgb: tuple[int, int, int], alpha: int = 0xFF) -> str:
    return f"Color(0x{alpha:02X}{rgb[0]:02X}{rgb[1]:02X}{rgb[2]:02X})"


def mix(a: tuple[int, int, int], b: tuple[int, int, int], t: float) -> tuple[int, int, int]:
    return (
        int(round(a[0] + (b[0] - a[0]) * t)),
        int(round(a[1] + (b[1] - a[1]) * t)),
        int(round(a[2] + (b[2] - a[2]) * t)),
    )


def darken(rgb: tuple[int, int, int], amount: float = 0.18) -> tuple[int, int, int]:
    return mix(rgb, (0, 0, 0), amount)


def lighten(rgb: tuple[int, int, int], amount: float = 0.22) -> tuple[int, int, int]:
    return mix(rgb, (255, 255, 255), amount)


def resolve_path(value: str) -> Path:
    path = Path(value).expanduser()
    if not path.is_absolute():
        path = (Path.cwd() / path).resolve()
    return path


def ensure_png(src: Path, dest: Path) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    suffix = src.suffix.lower()
    if suffix not in IMAGE_SUFFIXES:
        raise ValueError(f"Unsupported image type {src.suffix}. Use PNG, JPG, or WebP.")
    if suffix == ".png":
        if src.resolve() != dest.resolve():
            shutil.copy2(src, dest)
        return
    if shutil.which("sips"):
        subprocess.run(
            ["sips", "-s", "format", "png", str(src), "--out", str(dest)],
            check=True,
            capture_output=True,
        )
        return
    if shutil.which("magick"):
        subprocess.run(["magick", str(src), str(dest)], check=True)
        return
    raise ValueError("Non-PNG logos need `sips` (macOS) or ImageMagick. Pass a PNG instead.")


def normalize_font_family(name: str) -> str:
    cleaned = " ".join(name.strip().split())
    if not re.fullmatch(r"[A-Za-z][A-Za-z0-9+\- ]{0,60}", cleaned):
        raise ValueError(
            f"Expected a Google Fonts family like Inter or Open Sans, got {name!r}"
        )
    return cleaned


def apply_font_family(family: str) -> None:
    if not APP_TYPOGRAPHY.exists():
        raise RuntimeError("lib/core/theme/app_typography.dart is missing")
    text = APP_TYPOGRAPHY.read_text()
    updated, count = re.subn(
        r"static const String fontFamily = '[^']+';",
        f"static const String fontFamily = '{family}';",
        text,
        count=1,
    )
    if count != 1:
        raise RuntimeError("Could not update AppTypography.fontFamily")
    APP_TYPOGRAPHY.write_text(updated)


def set_dart_color(text: str, name: str, expr: str) -> str:
    pattern = rf"(static const Color {name} = )Color\(0x[0-9A-Fa-f]+\)"
    updated, count = re.subn(pattern, rf"\g<1>{expr}", text, count=1)
    if count != 1:
        raise RuntimeError(f"Could not update AppColors.{name}")
    return updated


def apply_primary(text: str, rgb: tuple[int, int, int]) -> str:
    dim = darken(rgb)
    soft = lighten(rgb, 0.86)
    tint = lighten(rgb, 0.92)
    text = set_dart_color(text, "primary", dart_color(rgb))
    text = set_dart_color(text, "primaryGlow", dart_color(rgb, 0x25))
    text = set_dart_color(text, "primaryDim", dart_color(dim))
    text = set_dart_color(text, "primarySoft", dart_color(soft))
    text = set_dart_color(text, "gradient1", dart_color(lighten(rgb)))
    text = set_dart_color(text, "gradient2", dart_color(dim))
    text = set_dart_color(text, "ambientGlow", dart_color(rgb, 0x15))
    text = set_dart_color(text, "authTint", dart_color(tint))
    return text


def apply_background(text: str, rgb: tuple[int, int, int]) -> str:
    elevated = mix(rgb, (227, 234, 244), 0.35)
    high = mix(rgb, (227, 234, 244), 0.55)
    text = set_dart_color(text, "background", dart_color(rgb))
    text = set_dart_color(text, "surfaceElevated", dart_color(elevated))
    text = set_dart_color(text, "surfaceHigh", dart_color(high))
    return text


def replace_hex_assignment(path: Path, key: str, hex_color: str) -> None:
    if not path.exists():
        return
    original = path.read_text()
    if key == "adaptive_icon_background":
        updated, count = re.subn(
            r'adaptive_icon_background:\s*"[#0-9A-Fa-f]+"',
            f'adaptive_icon_background: "{hex_color}"',
            original,
            count=1,
        )
    else:
        updated, count = re.subn(
            rf"(<color name=\"{key}\">)#[0-9A-Fa-f]+(</color>)",
            rf"\g<1>{hex_color}\2",
            original,
            count=1,
        )
        if count == 0 and key == "splash_background":
            updated = original.replace(
                "</resources>",
                f"    <color name=\"splash_background\">{hex_color}</color>\n</resources>",
                1,
            )
            count = 1
    if count:
        path.write_text(updated)


def write_android_splash(has_logo: bool, bg_hex: str | None) -> None:
    color = "@color/splash_background" if bg_hex else "@android:color/white"
    if bg_hex:
        replace_hex_assignment(ANDROID_COLORS, "splash_background", bg_hex)
    logo_item = ""
    if has_logo and ANDROID_SPLASH.exists():
        logo_item = """
    <item>
        <bitmap
            android:gravity="center"
            android:src="@drawable/splash_logo" />
    </item>
"""
    contents = f"""<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="{color}" />
{logo_item}</layer-list>
"""
    for path in SPLASH_XML:
        path.write_text(contents)


def apply_ios_splash_color(rgb: tuple[int, int, int]) -> None:
    if not IOS_STORYBOARD.exists():
        return
    r, g, b = (c / 255 for c in rgb)
    updated, count = re.subn(
        r'<color key="backgroundColor" red="[^"]+" green="[^"]+" blue="[^"]+" alpha="1" colorSpace="custom" customColorSpace="sRGB"/>',
        f'<color key="backgroundColor" red="{r:.3f}" green="{g:.3f}" blue="{b:.3f}" alpha="1" colorSpace="custom" customColorSpace="sRGB"/>',
        IOS_STORYBOARD.read_text(),
        count=1,
    )
    if count:
        IOS_STORYBOARD.write_text(updated)


def copy_logo_everywhere(logo: Path, foreground: Path | None) -> None:
    ensure_png(logo, LOGO_DEST)
    ensure_png(foreground or logo, FOREGROUND_DEST)
    shutil.copy2(LOGO_DEST, ANDROID_SPLASH)
    for dest in LAUNCH_IMAGES:
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(LOGO_DEST, dest)


def run_launcher_icons() -> None:
    if shutil.which("fvm"):
        cmd = ["fvm", "dart", "run", "flutter_launcher_icons"]
    elif shutil.which("dart"):
        cmd = ["dart", "run", "flutter_launcher_icons"]
    else:
        print("  skipped launcher icons (fvm/dart not on PATH). Run: dart run flutter_launcher_icons")
        return
    print("  generating Android / iOS launcher icons…")
    result = subprocess.run(cmd, cwd=ROOT)
    if result.returncode != 0:
        print("  launcher icon generation failed. Run: dart run flutter_launcher_icons")


def prompt_optional(label: str, current: str) -> str:
    display = current
    entered = input(f"{label} [{display}]: ").strip()
    return entered or current


def collect(args: argparse.Namespace, config: dict) -> dict[str, str]:
    values = {
        "logo": args.logo or "",
        "foreground": args.foreground or "",
        "primary": args.primary or nested_get(config, "theme.primary"),
        "background": args.background or nested_get(config, "theme.background"),
        "error": args.error or nested_get(config, "theme.error"),
        "font": args.font or nested_get(config, "theme.font_family"),
    }
    if args.yes or not sys.stdin.isatty():
        return values

    print("\nFlutter App Template theme")
    print("Every field is optional. Press Enter to skip.\n")
    values["logo"] = prompt_optional(
        "App logo path (PNG/JPG — in-app, launcher, splash)",
        values["logo"],
    )
    values["foreground"] = prompt_optional(
        "Adaptive icon foreground (optional, defaults to logo)",
        values["foreground"],
    )
    values["primary"] = prompt_optional("Primary color (e.g. #1E88E5)", values["primary"])
    values["background"] = prompt_optional("Background color (e.g. #F5F8FC)", values["background"])
    values["error"] = prompt_optional("Error color (e.g. #E05252)", values["error"])
    values["font"] = prompt_optional(
        "Text theme font (Google Fonts name, e.g. Inter)",
        values["font"],
    )
    return values


def persist_theme(primary: str, background: str, error: str, font_family: str) -> None:
    updates = {
        key: value
        for key, value in (
            ("primary", primary),
            ("background", background),
            ("error", error),
            ("font_family", font_family),
        )
        if value
    }
    if not updates or not CONFIG_PATH.exists():
        return
    text = CONFIG_PATH.read_text()
    loaded = load_config(CONFIG_PATH).get("theme") or {}
    existing = {str(k): str(v) for k, v in loaded.items() if v} if isinstance(loaded, dict) else {}
    existing.update(updates)
    lines = ["theme:"]
    for key in ("primary", "background", "error", "font_family"):
        if existing.get(key):
            lines.append(f"  {key}: {json.dumps(existing[key])}")
    block = "\n".join(lines) + "\n"
    if re.search(r"^theme:", text, re.M):
        text = re.sub(r"(?m)^theme:\n(?:  .*\n)*", block, text, count=1)
    else:
        text = text.rstrip() + "\n\n" + block
    CONFIG_PATH.write_text(text)


def main() -> int:
    parser = argparse.ArgumentParser(description="Optionally apply logo and theme colors.")
    parser.add_argument("-y", "--yes", action="store_true", help="Use values from project_config.yaml / flags only")
    parser.add_argument("--logo", help="Path to app logo image")
    parser.add_argument("--foreground", help="Path to adaptive-icon foreground image")
    parser.add_argument("--primary", help="Primary hex color")
    parser.add_argument("--background", help="Background hex color")
    parser.add_argument("--error", help="Error hex color")
    parser.add_argument("--font", help="Google Fonts family for the text theme (e.g. Inter)")
    args = parser.parse_args()

    config = load_config(CONFIG_PATH) if CONFIG_PATH.exists() else {}
    values = collect(args, config)

    logo = values["logo"].strip()
    foreground = values["foreground"].strip()
    primary = values["primary"].strip()
    background = values["background"].strip()
    error = values["error"].strip()
    font = values["font"].strip()

    if not any((logo, foreground, primary, background, error, font)):
        print("Nothing to apply — every theme field was skipped.")
        return 0

    parsed: dict[str, tuple[int, int, int]] = {}
    try:
        if primary:
            parsed["primary"] = parse_hex(primary)
        if background:
            parsed["background"] = parse_hex(background)
        if error:
            parsed["error"] = parse_hex(error)
        font_family = normalize_font_family(font) if font else ""
        logo_path = resolve_path(logo) if logo else None
        fg_path = resolve_path(foreground) if foreground else None
        if logo_path and not logo_path.is_file():
            raise ValueError(f"Logo not found: {logo_path}")
        if fg_path and not fg_path.is_file():
            raise ValueError(f"Foreground image not found: {fg_path}")
    except ValueError as exc:
        print(f"Theme setup did not run: {exc}")
        return 1

    changed: list[str] = []
    try:
        if logo_path:
            copy_logo_everywhere(logo_path, fg_path)
            write_android_splash(True, rgb_hex(parsed["background"]) if "background" in parsed else None)
            changed.append("logo (assets, launcher source, Android/iOS splash)")
        elif fg_path:
            ensure_png(fg_path, FOREGROUND_DEST)
            changed.append("adaptive icon foreground")

        colors_text = APP_COLORS.read_text()
        if "primary" in parsed:
            colors_text = apply_primary(colors_text, parsed["primary"])
            hex_color = rgb_hex(parsed["primary"])
            replace_hex_assignment(LAUNCHER_YAML, "adaptive_icon_background", hex_color)
            replace_hex_assignment(ANDROID_COLORS, "ic_launcher_background", hex_color)
            changed.append(f"primary {hex_color}")
        if "background" in parsed:
            colors_text = apply_background(colors_text, parsed["background"])
            hex_color = rgb_hex(parsed["background"])
            if not logo_path:
                write_android_splash(ANDROID_SPLASH.exists(), hex_color)
            apply_ios_splash_color(parsed["background"])
            changed.append(f"background {hex_color}")
        if "error" in parsed:
            colors_text = set_dart_color(colors_text, "error", dart_color(parsed["error"]))
            changed.append(f"error {rgb_hex(parsed['error'])}")
        if any(key in parsed for key in ("primary", "background", "error")):
            APP_COLORS.write_text(colors_text)
        if font_family:
            apply_font_family(font_family)
            changed.append(f"text theme font {font_family}")

        persist_theme(
            rgb_hex(parsed["primary"]) if "primary" in parsed else "",
            rgb_hex(parsed["background"]) if "background" in parsed else "",
            rgb_hex(parsed["error"]) if "error" in parsed else "",
            font_family,
        )
    except Exception as exc:  # noqa: BLE001
        print(f"Theme setup failed: {exc}")
        return 1

    if logo_path or fg_path or "primary" in parsed:
        run_launcher_icons()

    print("\nTheme applied:")
    for item in changed:
        print(f"  - {item}")
    print("Skipped fields were left unchanged.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
