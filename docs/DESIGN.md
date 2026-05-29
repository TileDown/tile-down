# Design: Tiledown

| Field | Value |
|---|---|
| **Status** | draft |
| **Created** | 2026-05-29 |
| **Last revised** | 2026-05-29 |
| **Tracking issue** | none |
| **Companion docs** | [CONVENTIONS.md](CONVENTIONS.md), [rules](rules/README.md), [research](research/) |

---

## TL;DR

Tiledown is a Swift static-site generator with a Markdown-canonical source
format and a typed tile model.

Authors write Tiledown Markdown on disk. The parser turns that constrained
Markdown profile into a typed tile tree. The site pipeline resolves content,
queries, templates, assets, and tile renderers, then emits static HTML, CSS,
browser JavaScript, and optional JSON outputs. JSON is a derived format for
tests, debugging, interchange, and future editor internals, not the primary
source file.

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

| ID | Requirement | Verified by |
|---|---|---|
| F1 | Markdown parses to a typed tile tree | unit test |
| F2 | Tile tree serializes to canonical Markdown | unit test |
| F3 | Parse, serialize, parse returns the same tile semantics | unit test |
| F4 | A page renders through a Mustache-style template to HTML | integration test |
| F5 | Unknown tile types preserve source data and render diagnostics | unit test |
| F6 | Output escaping prevents script injection through text fields | unit test |
| F7 | Service-backed tiles reject server secrets in generated browser output | unit test |
| F8 | Query filtering, ordering, limit, and offset work for content collections | unit test |

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
Generated HTML/CSS/JS/JSON files
```

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

Start with one package under `Packages/`, one library target, and one executable
target:

```text
Packages/
  Package.swift
  Sources/
    TileKit/
    TiledownCLI/
  Tests/
    TileKitTests/
```

Use internal namespaces before splitting modules. Add more modules only when
import boundaries become real.

Initial namespaces:

| Namespace | Responsibility |
|---|---|
| `TileKit.Site` | build request, generator, target, output |
| `TileKit.Source` | source files, front matter, content loading |
| `TileKit.Content` | content type, property, relation, query, scope |
| `TileKit.Markdown` | Markdown source parsing and tile directive parsing |
| `TileKit.Template` | template loading and rendering contracts |
| `TileKit.Tile` | tile model, definitions, renderers, registry |
| `TileKit.Service` | service manifests, auth exposure, operation schemas |
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

Tile definitions declare:

- type id
- accepted properties
- validation rules
- renderer
- required CSS and JS assets
- capability mode
- diagnostics

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

---

## 10. Services and Secrets

Service-backed tiles use provider-neutral manifests. Tiledown does not care
whether the backend is Hummingbird, Vapor, serverless, or a third-party API.

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

Secrets never appear in Markdown, generated HTML, generated JavaScript, or
browser storage.

Credential exposure:

| Exposure | Browser output allowed? |
|---|---|
| `none` | no credential |
| `browser` | yes, intentionally public |
| `server` | no |
| `build` | no |

The library does not read environment variables directly. The CLI or an injected
secret resolver provides typed credentials to the generator.

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
- Canonical serialization.
- Parse, serialize, parse round-trip.
- Unknown tile preservation and diagnostic render.
- HTML escaping.
- Content type property validation.
- Query filter/order/limit/offset.
- Mustache render from prepared context.
- Service manifest decoding.
- `service-form` rejects server secrets in browser output.

No live network tests in the core suite. HTTP is injected and tested with fakes.

---

## 15. Implementation Order

1. Scaffold `Packages/Package.swift`, `TileKit`, `TiledownCLI`, and
   `TileKitTests`.
2. Implement source loading for one Markdown file with front matter.
3. Implement one Mustache-style HTML render.
4. Add content type and query basics.
5. Add Markdown tile directives and tile registry.
6. Add generated assets and asset behavior registry.
7. Add `service-form` manifest decoding and generated HTML/CSS/JS.
8. Add JSON output.
9. Add `init`, `serve`, and `watch`.

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

## 17. Open Questions and Risks

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

## 18. Future Work

- Native macOS and iOS visual editor over the tile model.
- Built-in tiles for poll, YouTube, comments, email response, charts, and
  diagrams.
- Service proxy helper package or deployment template.
- GitHub Pages publishing workflow.
- Template/theme package story.

---

## 19. References

### Internal

- [CONVENTIONS.md](CONVENTIONS.md)
- [Rules index](rules/README.md)
- [Markdown source model research](research/2026-05-29-1654-markdown-tile-source-model.md)
- [Tile function source evaluation](research/2026-05-29-1718-tile-functions-source-evaluation.md)
- [Tile catalog and service contract](research/2026-05-29-1728-tile-catalog-service-contract.md)
- [Toucan parity architecture research](research/2026-05-29-1744-toucan-parity-tiledown-architecture.md)
