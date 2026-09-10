#!/usr/bin/env bash
# Build a flavor APK and upload it to Slack (Vokey s.sh flow).
#
# Usage:
#   ./s.sh dev
#   ./s.sh prod
#   ./s.sh dev "Custom message"
#   ./s.sh prod "Custom message" my-apk-name
#
# Slack credentials: flavor `.env.dev` / `.env.prod` `SLACK_API_TOKEN` +
# `SLACK_CHANNEL_ID` (same keys as Vokey), then `.slack.env`, then the shell.
# APK filename uses the app name from project_config.yaml, not a hardcoded
# product string.
#
# The Slack comment always includes git config user.name.
# Prod APKs use the same API_BASE_URL safety check as ./b.sh.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"
# shellcheck source=scripts/helpers/build_common.sh
source "$ROOT/scripts/helpers/build_common.sh"

ENVIRONMENT="${1:-prod}"
ENVIRONMENT_LOWER="$(echo "$ENVIRONMENT" | tr '[:upper:]' '[:lower:]')"

if [ "$ENVIRONMENT_LOWER" != "dev" ] && [ "$ENVIRONMENT_LOWER" != "prod" ]; then
  echo "❌ Invalid environment: $ENVIRONMENT"
  echo "Usage: ./s.sh <dev|prod> [message] [custom_name]"
  echo ""
  echo "Examples:"
  echo "  ./s.sh dev"
  echo "  ./s.sh prod"
  echo "  ./s.sh dev \"QA please smoke this APK\""
  exit 1
fi

if [ "$ENVIRONMENT_LOWER" = "dev" ]; then
  ENV_FILE="$ROOT/.env.dev"
  TARGET_FILE="lib/main_dev.dart"
  ENVIRONMENT_LABEL="DEV"
else
  ENV_FILE="$ROOT/.env.prod"
  TARGET_FILE="lib/main_prod.dart"
  ENVIRONMENT_LABEL="PROD"
fi

if [ -z "${SLACK_API_TOKEN:-}" ]; then
  SLACK_API_TOKEN="$(read_env_value "$ENV_FILE" "SLACK_API_TOKEN")"
fi
if [ -z "${SLACK_CHANNEL_ID:-}" ]; then
  SLACK_CHANNEL_ID="$(read_env_value "$ENV_FILE" "SLACK_CHANNEL_ID")"
fi

if [ -z "${SLACK_API_TOKEN:-}" ] || [ -z "${SLACK_CHANNEL_ID:-}" ]; then
  if [ -f "$ROOT/.slack.env" ]; then
    set -a
    # shellcheck disable=SC1091
    source "$ROOT/.slack.env"
    set +a
  fi
fi
if [ -z "${SLACK_API_TOKEN:-}" ]; then
  SLACK_API_TOKEN="${SLACK_BOT_TOKEN:-}"
fi

if [ -z "${SLACK_API_TOKEN:-}" ] || [ -z "${SLACK_CHANNEL_ID:-}" ]; then
  echo "❌ Slack is not configured."
  echo "   Set SLACK_API_TOKEN and SLACK_CHANNEL_ID in $ENV_FILE"
  echo "   (or .slack.env / the environment)."
  exit 1
fi

if [ "$ENVIRONMENT_LOWER" = "prod" ]; then
  require_prod_api_match
fi

APP_VERSION="$(read_app_version)"
APP_DISPLAY="$(display_app_name)"
GIT_USER="$(git_username)"

if [ -z "${3:-}" ]; then
  NAME="$(slug_app_name)-$ENVIRONMENT_LABEL-$APP_VERSION"
  echo "📦 Auto-generated name: $NAME"
else
  NAME="$3"
  echo "📦 Using provided name: $NAME"
fi

echo "  Environment: $ENVIRONMENT_LABEL"
echo "  App Version: $APP_VERSION"
echo "  Flavor: $ENVIRONMENT_LOWER"
echo "  Target: $TARGET_FILE"
echo "  Git user: $GIT_USER"
echo ""

if [ -z "${2:-}" ]; then
  MESSAGE="$APP_DISPLAY $ENVIRONMENT_LABEL APK - v$APP_VERSION — built by $GIT_USER"
  echo "Using default Slack message."
