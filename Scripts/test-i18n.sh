#!/usr/bin/env bash
# The editor's language switch: real bundle, real WKWebView, the real Locales/ files.
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ "${1:-}" != "--skip-editor" ]]; then
	echo "==> Building the editor bundle"
	(cd Editor && node build.mjs >/dev/null)
fi

echo "==> Running the i18n suite"
exec swift Scripts/editor-probe.swift "$PWD/Editor/dist/index.html" "$PWD/Editor/tests/i18n.test.js"
