#!/usr/bin/env bash
# Build Android App Bundle (AAB) using Flutter product flavors.
#
# Usage:
#   ./b.sh prod                       # Build PROD app bundle (default)
#   ./b.sh dev                        # Build DEV app bundle
#   ./b.sh prod my-bundle-name        # Build PROD app bundle with custom name
#
# Prod safety: .env.prod API_BASE_URL must match environment.prod.api_base_url
# from project_config.yaml (the Production API URL entered in setup_project.sh).

set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"
# shellcheck source=scripts/helpers/build_common.sh
source "$ROOT/scripts/helpers/build_common.sh"

ENVIRONMENT="${1:-prod}"
ENVIRONMENT_LOWER="$(echo "$ENVIRONMENT" | tr '[:upper:]' '[:lower:]')"

if [ "$ENVIRONMENT_LOWER" != "dev" ] && [ "$ENVIRONMENT_LOWER" != "prod" ]; then
  echo "❌ Invalid environment: $ENVIRONMENT"
  echo "Usage: ./b.sh <dev|prod> [custom_name]"
  echo ""
  echo "Examples:"
  echo "  ./b.sh                       # Build PROD app bundle"
  echo "  ./b.sh prod                  # Build PROD app bundle"
  echo "  ./b.sh dev                   # Build DEV app bundle"
  echo "  ./b.sh prod my-custom-bundle # Build PROD app bundle with custom name"
  exit 1
fi

if [ "$ENVIRONMENT_LOWER" = "dev" ]; then
  TARGET_FILE="lib/main_dev.dart"
  ENVIRONMENT_LABEL="DEV"
else
  TARGET_FILE="lib/main_prod.dart"
  ENVIRONMENT_LABEL="PROD"
fi

if [ "$ENVIRONMENT_LOWER" = "prod" ]; then
  require_prod_api_match
fi

APP_VERSION="$(read_app_version)"

if [ -z "${2:-}" ]; then
  NAME="$(slug_app_name)-$ENVIRONMENT_LABEL-$APP_VERSION"
  echo "📦 Auto-generated name: $NAME"
else
  NAME="$2"
  echo "📦 Using provided name: $NAME"
fi

echo "  Environment: $ENVIRONMENT_LABEL"
echo "  App Version: $APP_VERSION"
echo "  Flavor: $ENVIRONMENT_LOWER"
echo "  Target: $TARGET_FILE"
echo ""

prepare_flutter_project

echo ""
echo "🚀 Building app bundle for $ENVIRONMENT_LABEL environment..."
echo "   Command: flutter build appbundle --flavor $ENVIRONMENT_LOWER -t $TARGET_FILE"
flutter_cmd build appbundle --flavor "$ENVIRONMENT_LOWER" -t "$TARGET_FILE"

echo "✅ Verifying app bundle build..."
FLAVOR_AAB_PATH="build/app/outputs/bundle/${ENVIRONMENT_LOWER}Release/app-${ENVIRONMENT_LOWER}-release.aab"
DEFAULT_AAB_PATH="build/app/outputs/bundle/release/app-release.aab"

if [ -f "$FLAVOR_AAB_PATH" ]; then
  AAB_PATH="$FLAVOR_AAB_PATH"
  echo "Flavor app bundle found at $AAB_PATH"
elif [ -f "$DEFAULT_AAB_PATH" ]; then
  AAB_PATH="$DEFAULT_AAB_PATH"
  echo "Release app bundle found at $AAB_PATH"
else
  echo "App bundle file not found! Listing contents of the output directory:"
  ls -la build/app/outputs/bundle/ || true
  exit 1
fi

NEW_AAB_NAME="$NAME.aab"
NEW_AAB_PATH="build/app/outputs/bundle/$NEW_AAB_NAME"
echo "📝 Copying app bundle as $NEW_AAB_NAME..."
cp "$AAB_PATH" "$NEW_AAB_PATH"

FILE_SIZE="$(stat -f%z "$NEW_AAB_PATH" 2>/dev/null || stat -c%s "$NEW_AAB_PATH" 2>/dev/null || echo "0")"
if [ "$FILE_SIZE" -eq "0" ]; then
  echo "Error: Copied app bundle file is empty"
  exit 1
fi

echo ""
echo "✅ App bundle generated successfully!"
echo "   File: $NEW_AAB_PATH"
echo "   Environment: $ENVIRONMENT_LABEL"
echo "   Version: $APP_VERSION"
echo "   Size: $FILE_SIZE bytes"
