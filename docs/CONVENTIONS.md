# Tiledown Conventions

The coding conventions for Tiledown. They keep the codebase consistent,
testable, and portable. Read this before opening a PR. When in doubt, read the
surrounding files and match what is already there: consistency with existing code
outranks personal preference.

This page is the overview. The full per-area rules live in
[`docs/rules/`](rules/) (index at [`docs/rules/README.md`](rules/README.md)).

## Language

Swift for everything. The single exception is JavaScript, and only where it is
intrinsic to the output: client-side tiles (Mermaid, charts, forms, polls) emit
HTML and JS that run in the visitor's browser. JS is never used for build logic or
tooling.

## Tile and function conventions

Tiledown is Markdown-canonical on disk. The parser turns a constrained,
normalized Tiledown Markdown profile into a typed tile tree. JSON is a derived
form for tests, debugging, interchange, or editor internals, not the primary
source file.

- Plain Markdown is shorthand for core tiles: heading, paragraph, list, quote,
  code, image, and link.
- Tiles with structured properties use directive blocks:

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

- Tile type ids use lowercase kebab-case for built-ins (`youtube-video`,
  `email-response`) and dotted prefixes for externally supplied packages
  (`vendor.poll`) when a collision is possible.
- Tile ids are stable, lowercase kebab-case, unique within a document, and
  preserved by the serializer. The editor may generate ids for new tiles.
- Tile property keys use lowerCamelCase so Markdown, Swift `Codable`, and JSON
  exports stay aligned.
- Unknown tile types and unknown properties are preserved when parsing and
  serializing. Unknown tiles render as visible non-fatal diagnostics in generated
  output.
- Attribute order is canonical. The serializer emits `id`, `mode`, required
  schema properties, optional known properties, then unknown properties in source
  order.

Tile functions are declared by tile definitions, not by ad-hoc string
replacement. A tile definition declares its schema, renderer, required assets,
optional client script, and capability mode:

| Mode | Meaning | Examples |
|---|---|---|
| `static` | Emits HTML only, no browser state or network | YouTube embed, callout |
| `local` | Emits client JS and stores state in the browser | local poll using `localStorage` |
| `remote` | Browser calls a public endpoint with no secret | comments through a public widget endpoint |
| `proxy` | Browser calls a site-owned proxy that holds secrets | email response, private poll API |
| `build` | Generator fetches or transforms data during build | YouTube metadata, chart CSV |

Service-backed tiles use a provider-neutral manifest, not backend-specific
knowledge. The manifest declares service availability, operations, input schema,
output schema, UI hints, auth exposure, cache behavior, and error format. The
backend may be Hummingbird, Vapor, serverless, or a third-party API; Tiledown
consumes the manifest contract.

```markdown
:::tile service-form
id: price-calculator
service: calculator
operation: positive-decimal-calculation
mode: proxy
submitLabel: Calculate
:::
```

The generated HTML, CSS, and browser JavaScript come from the operation's input
and output schemas plus `inputUi` and `outputUi` hints. JSON Schema is the
normative format for service input and output contracts. OpenAPI may be linked
for full HTTP API descriptions, but the Tiledown service manifest is the source
for tile rendering and capability decisions.

Secrets never appear in Markdown, generated HTML, or browser JavaScript. If a
tile needs an API key, the tile uses `mode: proxy` or `mode: build` and refers to
an endpoint or environment variable name, never the secret value. Public browser
keys must be named `publicKey`, not `apiKey`, so review can distinguish them from
secrets.

Runtime Swift plugin loading is out of scope. Pluggability means in-process Swift
registries wired by the CLI composition root: tile definitions, renderers, output
engines, asset behaviors, and build-time functions are injected rather than
looked up from global state.

## Engineering principles

1. **Optimal over fast.** Respect existing code and idioms. Clarify ambiguity
   before coding rather than assuming requirements. When a real trade-off exists,
   surface two or three options instead of guessing.
2. **Progressive architecture.** Start with the simplest thing that works. Add a
   protocol only when a second concrete consumer exists. Generalise only when a
   pattern has actually emerged. Do not pre-abstract.