else
  MESSAGE="$2"$'\n'"Built by $GIT_USER"
  echo "Using custom Slack message (git user appended)."
fi

prepare_flutter_project

echo ""
echo "🚀 Building APK for $ENVIRONMENT_LABEL environment..."
echo "   Command: flutter build apk --flavor $ENVIRONMENT_LOWER -t $TARGET_FILE"
flutter_cmd build apk --flavor "$ENVIRONMENT_LOWER" -t "$TARGET_FILE"

echo "✅ Verifying APK build..."
FLAVOR_APK_PATH="build/app/outputs/flutter-apk/app-$ENVIRONMENT_LOWER-release.apk"
DEFAULT_APK_PATH="build/app/outputs/flutter-apk/app-release.apk"

if [ -f "$FLAVOR_APK_PATH" ]; then
  APK_PATH="$FLAVOR_APK_PATH"
  echo "Flavor APK found at $APK_PATH"
elif [ -f "$DEFAULT_APK_PATH" ]; then
  APK_PATH="$DEFAULT_APK_PATH"
  echo "Release APK found at $APK_PATH"
else
  echo "APK file not found! Listing contents of the output directory:"
  ls -la build/app/outputs/flutter-apk/ || true
  exit 1
fi

NEW_APK_NAME="$NAME.apk"
NEW_APK_PATH="build/app/outputs/flutter-apk/$NEW_APK_NAME"
echo "📝 Copying APK as $NEW_APK_NAME..."
cp "$APK_PATH" "$NEW_APK_PATH"

FILE_SIZE="$(stat -f%z "$NEW_APK_PATH" 2>/dev/null || stat -c%s "$NEW_APK_PATH" 2>/dev/null || echo "0")"
if [ "$FILE_SIZE" -eq "0" ]; then
  echo "Error: Copied APK file is empty"
  exit 1
fi

echo "APK file verified: $NEW_APK_PATH (size: $FILE_SIZE bytes)"

echo ""
echo "📤 Uploading APK to Slack..."

UPLOAD_URL_RESULT="$(curl -s -H "Authorization: Bearer $SLACK_API_TOKEN" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "filename=$NEW_APK_NAME" \
  --data-urlencode "length=$FILE_SIZE" \
  "https://slack.com/api/files.getUploadURLExternal")"

if ! echo "$UPLOAD_URL_RESULT" | grep -q '"ok":true'; then
  echo "Failed to get upload URL from Slack. Response: $UPLOAD_URL_RESULT"
  exit 1
fi

UPLOAD_URL="$(echo "$UPLOAD_URL_RESULT" | grep -o '"upload_url":"[^"]*"' | cut -d'"' -f4 | sed 's/\\//g')"
FILE_ID="$(echo "$UPLOAD_URL_RESULT" | grep -o '"file_id":"[^"]*"' | cut -d'"' -f4)"

if [ -z "$UPLOAD_URL" ] || [ -z "$FILE_ID" ]; then
  echo "Failed to parse Slack upload URL / file id. Response: $UPLOAD_URL_RESULT"
  exit 1
fi

echo "Uploading file (this can take a few minutes)..."
curl --connect-timeout 30 --max-time 600 --progress-bar -X POST \
  -F "file=@$NEW_APK_PATH" \
  "$UPLOAD_URL" >/dev/null

SLACK_TITLE="$NEW_APK_NAME (built by $GIT_USER)"
COMPLETE_RESULT="$(curl -s -H "Authorization: Bearer $SLACK_API_TOKEN" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "files=[{\"id\":\"$FILE_ID\",\"title\":\"$SLACK_TITLE\"}]" \
  --data-urlencode "channel_id=$SLACK_CHANNEL_ID" \
  --data-urlencode "initial_comment=$MESSAGE" \
  "https://slack.com/api/files.completeUploadExternal")"

if echo "$COMPLETE_RESULT" | grep -q '"ok":true'; then
  echo ""
  echo "✅ File uploaded successfully to Slack!"
  echo "   APK: $NEW_APK_NAME"
  echo "   Environment: $ENVIRONMENT_LABEL"
  echo "   Version: $APP_VERSION"
  echo "   Built by: $GIT_USER"
else
  echo "Failed to complete file upload to Slack. Response: $COMPLETE_RESULT"
  exit 1
fi
