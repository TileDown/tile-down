# Next Steps

Current implementation plan for Tiledown after the first tile renderer registry
slice.

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
- Page-local tile CSS and browser JavaScript exposed to templates.
- Service manifest and service operation contract models.
- `service-form` request validation, binding, and generated browser output for
  `remote` and `proxy` modes.
- `TileKit.ServiceForm.TileRenderer`, a tile renderer adapter that resolves a
  service contract through `TileKit.Service.ContractResolving`, binds the
  request, and delegates output to `TileKit.ServiceForm.Renderer`. The CLI
  registers it in `TileKit.Tile.Registry` for the `service-form` type id.

The wiring slice is done: a `:::tile service-form` block now renders through the
normal site pipeline. The CLI's contract resolver is still empty, so a
service-form tile fails with a typed missing-service error until service binding
configuration lands.

## Working Constraints

- Keep `TileCore` tiny.
- Keep `TileSite` generic. It should know about tile rendering only through
  `TileKit.Tile.Registry`.
- Keep implementation targets thin. Put pure validation, binding, rendering,
  and context preparation in domain targets.
- Add an implementation target only for concrete I/O such as filesystem, HTTP,
  process execution, or platform-specific behavior.
- Do not add a dependency until a slice has an acceptance check that needs it.
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

Bindings are constructed as direct values; a config file format is deferred until
CLI config loading needs it ("add YAML only when needed"). HTTP loading stays for
a later `TileServiceImpl` slice. Covered by `TileServiceImplTests`: resolve from a
file, missing service, unreadable file, malformed file, availability carried, and
a file-resolved contract rendering through the service-form path without leaking
server credentials.

### 3. Add derived JSON output

Goal: expose the parsed site and tile structure for tests, debugging,
interchange, and future editor work without making JSON canonical.

Design:

- Introduce `TileOutput` only when the second output renderer is added.
- Add an output renderer protocol and an injected output renderer registry.
- HTML remains the first output.
- JSON is derived from parsed source and resolved page data.
- JSON output must preserve tile type ids, property order, unknown tile data, and
  diagnostics.

Acceptance:

- A build can emit HTML and JSON for the same source page.
- JSON output is deterministic.
- JSON output is tested against a fixture.
- No source authoring path treats JSON as canonical.

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

Still open: definition-driven canonical property order (waits on tile definitions
with schema), and exposing canonical serialization through a `tiledown fmt`
command.

### 5. Add asset declarations and deduplication

Goal: move from raw page-local CSS and JavaScript strings toward explicit asset
declarations.

Design:

- Keep the existing `TileKit.Tile.Rendered` fields as the current simple path.
- Add asset declaration values when more than one tile needs shared runtime
  code.
- Deduplicate identical runtime assets per page.
- Later, lift site-wide asset behavior into `TileAsset`.
- Keep transforms such as Sass and CSS minification deferred until templates
  require them.

Acceptance:

- Multiple identical service-form tiles do not duplicate shared runtime JS more
  than the chosen asset policy allows.
- Page-specific data remains per tile.
- Asset ordering is deterministic.

### 6. Add the first named tiles

Implement named tiles only after the generic mechanics exist.

Recommended order:

| Tile | First mode | Why |
|---|---|---|
| `youtube-video` | `static` | proves safe iframe embeds and provider manifests |
| `poll` | `local` | proves browser-local state and localStorage conventions |
| `email-response` | `proxy` | proves secret-backed action tiles |
| `comments` | `remote` or `proxy` | proves public widget and private API branches |
| `chart` | `static` or `build` | proves structured data display and future asset handling |

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
4. `tiledown serve`
5. Optional proxy support

Keep `serve` and proxy support separate from the core generator. Runtime proxy
support needs a server dependency and belongs behind its own protocol and target
boundary.

## Package Placement

| Work | Target |
|---|---|
| service contract values, validation, and resolver protocol | `TileService` |
| service-form tile renderer adapter | `TileServiceForm` |
| tile registry registration | CLI or future composition target |
| site generator orchestration | `TileSite` |
| local filesystem I/O | `TileSiteImpl` |
| future local or HTTP service contract loading | future `TileServiceImpl` |
| future JSON, feed, and output renderer registry | future `TileOutput` |
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
