# Design: Tiledown

| Field | Value |
|---|---|
| **Status** | draft |
| **Created** | 2026-05-29 |
| **Last revised** | 2026-05-29 |
| **Tracking issue** | none |
| **Companion docs** | [CONVENTIONS.md](CONVENTIONS.md), [rules](rules/README.md), [research](research/), [architecture decisions](decisions/tiledown-architecture.md), [next steps](NEXT_STEPS.md) |

---

## TL;DR

Tiledown is a Swift static-site generator with a Markdown-canonical source
format and a typed tile model.

Authors write Tiledown Markdown on disk. The parser turns that constrained
Markdown profile into typed tile data. At full scope, the site pipeline resolves
content, queries, templates, assets, and tile renderers, then emits static HTML,
CSS, browser JavaScript, and optional JSON outputs. The current implementation
emits HTML plus page-local tile CSS and browser JavaScript fragments. JSON is a
derived format for tests, debugging, interchange, and future editor internals,
not the primary source file.

The generator aims for Toucan-level SSG functionality first: content loading,
front matter, content types, queries, scopes, Mustache-style templates, assets,
Markdown rendering, outlines, reading time, and build/serve/watch workflows.
Typed tiles and service-backed functions are the addon layer that makes the
system tile-native.

The engine builds on macOS and Linux. Swift is used for generator and tooling
code. JavaScript appears only as emitted browser runtime code for client-side
tiles.

---

## 1. Context

### 1.1 Problem

Tiledown needs the practical feature set of a static-site generator and the
structure of a tile-native document system.

Pure Markdown SSGs are easy to author but weakly typed. Pure JSON tile trees are
easy for editors but poor authoring files. The current direction is a constrained
Markdown profile with typed tile directives, parsed into a typed tile tree and
serialized back canonically.

### 1.2 Design Pivot

Earlier drafts treated JSON as canonical and Markdown as import/export. Research
changed that decision:

- Markdown is canonical on disk.
- The tile tree is the parsed in-memory model.
- JSON is derived.
- Stable tile ids, canonical serialization, and round-trip tests carry the
  editor correctness burden.

### 1.3 Toucan Baseline

Toucan is the functionality reference, not the architecture to copy verbatim.
Tiledown should cover most Toucan capabilities, but replace hard-coded switches
with dependency-injected registries and protocol boundaries.

---

## 2. Goals

### P0

- **G1**: A Tiledown Markdown document parses into a typed tile tree and
  serializes back to canonical Tiledown Markdown without semantic loss.
- **G2**: The generator renders a simple site from Markdown content and a
  Mustache-style template.
- **G3**: The core engine is pure Swift and builds on macOS and Linux.
- **G4**: All external collaborators are injected through initializers.

### P1

- **G5**: The SSG layer supports Toucan-parity content types, properties,
  relations, queries, scopes, output paths, and assets.
- **G6**: Core tiles render static HTML and collect CSS/JS assets.
- **G7**: Output renderers are registered by injected values, with HTML and JSON
  as the first renderers.

### P2

- **G8**: Service-backed tiles generate input fields, validation, service calls,
  output fields, formatting, and availability states from a provider-neutral
  service manifest.
- **G9**: Dev workflow supports `tiledown init`, `tiledown serve`, and
  `tiledown watch`.
- **G10**: A future native macOS and iOS editor can reuse the same tile model and
  canonical serializer.

---

## 3. Non-goals

- **NG1**: Runtime Swift plugin loading. Extension is by composing Swift
  registries in-process, not loading third-party code dynamically.
- **NG2**: JavaScript build tooling. JavaScript is emitted browser runtime code
  only.
- **NG3**: A mandatory hosted backend. Static output must work without a server.
  Secret-backed runtime tiles require a separately deployed proxy or backend.
- **NG4**: Copying Toucan command names or internals. Toucan is a parity target,
  not a compatibility contract.
- **NG5**: Pulling in broad dependencies before the vertical slice needs them.

---

## 4. Requirements

### 4.1 Functional

| ID | Requirement | Current status | Verified by |
|---|---|---|---|
| F1 | Markdown body parses into source-ordered Markdown and tile blocks | implemented | `TileTileTests` |
| F2 | Tile tree serializes to canonical Markdown | planned | serializer tests when implemented |
| F3 | Parse, serialize, parse returns the same tile semantics | planned | round-trip tests when implemented |
| F4 | A page renders through a Mustache-style template to HTML | implemented | `TileSiteTests` |
| F5 | Unknown tile types preserve source data and render diagnostics | implemented for rendering | `TileTileTests` |
| F6 | Output escaping prevents script injection through text fields | implemented for Markdown, templates, and service-form runtime config | unit tests |
| F7 | Service-backed tiles reject server secrets in generated browser output | implemented in binding and rendering rules | `TileServiceFormTests` |
| F8 | Query filtering, ordering, limit, and offset work for content collections | implemented | `TileContentTests` |
| F9 | `service-form` can generate controls, result regions, CSS, and browser JS from a service contract | implemented as a domain renderer, not yet registered by the site generator by default | `TileServiceFormTests` |

### 4.2 Non-functional

