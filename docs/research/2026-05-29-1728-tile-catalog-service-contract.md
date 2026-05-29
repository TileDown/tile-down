# Research: Tile catalog and service-backed tile contract

| Field | Value |
|---|---|
| **Created** | 2026-05-29 17:28 CEST |
| **Iteration** | 4 of N |
| **Status** | design inventory and convention recommendation |
| **Question** | What tile families should Tiledown plan for, and how should a generated HTML/CSS/JS tile discover inputs, outputs, formatting, service availability, and API-key handling for a custom backend? |
| **Context** | Tiledown is a Swift static-site generator with typed tiles. The generator emits HTML and CSS, and may emit browser JavaScript only as tile runtime code. Service-backed tiles need generated input fields, generated result views, validation, formatting, and clear rules for public keys versus secrets. |
| **Companions** | `2026-05-29-1718-tile-functions-source-evaluation.md` |

---

## Headline

Use a provider-neutral tile function manifest.

Tiledown should not care whether a service is implemented with Hummingbird,
Vapor, Node, Rails, a serverless function, or a third-party API. It should care
about this contract:

- Is the service available?
- Which operations does it expose?
- Which inputs does each operation require?
- Which outputs does each operation return?
- How should the generator render input controls and output fields?
- Can browser JavaScript call the service directly, or does the call need a
  proxy or build-time execution because a secret is required?

The right convention is:

1. Markdown names a tile, service id, operation id, and presentation overrides.
2. Site config maps the service id to a manifest URL and auth policy.
3. The manifest describes operations with JSON Schema inputs and outputs plus
   Tiledown UI hints.
4. The Swift generator emits deterministic HTML/CSS and a small JS runtime for
   interactive modes.
5. Secret API keys never appear in Markdown, generated HTML, generated JS, or
   browser storage.

---

## Tile families to plan for

This is not mathematically exhaustive, but it is broad enough to keep early
architecture honest.

| Family | Tile examples | Capability pressure |
|---|---|---|
| Core content | heading, paragraph, rich text, list, quote, code, code block, table, footnote, callout, details | `static` |
| Page structure | section, columns, grid, cards, hero, tabs, accordion, divider, spacer | `static`, sometimes `local` |
| Navigation | nav, breadcrumbs, table of contents, pagination, previous/next, sitemap entry | `static`, `build` |
| Media | image, figure, gallery, carousel, audio, video, YouTube, Vimeo, PDF, iframe | `static`, sometimes `remote` |
| Data display | metric, chart, data table, CSV viewer, JSON viewer, timeline, calendar, map | `static`, `build`, `local`, `remote` |
| Diagrams | Mermaid, Graphviz-like diagram, sequence chart, flowchart | `build`, `local` |
| Forms and actions | contact form, email response, newsletter signup, RSVP, survey, poll, quiz, calculator, estimate form, booking widget | `local`, `remote`, `proxy`, `build` |
| Local interaction | local poll, filter, sort, search, bookmarks, checklist, theme toggle, local notes | `local` |
| Remote interaction | comments, reactions, ratings, global poll, service-call form, lookup, personalized result | `remote`, `proxy` |
| Commerce and funding | product card, buy button, donation button, checkout link | `static`, `remote`, usually not direct payment handling |
| Build-time import | RSS import, GitHub release list, YouTube metadata, API-to-static table, chart precompute | `build` |
| SEO and metadata | Open Graph, JSON-LD, canonical URL, feed, robots, sitemap | `static`, `build` |
| Diagnostics | unsupported tile, missing service, schema mismatch, unavailable endpoint | generated fallback plus build diagnostic |

The important architectural point is that many tiles are specific skins over a
small set of mechanics:

- render structured content
- embed a trusted external surface
- store local browser state
- fetch public data from the browser
- call a private service through a proxy
- run a build-time function and bake the result into HTML

---

## Recommended capability modes

