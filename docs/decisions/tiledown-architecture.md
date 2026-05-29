# Tiledown architecture decisions

Accepted design decisions for Tiledown's current architecture.

## Context

Tiledown is a Swift static-site generator that uses typed tiles and a constrained
Markdown source format. It should cover Toucan-level static-site generation,
then add tile-native functions such as polls, email response, YouTube embeds,
comments, charts, and service-backed forms.

These decisions bind the current implementation and roadmap. If one changes,
update this file and `docs/DESIGN.md` in the same change.

## Decisions

### D1. Name and public surface

The product name is Tiledown. The command is `tiledown`. The engine facade
library is `TileKit`. The repo path may remain `tile-down`, but command names and
Swift imports avoid hyphenated names.

Toucan command names do not need to be copied. Toucan is a product-capability
reference, not a compatibility contract.

### D2. Canonical source format

Tiledown Markdown is canonical on disk. The parser produces a typed tile tree.
JSON is derived for tests, debugging, interchange, and future editor internals.

Structured tiles use directive blocks. Unknown tile types and unknown properties
are preserved through parse and serialize. The serializer emits a canonical
property order so round trips are stable.

### D3. Toucan parity scope

Tiledown carries forward Toucan's useful site-generator capabilities: source
loading, front matter, content types, properties, relations, queries, scopes,
Mustache-style templates, assets, Markdown rendering, HTML and JSON output, and
build, serve, watch, and init workflows.

Tiledown does not copy Toucan internals that conflict with the rules. Hard-coded
string switches become injected registries or protocols. The CLI composition
root wires concrete implementations.

### D4. Language and runtime boundary

Swift is used for generator and tooling code. JavaScript is allowed only as
emitted browser runtime code for client-side tiles such as charts, forms, polls,
and comments. JavaScript is not build logic or tooling.

### D5. Platform support

The engine builds and runs on macOS and Linux. Platform-specific behavior sits
behind injected protocol seams. Future HTTP work should use cross-platform
server-side libraries when real HTTP is needed.

### D6. Package shape

Tiledown uses one Swift package manifest at `Packages/Package.swift`, with many
focused targets. It does not use one `Package.swift` per library.

Current source targets are:

| Target | Role |
|---|---|
| `TileCore` | root `TileKit` namespace and tiny product metadata |
| `TileContent` | content records, values, queries, conditions, sorting, and query execution |
| `TileMarkdown` | Markdown rendering contract and basic HTML renderer |
| `TileService` | provider manifests, service operation contracts, capability inventory, and validation |
| `TileServiceForm` | binding between service-form tile requests, service contract operations, and generated browser output |
| `TileSource` | source documents, front matter parsing, content discovery, and source parser contracts |
| `TileTemplate` | template context, values, rendering contract, and Mustache-style renderer |
| `TileTile` | typed tile blocks, source-ordered properties, directive parser, renderer registry, and typed tile requests |
| `TileSite` | build requests/results, page context, generator orchestration, tile block rendering, and filesystem protocol |
| `TileSiteImpl` | concrete local filesystem adapter |
| `TileKit` | facade target re-exporting domain targets and current implementation adapter |
| `TiledownCLI` | executable composition root |

Each source target gets a matching test target.

### D7. Core, domain, and implementation boundaries

`TileCore` must stay small. It is not a dumping ground for shared code.

Domain targets are able-bodied. They own contracts, value types, validation, and
pure logic. Parser logic, query logic, renderers, and context preparation belong
in domain targets unless they wrap a concrete external integration.

Implementation targets are meatless adapters. They hold concrete I/O and
integration code: filesystem, network transport, service clients, clocks,
process execution, or platform-specific backends.

### D8. Dependency direction

Dependencies flow from composition roots toward focused libraries. Domain targets
may depend on `TileCore`. A domain target may depend on another domain target
only when its public API genuinely composes that domain. `TileSite` currently
composes `TileMarkdown`, `TileSource`, and `TileTemplate`.

The CLI and future app targets are composition roots. They may import the facade
or concrete implementations and wire dependencies together.

Allowed imports are recorded in
`docs/package-import-contract-status.md`.

### D9. Dependency injection

No globals, service locators, or singletons. External collaborators are passed
through initializers. Cross-target seams are named protocols, not closure
typealiases.

The generator receives concrete dependencies such as filesystem, Markdown
parser, Markdown renderer, tile parser, tile renderer registry, template
renderer, and content discovery through its initializer. Future registries
follow the same rule.

### D10. Registries

Variable behavior is represented by injected values:

| Registry | Purpose |
|---|---|
| `TileRegistry` | tile type id to tile renderer |
| `OutputRendererRegistry` | renderer id to output renderer |
| `TemplateRendererRegistry` | template engine id to template renderer |
| `AssetBehaviorRegistry` | behavior id to asset behavior |
| `ServiceRegistry` | service id to manifest binding and auth policy |

Registries are not global.

`TileKit.Tile.Registry` is the first implemented registry. It dispatches typed
tile instances to injected renderers by tile type id and falls back to an escaped
unsupported-tile diagnostic for unknown tile types. `TileSite` renders Markdown
and tile blocks in source order and exposes collected tile CSS and JavaScript in
template context.

