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
- Mustache-style list sections and nested object lookups, including a `pages`
  collection in content-directory builds.
- A typed content query core with filters, ordering, offset, and limit support
  for future site collections and tile function manifests.
- A `TileTile` domain target with typed tile blocks, source-ordered properties,
  directive parsing, injected tile renderer registry, unknown-tile diagnostics,
  typed `service-form` requests, and tests for structured Tiledown Markdown tile
  blocks.
- A `TileService` domain target with manifest models, capability inventory, and
  validation for manifest-driven provider integrations.
- Service operation contracts for service-backed tiles, including health,
  transport, input/output schema, UI hints, auth references, errors, cache, and
  validation.
- A `TileServiceForm` composition target that binds typed `service-form` tile
  requests to service contract operations and rejects unsafe remote credentials.
- A `TileKit.ServiceForm.Renderer` that emits deterministic generated form HTML,
  scoped CSS, and browser JavaScript for remote and proxy service forms without
  emitting credential ids or secrets.
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

- Split the Swift package into focused domain targets for content, source,
  Markdown, templates, and site generation, with `TileCore` limited to the root
  namespace and product metadata, `TileSiteImpl` holding concrete filesystem I/O,
  and `TileKit` acting as a facade target.
- Changed site generation to receive content discovery through the injected
  `TileKit.Source.ContentDiscovering` protocol.
- Changed site generation to render Markdown and tile directive blocks in source
  order through injected `TileKit.Tile.Parsing` and `TileKit.Tile.Registry`
  values, exposing collected tile CSS and JavaScript as `page.assets`.
- Updated the architecture and agent guidance for Tiledown Markdown as the
  canonical source format, the `tiledown` CLI name, Toucan-parity SSG goals, and
  dependency-injected registries.
- Updated SwiftLint settings to ignore SwiftPM build artifacts and align trailing
  comma handling with SwiftFormat.
- Restructured the coding rules: `engineering.md` now holds only judgment
  principles; agent-interaction rules moved to `AGENTS.md`; the no-force-unwrap
  rule is enforced by `.swiftlint.yml`; formatting by `.swiftformat`.
