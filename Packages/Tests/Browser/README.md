# Browser tests

End-to-end tests that drive a Tiledown-generated site in a real browser
(Chromium, via Playwright) and assert the rendered output: tables render,
images decode, drafts are excluded, slug overrides resolve, the post listing and
RSS feed contain the right posts, and the dark/light toggle actually changes the
page and persists.

These cover what the Swift unit tests cannot: the *rendered* result in a browser
(computed styles, image decoding, client-side tile JavaScript, the toggle).

## Why Python, not Swift

Tiledown's rule is Swift-only for tooling. This suite is a **documented
exception**: Playwright has official bindings for Node, Python, Java, and .NET
but **none for Swift**. Driving a browser from Swift would mean hand-rolling a
WebDriver or Chrome DevTools Protocol client (no mature library) or shelling out
to a JS/Python Playwright script anyway. Until a Swift-native browser-automation
story exists, the browser gate lives here in Python. The engine and CLI remain
Swift-only; this is test tooling that never ships in the product.

## Running

```sh
# from the repo root
Packages/Tests/Browser/run.sh
```

`run.sh` builds the fixture site twice (normal and `--drafts`), serves both,
runs `test_site.py`, and tears everything down. Exit code is 0 only if every
check passes.

This browser gate is part of the full local stack:

```sh
# from the repo root
scripts/check-local.sh
```

It is also run by the repo's `pre-push` hook when hooks are enabled and by the
Linux browser job in the GitHub workflow. Set `TILEDOWN_SKIP_BROWSER=1` only for a
narrow local iteration where browser coverage is intentionally deferred.

## Prerequisites

- A Swift toolchain (the script builds `tiledown` via `swift run`).
- Python Playwright and a Chromium:
  ```sh
  pip install playwright && playwright install chromium
  # or, on macOS with Homebrew: brew install playwright
  ```
  Set `PYTHON` if your interpreter is not `python3`.

## Fixture

`fixture/content/` is a small, self-contained site that deliberately exercises
every feature under test (a table, an image, a `local` counter tile, a draft
post, a slug override, a post listing, RSS, and the standard theme with the
appearance toggle). It is committed demo content, independent of any real site.
