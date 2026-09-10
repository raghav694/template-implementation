# Shared helpers for ./b.sh and ./s.sh. Source after cd to repo root.

flutter_cmd() {
  if command -v fvm >/dev/null 2>&1; then
    fvm flutter "$@"
  else
    flutter "$@"
  fi
}

dart_cmd() {
  if command -v fvm >/dev/null 2>&1; then
    fvm dart "$@"
  else
    dart "$@"
  fi
}

normalize_url() {
  echo "$1" | tr -d '[:space:]' | sed -e "s/^['\"]//" -e "s/['\"]$//" -e 's:/*$::'
}

config_get() {
  python3 - "$1" <<'PY'
import sys
from pathlib import Path

sys.path.insert(0, str(Path("scripts/helpers")))
from config import is_placeholder, load_config, nested_get  # noqa: E402

key = sys.argv[1]
config = load_config(Path("project_config.yaml"))
value = nested_get(config, key).strip()
if not value or is_placeholder(value):
    sys.exit(2)
print(value)
PY
}

slug_app_name() {
  python3 - <<'PY'
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path("scripts/helpers")))
from config import is_placeholder, load_config, nested_get  # noqa: E402

config = load_config(Path("project_config.yaml"))
name = nested_get(config, "app.name").strip()
if not name or is_placeholder(name):
    name = "app"
slug = re.sub(r"[^a-z0-9]+", "-", name.lower()).strip("-")
print(slug or "app")
PY
}

display_app_name() {
  python3 - <<'PY'
import sys
from pathlib import Path

sys.path.insert(0, str(Path("scripts/helpers")))
from config import is_placeholder, load_config, nested_get  # noqa: E402

config = load_config(Path("project_config.yaml"))
name = nested_get(config, "app.name").strip()
if not name or is_placeholder(name):
    name = "App"
print(name)
PY
}

read_env_value() {
  local env_file="$1"
  local key="$2"
  if [[ ! -f "$env_file" ]]; then
    echo ""
    return
  fi
  local line
  line="$(grep -E "^${key}=" "$env_file" | tail -n 1 || true)"
  if [[ -z "$line" ]]; then
    echo ""
    return
  fi
  echo "${line#${key}=}" | tr -d '\r'
}

read_app_version() {
  local pubspec="pubspec.yaml"
  if [ ! -f "$pubspec" ]; then
    echo "unknown"
    return
  fi
  local version
  version="$(grep -E "^version:" "$pubspec" | sed 's/version:[[:space:]]*//' | cut -d'+' -f1 | tr -d ' ')"
  if [ -z "$version" ]; then
    echo "unknown"
  else
    echo "$version"
  fi
}

git_username() {
  local name
  name="$(git config --get user.name 2>/dev/null || true)"
  if [ -z "$name" ]; then
    name="$(git config --get user.email 2>/dev/null || true)"
  fi
  if [ -z "$name" ]; then
    name="${USER:-unknown}"
  fi
  echo "$name"
}

require_prod_api_match() {
  local prod_env=".env.prod"
  if [ ! -f "$prod_env" ]; then
    echo "❌ Safety check failed: $prod_env not found."
    echo "   Copy .env.prod.example or run ./scripts/setup_project.sh"
    exit 1
  fi
  if [ ! -f "project_config.yaml" ]; then
    echo "❌ Safety check failed: project_config.yaml not found."
    exit 1
  fi

  local expected actual expected_norm actual_norm
  if ! expected="$(config_get environment.prod.api_base_url)"; then
    echo "❌ Safety check failed: Production API URL is missing or still a placeholder."
    echo "   Set environment.prod.api_base_url in project_config.yaml"
    echo "   (the Production API URL from ./scripts/setup_project.sh) and re-run setup."
    exit 1
  fi

  actual="$(grep -E '^API_BASE_URL=' "$prod_env" | head -n 1 | cut -d'=' -f2- || true)"
  expected_norm="$(normalize_url "$expected")"
  actual_norm="$(normalize_url "${actual:-}")"

  if [ -z "$actual_norm" ] || [ "$actual_norm" != "$expected_norm" ]; then
    echo "❌ Safety check failed for prod build."
    echo "   Expected API_BASE_URL (from setup / project_config.yaml): $expected_norm"
    echo "   Found API_BASE_URL in .env.prod:                          ${actual_norm:-<missing>}"
    echo "   Aborting build."
    exit 1
  fi

  echo "✅ Prod API_BASE_URL safety check passed ($expected_norm)."
}

prepare_flutter_project() {
  echo "🧹 Cleaning Flutter project..."
  flutter_cmd clean

  echo "🗑️  Deleting pubspec.lock file..."
  rm -f pubspec.lock

  echo "📥 Running flutter pub get..."
  flutter_cmd pub get

  echo "🔨 Running build_runner..."
  dart_cmd run build_runner build --delete-conflicting-outputs
}
