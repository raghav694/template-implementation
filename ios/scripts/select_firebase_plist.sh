#!/bin/sh
# Copies the flavor-specific GoogleService-Info.plist into ios/Runner/
# before the Xcode compile step.
set -euo pipefail

FLAVOR="${CONFIGURATION:-}"
SRC=""

case "$FLAVOR" in
  *dev*|*Dev*|*DEV*)
    SRC="${SRCROOT}/config/dev/GoogleService-Info.plist"
    ;;
  *prod*|*Prod*|*PROD*)
    SRC="${SRCROOT}/config/prod/GoogleService-Info.plist"
    ;;
  *)
    # Default schemes (Debug/Release/Profile) use prod unless FLUTTER_FLAVOR is set.
    if [ "${FLUTTER_FLAVOR:-}" = "dev" ]; then
      SRC="${SRCROOT}/config/dev/GoogleService-Info.plist"
    else
      SRC="${SRCROOT}/config/prod/GoogleService-Info.plist"
    fi
    ;;
esac

DEST="${SRCROOT}/Runner/GoogleService-Info.plist"
if [ ! -f "$SRC" ]; then
  echo "warning: Firebase plist not found at $SRC"
  exit 0
fi

cp "$SRC" "$DEST"
echo "Copied $SRC -> $DEST"
