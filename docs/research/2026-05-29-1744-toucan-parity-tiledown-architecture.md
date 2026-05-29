# Research: Toucan parity and Tiledown architecture

| Field | Value |
|---|---|
| **Created** | 2026-05-29 17:44 CEST |
| **Iteration** | 5 of N |
| **Status** | parity inventory and architecture recommendation |
| **Question** | Which Toucan static-site features should Tiledown carry forward, and where do typed tiles, service functions, Mustache templates, and dependency-injected registries fit? |
| **Context** | Tiledown should cover most Toucan site-generator functionality, but with the repo rules: Swift, namespaces, package boundaries, no unnecessary dependencies, no global state, no hidden environment reads, and all collaborators injected. |
| **Companions** | `2026-05-29-1718-tile-functions-source-evaluation.md`, `2026-05-29-1728-tile-catalog-service-contract.md` |

---

## Headline

Build Tiledown as a Toucan-parity SSG plus typed tile/function infrastructure.

Toucan already proves the needed static-site surface:

- source loading
- front matter
- content types
- properties and relations
- queries, sorting, filtering, and pagination-like iterators
- Markdown rendering
- block directives
- outline and reading time
- Mustache templates
- HTML and JSON outputs
- assets, Sass, and CSS transforms
- build, serve, watch, and init workflows

Tiledown should copy the product capabilities, not the architecture. The main
architectural change is that every variable behavior becomes an injected
registry or protocol implementation rather than a hard-coded string switch.

---

## What Toucan has that we need

| Area | Toucan shape | Tiledown choice |
|---|---|---|
| CLI | Separate `toucan`, `toucan-init`, `toucan-generate`, `toucan-watch`, `toucan-serve` executables | One `tiledown` command with subcommands |
| Source config | YAML target and site config | YAML first, behind decoder protocols |
| Source loading | `contents` tree, `index.md`, `index.yaml`, merged front matter, local assets | Keep the model, make filesystem injected |
| Content model | `ContentType`, `Property`, `Relation`, system keys | Keep the idea, align with tile document model |
| Query model | filters, operators, order, limit, offset, dynamic placeholders | Keep as SSG query contract |
| Iterators | repeated content pages from a query | Keep, likely rename to pagination or collection pages |
| Scopes | `detail`, `list`, `reference`, selected context fields | Keep concept, simplify names if needed |
| Markdown | front matter parser, Swift Markdown HTML renderer | Keep Markdown-canonical source, add typed tile directives |
| Block directives | configurable directive to HTML mapping | Replace with tile definitions where behavior is typed |
| Outline | headings extracted from HTML | Keep |
| Reading time | word-count based estimate | Keep |
| Templates | Mustache views, template overrides, content overrides | Keep Mustache-style renderer behind `TemplateRendering` |
| Output engines | hard-coded `json` and `mustache` switch | Replace with `OutputRendererRegistry` |
| Assets | copy, load, parse, compile Sass, minify CSS | Keep behaviors, inject `AssetBehaviorRegistry` |
| Dev server | Hummingbird static server | CLI-only optional dependency or later target |
| Watch | file monitor plus rebuild command | Later CLI feature, injected watcher |

---

## What not to carry forward unchanged

Do not reproduce these Toucan patterns:

- Hard-coded output engine switch on string ids.
- Hard-coded asset behavior switch on string ids.
- Library code creating encoders, decoders, renderers, and resolvers internally
  when they should be dependencies.
- Synchronous wrappers over async work.
- External command transformers as a core dependency.
- Broad package dependency set before the first vertical slice needs it.
- Multiple executables when one command with subcommands is enough.

Tiledown can still use the same ideas. It should expose them as explicit
contracts and wire concrete implementations in the CLI composition root.

---

## Package shape

Start with one package under `Packages/` and two products:

```text
Packages/
  Package.swift
  Sources/
    TileKit/
    TiledownCLI/
  Tests/
    TileKitTests/
```

