# Next Steps

Current implementation plan for Tiledown after the current static-site and tile
registry slices.

## Purpose

This document turns the design in [DESIGN.md](DESIGN.md) into an ordered work
queue. Keep it practical and current. When a slice lands, update this file in
the same change or remove the shipped item.

## Current Baseline

The repository currently has:

- A multi-target Swift package under `Packages/`.
- A `tiledown` CLI front door.
- Front matter parsing, basic Markdown rendering, Mustache-style templates, and
  content-directory page generation.
- Content records and query execution.
- Tiledown Markdown tile directive parsing.
- `TileKit.Tile.Registry`, `TileKit.Tile.Rendering`, and
  `TileKit.Tile.Rendered`.
- Site generation that renders Markdown blocks and tile blocks in source order.
- Built-in `topNav` and `leftSidebar` layouts, selected through
  `TileKit.Site.TemplateSource`.
- The built-in `standard` and `system` themes, applied through
  `TileKit.Site.Configuration`.
- `tiledown build-site <content-dir> <output-dir>`, which uses the built-in
  top-nav layout and standard theme without requiring a template file, and reads
  optional `tiledown.yml` settings from the content root.
- RSS feed output for the shared post collection when enabled in `tiledown.yml`.
- `Examples/minimal-site/`, a small content-only demo with about, contact, posts,
  footer social links, the `system` theme, and RSS.
- Page-local tile CSS and browser JavaScript exposed to templates.
- Built-in `callout`, `counter`, `embed`, `chart`, `mermaid`, `service-form`, and
  `buttondown` tile renderers registered by the CLI.
- `TileKit.Site.ButtondownPageGenerator`, a generated-page provider that writes
  local Buttondown redirect target pages when the CLI opts into the provider.
- Service manifest and service operation contract models.
- `service-form` request validation, binding, and generated browser output for
  `remote` and `proxy` modes.
- `TileKit.ServiceForm.TileRenderer`, a tile renderer adapter that resolves a
  service contract through `TileKit.Service.ContractResolving`, binds the
  request, and delegates output to `TileKit.ServiceForm.Renderer`. The CLI
  registers it in `TileKit.Tile.Registry` for the `service-form` type id.

The wiring slice is done: a `:::tile service-form` block now renders through the
normal site pipeline. The CLI reads `service.<id>.*` bindings from
`tiledown.yml`, resolves local contract files through
`TileKit.Service.LocalFileContractResolver`, and keeps in-root contract files out
of the public output.

## Working Constraints

- Keep `TileCore` tiny.
- Keep `TileSite` generic. It should know about tile rendering only through
  `TileKit.Tile.Registry`.
- Keep implementation targets thin. Put pure validation, binding, rendering,
  and context preparation in domain targets.
- Add an implementation target only for concrete I/O such as filesystem, HTTP,
  process execution, or platform-specific behavior.
- Do not add new external dependencies.
- Do not read process environment in library code. The CLI or an injected
  resolver passes typed values into the library.
- Generated browser JavaScript is allowed for tile runtime behavior. JavaScript
  is not build tooling.

## Immediate Sequence

### 1. Register `service-form` through the tile registry (done)

Shipped. `TileKit.Service.ContractResolving` is the resolver seam, with a pure
`TileKit.Service.InMemoryContractResolver` as the first concrete.
`TileKit.ServiceForm.TileRenderer` conforms to `TileKit.Tile.Rendering`, converts
a `TileKit.Tile.Instance` into a `TileKit.Tile.ServiceFormRequest`, resolves the
contract, binds through `TileKit.ServiceForm.Binder`, and delegates output to
`TileKit.ServiceForm.Renderer`. The CLI registers it for the `service-form` type
id. `TileSite` still does not import `TileServiceForm`.

Covered by tests: `TileSiteTests` builds a page containing `:::tile service-form`
and asserts generated form HTML plus CSS and browser JavaScript exposed through
`page.assets.css` and `page.assets.javascript`. `TileServiceFormTests` asserts
that missing services, missing operations, unsupported modes, unsafe credential
exposure, and wrong tile types fail with typed errors.

### 2. Add service binding configuration (done)

Shipped. `TileKit.Service.Binding` models site bindings (service id, contract
source, mode, optional proxy route, availability, auth binding), separate from
`TileKit.Service.Contract`. `TileKit.Service.Availability` carries the build
policy (`required`/`optional`/`unchecked`); `TileKit.Service.ContractSource` is
`.localFile(path:)` for now (extensible to remote); `TileKit.Service.AuthBinding`
is a declarative placeholder (no secret resolution; `remote` uses a public key,
`server`/`build` reference secrets by name only). A new `TileServiceImpl` target
holds `TileKit.Service.LocalFileContractResolver`, the concrete file-backed
`ContractResolving` that reads a binding's file and decodes a `Contract`. New
`ContractResolutionError` cases cover unreadable and malformed files.