| Mode | Meaning | Generated output |
|---|---|---|
| `static` | No browser state and no network call | HTML/CSS only |
| `local` | Browser-only state, no remote service | HTML/CSS plus JS, often `localStorage` |
| `remote` | Browser calls a public endpoint | HTML/CSS plus JS `fetch`, no secrets |
| `proxy` | Browser calls a site-owned endpoint that holds secrets | HTML/CSS plus JS `fetch` to the proxy |
| `build` | The Swift generator calls the service during build | Static HTML result, no runtime call |

Rules:

- A tile may support more than one mode, but the selected mode must be explicit.
- `remote` allows only `none` or intentionally public browser credentials.
- `proxy` is required when a secret API key is needed at visitor runtime.
- `build` is allowed when the result can be computed before publishing.
- A pure static host such as GitHub Pages cannot keep secrets at runtime. Secret
  backed runtime tiles need a separately deployed proxy or backend.

---

## Service-backed tile shape

Use one generic base tile for schema-driven forms and results:

```markdown
:::tile service-form
id: price-calculator
service: calculator
operation: positive-decimal-calculation
mode: proxy
submitLabel: Calculate
:::
```

The tile does not duplicate the service schema. It references an operation. The
author may override labels, defaults, layout, and result presentation, but the
manifest remains the source of truth for accepted input and returned output.

Site config provides the service binding:

```yaml
services:
  calculator:
    manifest: https://calc.example.com/tiledown/service.json
    mode: proxy
    proxyRoute: /_td/services/calculator
    auth:
      type: bearer
      valueFromEnv: CALCULATOR_API_KEY
      exposure: server
```

For a public browser key, the config must say it is public:

```yaml
services:
  comments:
    manifest: https://comments.example.com/tiledown/service.json
    mode: remote
    auth:
      type: publicKey
      name: X-Site-Key
      value: pk_site_public_123
      exposure: browser
```

The word `apiKey` should be avoided in Markdown and public config because it
does not say whether the value is safe to ship. Use `publicKey` for browser
values and `valueFromEnv` or `secretRef` for server-side secrets.

---

## What the manifest must tell Tiledown

Minimum manifest fields:

| Field | Purpose |
|---|---|
| `id` | Stable service id |
| `name` | Human-readable service name |
| `version` | Service contract version |
| `health` | Availability check endpoint and timeout |
| `operations` | Callable operations |
| `operations[].id` | Stable operation id used by the tile |
| `operations[].modes` | Supported `remote`, `proxy`, or `build` modes |
| `operations[].transport` | HTTP method, path, content type, response type |
| `operations[].inputSchema` | JSON Schema for accepted input |
| `operations[].inputUi` | Generator hints for controls, labels, order, units |
| `operations[].outputSchema` | JSON Schema for returned output |
| `operations[].outputUi` | Generator hints for formatting and result layout |
| `operations[].auth` | Required auth scheme and exposure |
| `operations[].errors` | Error format, preferably Problem Details JSON |
| `operations[].cache` | Whether results can be cached and for how long |

JSON Schema should be the normative contract for inputs and outputs. UI hints are
presentation only. If an input fails schema validation, the value is invalid even
if a UI hint would have rendered it.

OpenAPI can be supported later, but the tile manifest should remain the primary
thing Tiledown consumes. OpenAPI describes HTTP APIs well, but Tiledown also
needs tile-specific rendering, capability, availability, cache, and auth-exposure
decisions.

---

## Example manifest for positive decimal inputs

This is provider-neutral. A Hummingbird service, Vapor service, serverless
function, or third-party service can all expose this shape.

