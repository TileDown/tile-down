# Changelog

All notable changes to Tiledown are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Slug override: a non-empty `slug` value in a page's front matter overrides the
  folder-derived slug, deciding the output path the page publishes under.
  Surrounding slashes are trimmed, so `slug: /custom/` and `slug: custom` agree,
  and two pages that resolve to the same slug raise a typed build error rather
  than silently clobbering each other's output. (#44)

- GFM tables: pipe tables render to a real `<table>` with `<thead>`/`<tbody>`
  and per-column alignment from the `:--`/`--:`/`:-:` markers (emitted as inline
  `text-align`, so alignment works without theme CSS). Cells render inline
  markup; both built-in themes style tables. (#43)

- Drafts: a page with `draft: true` in its front matter is excluded from the
  whole build, no output file, and absent from navigation, the post listing, and
  the feed. Unset or any non-truthy value publishes as normal. The
  `build-site --drafts` flag includes drafts for local preview. (#42)

- `appearance` site setting: choose how the site offers dark and light. `toggle`
  (default) shows a control that follows the OS until the visitor picks, then
  remembers it; `auto` follows the OS with no control; `light` and `dark` pin one
  appearance and emit no toggle. Set it in `tiledown.yml` as `appearance: <mode>`.
  Forced modes set `data-theme` on the document; `toggle` emits the button and
  its no-flash script only when selected.

### Fixed

- Asset copying no longer clobbers generated output or publishes build inputs.
  A content file whose destination collides with a generated page, stylesheet,
  or feed is skipped, and `tiledown.yml`/`tiledown.yaml` and `.DS_Store` are
  never copied into the output.
- Identical tile JavaScript is now deduplicated per page (mirroring tile CSS), so
  a runtime that binds every instance by a shared selector is emitted once and
  does not double-bind when the same tile type repeats on a page.
- The RSS feed strips XML-1.0-illegal control characters from post content and
  metadata, so a stray control byte in a post no longer makes the whole feed
  not-well-formed.

### Added

- Two built-in demo tiles. `callout` is a static titled box (HTML plus themed
  CSS, no runtime) and `counter` is a `local`-mode button that counts clicks in
  the browser, demonstrating a tile that emits scoped JavaScript. Both are
  registered by the CLI. The built-in layouts now emit a page's collected tile
  JavaScript in a `<script>` before `</body>`, so a `local` tile actually runs.

- Post listing: a page with `postList: true` in its front matter renders a card
  list of the site's posts after its content, in both built-in layouts. Each card
  is a thumbnail (the post's `image`) on the left with the title, date, and
  description on the right. Templates get `site.posts`, every page under `posts/`
  with a `date`, newest first (the same selection the RSS feed uses). The hero on
  a post and the thumbnail in the listing are now capped in size by the theme so
  an image no longer renders full-bleed.

### Changed

- Mustache sections over a missing key now render nothing (falsey), per the
  Mustache spec, instead of throwing. This makes an optional field such as
  `page.image` safe in a shared layout. A missing plain interpolation
  (`{{ x }}`) still throws, since that is an authoring error.

### Added

- Post hero images: a page with an `image` front-matter value renders it as a
  hero at the top of the content in both built-in layouts (`<img class="td-hero">`).
  A page without `image` is unchanged.

- Full-text RSS: each feed item now carries the whole rendered post body in a
  `<content:encoded>` element (CDATA), not just the front-matter summary, so
  readers show the complete article. The feed declares the
  `content` namespace; `<description>` remains the summary.

- Asset copying: `tiledown build-site` now copies every non-Markdown file under
  the content root verbatim into the output, preserving its relative path. One
  rule serves both a site-level `assets/` tree and a page-local file beside its
  `index.md`, so a Markdown image such as `![logo](/assets/images/logo.png)`
  resolves once its file lands in the output. Markdown stays source: an
  `index.md` becomes a page and any other `.md` is ignored, neither is copied.
  `TileKit.Site.FileSystem` gains a binary-safe `copyFile(from:to:)`.

- Image-checking pass: the generator runs an injected
  `TileKit.Site.ImageChecking` over the content's image assets on every build.
  The default `TileKit.Site.PassthroughImageChecker` accepts everything, so the
  step is inert until a real checker (missing references, oversize files,
  missing alt text) replaces it. A checker can reject a build by throwing.

- Minimal demo site support: `tiledown build-site` now reads an optional
  `tiledown.yml` or `tiledown.yaml` file from the content root. The flat config
  format supports `title`, `baseURL`, `layout`, `theme`, `rss`, RSS metadata, and
  `social.*` footer links. Built-in layouts render footer social links, an RSS
  link, and a "Built with TileKit" footer credit. When RSS is enabled, content
  builds write `feed.xml` from dated pages under `posts/`. The new
  `TileKit.Site.Theme.system` theme provides a crisp platform-native light and
  dark design. A minimal example site lives in `Examples/minimal-site/`.

- CLI site builds now work without a hand-written template:
  `tiledown build-site <content-dir> <output-dir>` uses the built-in top-nav
  layout and the standard theme by default, producing a styled, navigable site
  from content alone. The explicit custom-template form remains available as
  `tiledown build-site <content-dir> <template.html> <output-dir>`.
  `TileKit.Site.TemplateSource` models this choice as `.layout(Layout)` or
  `.file(path:)`, replacing raw template paths on `ContentBuildRequest`.
  `Configuration.theme` now defaults to `.standard`; pass `theme: nil` for an
  unstyled build where tiles still carry their own CSS.

- Built-in theme: `TileKit.Site.Theme.standard` is the first built-in theme, a warm,
  readable design with a centered measure. It defines its semantic theme properties
  (`--td-*`) twice, a light set on `:root` and a dark set under `prefers-color-scheme:
  dark` and `[data-theme="dark"]`, so light and dark are a mode of the theme rather than
  separate themes, plus reset and base styles for the layout regions. A theme is
  orthogonal to a layout: any layout wears any theme. It is the default site
  theme; pass `Configuration.theme: nil` for an unstyled build. The generator
  composes the theme's properties, reset, and base into the shared stylesheet's
  cascade layers, so a themed site always emits a `styles.css`. See
  [docs/decisions/theming.md](docs/decisions/theming.md) and
  [docs/decisions/site-structure-navigation.md](docs/decisions/site-structure-navigation.md).

- Built-in layouts: `TileKit.Site.Layout` ships two page layouts, `topNav`
  (horizontal nav across the top) and `leftSidebar` (vertical nav in a left
  sidebar), the two primary placements the research supports. Each is a Mustache
  template that arranges header/sidebar, navigation (built from `site.sections`),
  main content, and a footer, and links the shared stylesheet. A layout is a
  template, not Swift that emits HTML; all layouts use the same data and differ only
  in how they arrange the regions. The closed enum of cases is the selection itself
  (the engine ships a curated few, not an open extension point), and
  `TemplateSource.layout(_:)` wires that selection into content builds. See
  [docs/decisions/site-structure-navigation.md](docs/decisions/site-structure-navigation.md).

- Site navigation: templates can build a menu from `site.sections`, the site's top-level
  sections (each section's `index.md` landing page, i.e. the depth-1 pages), ordered by a
  front-matter `weight` (pages without a weight sort last, then alphabetically by title,
  then by slug for a fully deterministic order).
  The root page is the home page, not a section. The engine derives sections (the content
  tree is encoded in slugs) because logic-less Mustache cannot filter or sort. See
  [docs/decisions/site-structure-navigation.md](docs/decisions/site-structure-navigation.md).

- Site-level shared stylesheet: a multi-page build now collects every tile's CSS into one
  `styles.css` at the output root, deduplicated across the whole site, so a tile type used
  on many pages emits its CSS once (not per page). `TileKit.Output.Stylesheet` carries the
  per-layer CSS fragments and merges across pages; `TileKit.Output.Assets` exposes it (with a
  computed `css` for the inline form). The stylesheet path is exposed to templates as
  `site.stylesheetPath` (baseURL-joined) for a `<link>`. Single-page `build` still inlines.
  Part of #17.

- Site-wide configuration: `TileKit.Site.Configuration` (`title`, `baseURL`) is carried
  on the build requests and exposed to templates under `site` (`site.title`,
  `site.baseURL`). The first-class site-scoped counterpart to per-page front matter, the
  foundation for site-level assets and theming (#17). Carried as direct values; loading
  it from a config file is a later concern.

- Tiles can now reject the site theme. `TileKit.Tile.Rendered` carries a
  `TileKit.Tile.StylePosture` (`themed` by default, or `overriding`), and
  `TileKit.Output.HTMLRenderer` places `themed` CSS in the `theme` layer and
  `overriding` CSS in the later `tile-override` layer, which wins over the theme
  regardless of specificity. Existing tiles are unaffected (posture defaults to
  `themed`). See [docs/decisions/theming.md](docs/decisions/theming.md).

- Tile CSS is now wrapped in CSS cascade layers and deduplicated. `TileKit.Output.HTMLRenderer`
  emits the canonical layer order `@layer reset, theme, tile-override;` and places tile
  component CSS inside the `theme` layer, so no tile rule can sit unlayered and silently
  outrank the theme. Identical CSS fragments are emitted once per page (a tile type repeated
  on a page no longer duplicates its CSS). See
  [docs/decisions/theming.md](docs/decisions/theming.md) and
  [docs/research/theming-styling-api.md](docs/research/theming-styling-api.md).

- HTML rendering now flows through the output renderer seam: `TileKit.Output.HTMLRenderer`
  is the first output renderer (beside `TileKit.Output.JSONRenderer`), projecting a
  parsed document's block tree to body HTML and collecting page-local CSS and
  JavaScript into the new `TileKit.Output.Artifact.assets` (`TileKit.Output.Assets`).
  `TileKit.Site.Generator` no longer renders HTML inline; it parses the document,
  delegates body rendering to an injected `TileKit.Output.Rendering`, and composes the
  page template as before. HTML output is byte-identical to the previous inline path.

- `tiledown fmt` command: rewrites a Tiledown Markdown document to its canonical
  form, the CLI consumer of the serializer's fixed-point law. `TileKit.Site.DocumentFormatter`
  splits the raw front matter off (preserved verbatim, since front matter has no
  canonical serializer yet), canonicalizes the body through
  `TileKit.Site.DocumentSerializer`, and recomposes; `isCanonical(_:)` is exactly
  `format(x) == x`. A new `TileKit.Source.FrontMatterSplitting` seam returns the raw
  split (`TileKit.Source.Split`), and `FrontMatterParser.parse` now decodes that same
  split, so there is one definition of where front matter ends. The command prints the
  canonical form to stdout by default, `--write` rewrites in place, and `--check` exits
  non-zero (cleanly) when a file is not already canonical, for use as a CI gate.

- Derived JSON output: a new `TileOutput` target carrying the output renderer seam
  (DESIGN G7, § 8.3). `TileKit.Output.Rendering` is the renderer Strategy (a
  `formatID` plus `render(_:) -> Artifact`), `TileKit.Output.Registry` is the
  injected registry that dispatches a `TileKit.Output.Document` by format id (the
  structural twin of `TileKit.Tile.Registry`; an unregistered format throws
  `TileKit.Output.RenderingError.unknownFormat` rather than guessing).
  `TileKit.Output.JSONRenderer` is the second output renderer (HTML is the first),
  projecting the parsed tile tree into deterministic JSON: tile type ids, source
  property order (properties are an ordered array, not an object), both value kinds
  (tagged `string`/`list`), and unknown tile data all survive. JSON is a derived
  view, never canonical. A `tiledown json <source.md> <output.json>` command writes
  it. See [docs/DESIGN.md](docs/DESIGN.md) § 7.2 and § 8.3.

- Canonical serialization for the whole document: `TileKit.Markdown.CommonMarkFormatter`
  normalizes prose via swift-markdown's `MarkupFormatter` (ATX headings, `-` markers,
  fenced code, `*` emphasis), behind a `TileKit.Markdown.Formatting` seam, and
  `TileKit.Site.DocumentSerializer` composes prose and tile canonicalization into a
  fixed-point Tiledown Markdown document. Custom ordered-list start is normalized to
  1 (a documented profile property; swift-markdown #76). See
  [docs/markdown-profile.md](docs/markdown-profile.md).

- Real CommonMark rendering via [swift-markdown](https://github.com/apple/swift-markdown):
  `TileKit.Markdown.CommonMarkRenderer` parses prose into swift-markdown's typed
  tree and emits HTML for headings, paragraphs, emphasis, strong, inline and
  fenced code, links, images, lists, block quotes, and breaks. Raw HTML is escaped,
  not passed through. The first external dependency. See
  [docs/markdown-profile.md](docs/markdown-profile.md).
- `TileKit.Tile.DirectiveSerializer`: serializes the parsed tile block tree back
  to Tiledown Markdown (tile blocks in one canonical form, preserving unknown tile
  types and properties; Markdown blocks verbatim), the `put` inverse of the
  directive parser. Round-trip law tests assert the research's semantic invariant:
  PutGet (`parse(serialize(parse(x))) == parse(x)`) and PutPut (canonical output is
  a fixed point). Byte identity is not a goal.

### Changed

- `TileKit.Markdown.Rendering` now refines `Sendable`, matching the other render and
  parse seams, so output renderers that hold one can be `Sendable`.

### Fixed

- `TileKit.Tile.DirectiveParser` now tracks fenced code blocks, so a `:::tile`
  line inside a ``` or `~~~` code fence is treated as Markdown content instead of
  being mis-parsed as a tile directive (which previously threw
  `missingClosingFence`). This lets documents show tile examples in code blocks.
  Fence detection follows CommonMark's rule that a backtick fence's info string
  may not contain a backtick, so an inline code span like ```` ```inline``` ````
  is not treated as a fence opener.

### Removed

- `TileKit.Markdown.BasicHTMLRenderer`, the placeholder heading/paragraph renderer,
  replaced by `CommonMarkRenderer`.

## [0.1.0] - 2026-05-29

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
- A `TileKit.ServiceForm.TileRenderer` adapter that registers `service-form`
  through the tile registry, resolving the referenced contract via an injected
  `TileKit.Service.ContractResolving` seam, with an in-memory resolver first.
- `TileKit.Service.Binding` site bindings (contract source, mode, proxy route,
  availability policy, declarative auth binding), kept separate from contracts,
  plus a `TileServiceImpl` target with `TileKit.Service.LocalFileContractResolver`
  for file-backed contract loading.
- `tiledown version` (and `--version`) reports the product version.
- `docs/linux-testing.md`: how to build and test on Linux through Docker/Colima,
  Podman, a Lima VM, a native toolchain, or cross-compilation.
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
  gates on macOS and Linux.

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