Bindings can be declared in `tiledown.yml` with
`service.<id>.contract`, `service.<id>.mode`, optional
`service.<id>.proxyRoute`, and optional `service.<id>.availability`. The CLI
maps those project-file values to `TileKit.Service.Binding`, resolves local
contract files at render time, and marks in-root contract files as private build
inputs so they are not mirrored into `dist/`. HTTP loading stays for a later
`TileServiceImpl` slice. Covered by `TileServiceImplTests`, `TileSiteTests`, and
`TiledownCLITests`: resolve from a file, missing service, unreadable file,
malformed file, availability carried, project-file parsing, `build-site`
service-form rendering, and no server credential or contract-file leak.

### 3. Add derived JSON output (done)

Shipped. The new `TileOutput` target carries the output renderer seam:
`TileKit.Output.Rendering` (the renderer Strategy: a `formatID` plus
`render(_:) -> Artifact`), `TileKit.Output.Document` (the renderer input: front
matter, the parsed tile block tree, slug), `TileKit.Output.Artifact` (contents +
file extension), and `TileKit.Output.Registry`, the injected registry that
dispatches by format id and is the structural twin of `TileKit.Tile.Registry`. An
unregistered format throws `TileKit.Output.RenderingError.unknownFormat` rather
than falling back, because an unknown output format is a wiring error, not a
content edge case. `TileKit.Output.JSONRenderer` is the second output renderer
(HTML is the first); the CLI `tiledown json <source.md> <output.json>` parses
front matter and blocks, then renders through the registry.

The JSON is a derived view of the canonical tile tree, never canonical. The
projection preserves tile type ids, source property order (properties are an
ordered array of `{ key, value }`, not an object, so order survives), both value
kinds (tagged `string`/`list`), and unknown tile data (an unknown tile type
projects like any other, so its type and properties survive). Output is
deterministic (sorted object keys, so dictionary order never leaks). There is no
`diagnostics` field: the engine has no diagnostics model yet, so inventing one
here was rejected; it lands with that model.

Covered by `TileOutputTests`: the JSON renderer (file extension, valid JSON with
trailing newline, self-describing header, determinism across renders and across
front-matter insertion order, block and property order, value-kind tagging,
unknown tile survival, empty document) and the registry (dispatch by explicit and
self-described format id, last-registration-wins, unknown-format throws, the JSON
renderer through the registry).

Two deviations from the § 7.2 sketch, both forced by the project's invariants and
now documented there: `props` is an ordered array (not an object), and no
`id`/`mode` fields (the model does not carry them yet). The fixture is asserted by
decoding the output and checking structure plus determinism, the same semantic
posture the Markdown serializer takes, rather than a byte-golden that would be
fragile across Foundation versions.

HTML now renders through the same seam: `TileKit.Output.HTMLRenderer` is the first
output renderer, `TileKit.Site.Generator` delegates body rendering to an injected
`Output.Rendering` and composes the page template on top, and `Output.Artifact`
gained `assets` (the new `TileKit.Output.Assets`) for the renderer's CSS and
JavaScript. HTML output is byte-identical to the previous inline path. Still open:
add an RSS or feed renderer behind the same seam.

### 4. Add canonical Markdown serialization (tile-block slice done)

`TileKit.Tile.DirectiveSerializer` in `TileTile` serializes the parsed block tree
back to Tiledown Markdown: tile blocks in one canonical form (preserving unknown
tile types and unknown properties, source property order), Markdown blocks
verbatim. `TileTileTests` proves the research's semantic round-trip:

- PutGet: `parse(serialize(parse(x))) == parse(x)`.
- PutPut: the canonical serialization is a fixed point.
- Unknown tile types and unknown properties survive the round-trip.

Byte identity is not a goal (the parser trims values and folds blank lines; the
research rules byte-identity out). Done was taken at the tile-tree level.