```json
{
  "$schema": "https://tiledown.example/schemas/service-manifest/v1.json",
  "id": "calculator",
  "name": "Calculator",
  "version": "1.0.0",
  "health": {
    "method": "GET",
    "path": "/health",
    "expectedStatus": 200,
    "timeoutMs": 2000
  },
  "operations": [
    {
      "id": "positive-decimal-calculation",
      "title": "Positive decimal calculation",
      "modes": ["remote", "proxy", "build"],
      "transport": {
        "method": "POST",
        "path": "/calculate",
        "contentType": "application/json",
        "responseType": "application/json"
      },
      "inputSchema": {
        "type": "object",
        "required": ["a", "b"],
        "additionalProperties": false,
        "properties": {
          "a": {
            "type": "string",
            "pattern": "^(?=.*[1-9])(?:0|[1-9][0-9]*)(?:\\.[0-9]+)?$",
            "x-tiledownType": "positiveDecimal"
          },
          "b": {
            "type": "string",
            "pattern": "^(?=.*[1-9])(?:0|[1-9][0-9]*)(?:\\.[0-9]+)?$",
            "x-tiledownType": "positiveDecimal"
          }
        }
      },
      "inputUi": {
        "order": ["a", "b"],
        "fields": {
          "a": {
            "label": "First value",
            "control": "decimal",
            "inputMode": "decimal",
            "step": "any"
          },
          "b": {
            "label": "Second value",
            "control": "decimal",
            "inputMode": "decimal",
            "step": "any"
          }
        }
      },
      "outputSchema": {
        "type": "object",
        "required": ["result"],
        "additionalProperties": false,
        "properties": {
          "result": {
            "type": "string",
            "x-tiledownType": "decimal"
          }
        }
      },
      "outputUi": {
        "layout": "result-card",
        "fields": {
          "result": {
            "label": "Result",
            "format": {
              "style": "decimal",
              "maximumFractionDigits": 4
            }
          }
        }
      },
      "auth": {
        "required": true,
        "schemes": [
          {
            "type": "bearer",
            "exposure": "server"
          }
        ]
      },
      "errors": {
        "contentType": "application/problem+json"
      },
      "cache": {
        "ttlSeconds": 0
      }
    }
  ]
}
```

Use strings for exact decimal transport when precision matters. Swift can then
parse into `Decimal` on the service side without floating-point surprises. If
precision does not matter, a simpler JSON Schema number works:

```json
{
  "type": "number",
  "exclusiveMinimum": 0
}
```

Client-side validation is only a user experience improvement. The service must
validate again.

---

## Generated HTML/CSS/JS behavior

For `service-form`, the generator should produce:

- A stable root element with `data-td-tile-id`, `data-td-service`, and
  `data-td-operation`.
- A form with generated controls from `inputSchema` plus `inputUi`.
- Accessible labels and validation messages.
- A result region with generated fields from `outputSchema` plus `outputUi`.
- A loading state, success state, unavailable state, validation state, and error
  state.
- CSS scoped by a stable tile class.
- A JS module that reads JSON configuration, validates user input, performs the
  call for `remote` or `proxy`, and renders typed output.

For proxy mode, generated browser JS calls the site proxy:

```text
POST /_td/services/calculator/positive-decimal-calculation
```

For remote mode, generated browser JS calls the service endpoint directly, with
only public credentials if any are declared.

For build mode, the Swift generator calls the operation during generation and
writes the result into static HTML. Build mode only works when all required
inputs are known at build time.

Avoid embedding dynamic config by string interpolation into JavaScript source.
Prefer a JSON data island:

```html
<script type="application/json" data-td-config="price-calculator">
{"service":"calculator","operation":"positive-decimal-calculation","mode":"proxy"}
</script>
```

Then the JS runtime parses that JSON.

---

## Schema to control mapping

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

---

## Output formatting mapping

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

HTML returned by a service should be rejected by default. If a future tile allows
remote HTML, it must be an explicit high-trust capability with sanitization and
content-security guidance.

---

## Availability model

Tiledown needs two availability checks:

1. Build-time availability: fetch the manifest and optionally call the health
   endpoint. In strict mode, missing required services fail the build. In warning
   mode, render an unavailable fallback.
2. Runtime availability: generated JS handles fetch errors, timeouts, invalid
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

The manifest should be cacheable with HTTP caching. The generator should still
allow a lockfile later if reproducible builds need pinned manifest versions.

---

## API-key conventions

Tiledown should model credentials by exposure:

| Exposure | Can be emitted to browser? | Use case |
|---|---|---|
| `none` | no credential | public service |
| `browser` | yes, intentionally public | public widget key restricted by origin |
| `server` | no | bearer token, secret API key, private webhook |
| `build` | no | build-time fetch or precompute |