Add more modules only when import boundaries are real.

Early namespaces inside `TileKit`:

| Namespace | Responsibility |
|---|---|
| `TileKit.Site` | build request, generator, target, output |
| `TileKit.Source` | source files, front matter, content loading |
| `TileKit.Content` | content type, property, relation, query, scope |
| `TileKit.Markdown` | Markdown source parsing and tile directive parsing |
| `TileKit.Template` | template loading, template rendering contract |
| `TileKit.Tile` | tile model, tile definitions, renderer registry |
| `TileKit.Service` | service manifest, operation schema, auth exposure |
| `TileKit.Asset` | asset declarations and asset behavior registry |
| `TileKit.Output` | output renderers and generated files |
| `TileKit.Diagnostics` | warnings and build errors |

Every public concrete type should live under a namespace that maps to its folder.
For example:

```swift
extension TileKit.Service {
    public struct Manifest: Sendable, Codable, Equatable {}
}
```

---

## Dependency boundaries

Use protocols only at real boundaries:

| Boundary | Why it is a boundary |
|---|---|
| `FileSystem` | tests need memory files, production needs disk |
| `Clock` | build metadata and date filters must be deterministic |
| `Logger` or diagnostics sink | tests should assert diagnostics without global logging |
| `ConfigurationDecoding` | YAML now, JSON later, tests can use direct values |
| `MarkdownParsing` | parser choice should not leak into the site pipeline |
| `MarkdownRendering` | source parser and HTML renderer can evolve independently |
| `TemplateLoading` | template library and overrides are replaceable |
| `TemplateRendering` | Mustache is first, not hard-coded everywhere |
| `OutputRendering` | HTML, JSON, RSS, and future outputs use one injected contract |
| `AssetProcessing` | copy, Sass, CSS minify, and future transforms are behaviors |
| `HTTPClient` | service manifests and build-mode functions need test doubles |
| `ServiceManifestLoading` | remote, local, and cached manifests share one interface |

Avoid protocols for plain values and pure transforms until there is a second
consumer or a test boundary that needs substitution.

---

## Registry contracts

Tiledown needs registries, but they should be values passed through
initializers, not globals.

```text
TileRegistry
  tile type id -> tile definition

OutputRendererRegistry
  renderer id -> output renderer

TemplateRendererRegistry
  template engine id -> template renderer

AssetBehaviorRegistry
  behavior id -> asset behavior

ServiceRegistry
  service id -> manifest binding and auth policy
```

The CLI constructs these registries:

```text
tiledown main
  parse command
  load config
  construct filesystem, clock, decoders, renderers, registries
  create TileKit.Site.Generator
  run build
```

The library does not read process environment by itself. If a service auth value
comes from `CALCULATOR_API_KEY`, the CLI or an injected secret resolver reads it
and passes a typed credential into the library.

---

## Templating decision

Use Mustache-style templates first, behind a rendering protocol.

Why:

- Toucan already uses Mustache successfully.
- Mustache keeps themes mostly logic-light.
- The content context can stay data-first.
- It supports template overrides and partial-like composition without making the
  template layer the application language.

Do not let Mustache become the extension system for service calls or tile logic.
Templates render prepared context. Tiles and service functions are resolved
before or during page rendering through typed definitions and registries.

---

## Tile/function addon integration

The tile/function layer should attach at two points:

1. Markdown parsing: typed directives become tile nodes in the document tree.
2. Rendering: tile definitions emit HTML, CSS assets, JS assets, diagnostics, and
   optional service requirements.

For service-backed tiles:

```text
Markdown tile
  -> tile node
  -> service operation lookup
  -> schema-driven generated form
  -> generated output fields
  -> emitted JS for remote/proxy mode or baked output for build mode
```

This is how poll, comments, email response, YouTube embed, charts, and calculator
tiles avoid one-off code paths.

---

## MVP parity order

### Slice 1: package and one page