3. **Make impossible states unrepresentable.** Use exhaustive enums with
   associated values. Never force-unwrap (`!`, `try!`) in shipping code. Errors
   carry both a human-readable reason and an actionable recovery path.
4. **Testable by design.** Inject every collaborator through the initialiser. Test
   behaviour through the public API, not implementation details.
5. **Profile, then optimise.** Value semantics by default. Pick the right data
   structure first. Optimise only with a profile in hand.

## Dependency injection

- **No singletons.** No `static let shared`, no process-wide config reached
  through static accessors. Every dependency appears at the `init` site so
  coupling is visible, testable, and removable.
- **Every external collaborator goes through `init`.** Not method parameters at
  the call site, not static fallbacks, not environment lookup. Pure free functions
  that compute from their arguments are fine.
- **Cross-module seams are protocols, not concrete imports.** A library module
  does not reach into another module's concrete types. The executable (the
  composition root) is the only place that wires concretes together.
- **No closure typealiases for named cross-module contracts.** Use a named
  protocol. Closures as ordinary method parameters (`onProgress:`) are fine.

## Namespacing and file layout

- **Every public type lives under an `enum`/`struct` namespace that mirrors its
  folder.** No public type at file scope. Reading `Module.Sub.Leaf` should tell you
  where the type lives and what it does.
- **Namespace anchors are caseless `enum`.** Use `struct` only when the type is
  also a value. Never `class` for a namespace. Shared mutable state is an `actor`
  or an injected value, never a `class`.
- **Drop redundant context.** Under `Availability`, the error is `Availability.Error`,
  not `AvailabilityError`.
- **Concrete types are declared via extensions** on the leaf namespace.
  Conformances may be separate extensions on the qualified path.
- **One non-private type per file.** Private helper types may co-locate when they
  exist only to support the main type.
- **File naming.** A file declaring `extension Foo.Bar { public struct X }` is
  named `Foo.Bar.X.swift` (dots, matching the qualified name). Anchor files
  contain only the namespace declaration, no implementation.

## Concurrency

- Swift 6 strict concurrency is on. Types crossing concurrency boundaries are
  `Sendable`; prove it, do not silence it with `@unchecked` unless you have a
  documented reason.
- Shared mutable state goes in an `actor`. UI-affine state is `@MainActor`.
- Use structured concurrency. No arbitrary `Task.sleep` to paper over ordering.

## Cross-platform

Tiledown builds and runs on macOS and Linux.

- Guard platform-divergent code and abstract platform-specific dependencies behind
  a protocol seam: one implementation per platform, wired by the composition root.
  Subprocess use is allowed.
- Prefer pure-Swift implementations over Foundation-only conveniences in the core.
- Do not add new external dependencies, package-manager requirements, CDN assets,
  or hosted services. See [`rules/external-dependencies.md`](rules/external-dependencies.md).

## Testing

- Use the **Swift Testing** framework: `@Test`, `@Suite`, `#expect`. Not XCTest.
- One behaviour per test. Descriptive names. Deterministic data. No live network
  or filesystem dependence; inject test doubles.
- One test target per source target, named `<SourceTarget>Tests`.
- Use parameterised tests (`@Test(arguments:)`) for families of similar cases.
- Any new browser-visible TileDown feature, including tiles, built-in layout
  behavior, content configuration, generated assets, CLI preview/build behavior,
  or migration-facing output, must update `Examples/everything/content`. If a
  real browser can observe it, update `Packages/Tests/Browser/test_site.py` too.

## Verification before "done"

Do not claim a change is done, fixed, or passing without fresh command output in
the same response. Match the command to the claim:

| Claim | Command |
|---|---|
| Build succeeds | `swift build` |
| Tests pass | `swift test` (cite the count, e.g. `42 / 42`) |
| Bug fixed | the test that reproduced it, now passing |

"Looks good" and "should pass" are not evidence.

## Commits, branches, PRs

See [CONTRIBUTING.md](../CONTRIBUTING.md). In short: Conventional Commits, one
focused change per PR, a `CHANGELOG.md` entry for any change touching shipping
source, and no AI attribution or em dashes in any committed text.
