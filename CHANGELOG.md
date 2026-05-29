# Changelog

All notable changes to Tiledown are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- First site-generation slice: `tiledown build <source.md> <template.html>
  <output.html>` loads one Markdown file with simple front matter, renders
  heading/paragraph HTML through a Mustache-style template, and writes an HTML
  output file.
- Content-directory generation with `tiledown build-site <content-dir>
  <template.html> <output-dir>`, discovering `index.md` and `index.markdown`
  files and writing slugged `index.html` outputs.
- `Packages/`: initial Swift package scaffold with `TileKit`, `TiledownCLI`, and
  Swift Testing coverage.
- `docs/research/`: research notes for Markdown-canonical tiles, tile functions,
  service-backed tiles, and Toucan parity.
- Community and governance docs: contributing guide, code of conduct, security
  policy, support guide, issue forms, pull request template, and git style hooks.
- `docs/CONVENTIONS.md`: the project's Swift coding conventions.
- `docs/DESIGN.md`: the Tiledown architecture design doc (draft).
- `docs/rules/`: the full per-area coding rules (engineering, code style,
  namespacing, dependency injection, concurrency, cross-platform, testing,
  verification, and more), with an index.
- `AGENTS.md` and `CLAUDE.md`: agent guides pointing to the rules and workflow.
- Mechanical enforcement, local and CI: `scripts/check-style.sh` and
  `scripts/check-namespacing.sh`, a `pre-push` hook running the format, lint,
  namespacing, build, and test gates, and `.github/workflows/ci.yml` mirroring all
  gates on macOS and Linux. Swift gates are inert until the package lands.

### Changed

- Updated the architecture and agent guidance for Tiledown Markdown as the
  canonical source format, the `tiledown` CLI name, Toucan-parity SSG goals, and
  dependency-injected registries.
- Updated SwiftLint settings to ignore SwiftPM build artifacts and align trailing
  comma handling with SwiftFormat.
- Restructured the coding rules: `engineering.md` now holds only judgment
  principles; agent-interaction rules moved to `AGENTS.md`; the no-force-unwrap
  rule is enforced by `.swiftlint.yml`; formatting by `.swiftformat`.
