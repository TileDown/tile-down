# Agent Guide

Guidance for anyone (human or coding agent) writing code in Tiledown.

## What Tiledown is

A tile-native static site generator. The canonical document is a tree of typed
**tiles** (not Markdown), rendered to static HTML for publishing to GitHub Pages.
The engine library is `TileKit`; the CLI is `tile-down`. A native macOS and iOS
visual editor over the same tile model is planned. See [docs/DESIGN.md](docs/DESIGN.md).

## Language policy

Swift for everything. The only exception is JavaScript, and only where it is
intrinsic to the output: client-side tiles (charts, diagrams, forms, polls) emit
HTML and JS that run in the visitor's browser. JS is never used for build logic or
tooling.

## Rules

Conventions live in [docs/rules/](docs/rules/). Read the surrounding files before
writing code and match what is there.

**Read these for any change to engine or tooling code:**

- [docs/rules/engineering.md](docs/rules/engineering.md)
- [docs/rules/code-style.md](docs/rules/code-style.md) and
  [docs/rules/namespacing.md](docs/rules/namespacing.md)
- [docs/rules/dependency-injection.md](docs/rules/dependency-injection.md)
- [docs/rules/concurrency.md](docs/rules/concurrency.md)
- [docs/rules/cross-platform.md](docs/rules/cross-platform.md)
- [docs/rules/testing.md](docs/rules/testing.md) and
  [docs/rules/verification.md](docs/rules/verification.md)

**Load the rest on demand**: testing-discipline, documentation, linux-server,
point-free-dependencies, systematic-debugging, file-naming, folder-grouping,
commits, git-discipline, and (for the planned native app) views, view-models,
components, colors, fonts, and (if Tiledown becomes multi-package) the package
architecture set. The index is [docs/rules/README.md](docs/rules/README.md).

## Workflow

- Clarify ambiguity before coding; do not assume requirements. Surface two or
  three options when a real trade-off exists.
- Verify before claiming done: run `swift build` and `swift test` and cite the
  output. See [docs/rules/verification.md](docs/rules/verification.md).
- Commits follow Conventional Commits. One focused change per PR. A CHANGELOG
  entry for any change touching shipping source.
- No AI attribution and no em dashes in any committed text. The repo ships git
  hooks that enforce this; enable them with `git config core.hooksPath .githooks`.

## Commands

```sh
swift build
swift test
swift run tile-down
```

(The engine package is not yet committed; these are the intended commands once it
lands. See [CONTRIBUTING.md](CONTRIBUTING.md).)
