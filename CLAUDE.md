# CLAUDE.md

Guidance for Claude Code (and other coding agents) working in this repository.

## Project

Tiledown is a Swift static site generator with a Markdown-canonical source format
and a typed tile model. Tiledown Markdown is parsed into a tree of typed tiles,
then rendered to static HTML, CSS, browser JavaScript, and optional JSON outputs.
The engine library is `TileKit`, the CLI is `tiledown`, and the package name is
`Tiledown`. The engine targets macOS and Linux. A native macOS and iOS editor app
over the same tile model is a separate, future concern. Architecture:
[docs/DESIGN.md](docs/DESIGN.md).

## Rule loading (do this first)

At session start, read [docs/rules/README.md](docs/rules/README.md) and the rules
it marks as always relevant. Confirm by replying with the token `rules-loaded` and
naming the rule files that apply to the current task. If you cannot name them, you
have not loaded them.

## Read first

- [AGENTS.md](AGENTS.md) - the agent guide: language policy, workflow, commands.
- [docs/rules/](docs/rules/) - the coding conventions. Start at
  [docs/rules/README.md](docs/rules/README.md).
- [CONTRIBUTING.md](CONTRIBUTING.md) - contributor workflow.

## Non-negotiables

- **Swift only**, except JavaScript where it is intrinsic to client-side tile
  output (charts, diagrams, forms, polls). No JS for build logic or tooling.
- **Clarify before coding.** Do not assume requirements. Surface options when a
  real trade-off exists. Do not pre-abstract; add abstraction only at the second
  real consumer.
- **Inject dependencies through `init`.** No singletons. No force-unwrapping in
  shipping code.
- **Namespace every public type** under an `enum`/`struct` that mirrors its
  folder; one non-private type per file; file named for the qualified type.
- **Cross-platform core.** The core builds on macOS and Linux. Guard
  platform-divergent code and put platform-specific dependencies behind a protocol
  seam, one implementation per platform, wired by the composition root. Subprocess
  use is allowed.
- **Verify before claiming done.** Run `swift build` and `swift test`; cite the
  output. Never say "should pass".
- **No AI attribution, no em dashes** in any committed text (commits, comments,
  docs, PRs). Enable the hooks: `git config core.hooksPath .githooks`.

## Commands

```sh
swift build
swift test
swift run tiledown
```

Run these from `Packages/`. The engine package is committed and builds today.