- `Packages/Package.swift`
- `TileKit` library
- `tiledown` CLI
- one Markdown file with front matter
- one Mustache template
- one HTML output
- tests for source load and render

### Slice 2: Toucan content parity

- content tree discovery
- content types
- typed properties
- slug and permalink
- date input/output format
- query filter/order/limit/offset
- scopes for `detail`, `list`, and `reference`
- JSON output renderer

### Slice 3: Markdown/tile parity

- constrained Tiledown Markdown profile
- directive tiles
- tile registry
- unknown tile diagnostics
- outline
- reading time
- local assets

### Slice 4: templates and assets

- template assets
- site assets
- content assets
- template overrides
- asset behavior registry
- copy behavior first
- Sass/minify only when a real template needs them

### Slice 5: service-form proof

- service manifest model
- service binding config
- auth exposure checks
- generated `service-form` HTML/CSS/JS
- fixture calculator operation with two positive decimal inputs and one result
- tests proving server secrets are not emitted to browser output

### Slice 6: dev workflow

- `tiledown init`
- `tiledown serve`
- `tiledown watch`

---

## Dependency posture

Start with the smallest dependency set that produces the first vertical slice:

- `swift-argument-parser` for CLI.
- YAML decoder only when config/front matter is implemented.
- Markdown parser only when real Markdown rendering starts.
- Mustache renderer only when templates are implemented.

Defer:

- Hummingbird until `serve` or proxy support is real.
- file watcher until `watch`.
- Sass and CSS parser until asset behavior tests require them.
- AsyncHTTPClient until service manifest loading or build-mode functions need
  real HTTP.
- External command runner until there is a confirmed transformer feature.

This keeps the package Linux-friendly and avoids inheriting Toucan's dependency
surface before Tiledown needs it.

---

## Design update required

`docs/DESIGN.md` is stale. It still says:

- JSON tile tree is canonical.
- Markdown is only import/export.
- Markdown-native SSG was rejected.

Current research has changed that:

- Tiledown Markdown is canonical on disk.
- A typed tile tree is the parsed model.
- JSON is derived for tests, debugging, interchange, and editor internals.
- The SSG layer should be Toucan-parity.
- Typed tiles and service functions are the extension layer.

---

## Sources inspected

Local Toucan source:

- `/Volumes/Code/DeveloperExt/public/toucan/Package.swift`
- `/Volumes/Code/DeveloperExt/public/toucan/Sources/ToucanSDK/Toucan.swift`
- `/Volumes/Code/DeveloperExt/public/toucan/Sources/ToucanSDK/Renderers/BuildTargetSourceRenderer.swift`
- `/Volumes/Code/DeveloperExt/public/toucan/Sources/ToucanSDK/Renderers/MustacheRenderer.swift`
- `/Volumes/Code/DeveloperExt/public/toucan/Sources/ToucanSDK/Outputs/ContextBundleToHTMLRenderer.swift`
- `/Volumes/Code/DeveloperExt/public/toucan/Sources/ToucanSDK/Outputs/ContextBundleToJSONRenderer.swift`
- `/Volumes/Code/DeveloperExt/public/toucan/Sources/ToucanSDK/Content/ContentResolver.swift`
- `/Volumes/Code/DeveloperExt/public/toucan/Sources/ToucanSDK/Content/Content+Query.swift`
- `/Volumes/Code/DeveloperExt/public/toucan/Sources/ToucanSource/Objects/Pipeline/`
- `/Volumes/Code/DeveloperExt/public/toucan/Sources/ToucanSource/Objects/Types/ContentType.swift`
- `/Volumes/Code/DeveloperExt/public/toucan/Sources/ToucanSource/Objects/Property/`
- `/Volumes/Code/DeveloperExt/public/toucan/Sources/ToucanSource/Objects/Relation/`
- `/Volumes/Code/DeveloperExt/public/toucan/Sources/ToucanSource/Loaders/`
- `/Volumes/Code/DeveloperExt/public/toucan/Sources/ToucanMarkdown/`
