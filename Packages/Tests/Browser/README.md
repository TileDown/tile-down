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

`run.sh` builds variants of `Examples/everything/content`, serves the normal,
`--drafts`, and system theme variants through `tiledown serve`, serves the
baseURL subpath variant from its parent directory, runs `test_site.py`, and tears
everything down. Exit code is 0 only if every check passes.

This browser gate is part of the full local stack:

```sh
# from the repo root
scripts/check-local.sh
```

It is also run by the repo's `pre-push` hook when hooks are enabled and by the
Linux browser job in the GitHub workflow. Set `TILEDOWN_SKIP_BROWSER=1` only for a
narrow local iteration where browser coverage is intentionally deferred.

## Prerequisites

- A Swift toolchain (the script builds `tiledown` before serving fixtures).
- Python Playwright and a Chromium:
  ```sh
  pip install playwright && playwright install chromium
  # or, on macOS with Homebrew: brew install playwright
  ```
  Set `PYTHON` if your interpreter is not `python3`.

## Fixture

`Examples/everything/content/` is a small, self-contained site that deliberately
exercises every browser-visible feature under test. It is committed demo
content, independent of any real site, and it doubles as the canonical example
site users can build locally.

When adding a new browser-visible TileDown feature, update
`Examples/everything/content/` and add or adjust the matching checks in
`test_site.py`.