| ID | Requirement | Target |
|---|---|---|
| N1 | Core builds on macOS and Linux | green CI on both |
| N2 | No global registries or singletons | code review and tests |
| N3 | External collaborators are injected | code review |
| N4 | Dependencies are added only when a slice needs them | package review |
| N5 | Generated output is deterministic for the same inputs | integration test |

---

## 5. Design Overview

```text
Tiledown Markdown + front matter
        |
        v
Source loader
        |
        v
Markdown parser -> typed tile tree
        |
        v
Content resolver -> content types, properties, relations, queries, scopes
        |
        v
Site pipeline -> templates, output renderers, assets, tile renderers
        |
        v
Generated HTML/CSS/JS files now, derived JSON later
```

The current implementation has the first end-to-end HTML path:

```text
Markdown file
        |
        v
TileKit.Source.FrontMatterParser
        |
        v
TileKit.Tile.DirectiveParser
        |
        v
Markdown blocks -> TileKit.Markdown.BasicHTMLRenderer
Tile blocks    -> TileKit.Tile.Registry
        |
        v
TileKit.Template.SimpleMustacheRenderer
        |
        v
Static HTML file
```

The current tile render contract returns page-local HTML, CSS, and browser
JavaScript fragments. `TileSite` keeps Markdown blocks and tile blocks in source
order, joins HTML fragments into `page.contents.html`, and exposes collected
tile assets as `page.assets.css`, `page.assets.javascript`, `assets.css`, and
`assets.javascript`.

### 5.1 Current Implementation Snapshot

Implemented as of the current design revision:

| Area | Current state |
|---|---|
| Package shape | one Swift package manifest under `Packages/` with focused targets and matching test targets |
| Facade | `TileKit` re-exports the domain targets and current local filesystem adapter |
| CLI | `tiledown` builds one page or a content directory using injected generator dependencies |
| Source | front matter parsing and index-content discovery |
| Markdown | basic HTML renderer for headings, paragraphs, and escaped text |
| Templates | Mustache-style rendering, nested values, raw values, and list sections |
| Content | typed records, field values, filters, sorting, offset, limit, and query runner |
| Tiles | source-ordered directive parser, typed tile values, `service-form` request validation, renderer protocol, render output, registry, and unknown fallback |
| Site generation | renders Markdown and tile blocks in source order through injected parser and registry values |
| Services | provider integration manifest models, service operation contracts, capability inventory, validation, and auth exposure models |
| Service forms | request-to-contract binding and generated HTML/CSS/browser-JS renderer for `remote` and `proxy` modes |
| Filesystem | local filesystem adapter isolated in `TileSiteImpl` |

Not implemented yet:

| Area | Missing piece |
|---|---|
| Canonical source | canonical Markdown serializer and parse/serialize/parse law tests |
| Output | derived JSON output and output renderer registry |
| Site config | config loading, service binding config, output config, and template/theme config |
| Service loading | local or remote service contract resolver, health checks, availability policy execution, and manifest caching |
| Built-in tile wiring | default registration for `service-form`, `youtube-video`, `poll`, comments, email response, and charts |
| Assets | asset declarations, deduplication, copying, transforms, and site-level asset behavior registry |
| CLI workflow | `init`, `serve`, `watch`, and proxy support |

Registries are values passed into the generator:

```text
TileRegistry
OutputRendererRegistry
TemplateRendererRegistry
AssetBehaviorRegistry
ServiceRegistry
```

The CLI is the composition root. It parses arguments, loads config, creates
filesystem/clock/decoder/renderer dependencies, constructs registries, and calls
`TileKit.Site.Generator`.

---

## 6. Package Design

Tiledown uses one package under `Packages/`, with focused SPM targets inside
that single manifest:

```text
Packages/
  Package.swift
  Sources/
    TileCore/
    TileContent/
    TileMarkdown/
    TileSite/
    TileService/
    TileServiceForm/
    TileSource/
    TileTemplate/
    TileTile/
    TileKit/
    TileSiteImpl/
    TiledownCLI/
  Tests/
    TileCoreTests/
    TileContentTests/
    TileMarkdownTests/
    TileSiteTests/
    TileServiceTests/
    TileServiceFormTests/
    TileSourceTests/
    TileTemplateTests/
    TileTileTests/
    TileKitTests/
    TileSiteImplTests/
```

This is a multi-target package, not separate Swift packages. The intent is
clear import boundaries and isolated tests without fragmenting the workspace.

### 6.1 Target Roles

`TileCore` is deliberately small. It owns the root `TileKit` namespace and tiny
shared product metadata. It must not become a second god package.

Domain targets are able-bodied. They own their contracts, value types, and pure
logic:

| Target | Owns |
|---|---|
| `TileContent` | `TileKit.Content` records, field values, conditions, sort orders, queries, and query execution |
| `TileMarkdown` | `TileKit.Markdown` rendering contract and basic Markdown-to-HTML renderer |
| `TileService` | `TileKit.Service` provider manifests, service operation contracts, capability inventory, and validation |
| `TileServiceForm` | `TileKit.ServiceForm` binding between service-form tile requests, service contract operations, and generated browser output |
| `TileSource` | `TileKit.Source` documents, front matter parsing, content discovery, and source parser contracts |
| `TileTemplate` | `TileKit.Template` context values, renderer contract, and Mustache-style renderer |
| `TileTile` | `TileKit.Tile` typed tile blocks, source-ordered properties, directive parser, render output, renderer registry, and typed tile requests |
| `TileSite` | `TileKit.Site` build requests/results, page context, generator orchestration, tile block rendering, and filesystem protocol |

