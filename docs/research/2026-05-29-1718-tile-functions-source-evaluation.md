# Research: Source evaluation for tile functions

| Field | Value |
|---|---|
| **Created** | 2026-05-29 17:18 CEST |
| **Iteration** | 3 of N |
| **Status** | source audit and applicability pass |
| **Question** | Which research and prior-art sources should drive Tiledown conventions for typed tiles, pluggable functions, and interactive static-site features? |
| **Context** | Tiledown aims to replicate Toucan-level static-site functionality, then add typed tiles and pluggable functions such as polls, email response, YouTube embeds, comments, local browser storage, third-party APIs, and build-time data fetches. |
| **Companions** | `2026-05-29-1654-markdown-tile-source-model.md`, `2026-05-29-1657-markdown-tile-source-model-industry-pass.md` |

---

## Headline

The scientific sources are valid, but they support a precise architectural claim:
Tiledown can make Markdown canonical only if it treats Markdown as a constrained,
normalized profile and treats the parser/serializer/editor loop as a practical
bidirectional transformation.

For tile functions, the scientific papers do not prescribe poll/comment/email
features directly. They prescribe the correctness constraints that make those
features safe to edit and serialize: stable tile ids, schema-checked properties,
unknown-field preservation, and canonical output. Industry sources then fill in
the extension shape: tags/directives, schemas, functions, renderers, and explicit
security boundaries for browser-side code.

---

## Corrections to existing notes

### Boomerang DOI

The earlier research notes used this DOI:

```text
10.1145/1328897.1328487
```

DBLP and other bibliographic records list the DOI as:

```text
10.1145/1328438.1328487
```

Use `10.1145/1328438.1328487`.

Source:

- https://dblp.uni-trier.de/rec/conf/popl/BohannonFPPS08.html

---

## Source ranking

### Tier 1: load-bearing scientific sources

These should shape Tiledown's core model and tests.

#### Foster et al., lenses

Use for: the formal frame. The Markdown file is the source, the tile tree is the
view, and editor edits must be propagated back through a serializer-like `put`.

Applicability:

- Justifies canonical serialization.
- Justifies explicit round-trip laws as tests.
- Justifies restricting arbitrary Markdown to a normalized Tiledown profile.
- Does not prescribe syntax or plugin APIs.

Primary records:

- https://dblp.org/rec/journals/toplas/FosterGMPS07.html
- https://cir.nii.ac.jp/crid/1364233268526934144

#### Boomerang

Use for: string round-trip and reorder-safe chunks.

Applicability:

- Directly supports stable tile ids.
- The "reordered chunks" problem maps to moving tiles in a future visual editor.
- Best used as a design principle, not as an implementation dependency.

Primary records:

- https://dblp.uni-trier.de/rec/conf/popl/BohannonFPPS08.html
- https://repository.upenn.edu/entities/publication/4ac8804d-ed5e-402d-95ce-da363b1c0cdb
- https://www.cs.cornell.edu/~jnfoster/papers/boomerang.pdf

#### Hu, Mu, Takeichi structured-document editor

Use for: future editor architecture.

Applicability:

- Directly matches "edit a structured document view and derive source."
- Confirms that the editor problem is view-update / bidirectional transformation,
  not merely Markdown parsing.
- Does not help much with static-site generation or runtime interactive tiles.

Primary record:

- https://link.springer.com/article/10.1007/s10990-008-9025-5

### Tier 2: production and implementation precedent

These should shape syntax, schemas, functions, and editor ergonomics.

#### Quarto visual editor

Use for: canonical Markdown writer precedent.

Applicability:

- Strong precedent for mixed source/visual workflows.
- Its visual editor explicitly rewrites Markdown into standard conventions.
- Its `canonical: true` mode is the closest production precedent for Tiledown's
  desired source/visual consistency.

Sources:

- https://quarto.org/docs/visual-editor/
- https://quarto.org/docs/visual-editor/markdown.html

#### Pandoc fenced divs

Use for: `:::` block syntax precedent.

Applicability:

- Strong support for colon-fenced blocks as a Markdown-adjacent block extension.
- Good precedent for nested block containers.
- Pandoc divs are generic, so Tiledown still needs a schema layer to make them
  typed tiles.

Source:

- https://pandoc.org/MANUAL.html

#### remark-directive

Use for: directive syntax and custom Markdown extension precedent.

Applicability:

- Strong precedent for container, leaf, and text directives.
- The YouTube example is directly relevant to a `youtube-video` tile.
- It is JavaScript ecosystem prior art, not a dependency for Tiledown build logic.

Source:

- https://github.com/remarkjs/remark-directive

#### Markdoc

Use for: schema, tags, functions, transform, validate, and render shape.

Applicability:

- Strong precedent for typed tags and custom functions.
- Its syntax does not have to be copied.
- Its core idea maps well to Tiledown: a tile definition declares accepted
  attributes, validation, transformation, and output.

Sources:

- https://markdoc.dev/docs/tags
- https://markdoc.dev/docs/functions

#### ProseMirror Markdown

Use for: future editor architecture.

Applicability:

- Strong precedent for a schema document tree plus Markdown parser/serializer.
- Confirms the parser/serializer should be schema-specific.
- Not a Swift implementation dependency.

Source:

- https://github.com/ProseMirror/prosemirror-markdown

### Tier 3: security sources for interactive tiles