Rules:

- `server` and `build` credentials are resolved from environment variables or a
  future secret provider.
- Generated output must not include `server` or `build` credential values.
- Browser storage may hold non-sensitive tile state, not credentials.
- Public browser keys should be named `publicKey`.
- Secret references should be named `secretRef`, `valueFromEnv`, or equivalent.
- If a third-party provider calls its public identifier an API key, Tiledown
  should still store it under `publicKey` once the author declares it safe to
  expose.

---

## Specific tile recommendations

Implement generic mechanics first, then build named tile definitions on top.

### First slice

- `service-form`: schema-driven generated form and result view.
- `youtube-video`: safe iframe/embed tile.
- `poll`: local mode first, remote/proxy later.
- `email-response`: proxy only.
- `comments`: remote for public widget providers, proxy for private APIs.
- `chart`: static/build data first, local JS rendering later.

### Later slices

- `quiz`: local or proxy scoring.
- `survey`: proxy for collection, build/static for published summary.
- `lookup`: remote or proxy service call with typed result.
- `estimate`: `service-form` specialization with formatted money/unit outputs.
- `calendar`: static/build import, remote refresh optional.
- `search`: local generated index first, remote search later.

Do not start by making a separate custom Swift tile for every backend operation.
Start with `service-form` and let manifests describe operation-specific input,
output, validation, formatting, and availability.

---

## Linux portability

This design is compatible with Linux if the implementation keeps the current
repo rule: Swift for generator/tooling, JavaScript only as emitted browser tile
runtime code, and no Apple-only APIs in engine code.

Portability boundaries:

- The generated site is static HTML, CSS, and browser JavaScript, so it is host
  independent.
- The Swift generator should run on macOS and Linux.
- Manifest discovery, JSON Schema validation, HTML generation, CSS generation,
  and JS emission are normal cross-platform Swift work.
- `remote` mode is platform independent because the browser calls a public
  endpoint.
- `build` mode works on Linux if the build environment can reach the service and
  has any required environment secrets.
- `proxy` mode works on Linux if the site owner deploys a proxy/backend on Linux
  or elsewhere. A pure static host cannot hold runtime secrets by itself.
- Service implementations can be Hummingbird, Vapor, another Swift server, a
  non-Swift server, or a third-party API as long as they expose the manifest
  contract.

Do not make the manifest contract depend on a Swift server framework. If a Swift
server package wants to help authors, it can generate the manifest from Swift
types, but Tiledown should consume the published HTTP contract.

---

## Choice

Choose this stack:

1. Tiledown directive tiles in Markdown.
2. Site-level service bindings in config.
3. Tiledown service manifest as the provider-neutral contract.
4. JSON Schema 2020-12 for input and output schemas.
5. Tiledown `inputUi` and `outputUi` hints for generated controls and formatting.
6. Optional OpenAPI links later for services that already publish OpenAPI.
7. RFC 9457 Problem Details for service errors.
8. Explicit capability modes and auth exposure.

This gives the generator enough information to build input fields, validate
positive decimal inputs, call a custom backend, detect unavailable services,
render result output fields, and format returned values without binding Tiledown
to any one backend framework.

---

## Sources

- JSON Schema Draft 2020-12: https://json-schema.org/draft/2020-12
- OpenAPI Specification latest published version: https://spec.openapis.org/oas/latest.html
- RFC 9457, Problem Details for HTTP APIs: https://www.rfc-editor.org/rfc/rfc9457
- MDN Fetch API: https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API
- MDN `input type="number"`: https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/input/number
- MDN `localStorage`: https://developer.mozilla.org/en-US/docs/Web/API/Window/localStorage
- MDN iframe element: https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/iframe
- MDN custom elements: https://developer.mozilla.org/en-US/docs/Web/API/Web_components/Using_custom_elements
- OWASP Secrets Management Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html
- OWASP Top 10 Client-Side Security Risks: https://owasp.org/www-project-top-10-client-side-security-risks/