Implementation targets are meatless adapters. They contain concrete I/O or
integration code only when that code is not pure domain logic. Today that means:

| Target | Owns |
|---|---|
| `TileSiteImpl` | local filesystem I/O through `TileKit.Site.LocalFileSystem` |

`TileKit` is a facade target. It re-exports the domain targets and the current
implementation adapter so consumers can import one module while the internal
dependency graph stays explicit.

`TiledownCLI` is the composition root. It parses arguments, creates concrete
implementations, and passes them into domain types through protocols and
initializers.

### 6.2 Dependency Graph

Current dependency flow:

```text
TileCore
  ^
  |
  +-- TileContent
  +-- TileMarkdown
  +-- TileService
  |     ^
  |     |
  |   TileServiceForm ----> TileTile
  +-- TileSource
  +-- TileTemplate
  +-- TileTile
  |
  +-- TileSite ----> TileMarkdown
        |            TileSource
        |            TileTemplate
        |            TileTile
        v
      TileSiteImpl

TileKit facade -> TileCore, domain targets, TileSiteImpl
TiledownCLI    -> TileKit
```

Allowed imports are tracked in
[package-import-contract-status.md](package-import-contract-status.md).

### 6.3 Split Rules

- Do not make `TileCore` a dumping ground. Move code into the most specific
  domain target unless it is truly root-level shared metadata or a namespace
  anchor.
- Do not create an `Impl` target for pure logic. Parser logic, query logic,
  renderers, and context preparation belong in domain targets unless they wrap a
  concrete external integration.
- `Impl` targets are for concrete adapters: filesystem, network transport,
  service clients, clocks, process execution, or future platform-specific
  integrations.
- Domain targets may depend on `TileCore`. A domain target may depend on another
  domain target only when its public API genuinely composes that domain, as
  `TileSite` currently composes `TileMarkdown`, `TileSource`, `TileTemplate`, and
  `TileTile`.
- The CLI and future app targets are composition roots. They may import the
  facade or concrete implementations and wire dependencies together.

### 6.4 Future Target Growth

The current split covers the code that exists. Future namespaces should become
future targets when they gain real code:

| Future target | Trigger |
|---|---|
| `TileAsset` | asset declarations, asset collection, copy behavior, and future transforms |
| `TileOutput` | HTML, JSON, RSS, and other output renderer contracts |
| `TileServiceImpl` | local or remote service contract loading, HTTP clients, health checks, and manifest caching |
| `TileDiagnostics` | structured warnings, build errors, and diagnostic sinks when diagnostics need their own API |

Do not put future tile, service, asset, output, or diagnostics code into
`TileCore` just because it is shared. Put it in a focused target and depend on
that target explicitly. Create an implementation target only for concrete
adapters such as HTTP clients, filesystem writers, service proxies, process
runners, or platform-specific backends.

Initial namespaces:

| Namespace | Responsibility |
|---|---|
| `TileKit.Site` | build request, generator, target, output |
| `TileKit.Source` | source files, front matter, content loading |
| `TileKit.Content` | content type, property, relation, query, scope |
| `TileKit.Markdown` | Markdown rendering contracts and Markdown-to-HTML rendering |
| `TileKit.Template` | template loading and rendering contracts |
| `TileKit.Tile` | tile model, directive parsing, definitions, renderers, registry |
| `TileKit.Service` | service manifests, auth exposure, operation schemas |
| `TileKit.ServiceForm` | service-form request binding, validation, and generated browser output |
| `TileKit.Asset` | asset declarations and behavior registry |
| `TileKit.Output` | output renderer contracts and generated files |
| `TileKit.Diagnostics` | warnings and build errors |

Public concrete types live under their namespace and file path. For example,
`TileKit.Service.Manifest` belongs in a matching service folder and file.

---

## 7. Source Model

### 7.1 Markdown

Tiledown Markdown is the canonical on-disk source. Plain Markdown is shorthand
for core tiles. Structured tiles use directive blocks:

```markdown
:::tile poll
id: favorite-editor
mode: local
question: What editor do you use?
options:
  - Xcode
  - VS Code
  - Other
:::
```

The parser must preserve unknown tile types and unknown properties. The
serializer emits one canonical form.

### 7.2 Tile Tree

A tile has:

```json
{
  "id": "stable-id",
  "type": "service-form",
  "mode": "proxy",
  "props": {},
  "children": []
}
```

The exact Swift model should use typed values, not raw dictionaries everywhere.
The JSON shape is useful for tests and interchange, but it is derived from
Markdown.

### 7.3 Content

The SSG content layer carries forward the useful Toucan model:

- content items
- front matter
- content types
- typed properties
- relations
- user-defined metadata
- slug and permalink
- last update
- query fields

---

## 8. Rendering

### 8.1 Site Pipeline

The generator resolves a site in stages:

1. Load target config.
2. Load source files.
3. Parse Markdown and front matter.
4. Resolve content types, properties, relations, slugs, and assets.
5. Run queries and scopes.
6. Render tile trees.
7. Render templates.
8. Write output files.

### 8.2 Templates

Mustache-style templates are the first template renderer. They are behind a
`TemplateRendering` boundary so the generator is not tied to one concrete
library.

Templates receive prepared context. They should not perform service calls,
secret reads, or tile logic.

### 8.3 Output Renderers

Output renderers are injected:

- HTML renderer first.
- JSON renderer second.
- RSS or feed renderer later.

No renderer selection should be implemented as a hard-coded switch in the core
pipeline.

---

## 9. Tiles and Functions

Tiles are typed document nodes, not string replacements. A tile definition is
the unit of validation, rendering, assets, and runtime capability.

Tile definitions declare:

- type id
- accepted properties
- canonical property order
- validation rules
- renderer
- required CSS and JS assets
- capability mode
- unknown-property preservation policy
- diagnostics

`TileKit.Tile.Registry` is the first tile dispatch seam. It maps tile type ids to
injected renderers and falls back to a deterministic unsupported-tile diagnostic
for unknown tile types. `TileKit.Site.Generator` receives a tile parser and tile
registry through its initializer, renders Markdown blocks and tile blocks in
source order, and exposes collected tile CSS and JavaScript as
`page.assets.css`, `page.assets.javascript`, `assets.css`, and
`assets.javascript` in the template context.

Capability modes:

| Mode | Meaning |
|---|---|
| `static` | HTML/CSS only |
| `local` | browser JS and local browser state |
| `remote` | browser calls a public endpoint |
| `proxy` | browser calls a site-owned proxy that holds secrets |
| `build` | generator calls a service during build |

The first service-backed generic tile is `service-form`. It reads a service
manifest operation and generates input fields, validation, service calls, output
fields, formatting, and availability states.

### 9.1 Tile Families

Plan for these tile families so early boundaries do not assume only text pages:

| Family | Examples | Capability pressure |
|---|---|---|
| Core content | heading, paragraph, rich text, list, quote, code, table, callout, details | `static` |
| Page structure | section, columns, grid, cards, hero, tabs, accordion, divider | `static`, sometimes `local` |
| Navigation | nav, breadcrumbs, table of contents, pagination, previous/next, sitemap entry | `static`, `build` |
| Media | image, figure, gallery, carousel, audio, video, YouTube, Vimeo, PDF, iframe | `static`, sometimes `remote` |
| Data display | metric, chart, data table, CSV viewer, JSON viewer, timeline, calendar, map | `static`, `build`, `local`, `remote` |
| Diagrams | Mermaid, Graphviz-like diagram, sequence chart, flowchart | `build`, `local` |
| Forms and actions | contact form, email response, newsletter signup, RSVP, survey, poll, quiz, calculator, estimate form, booking widget | `local`, `remote`, `proxy`, `build` |
| Local interaction | local poll, filter, sort, search, bookmarks, checklist, theme toggle, local notes | `local` |
| Remote interaction | comments, reactions, ratings, global poll, service-call form, lookup, personalized result | `remote`, `proxy` |
| Commerce and funding | product card, buy button, donation button, checkout link | `static`, `remote` |
| Build-time import | RSS import, GitHub release list, YouTube metadata, API-to-static table, chart precompute | `build` |
| SEO and metadata | Open Graph, JSON-LD, canonical URL, feed, robots, sitemap | `static`, `build` |
| Diagnostics | unsupported tile, missing service, schema mismatch, unavailable endpoint | generated fallback and build diagnostic |

Most named tiles are skins over a smaller set of mechanics: render structured
content, embed a trusted external surface, store local browser state, fetch
public data, call a private service through a proxy, or run a build-time
function and bake the result into HTML.

### 9.2 First Tile Slices

Implement generic mechanics first, then named tiles:

| Slice | Notes |
|---|---|
| `service-form` | schema-driven generated form and result view |
| `youtube-video` | safe iframe embed, privacy-enhanced URL by default |
| `poll` | local mode first, remote and proxy later |
| `email-response` | proxy only because provider credentials are secret |
| `comments` | remote for public widget providers, proxy for private APIs |
| `chart` | static or build-time data first, local JS rendering later |

Later tiles can specialize the same mechanics: quiz, survey, lookup, estimate,
calendar, search, reactions, ratings, and booking widgets.

### 9.3 Tile Rendering Contract

A tile renderer returns deterministic render output:

- HTML fragment.
- CSS asset declarations.
- JS asset declarations for `local`, `remote`, and `proxy` modes.
- JSON configuration data for browser runtime tiles.
- Service requirements for `remote`, `proxy`, and `build` modes.
- Diagnostics for invalid properties, unsupported modes, missing services, or
  unsafe credential exposure.

HTML returned by a remote service is rejected by default. If a future tile allows
remote HTML, it must be a separate high-trust capability with sanitization and
content-security guidance.

---

## 10. Services and Secrets

Service-backed tiles use provider-neutral manifests. Tiledown does not care
whether the backend is Hummingbird, Vapor, serverless, or a third-party API.

