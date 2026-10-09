#!/usr/bin/env bash
#
# Assembles Pane.app around the SwiftPM executable.
#
# There is no Xcode project on purpose — `swift build` works with only the Command Line Tools, so
# this script is the whole build. It compiles the editor bundle, compiles the Swift binary, lays out
# the bundle, and signs it — with a Developer ID when PANE_SIGN_IDENTITY is set (the release
# workflow), ad-hoc otherwise (arm64 binaries must carry at least an ad-hoc signature to launch, and
# rewriting the bundle invalidates the signature SwiftPM applied).
#
#   Scripts/build-app.sh                 release build for the host architecture
#   Scripts/build-app.sh --debug         isolated Pane Dev.app, faster, for iterating
#   Scripts/build-app.sh --dev --release isolated Pane Dev.app with release optimization
#   Scripts/build-app.sh --universal     arm64 + x86_64, for a release artifact
#   Scripts/build-app.sh --skip-editor   reuse the existing Editor/dist
#
#   PANE_SIGN_IDENTITY="Developer ID Application: ..." Scripts/build-app.sh --universal
#                                        hardened-runtime Developer ID signature, for release
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

CONFIG=release
CHANNEL=release
SKIP_EDITOR=0
ARCH_ARGS=()

while [[ $# -gt 0 ]]; do
	case "$1" in
		--debug)       CONFIG=debug; CHANNEL=dev ;;
		--dev)         CHANNEL=dev ;;
		--release)     CONFIG=release ;;
		--universal)   ARCH_ARGS=(--arch arm64 --arch x86_64) ;;
		--skip-editor) SKIP_EDITOR=1 ;;
		-h|--help)     sed -n '2,23p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
		*)             echo "unknown flag: $1" >&2; exit 2 ;;
	esac
	shift
done

VERSION="${PANE_VERSION:-0.1.0}"
BUILD_NUMBER="${PANE_BUILD:-$(git rev-list --count HEAD 2>/dev/null || echo 1)}"

APP_NAME=Pane
[[ "$CHANNEL" == "dev" ]] && APP_NAME="Pane Dev"
APP="$ROOT/build/$APP_NAME.app"
CONTENTS="$APP/Contents"

say() { printf '\033[1m==>\033[0m %s\n' "$*"; }

# ---- 1. editor bundle -------------------------------------------------------------------------
if [[ "$SKIP_EDITOR" -eq 0 ]]; then
	say "Building editor bundle"
	if [[ ! -d "$ROOT/Editor/node_modules" ]]; then
		( cd "$ROOT/Editor" && npm ci --no-audit --no-fund )
	fi
	( cd "$ROOT/Editor" && npm run build )
fi

if [[ ! -f "$ROOT/Editor/dist/index.html" ]]; then
	echo "error: Editor/dist/index.html is missing — run without --skip-editor" >&2
	exit 1
fi

# ---- 2. swift binary --------------------------------------------------------------------------
# `${arr[@]+"${arr[@]}"}` rather than plain `"${arr[@]}"`, and it is not superstition: under `set -u`
# **bash 3.2 treats an empty array's expansion as an unbound variable**, and bash 3.2 is what
# /bin/bash is on macOS. It only ever fails where the array is empty — that is, every build without
# --universal — and never on a machine whose PATH finds a modern bash first, which is why this ran
# clean here for weeks and failed on CI's first attempt.
say "Building Pane ($CONFIG${ARCH_ARGS:+, universal})"
swift build -c "$CONFIG" ${ARCH_ARGS[@]+"${ARCH_ARGS[@]}"} --product Pane

BIN="$(swift build -c "$CONFIG" ${ARCH_ARGS[@]+"${ARCH_ARGS[@]}"} --product Pane --show-bin-path)/Pane"
[[ -f "$BIN" ]] || { echo "error: binary not found at $BIN" >&2; exit 1; }

# ---- 3. bundle layout -------------------------------------------------------------------------
say "Assembling $APP"
rm -rf "$APP"
mkdir -p "$CONTENTS/MacOS" "$CONTENTS/Resources"

cp "$BIN" "$CONTENTS/MacOS/Pane"
cp -R "$ROOT/Editor/dist/." "$CONTENTS/Resources/Editor/"

# Static bundle resources — currently the menu bar template images. Flat rather than in a
# subdirectory because `NSImage(named:)` only searches the top level of Resources, and going through
# a subdirectory would mean loading them by path and losing the automatic @2x/@3x selection.
if [[ -d "$ROOT/Resources" ]]; then
	cp -R "$ROOT/Resources/." "$CONTENTS/Resources/"
