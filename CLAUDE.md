# CLAUDE.md

Guidance for Claude Code (and other coding agents) working in this repository.

## Project

Tiledown is a tile-native static site generator. A page is a tree of typed
**tiles** (not Markdown); the engine renders it to static HTML for GitHub Pages.
The engine library is `TileKit`, the CLI is `tile-down`, the namespace root is
`TileDown`. The engine targets macOS and Linux. A native macOS editor app over the
same tile model is a separate, future concern. Architecture: [docs/DESIGN.md](docs/DESIGN.md).

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
swift run tile-down
```

The engine package is not committed yet; these are the intended commands once it
lands.