Markdown names a tile, service id, operation id, mode, and presentation
overrides. Site config maps the service id to a manifest URL and auth policy.
The manifest describes operations with JSON Schema inputs and outputs plus
Tiledown UI hints. The generator emits deterministic HTML, CSS, and small
browser JavaScript for interactive modes.

Example tile:

```markdown
:::tile service-form
id: price-calculator
service: calculator
operation: positive-decimal-calculation
mode: proxy
submitLabel: Calculate
:::
```

This parses to a generic `TileKit.Tile.Instance` first. The service-specific
view of that generic tile is `TileKit.Tile.ServiceFormRequest`, which validates
the tile id, service id, operation id, selected mode, and optional submit label
without importing `TileService`.

`TileKit.ServiceForm.Binder` then binds that request to a
`TileKit.Service.Contract` operation. The binder verifies that the service id
matches, the operation exists, the selected mode is supported, and private
credentials are not used by direct browser `remote` mode.

Example service binding:

```yaml
services:
  calculator:
    manifest: https://calc.example.com/tiledown/service.json
    mode: proxy
    proxyRoute: /_td/services/calculator
    availability: required
    auth:
      type: bearer
      valueFromEnv: CALCULATOR_API_KEY
      exposure: server
```

The manifest declares:

- service availability
- operations
- input schema
- output schema
- input UI hints
- output UI hints
- auth exposure
- error format
- cache policy

Minimum manifest fields:

| Field | Purpose |
|---|---|
| `id` | stable service id |
| `name` | human-readable service name |
| `version` | service contract version |
| `health` | availability check endpoint and timeout |
| `operations` | callable operations |
| `operations[].id` | stable operation id used by the tile |
| `operations[].modes` | supported `remote`, `proxy`, or `build` modes |
| `operations[].transport` | HTTP method, path, content type, and response type |
| `operations[].inputSchema` | JSON Schema for accepted input |
| `operations[].inputUi` | generator hints for controls, labels, order, and units |
| `operations[].outputSchema` | JSON Schema for returned output |
| `operations[].outputUi` | generator hints for formatting and result layout |
| `operations[].auth` | required auth scheme and exposure |
| `operations[].errors` | error format, preferably Problem Details JSON |
| `operations[].cache` | whether results can be cached and for how long |

The Swift model for this service-backed contract is
`TileKit.Service.Contract`. It is separate from provider integration manifests:
contracts describe callable operations, while provider manifests map a
third-party embed or provider surface onto existing Tiledown capabilities. Both
stay declarative and both are validated before generation.

JSON Schema 2020-12 is the normative contract for inputs and outputs. UI hints
are presentation only. If an input fails schema validation, the value is invalid
even if a UI hint would have rendered it.

OpenAPI can be supported later, but the Tiledown manifest remains the primary
contract consumed by the generator. OpenAPI describes HTTP APIs; Tiledown also
needs rendering, capability, availability, cache, and auth exposure decisions.

For exact decimal values, use strings with a semantic hint rather than floating
point numbers:

```json
{
  "type": "string",
  "pattern": "^(?=.*[1-9])(?:0|[1-9][0-9]*)(?:\\.[0-9]+)?$",
  "x-tiledownType": "positiveDecimal"
}
```

If precision does not matter, use JSON Schema numbers:

```json
{
  "type": "number",
  "exclusiveMinimum": 0
}
```

Client-side validation is only a user experience improvement. The service must
validate again.

### 10.1 Generated Service Runtime

For `service-form`, the generator produces:

- A stable root element with `data-td-tile-id`, `data-td-service`, and
  `data-td-operation`.
- A form with generated controls from `inputSchema` plus `inputUi`.
- Accessible labels and validation messages.
- A result region with generated fields from `outputSchema` plus `outputUi`.
- Loading, success, unavailable, validation, and error states.
- CSS scoped by a stable tile class.
- A browser JavaScript runtime that reads JSON configuration, validates user
  input, performs the call for `remote` or `proxy`, and renders typed output.

The current `TileKit.ServiceForm.Renderer` covers the first browser-runtime
slice. It emits deterministic form HTML, a JSON data island, scoped CSS, and a
small reusable JavaScript runtime for `remote` and `proxy` modes. It derives
text, email, URL, number, checkbox, textarea, hidden, and select controls from
the operation schema plus `inputUi`; exact decimal semantic fields render as
text inputs with decimal input mode. The renderer rejects `build`, `local`, and
`static` modes until those execution models have their own renderer paths.

For proxy mode, generated browser JavaScript calls the site proxy:

```text
POST /_td/services/calculator/positive-decimal-calculation
```

For remote mode, generated browser JavaScript calls the service endpoint
directly, with only public credentials if any are declared. For build mode, the
Swift generator calls the operation during generation and writes the result into
static HTML. Build mode only works when all required inputs are known at build
time.

Avoid embedding dynamic config by string interpolation into JavaScript source.
Prefer a JSON data island:

```html
<script type="application/json" data-td-config="price-calculator">
{"service":"calculator","operation":"positive-decimal-calculation","mode":"proxy"}
</script>
```

The JS runtime parses that JSON.

### 10.2 Generated Controls and Outputs

Schema to control mapping:

| Schema shape | Generated control |
|---|---|
| `string` | text input |
| `string`, `format: email` | email input |
| `string`, `format: uri` | URL input |
| `string`, `x-tiledownType: decimal` | text input with decimal input mode |
| `number` or `integer` | number input |
| `number`, `exclusiveMinimum: 0` | number input with positive validation |
| `boolean` | checkbox or toggle |
| `enum` | select, radio group, or segmented control |
| `array` | repeatable field or multi-select |
| `object` | fieldset or nested group |
| `oneOf` | mode selector with conditional fields |

Use `inputUi` to choose between equivalent controls. For example, an enum can be
a select for many values or radio buttons for a short list.

Output formatting mapping:

| Output type | Generated presentation |
|---|---|
| decimal string | formatted number text |
| number | formatted number, currency, percent, or unit value |
| boolean | status text or icon slot |
| string | escaped text |
| markdown string | parsed through the trusted Markdown pipeline only if explicitly allowed |
| URL string | link, image, video, or iframe depending on declared media type |
| array of objects | table, list, cards, or chart source |
| object | result card or named field group |
| problem details | error state |

### 10.3 Availability

Tiledown checks availability in two places:

1. Build time: fetch the manifest and optionally call the health endpoint.
2. Runtime: generated JavaScript handles fetch errors, timeouts, invalid
   responses, and service-declared Problem Details.

Recommended build policy:

```yaml
services:
  calculator:
    manifest: https://calc.example.com/tiledown/service.json
    availability: required
```

Allowed values:

| Value | Build behavior |
|---|---|
| `required` | fail if manifest or health check fails |
| `optional` | warn and render fallback |
| `unchecked` | do not call during build |

The manifest should be cacheable with HTTP caching. Add a lockfile later if
reproducible builds need pinned manifest versions.

### 10.4 Manifest-Driven Integrations

Provider integrations should be manifest-driven whenever existing Tiledown
capabilities are enough. New provider support should not require custom Swift
code just to map provider inputs, validation, layout, credentials, and embed
outputs onto capabilities the engine already supports.

The refined pipeline is:

```text
Tiledown Markdown
        |
        v
Tile parser
        |
        v
Typed tile tree
        |
        v
Manifest lookup and validation
        |
        v
Capability renderer
        |
        v
Static site output
```

Tiledown does not execute arbitrary provider-specific code from a manifest. Swift
code defines capabilities. Manifests compose those capabilities.

Manifest-driven integrations have three inputs:

| Input | Role |
|---|---|
| Tiledown capability inventory | complete set of primitives the engine can validate and render |
| Tiledown manifest schema | structural contract every integration manifest must satisfy |
| Provider documentation | provider-specific ids, embed URLs, auth requirements, limits, and options |

The integration authoring flow is:

```text
Provider documentation
        +
Capability inventory
        +
Manifest schema
        |
        v
manifest.yml
        |
        v
Tiledown runtime
```

The output is `manifest.yml`, not `ProviderPlugin.swift`. For example, a quiz
provider that needs a quiz id, optional theme, credential reference, responsive
iframe, and block layout should map to existing input, credential, output, and
layout capabilities. No new Swift code is needed unless the provider requires a
capability Tiledown does not have.

Do not put secret values in integration manifests. A provider manifest can
declare that an operation requires a credential with `server`, `build`, or
`browser` exposure. Site config binds that requirement to `valueFromEnv`,
`secretRef`, or `publicKey`. If a scaffold accepts shorthand such as
`apiKey.environmentVariable`, it normalizes that shorthand into an explicit
credential requirement plus a site-level binding.

### 10.5 Capability Inventory

The capability inventory is the contract between Tiledown and integration
manifests. It is versioned, documented, and implemented in Swift. Manifests can
only reference capabilities in the inventory.

Initial input capabilities:

| Capability | Meaning |
|---|---|
| `text` | single-line string |
| `multiline-text` | multi-line string |
| `integer` | integer number |
| `double` | floating-point number when exact decimal precision is not required |
| `decimal` | exact decimal transported as a string |
| `boolean` | true or false value |
| `date` | date input |
| `image` | image URL or asset reference |
| `video` | video URL or asset reference |
| `color` | color value |
| `url` | URL value |
| `select` | one value from allowed values |
| `credential-reference` | reference to a declared credential, not the credential value |

Initial output capabilities:

| Capability | Meaning |
|---|---|
| `html` | generated HTML output from Tiledown capabilities |
| `markdown` | Markdown rendered by Tiledown only when explicitly allowed |
| `image-placeholder` | generated image placeholder |
| `video-placeholder` | generated video placeholder |
| `iframe` | iframe embed with declared origin and layout constraints |
| `form` | generated form |
| `css-asset` | CSS asset declaration |
| `javascript-asset` | browser JavaScript asset declaration |
| `external-embed` | declared third-party embed surface |

Initial layout capabilities:

| Capability | Meaning |
|---|---|
| `inline` | inline flow |
| `block` | normal block flow |
| `full-width` | spans available content width |
| `responsive` | preserves responsive sizing behavior |

Initial validation capabilities:

