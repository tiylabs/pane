#!/usr/bin/env bash
#
# Runs the PlumeKit suite.
#
# Not `swift test`: neither XCTest nor swift-testing ships with the Command Line Tools, so the
# standard runner needs a full Xcode install. The suite is an ordinary executable instead, which
# means a fresh checkout can be tested with nothing but the toolchain that builds the app.
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# SwiftPM's Xcode build-system layout is not always .build/<triple>/<config>; make the
# test-only resource path explicit rather than relying on the executable's directory depth.
export PLUME_LOCALES="${PLUME_LOCALES:-$ROOT/Locales}"
exec swift run "$@" PlumeKitTests
