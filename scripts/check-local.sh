#!/usr/bin/env bash
# Full local verification stack. Runs the mechanical style gates, Swift format
# and lint checks, Swift build and tests, then the local Playwright browser gate.
#
# Set TILEDOWN_SKIP_BROWSER=1 to skip the browser gate for a narrow local-only
# iteration. Do not use that skip for release checks or browser-facing changes.

set -euo pipefail

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$ROOT"

scripts/check-style.sh
scripts/check-namespacing.sh

if ! command -v swiftformat >/dev/null 2>&1; then
  echo "check-local: swiftformat is required." >&2
  exit 1
fi
swiftformat . --config .swiftformat --lint

if ! command -v swiftlint >/dev/null 2>&1; then
  echo "check-local: swiftlint is required." >&2
  exit 1
fi
swiftlint --config .swiftlint.yml --strict

( cd Packages && swift build && swift test )

case "${TILEDOWN_SKIP_BROWSER:-0}" in
  1|true|TRUE|yes|YES)
    echo "check-local: skipping Playwright browser gate because TILEDOWN_SKIP_BROWSER is set." >&2
    ;;
  *)
    Packages/Tests/Browser/run.sh
    ;;
esac