### D11. Tile capability model

Tile modes are explicit:

| Mode | Meaning |
|---|---|
| `static` | HTML/CSS only |
| `local` | browser JavaScript and browser-local state |
| `remote` | browser calls a public endpoint |
| `proxy` | browser calls a site-owned proxy that holds secrets |
| `build` | generator calls a service during build |

A tile may support multiple modes, but the selected mode must be explicit when
runtime behavior or credentials are involved.

### D12. Service-backed tile contract

Service-backed tiles use provider-neutral manifests. Tiledown does not care
whether a backend is Hummingbird, Vapor, serverless, another Swift server, a
non-Swift server, or a third-party API.

Markdown references a service id and operation id. Site config maps the service
id to a manifest URL, availability policy, proxy route when needed, and auth
policy. The manifest describes operations using JSON Schema 2020-12 for input
and output plus Tiledown-specific `inputUi` and `outputUi` hints.

The Swift model for this operation manifest is `TileKit.Service.Contract`.
Provider integration manifests remain separate because they describe capability
composition for provider embeds rather than callable service operations.

OpenAPI can be linked later, but the Tiledown service manifest remains the
rendering and capability contract.

### D13. Generated service-form behavior

The first generic service-backed tile is `service-form`. Markdown parses to a
generic tile instance first, then `TileKit.Tile.ServiceFormRequest` validates the
tile id, service id, operation id, selected mode, and optional submit label. It
does not import `TileService`; later composition binds the request to a
`TileKit.Service.Contract`.

`TileKit.ServiceForm.Binder` performs that composition. It rejects mismatched
service ids, missing operations, unsupported modes, and direct browser `remote`
mode when the operation requires non-browser credentials.

`TileKit.ServiceForm.Renderer` performs the first generated-output pass for
browser runtime forms. It emits deterministic HTML, a JSON data island, scoped
CSS, and browser JavaScript for `remote` and `proxy` modes. It rejects `build`,
`local`, and `static` until those modes have dedicated execution paths.

Generation then produces:

- Input fields from `inputSchema` plus `inputUi`.
- Client-side validation for user experience.
- Result fields from `outputSchema` plus `outputUi`.
- Loading, success, unavailable, validation, and error states.
- Scoped CSS.
- Browser JavaScript for `remote` and `proxy` mode.
- Static result HTML for `build` mode when all inputs are known at build time.

Client-side validation is not security. The service validates again.

### D14. Decimal input convention

For exact decimal transport, service manifests use JSON strings with a semantic
hint such as `x-tiledownType: positiveDecimal`. This avoids floating-point
surprises between browser JavaScript, Swift, and backend services.

When precision does not matter, JSON Schema numbers with constraints such as
`exclusiveMinimum: 0` are acceptable.

### D15. Availability model

Services declare availability policy in site config:

| Value | Build behavior |
|---|---|
| `required` | fail if manifest or health check fails |
| `optional` | warn and render fallback |
| `unchecked` | do not call during build |

Runtime JavaScript handles fetch errors, timeouts, invalid responses, and
Problem Details responses.

### D16. Credential exposure

Secrets never appear in Markdown, generated HTML, generated JavaScript, browser
storage, comments, or source maps.

Credential exposure is explicit:

| Exposure | Browser output |
|---|---|
| `none` | no credential |
| `browser` | intentionally public credential may be emitted |
| `server` | not emitted |
| `build` | not emitted |

Use `publicKey` for intentionally public browser credentials. Use `secretRef` or
`valueFromEnv` for server-side or build-time secrets. Avoid `apiKey` in Markdown
because it does not communicate exposure.

### D17. First tile roadmap

Implement generic mechanics first:

| Tile | First mode |
|---|---|
| `service-form` | `proxy` or `build` depending on service |
| `poll` | `local` |
| `youtube-video` | `static` |
| `email-response` | `proxy` |
| `comments` | `remote` for public widgets, `proxy` for private APIs |
| `chart` | `static` or `build` |

Do not create a custom Swift tile for every backend operation. Start with
`service-form` and let manifests describe operation-specific input, output,
validation, formatting, and availability.

### D18. Manifest-driven provider integrations

Provider integrations should be manifest-driven whenever existing Tiledown
capabilities are enough.

The authoring input is provider documentation plus the Tiledown capability
inventory plus the Tiledown manifest schema. The output is `manifest.yml`, not a
provider-specific Swift plugin.

Tiledown does not execute arbitrary provider-specific code from a manifest. Swift
code defines capabilities. Manifests compose capabilities. New Swift code is
required only when an integration needs a new capability: a rendering primitive,
validation type, asset type, credential exposure model, build-time execution
model, or transport shape that cannot be described by the current schema.

Provider manifests can declare credential requirements, but secret values are
bound in site config through `valueFromEnv`, `secretRef`, or `publicKey`
depending on exposure.

## Consequences

- The package graph stays explicit without turning `TileCore` or `TileKit` into a
  god package.
- Future features can lift into focused targets as real boundaries emerge.
- Static hosting works without a backend. Secret-backed runtime behavior needs a
  separately deployed proxy or backend.
- Linux support remains viable because generator code is Swift and browser
  runtime behavior is emitted JavaScript, not build tooling.