| Capability | Meaning |
|---|---|
| `required` | value must be present |
| `optional` | value may be omitted |
| `default-value` | default applied when omitted |
| `allowed-values` | enum-like allowed value set |
| `min-length` | minimum string length |
| `max-length` | maximum string length |
| `regex` | regular expression validation |
| `minimum` | numeric lower bound |
| `maximum` | numeric upper bound |

Remote HTML is not an output capability. If a provider needs raw HTML injection,
that is a new high-trust capability with sanitization and content-security
requirements, not a default manifest mapping.

Example provider integration manifest:

```yaml
id: quiz.typeform

provider:
  name: Typeform
  website: https://typeform.com

requirements:
  credentials:
    - id: typeform
      type: bearer
      exposure: server

inputs:
  formId:
    type: text
    required: true

  theme:
    type: select
    required: false
    default: light
    allowedValues:
      - light
      - dark

outputs:
  embed:
    type: iframe
    responsive: true
    origin: https://form.typeform.com

layout:
  mode: block

build:
  strategy: provider-embed
```

The corresponding site config supplies the credential binding:

```yaml
services:
  typeform:
    integration: quiz.typeform
    auth:
      type: bearer
      valueFromEnv: TYPEFORM_API_KEY
      exposure: server
```

### 10.6 When Swift Code Is Required

Swift code is required when an integration needs a capability Tiledown does not
already support. Examples:

- New rendering primitive.
- New validation type.
- New asset type.
- New credential exposure model.
- New build-time execution model.
- New transport that cannot be described by the existing manifest schema.

Once the capability exists, future providers reuse it through manifests. This
keeps growth capability-first rather than provider-plugin-first.

### 10.7 Credentials

Secrets never appear in Markdown, generated HTML, generated JavaScript, or
browser storage.

Credential exposure:

| Exposure | Can be emitted to browser? | Use case |
|---|---|---|
| `none` | no | public service |
| `browser` | yes, intentionally public | public widget key restricted by origin |
| `server` | no | bearer token, secret API key, private webhook |
| `build` | no | build-time fetch or precompute |

The library does not read environment variables directly. The CLI or an injected
secret resolver provides typed credentials to the generator.

Rules:

- Do not use `apiKey` in tile Markdown because it does not say whether a value is
  safe to ship.
- Use `publicKey` only for intentionally public browser credentials.
- Use `secretRef` or `valueFromEnv` only for server-side or build-time secrets.
- `mode: proxy` means the generated page calls a public proxy endpoint, never the
  private third-party API directly.
- `mode: build` may read secrets from the build environment, but the rendered
  output must not contain them.

---

## 11. Assets

Asset handling should cover Toucan's useful cases:

- copy static assets
- resolve content-local asset paths
- load text assets into content properties
- parse structured assets into content properties
- transform assets through named behaviors

Asset behaviors are injected. Copy behavior comes first. Sass and CSS minify are
deferred until real templates need them.

---

## 12. Dependency Strategy

Start small:

- `swift-argument-parser` for the CLI.
- YAML support when config/front matter lands.
- Markdown parser when Markdown rendering lands.
- Mustache renderer when templates land.

Defer:

- Hummingbird until `serve` or proxy support is implemented.
- file watching until `watch`.
- Sass and CSS parser until asset behavior tests require them.
- AsyncHTTPClient until service manifests or build-mode functions need HTTP.
- external command runner until a transformer feature is confirmed.

Every dependency must support Linux or sit outside the cross-platform core.

---

## 13. Security and Privacy

- Escape text output by default.
- Reject remote HTML by default.
- Preserve unknown tiles as diagnostics rather than silently executing them.
- Do not emit server or build secrets to browser output.
- Browser storage is allowed only for non-sensitive local tile state.
- The generator does not phone home.
- Runtime network access is explicit per tile capability mode.

| Threat | Vector | Mitigation |
|---|---|---|
| Script injection | unescaped text or remote HTML | escape output, reject remote HTML by default |
| Secret leak | API key in Markdown or JS | `publicKey` versus `secretRef`/`valueFromEnv`, auth exposure checks |
| Broken service tile | unavailable manifest or endpoint | build diagnostics and runtime unavailable state |

---

## 14. Testing Strategy

Use Swift Testing.

Initial tests:

- Markdown front matter parsing.
- Markdown tile directive parsing.
- Tile renderer registry dispatch and unknown-tile diagnostic rendering.
- Canonical serialization.
- Parse, serialize, parse round-trip.
- Unknown tile preservation and diagnostic render.
- HTML escaping.
- Content type property validation.
- Query filter/order/limit/offset.
- Mustache render from prepared context.
- Service manifest decoding.
- Service operation contract decoding and validation.
- `service-form` tile request decoding and validation.
- `service-form` request-to-contract binding.
- `service-form` generated HTML, CSS, and browser JavaScript for `remote` and
  `proxy` mode.
- `service-form` rejects server secrets in browser output.

No live network tests in the core suite. HTTP is injected and tested with fakes.

---

## 15. Implementation Status

Completed slices:

| Slice | Status |
|---|---|
| Package scaffold, facade, and CLI front door | implemented |
| Single-page source loading with front matter | implemented |
| Mustache-style HTML render | implemented |
| Content records and query basics | implemented |
| Content directory builds from `index.md` files | implemented |
| Markdown tile directives | implemented |
| Tile renderer registry and unknown-tile diagnostics | implemented |
| Tile-generated CSS and JavaScript exposed to templates | implemented |
| Service integration manifest models and capability inventory | implemented |
| Service operation contract decoding and validation | implemented |
| `service-form` tile request decoding and validation | implemented |
| `service-form` request-to-contract binding | implemented |
| `service-form` generated HTML/CSS/browser-JS renderer | implemented in `TileServiceForm`; not yet registered in the site generator by default |

Near-term slices are tracked in [NEXT_STEPS.md](NEXT_STEPS.md). The immediate
priority is to wire existing service-form domain logic through the tile registry
without making `TileSite` depend on concrete service-form behavior. `TileSite`
should continue to know only about `TileKit.Tile.Rendering` through the injected
registry.

Next major design milestones:

1. Add a `service-form` tile renderer adapter in `TileServiceForm`.
2. Add an injected service contract resolver and service binding configuration.
3. Add JSON output as a derived renderer, not a source format.
4. Add canonical Markdown serialization.
5. Add asset declarations and asset behavior registry.
6. Add `init`, `serve`, `watch`, and optional proxy support.

---

## 16. Alternatives Considered

### 16.1 JSON Canonical Tile Tree

**Considered**: store pages as JSON tile trees and treat Markdown as import and
export.

**Rejected**: JSON is poor as the author-facing source file and loses the
Markdown ecosystem benefit. Current research supports constrained canonical
Markdown plus stable tile ids instead.

### 16.2 Copy Toucan Internals

**Considered**: port Toucan structure directly.

**Rejected**: Toucan has useful product capabilities, but several implementation
choices conflict with Tiledown's rules. Tiledown should keep the SSG surface and
replace hard-coded behavior selection with injected registries.

### 16.3 Runtime Swift Plugins

**Considered**: load third-party Swift tile code at runtime.

**Rejected**: too much complexity and deployment risk. Tiledown composes tile
definitions in process at build time.

---

## 17. Design Decisions

Detailed decisions live in
[tiledown-architecture.md](decisions/tiledown-architecture.md). The current
accepted decisions are:

| ID | Decision |
|---|---|
| D1 | Product name is Tiledown, CLI command is `tiledown`, engine library facade is `TileKit` |
| D2 | Markdown is canonical on disk; JSON is derived |
| D3 | Toucan is a parity reference, not a compatibility or naming contract |
| D4 | Swift is used for generator and tooling; JavaScript is emitted only for browser tile runtimes |
| D5 | Engine targets macOS and Linux |
| D6 | One `Packages/Package.swift` contains many focused targets |
| D7 | `TileCore` stays tiny; domain targets own real contracts and pure logic |
| D8 | `Impl` targets are thin concrete adapters only |
| D9 | `TileKit` remains a facade import for consumers |
| D10 | Cross-target and external collaborators are injected through protocols and initializers |
| D11 | Service-backed tiles use provider-neutral manifests, not backend-specific code |
| D12 | Tile capability modes are explicit: `static`, `local`, `remote`, `proxy`, and `build` |
| D13 | Secret credentials never enter Markdown or generated browser output |
| D14 | First interactive mechanics are `service-form`, local poll, YouTube embed, email response, comments, and chart |
| D15 | Services declare build-time availability policy |
| D16 | Credential exposure is explicit and controls browser output |
| D17 | First tile roadmap starts with reusable mechanics before provider-specific tiles |
| D18 | Provider integrations should be manifest-driven whenever existing Tiledown capabilities are enough |

---

## 18. Open Questions and Risks

### Open

| ID | Question | Tracking |
|---|---|---|
| Q1 | Exact constrained Markdown grammar | open |
| Q2 | Exact service manifest schema URL and versioning | open |
| Q3 | How much of Toucan's iterator model should be renamed to pagination | open |
| Q4 | Whether templates support partials through Mustache library features or explicit Tiledown loading | open |

### Risks

| ID | Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|---|
| R1 | SSG parity grows too large before first output | high | high | ship one vertical slice first |
| R2 | Markdown round-trip is harder than expected | med | high | constrain syntax and test serializer laws |
| R3 | Service tiles leak secrets if auth exposure is vague | med | high | require explicit credential exposure |
| R4 | Dependencies pull platform assumptions into core | med | med | add dependencies slice by slice |

---

## 19. Future Work

- Native macOS and iOS visual editor over the tile model.
- Built-in tiles for poll, YouTube, comments, email response, charts, and
  diagrams.
- Service proxy helper package or deployment template.
- GitHub Pages publishing workflow.
- Template/theme package story.

---

## 20. References

### Internal

- [CONVENTIONS.md](CONVENTIONS.md)
- [Rules index](rules/README.md)
- [Architecture decisions](decisions/tiledown-architecture.md)
- [Next steps](NEXT_STEPS.md)
- [Markdown source model research](research/2026-05-29-1654-markdown-tile-source-model.md)
- [Tile function source evaluation](research/2026-05-29-1718-tile-functions-source-evaluation.md)
- [Tile catalog and service contract](research/2026-05-29-1728-tile-catalog-service-contract.md)
- [Toucan parity architecture research](research/2026-05-29-1744-toucan-parity-tiledown-architecture.md)