Prose canonicalization is now done too: `TileKit.Markdown.CommonMarkFormatter`
(swift-markdown `MarkupFormatter`) normalizes prose to ATX headings, `-` markers,
fenced code, and `*` emphasis, and `TileKit.Site.DocumentSerializer` composes
prose + tiles into a fixed-point canonical document (`TileSiteTests`,
`TileMarkdownTests`). Custom ordered-list start is normalized to 1 (swift-markdown
#76), an accepted profile property documented in `docs/markdown-profile.md`.

The `tiledown fmt` command now exposes this canonical serialization.
`TileKit.Site.DocumentFormatter` splits the raw front matter off (preserved
verbatim through the new `TileKit.Source.FrontMatterSplitting` seam, since front
matter has no canonical serializer yet), canonicalizes the body through
`DocumentSerializer`, and recomposes; `isCanonical(_:)` is `format(x) == x`, the
fixed-point law made observable. The CLI prints to stdout by default, `--write`
rewrites in place, and `--check` is a CI gate (clean non-zero exit when a file is
not canonical). Covered by `DocumentFormatterTests` (fixed point, front matter
preserved verbatim, body canonicalized, no-front-matter, malformed front matter
throws) and `FrontMatterParserTests` (the raw split).

Still open: definition-driven canonical property order (waits on tile definitions
with schema).

### 5. Add asset declarations and deduplication

CSS deduplication and cascade-layer wrapping are done at two altitudes:
per-page dedup and the cascade-layer order live in `TileKit.Output.HTMLRenderer`
(it produces a `TileKit.Output.Stylesheet` of deduplicated fragments per layer),
and cross-page dedup lives in `TileKit.Site.Generator`, which merges every page's
stylesheet into one shared `styles.css` at the output root and links it from each
page via `site.stylesheetPath`, per [docs/decisions/theming.md](decisions/theming.md).
The tile styling posture is now done too: `TileKit.Tile.Rendered` carries a
`TileKit.Tile.StylePosture` (`themed` default, or `overriding`), and the renderer
routes overriding CSS into the `tile-override` layer. The standard site theme and
theme properties are done too. Identical browser JavaScript is also deduplicated
per page by `TileKit.Output.HTMLRenderer`. Still to do below: explicit asset
declarations, an explicit per-tile dedup key (CSS and JavaScript are currently
deduped by content), and a site-wide runtime asset policy.

Goal: move from raw page-local CSS and JavaScript strings toward explicit asset
declarations.

Design:

- Keep the existing `TileKit.Tile.Rendered` fields as the current simple path.
- Add asset declaration values when more than one tile needs shared runtime
  code.
- Keep per-page deduplication deterministic while moving from raw strings to
  named asset declarations.
- Later, lift site-wide asset behavior into `TileAsset`.
- Keep transforms such as Sass and CSS minification deferred until templates
  require them.

Acceptance:

- Multiple identical service-form tiles do not duplicate shared runtime JS more
  than the chosen asset policy allows.
- Page-specific data remains per tile.
- Asset ordering is deterministic.

### 6. Expand named tiles

The first named tile set is no longer hypothetical. The CLI registers static
`callout`, local `counter`, safe `embed`, static SVG `chart`, client-side
`mermaid`, and contract-backed `service-form` renderers.

Remaining recommended order:

| Tile | First mode | Why |
|---|---|---|
| `poll` | `local` | proves browser-local state and localStorage conventions |
| `email-response` | `proxy` | proves secret-backed action tiles |
| `comments` | `remote` or `proxy` | proves public widget and private API branches |
| provider-specific tiles, if needed | `static` | extend safe `embed` only when a provider needs typed authoring |

Acceptance:

- Each tile is a small renderer or manifest over existing capabilities.
- Provider-specific Swift code is added only when a capability is missing.
- Each tile documents its credential and runtime mode.

### 7. Add CLI workflow commands

Goal: reach a usable static-site workflow.

Order:

1. `tiledown init`
2. `tiledown build` config loading
3. `tiledown watch`
4. `tiledown serve` (first static preview slice exists)
5. Optional proxy support

Keep proxy support separate from the core generator. Runtime proxy support needs
a server dependency and belongs behind its own protocol and target boundary. The
first `serve` slice stays Swift-only: it builds a content directory, serves static
files on `127.0.0.1`, resolves directory `index.html` files, and maps common
content types.

## Package Placement

| Work | Target |
|---|---|
| service contract values, validation, and resolver protocol | `TileService` |
| service-form tile renderer adapter | `TileServiceForm` |
| tile registry registration | CLI or future composition target |
| site generator orchestration | `TileSite` |
| local filesystem I/O | `TileSiteImpl` |
| local service contract loading | `TileServiceImpl` |
| future HTTP service contract loading | future `TileServiceImpl` |
| output renderer seam, registry, and JSON renderer (feed renderers later) | `TileOutput` |
| future asset declarations and transforms | future `TileAsset` |
| future diagnostics sink if warnings grow | future `TileDiagnostics` |

Do not place any of the above in `TileCore`.

## Definition of Done

For each implementation slice:

- Update `docs/DESIGN.md` when architecture changes.
- Update this document when the next-step queue changes.
- Add or update focused Swift Testing tests.
- Run `swift build` from `Packages`.
- Run `swift test` from `Packages`.
- Run formatting, lint, style, namespacing, and whitespace checks from the repo
  root.
- Commit one focused change with a Conventional Commit message.
