#!/usr/bin/env bash
set -euo pipefail

# Create or reuse "<app-name> app auth" in the active 1Password account.
# Never prints concealed fields.
#
# Required env:
#   APP_NAME
#   APP_ALLOWED_EMAILS   comma-separated Google emails
# Optional env:
#   BETTER_AUTH_URL      default http://localhost:5173
#   APP_ALLOWED_GOOGLE_HD  Workspace domain, or - to leave unset

if [[ -z "${APP_NAME:-}" || -z "${APP_ALLOWED_EMAILS:-}" ]]; then
  echo "Usage: APP_NAME=<slug> APP_ALLOWED_EMAILS=<emails> $0" >&2
  exit 1
fi

if ! command -v op >/dev/null; then
  echo "1Password CLI (op) is not installed." >&2
  exit 1
fi

if ! op whoami >/dev/null; then
  echo "1Password CLI is not signed in. Run: op signin" >&2
  exit 1
fi

TITLE="${APP_NAME} app auth"
AUTH_URL="${BETTER_AUTH_URL:-http://localhost:5173}"
AUTH_URL="${AUTH_URL%/}"
HD="${APP_ALLOWED_GOOGLE_HD:--}"
FIRST_EMAIL="$(printf '%s' "$APP_ALLOWED_EMAILS" | tr ',' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | awk 'NF { print; exit }')"

if [[ -z "$FIRST_EMAIL" ]]; then
  echo "APP_ALLOWED_EMAILS did not contain an email." >&2
  exit 1
fi

if op item get "$TITLE" >/dev/null 2>&1; then
  echo "Reusing 1Password item: $TITLE"
  op item get "$TITLE" --fields username,GOOGLE_CLIENT_ID,APP_ALLOWED_EMAILS,BETTER_AUTH_URL,APP_ALLOWED_GOOGLE_HD
  exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMPLATE="$SCRIPT_DIR/app-auth.json"
tmp="$(mktemp)"
chmod 600 "$tmp"

python3 - "$TEMPLATE" "$tmp" "$TITLE" "$FIRST_EMAIL" "$APP_ALLOWED_EMAILS" "$AUTH_URL" "$HD" <<'PY'
import json
import sys

src, dst, title, username, emails, url, hd = sys.argv[1:]
item = json.loads(open(src, encoding="utf-8").read())
item["title"] = title
item["urls"] = [{"href": url, "primary": True}]
notes = (
    "Better Auth Google SSO for this app.\n\n"
    "password = BETTER_AUTH_SECRET\n"
    "GOOGLE_CLIENT_ID / GOOGLE_CLIENT_SECRET = OAuth web client\n"
    "APP_ALLOWED_EMAILS = comma-separated Google emails\n"
    "BETTER_AUTH_URL = deployed origin, no trailing slash\n"
    "APP_ALLOWED_GOOGLE_HD = optional Workspace domain, or -\n\n"
    "Redirect URIs:\n"
    "http://localhost:5173/api/auth/callback/google\n"
    f"{url}/api/auth/callback/google\n\n"
    "Put the Google client ID and secret in this item. Do not paste them into chat."
)
values = {
    "username": username,
    "notesPlain": notes,
    "APP_ALLOWED_EMAILS": emails,
    "BETTER_AUTH_URL": url,
    "APP_ALLOWED_GOOGLE_HD": hd or "-",
    "GOOGLE_CLIENT_ID": "pending",
    "GOOGLE_CLIENT_SECRET": "pending",
    "password": "",
}
for field in item["fields"]:
    field_id = field.get("id")
    if field_id in values:
        field["value"] = values[field_id]
open(dst, "w", encoding="utf-8").write(json.dumps(item))
PY

op item create --template "$tmp" --generate-password='letters,digits,symbols,32' >/dev/null
rm -f "$tmp"

echo "Created 1Password item: $TITLE"
op item get "$TITLE" --fields username,GOOGLE_CLIENT_ID,APP_ALLOWED_EMAILS,BETTER_AUTH_URL,APP_ALLOWED_GOOGLE_HD
