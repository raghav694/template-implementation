#!/usr/bin/env bash
# Slack chat + file upload for Jenkins (same files.getUploadURLExternal flow as ./s.sh).
#
# Usage:
#   SLACK_API_TOKEN=... SLACK_CHANNEL_ID=... ./scripts/ci_slack.sh message "text"
#   SLACK_API_TOKEN=... SLACK_CHANNEL_ID=... ./scripts/ci_slack.sh upload path/to/file "comment"
set -euo pipefail

if [ -z "${SLACK_API_TOKEN:-}" ] || [ -z "${SLACK_CHANNEL_ID:-}" ]; then
  echo "SLACK_API_TOKEN and SLACK_CHANNEL_ID must be set"
  exit 1
fi

ACTION="${1:-}"
if [ "$ACTION" != "message" ] && [ "$ACTION" != "upload" ]; then
  echo "Usage: $0 message <text>"
  echo "       $0 upload <file> <comment>"
  exit 1
fi

post_message() {
  local text="$1"
  python3 - "$text" <<'PY'
import json, os, sys, urllib.error, urllib.request

text = sys.argv[1]
body = json.dumps(
    {"channel": os.environ["SLACK_CHANNEL_ID"], "text": text},
    ensure_ascii=False,
).encode("utf-8")
req = urllib.request.Request(
    "https://slack.com/api/chat.postMessage",
    data=body,
    headers={
        "Authorization": "Bearer " + os.environ["SLACK_API_TOKEN"],
        "Content-Type": "application/json; charset=utf-8",
    },
    method="POST",
)
with urllib.request.urlopen(req, timeout=60) as resp:
    payload = json.loads(resp.read().decode())
if not payload.get("ok"):
    raise SystemExit("Slack chat.postMessage failed: " + json.dumps(payload))
print("Slack message sent")
PY
}

upload_file() {
  local file_path="$1"
  local comment="$2"
  if [ ! -f "$file_path" ]; then
    echo "File not found: $file_path"
    exit 1
  fi
  local filename
  filename="$(basename "$file_path")"
  local file_size
  file_size="$(stat -c%s "$file_path" 2>/dev/null || stat -f%z "$file_path")"

  python3 - "$file_path" "$filename" "$file_size" "$comment" <<'PY'
import json, os, subprocess, sys, urllib.parse, urllib.request

file_path, filename, file_size, comment = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
token = os.environ["SLACK_API_TOKEN"]
channel = os.environ["SLACK_CHANNEL_ID"]

query = urllib.parse.urlencode({"filename": filename, "length": file_size}).encode()
req = urllib.request.Request(
    "https://slack.com/api/files.getUploadURLExternal",
    data=query,
    headers={
        "Authorization": "Bearer " + token,
        "Content-Type": "application/x-www-form-urlencoded",
    },
    method="POST",
)
with urllib.request.urlopen(req, timeout=60) as resp:
    meta = json.loads(resp.read().decode())
if not meta.get("ok"):
    raise SystemExit("files.getUploadURLExternal failed: " + json.dumps(meta))

upload_url = meta["upload_url"]
file_id = meta["file_id"]
curl = subprocess.run(
    [
        "curl",
        "--fail",
        "--silent",
        "--show-error",
        "--connect-timeout",
        "30",
        "--max-time",
        "600",
        "-X",
        "POST",
        "-F",
        "file=@" + file_path,
        upload_url,
    ],
    check=False,
)
if curl.returncode != 0:
    raise SystemExit("Slack file PUT failed")

complete = urllib.parse.urlencode(
    {
        "files": json.dumps([{"id": file_id, "title": filename}]),
        "channel_id": channel,
        "initial_comment": comment,
    }
).encode()
req = urllib.request.Request(
    "https://slack.com/api/files.completeUploadExternal",
    data=complete,
    headers={
        "Authorization": "Bearer " + token,
        "Content-Type": "application/x-www-form-urlencoded",
    },
    method="POST",
)
with urllib.request.urlopen(req, timeout=60) as resp:
    payload = json.loads(resp.read().decode())
if not payload.get("ok"):
    raise SystemExit("files.completeUploadExternal failed: " + json.dumps(payload))
print("Slack file uploaded: " + filename)
PY
}

case "$ACTION" in
  message)
    if [ -n "${2:-}" ]; then
      post_message "$2"
    else
      post_message "$(cat)"
    fi
    ;;
  upload)
    comment="${3:-}"
    if [ -z "$comment" ] && [ -f .ci-slack-comment.txt ]; then
      comment="$(cat .ci-slack-comment.txt)"
    fi
    upload_file "${2:-}" "$comment"
    ;;
esac
