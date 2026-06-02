#!/usr/bin/env bash
# Build the fixture site (normal + --drafts + system theme + baseURL subpath),
# serve them, run the Playwright browser tests, then tear everything down. Exit
# code propagates from the tests.
#
# Requires: a built `tiledown` (built here) and either Python
# Playwright or `uv` for an ephemeral Python Playwright runner.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Browser/ -> Tests/ -> Packages/. The Swift package (and `tiledown`) live here.
packages="$(cd "$here/../.." && pwd)"
fixture_source="$here/fixture/content"
work="$(mktemp -d)"
normal_fixture="$work/normal-fixture"
drafts_fixture="$work/drafts-fixture"
normal="$work/normal"
drafts="$work/drafts"
system_fixture="$work/system-fixture"
system="$work/system"
base_fixture="$work/base-fixture"
base="$work/base"
normal_port="${NORMAL_PORT:-8090}"
drafts_port="${DRAFTS_PORT:-8091}"
system_port="${SYSTEM_PORT:-8092}"
base_port="${BASE_PORT:-8093}"
python="${PYTHON:-python3}"
pids=()

cleanup() {
  for pid in "${pids[@]:-}"; do kill "$pid" 2>/dev/null || true; done
  for pid in "${pids[@]:-}"; do wait "$pid" 2>/dev/null || true; done
  rm -rf "$work"
}
trap cleanup EXIT

run_browser_checks() {
  if "$python" - <<'PY' >/dev/null 2>&1
import playwright.sync_api
PY
  then
    NORMAL_URL="http://localhost:$normal_port" \
    DRAFTS_URL="http://localhost:$drafts_port" \
    SYSTEM_URL="http://localhost:$system_port" \
    NORMAL_ROOT="$normal" \
    BASE_URL="http://localhost:$base_port" \
      "$python" "$here/test_site.py"
  elif command -v uv >/dev/null 2>&1; then
    NORMAL_URL="http://localhost:$normal_port" \
    DRAFTS_URL="http://localhost:$drafts_port" \
    SYSTEM_URL="http://localhost:$system_port" \
    NORMAL_ROOT="$normal" \
    BASE_URL="http://localhost:$base_port" \
      uv run --with playwright "$python" "$here/test_site.py"
  else
    echo "Python Playwright is not installed. Install it for $python, or install uv for the ephemeral Playwright runner." >&2
    exit 1
  fi
}

set_base_url() {
  local fixture_dir="$1"
  local url="$2"
  local config="$fixture_dir/tiledown.yml"

  if grep -q "^baseURL:" "$config"; then
    perl -0pi -e "s#^baseURL:.*\$#baseURL: $url#m" "$config"
  else
    printf "\nbaseURL: %s\n" "$url" >> "$config"
  fi
}

echo "Building fixture (normal + --drafts + system theme + baseURL subpath)..."
cp -R "$fixture_source" "$normal_fixture"
cp -R "$fixture_source" "$drafts_fixture"
cp -R "$fixture_source" "$system_fixture"
cp -R "$fixture_source" "$base_fixture"
set_base_url "$normal_fixture" "http://localhost:$normal_port"
set_base_url "$drafts_fixture" "http://localhost:$drafts_port"
set_base_url "$system_fixture" "http://localhost:$system_port"
set_base_url "$base_fixture" "http://localhost:$base_port/docs"
( cd "$packages" && swift build --product tiledown )
tiledown="$packages/.build/debug/tiledown"
perl -0pi -e 's/^theme: standard$/theme: system/m' "$system_fixture/tiledown.yml"
grep -qx "theme: system" "$system_fixture/tiledown.yml"
"$tiledown" build-site "$base_fixture" "$base/docs"

# Refuse to run if a port is already taken: a stale server there would answer
# our requests from the wrong directory and the tests would fail confusingly.
for port in "$normal_port" "$drafts_port" "$system_port" "$base_port"; do
  if lsof -ti "tcp:$port" >/dev/null 2>&1; then
    echo "Port $port is already in use. Free it (or set NORMAL_PORT/DRAFTS_PORT/SYSTEM_PORT) and retry." >&2
    exit 1
  fi
done

# `exec` so the backgrounded process IS the server (not a wrapping subshell),
# which makes $! the real PID and lets cleanup kill it instead of orphaning it.
echo "Serving normal on $normal_port, drafts on $drafts_port, system on $system_port, baseURL on $base_port..."
"$tiledown" serve --port "$normal_port" --output "$normal" "$normal_fixture" >/dev/null 2>&1 & pids+=($!)
"$tiledown" serve --drafts --port "$drafts_port" --output "$drafts" "$drafts_fixture" >/dev/null 2>&1 & pids+=($!)
"$tiledown" serve --port "$system_port" --output "$system" "$system_fixture" >/dev/null 2>&1 & pids+=($!)
( cd "$base" && exec python3 -m http.server "$base_port" >/dev/null 2>&1 ) & pids+=($!)

# Wait until each server actually answers, rather than guessing with a fixed sleep.
for port in "$normal_port" "$drafts_port" "$system_port" "$base_port"; do
  for _ in $(seq 1 50); do
    if curl -sf -o /dev/null "http://localhost:$port/"; then break; fi
    sleep 0.1
  done
done

echo "Running browser tests..."
run_browser_checks