These should shape the capability model and secret rules.

#### OWASP client-side risks and information leakage

Use for: browser-side tile safety.

Applicability:

- API tokens, private keys, and sensitive configuration must not appear in
  generated HTML, JavaScript, browser storage, comments, or source maps.
- Local browser storage is acceptable for non-sensitive local tile state, such as
  local-only poll votes, but not for credentials or private data.
- Third-party widgets and scripts need explicit origin and capability treatment.

Sources:

- https://owasp.org/www-project-top-10-client-side-security-risks/
- https://owasp.org/www-project-web-security-testing-guide/stable/4-Web_Application_Security_Testing/01-Information_Gathering/05-Review_Webpage_Content_for_Information_Leakage
- https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html

### Tier 4: background only

These are useful for context but should not drive conventions.

- Knuth, literate programming: historical single-source framing, not tile design.
- XML / DITA / DocBook single-source publishing: background on structured
  authoring, not Markdown/tile-function design.
- PDF-to-Markdown layout papers: evidence that Markdown remains a target format,
  but not relevant to Tiledown's source model or tile functions.
- Wikipedia / summary sites: useful discovery aids only, not authority.

---

## Implications for tile functions

Tile functions should be modeled as typed definitions, not text replacement.

A tile definition needs:

- Type id.
- Schema for properties.
- Canonical serialization order.
- Validation rules.
- Render function.
- Required CSS and JS assets.
- Capability declaration.
- Unknown-property preservation policy.
- Diagnostics for unsupported modes or missing configuration.

The capability declaration should be explicit:

| Mode | Meaning | Examples |
|---|---|---|
| `static` | Rendered HTML only, no runtime state or network | YouTube iframe, callout |
| `local` | Client JS with browser-local state | local-only poll using `localStorage` |
| `remote` | Browser calls a public endpoint with no secret | public comments widget |
| `proxy` | Browser calls a site-owned proxy that holds secrets | email response, private poll API |
| `build` | Generator fetches or transforms data during build | YouTube metadata, chart CSV |

Security rule:

- `apiKey` is forbidden in tile Markdown because it implies a secret.
- Use `publicKey` only for intentionally public browser keys.
- Use `secretRef` or `env` only for server-side or build-time secrets.
- `mode: proxy` means the generated page calls a public proxy endpoint, never the
  private third-party API directly.
- `mode: build` may read secrets from the build environment, but the rendered
  output must not contain them.

---

## Examples for conventions

### Local poll

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

Evaluation:

- Valid for static hosting.
- Uses `localStorage` only for non-sensitive local state.
- No server or API key needed.
- Votes are per browser, not globally aggregated.

### Remote poll through public endpoint

```markdown
:::tile poll
id: favorite-editor
mode: remote
endpoint: https://example.com/api/polls/favorite-editor
question: What editor do you use?
options:
  - Xcode
  - VS Code
  - Other
:::
```

Evaluation:

- Valid only if the endpoint is designed for public browser access.
- No private secret in Markdown or JavaScript.
- Requires CORS and abuse/rate-limit handling outside Tiledown.

### Email response through proxy

```markdown
:::tile email-response
id: newsletter-question
mode: proxy
endpoint: https://example.com/api/email-response
form:
  email: required
  message: required
:::
```

Evaluation:

- Correct shape for a secret-backed workflow.
- The email provider key lives behind the proxy.
- Tiledown can validate the shape and render the form, but cannot make the proxy
  secure by itself.

### YouTube embed

```markdown
:::tile youtube-video
id: swift-talk
mode: static
videoId: dQw4w9WgXcQ
title: Swift talk
privacyEnhanced: true
:::
```

Evaluation:

- Static tile by default.
- May optionally have `mode: build` later to fetch title/thumbnail metadata.
- The embed renderer should use privacy-enhanced YouTube URLs by default.

### Comments through a third-party widget

```markdown
:::tile comments
id: post-comments
mode: remote
provider: giscus
repo: owner/repo
category: Announcements
publicKey: public-browser-key-if-required
:::
```

Evaluation:

- Treat as remote/public, not secret-backed.
- Any provider token that can mutate private data must move behind `mode: proxy`.
- Third-party script origin should be surfaced in diagnostics and site policy docs.

---

## Recommended convention changes

1. Keep Markdown canonical, but define it as "Tiledown Markdown", a constrained
   profile with a canonical serializer.
2. Use directive-style `:::tile <type>` blocks for structured tiles.
3. Require stable ids for structured and interactive tiles.
4. Require each tile definition to declare schema, renderer, assets, and
   capability mode.
5. Preserve unknown tile types and unknown attributes through parse and serialize.
6. Separate tile modes by capability: `static`, `local`, `remote`, `proxy`,
   `build`.
7. Forbid secrets in Markdown and generated browser assets.
8. Treat JSON as a derived representation for tests, debugging, interchange, and
   future editor internals.

---

## Verification target for implementation

The first implementation milestone should prove:

```text
parse(markdown) == ast1
serialize(ast1) == markdown2
parse(markdown2) == ast2
ast1 == ast2
```

For interactive tiles, add fixture tests for:

- Unknown property preservation.
- Stable attribute ordering.
- Missing required property diagnostics.
- Secret-like property rejection in browser modes.
- Asset collection without duplicate scripts.
- Unknown tile visible diagnostic rendering.

Only after those pass should the visual editor work begin.
