#!/usr/bin/env bash
#
# Submits a file to Apple's notary service, waits for the verdict, and staples the ticket.
#
#   Scripts/notarize.sh build/Pane.app      zips the bundle for upload, staples the .app itself
#   Scripts/notarize.sh build/Pane-1.0.dmg  uploads the image as is, staples the image
#
# Credentials come from the environment, never from flags, so they cannot land in a process list or
# a shell history:
#
#   APPLE_ID, APPLE_APP_SPECIFIC_PASSWORD, APPLE_TEAM_ID
#
# It fails unless the verdict is exactly "Accepted". `notarytool submit --wait` exits 0 for some
# rejected submissions, and a release step that reports success on a rejection is worse than no step
# — the first person to find out would be a user whose Mac refuses to open the app.
#
set -euo pipefail

TARGET="${1:-}"
[[ -n "$TARGET" && -e "$TARGET" ]] || { echo "usage: $0 <Pane.app|Pane.dmg>" >&2; exit 2; }

for v in APPLE_ID APPLE_APP_SPECIFIC_PASSWORD APPLE_TEAM_ID; do
	[[ -n "${!v:-}" ]] || { echo "error: $v is not set" >&2; exit 1; }
done

say() { printf '\033[1m==>\033[0m %s\n' "$*"; }

WORK="$(mktemp -d "${TMPDIR:-/tmp}/pane-notarize.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

# notarytool takes a zip, a pkg or a dmg — not a bare .app.
if [[ -d "$TARGET" ]]; then
	UPLOAD="$WORK/$(basename "$TARGET").zip"
	ditto -c -k --keepParent "$TARGET" "$UPLOAD"
else
	UPLOAD="$TARGET"
fi

creds=(--apple-id "$APPLE_ID" --password "$APPLE_APP_SPECIFIC_PASSWORD" --team-id "$APPLE_TEAM_ID")

say "Submitting $(basename "$TARGET") for notarization (waiting for the verdict)"
# `|| true`: the verdict is read from the JSON below, not from the exit status.
xcrun notarytool submit "$UPLOAD" "${creds[@]}" --wait --output-format json > "$WORK/result.json" || true
cat "$WORK/result.json"; echo

STATUS="$(plutil -extract status raw -o - "$WORK/result.json" 2>/dev/null || echo unknown)"
ID="$(plutil -extract id raw -o - "$WORK/result.json" 2>/dev/null || true)"

if [[ "$STATUS" != "Accepted" ]]; then
	echo "error: notarization finished as '$STATUS' (submission $ID)" >&2
	[[ -n "$ID" ]] && xcrun notarytool log "$ID" "${creds[@]}" >&2 || true
	exit 1
fi

say "Stapling"
xcrun stapler staple "$TARGET"
xcrun stapler validate "$TARGET"
say "Notarized $(basename "$TARGET")"