fi

# The preset markdown themes (decision 19). They ship inside the bundle and are copied out to
# ~/Library/Application Support/Pane/Themes the first time Pane runs, where they are ordinary files
# the user owns and can edit or delete.
if [[ -d "$ROOT/Themes" ]]; then
	mkdir -p "$CONTENTS/Resources/Themes"
	cp -R "$ROOT/Themes/." "$CONTENTS/Resources/Themes/"
fi

# The interface languages (Locales/<code>/strings.json + welcome.md). Copied whole, so a new language
# directory ships with no edit here. The Swift side reads them at runtime (PaneKit/Localization.swift)
# and the web bundle has already inlined its `editor.*` half at build time.
if [[ -d "$ROOT/Locales" ]]; then
	mkdir -p "$CONTENTS/Resources/Locales"
	# `README.md` is for contributors, not for the bundle.
	rsync -a --exclude 'README.md' "$ROOT/Locales/" "$CONTENTS/Resources/Locales/"
fi

sed -e "s/__VERSION__/$VERSION/" -e "s/__BUILD__/$BUILD_NUMBER/" \
	"$ROOT/Scripts/Info.plist" > "$CONTENTS/Info.plist"

# Declare every shipped language in Info.plist, discovered from the same directories.
#
# Without CFBundleLocalizations macOS treats the app as English-only, and its own chrome — the open
# and save panels, the standard Alert buttons, the Edit menu's system items — stays English no matter
# what the user's language is. The list is built from Locales/ so it cannot drift from what ships.
if [[ -d "$ROOT/Locales" ]]; then
	/usr/libexec/PlistBuddy -c "Add :CFBundleLocalizations array" "$CONTENTS/Info.plist" >/dev/null
	index=0
	for dir in "$ROOT"/Locales/*/; do
		[[ -f "$dir/strings.json" ]] || continue
		/usr/libexec/PlistBuddy -c "Add :CFBundleLocalizations:$index string $(basename "$dir")" \
			"$CONTENTS/Info.plist" >/dev/null
		index=$((index + 1))
	done
fi

# The channel is stamped into the bundle; inherited environment cannot redirect its settings.
# A dev channel can use release optimization without taking the installed app's identity or data.
if [[ "$CHANNEL" == "dev" ]]; then
	/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier com.tiylabs.pane.dev" "$CONTENTS/Info.plist"
	/usr/libexec/PlistBuddy -c "Set :CFBundleName Pane Dev" "$CONTENTS/Info.plist"
	/usr/libexec/PlistBuddy -c "Add :CFBundleDisplayName string Pane Dev" "$CONTENTS/Info.plist"
	/usr/libexec/PlistBuddy -c "Add :PaneScratchBuild bool true" "$CONTENTS/Info.plist"
fi

printf 'APPL????' > "$CONTENTS/PkgInfo"

ICON="$ROOT/Scripts/AppIcon.icns"
[[ "$CHANNEL" == "dev" ]] && ICON="$ROOT/Scripts/AppIcon-dev.icns"
if [[ -f "$ICON" ]]; then
	cp "$ICON" "$CONTENTS/Resources/AppIcon.icns"
	/usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string AppIcon" "$CONTENTS/Info.plist" >/dev/null
fi

# ---- 4. signature -----------------------------------------------------------------------------
# Two modes, chosen by PANE_SIGN_IDENTITY:
#
#   unset — ad-hoc. Local and CI builds. An arm64 Mach-O with no signature at all will not launch, so
#           this is not optional, but it carries no identity and Gatekeeper will not accept it.
#   set   — Developer ID with the hardened runtime and a secure timestamp, which is what notarization
#           requires. No --deep: the bundle holds exactly one executable and no nested code, and
#           Apple deprecates --deep for signing. No entitlements file either — WKWebView, Carbon
#           hotkeys and SMAppService need none under the hardened runtime.
if [[ -n "${PANE_SIGN_IDENTITY:-}" ]]; then
	say "Signing with Developer ID: $PANE_SIGN_IDENTITY"
	codesign --force --options runtime --timestamp --sign "$PANE_SIGN_IDENTITY" "$APP"
else
	say "Ad-hoc signing"
	codesign --force --sign - --timestamp=none "$APP"
fi
codesign --verify --deep --strict "$APP"

say "Built $APP ($VERSION build $BUILD_NUMBER)"
