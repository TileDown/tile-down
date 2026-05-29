# Design: Tiledown

| Field | Value |
|---|---|
| **Status** | draft |
| **Created** | 2026-05-29 |
| **Last revised** | 2026-05-29 |
| **Tracking issue** | none |
| **Companion docs** | [CONVENTIONS.md](CONVENTIONS.md) |

---

## TL;DR

Tiledown is a tile-native static site generator. A page is a tree of typed
**tiles** rather than a Markdown document, and that tile tree is the canonical,
source-of-truth representation. The engine resolves each tile through a registry
to a renderer and emits static HTML for publishing to GitHub Pages. Rich tiles
(charts, diagrams, forms, polls) render client-side, so there is no server to run
and the whole pipeline can run on-device, which is what makes a future native
macOS and iOS visual editor over the same model possible.

---

## 1. Context

### 1.1 Problem

Existing static site generators are text-first: the document is Markdown, and
richer structure is bolted on as directives or shortcodes. A visual,
block-by-block authoring experience fights that grain, because the source of truth
is prose with embedded escapes, not a structured document.

### 1.2 Why the obvious approaches fall short

- **Markdown-first SSG with custom blocks**: structure is secondary to prose;
  round-tripping a visual layout through Markdown is lossy.
- **Embed an existing SSG as a library**: viable for output, but the core document
  model stays text-first, so the block model can never be primary.

### 1.3 Why now

The goal is a native visual website builder. That product needs a structured
document model shared end to end between the editor and the generator. A
tile-native engine is the foundation that makes the editor tractable.

---

## 2. Goals

### P0
- **G1**: A page is representable as a typed tile tree that serialises to and from
  JSON without loss.
- **G2**: The engine renders a tile tree to static HTML via a registry of tile
  types.
- **G3**: The core is pure Swift, builds on Apple platforms and Linux, and uses no
  subprocess or platform-only APIs, so it can run on iOS.

### P1
- **G4**: Rich tiles (chart, diagram, form, poll) render client-side with no
  server required.
- **G5**: A CLI generates a site and a path exists to publish it to GitHub Pages.

### P2
- **G6**: A native macOS and iOS visual editor over the same tile model.

---

## 3. Non-goals

- **NG1**: Being a Markdown processor. *Markdown is at most an import/export
  format, never the source of truth.*
- **NG2**: A hosted backend or dynamic server. *Output is static; dynamic features
  call external APIs from the browser.*
- **NG3**: A plugin system that loads third-party Swift code at runtime. *Tile
  types are registered in-process; extension is by adding tile types, not dynamic
  loading.*

---

## 4. Requirements

### 4.1 Functional

| ID | Requirement | Verified by |
|---|---|---|
| F1 | A tile round-trips through JSON unchanged | unit test |
| F2 | An unknown tile type renders to a visible, non-fatal marker | unit test |
| F3 | The renderer escapes text content in output | unit test |

### 4.2 Non-functional

| ID | Requirement | Target | Current state |
|---|---|---|---|
| N1 | Core builds on Linux | green CI on Linux | not yet set up |
| N2 | Core has no subprocess dependency | grep clean in core | holds in scaffold |

---

## 5. Design Overview

```
SiteDocument (tiles, JSON)
        |
        v
   TileRegistry  --->  resolve tile.type to a renderer
        |
        v
   HTMLRenderer  --->  walk the tile tree, emit HTML
        |
        v
   static site (HTML + assets + client JS for rich tiles)
        |
        v
   publish (GitHub Pages)
```

The canonical document is a tile tree. The registry maps each tile's `type` to a
renderer. The renderer walks the tree and produces HTML. Rich tiles emit the
HTML and JS that run in the browser. The CLI drives the pipeline; the same engine
embeds in a future editor.

---

## 6. Detailed Design

### 6.1 Document model

*Goal: a structured, serialisable, source-of-truth representation of a page.*

A page is an ordered tree of tiles. A tile has a stable `id`, a `type` string, a
bag of typed `props`, and optional `children`. The model is inspired by Portable
Text: typed nodes with inline marks for rich text. The canonical serialisation is
JSON. Markdown import/export sits on top and is never the source of truth.

### 6.2 Tile types and registry

*Goal: resolve a tile's `type` to the code that renders it.*

Each tile type declares its id and a render function. A registry maps ids to
types. Core tiles (heading, paragraph, list, image) and rich tiles (chart,
diagram, form, poll) register through the same mechanism. Per the progressive
architecture rule, the registry and the tile-type protocol are introduced only as
real tile types accumulate, not ahead of need.

### 6.3 Rendering

*Goal: turn a tile tree into HTML.*

The renderer walks the tree and dispatches each tile to its registered renderer.
An unknown type yields an HTML comment rather than failing the build, so an
authoring mistake is visible but not fatal. Rich tiles emit a container plus the
client-side script they need; the renderer collects required scripts so each is
included once per page.

---

## 7. Data Model

The canonical document is JSON. A tile is:

```json
{
  "id": "string, unique within the document",
  "type": "string, resolved via the registry",
  "props": { "key": "JSON value" },
  "children": [ "nested tiles" ]
}
```

No database. The document is a file; assets are files; output is files.

---

## 11. Security & Privacy

- **Output escaping**: text content is HTML-escaped on render. Missing escaping
  that enables script injection in generated output is a security bug (see
  SECURITY.md).
- **Data collection**: none. Tiledown does not phone home.
- **Runtime network access**: the generator opens no sockets by default. Rich
  tiles may call external APIs from the visitor's browser; those endpoints are the
  site author's choice and are configured per tile.

| Threat | Vector | Mitigation |
|---|---|---|
| Script injection in output | unescaped tile text | escape on render (F3) |

---

## 13. Testing Strategy

Swift Testing throughout. Unit tests for the document model (round-trip,
escaping, unknown-type handling) and per tile-type rendering. Integration tests
for the full render of a sample document once the pipeline lands. CI builds and
tests on macOS and Linux.

---

## 15. Alternatives Considered

### 15.1 Markdown-native SSG with custom blocks

**Considered**: build on a Markdown core and add block directives.

**Rejected**: structure stays secondary to prose; a visual editor would
round-trip layout through lossy Markdown.

**Cost paid**: we lose Markdown's huge existing ecosystem as the native format.
Mitigated by supporting Markdown as import/export.

### 15.2 Embed an existing SSG as a library

**Considered**: depend on an existing Swift SSG and add tiles on top.

**Rejected**: the core document model stays text-first; the tile model could never
be primary, and roadmap velocity is gated by the upstream project.

**Cost paid**: we reimplement SSG plumbing. Mitigated by reusing well-established
libraries for templating, the dev server, file watching, and HTTP, and inventing
only the tile model.

---

## 16. Open Questions & Risks

### Open

| ID | Question | Tracking |
|---|---|---|
| Q1 | Exact JSON schema for tiles and inline marks | open |
| Q2 | Theme story: Swift render functions, user-editable templates, or both | open |
| Q3 | iOS publishing UX and GitHub auth flow | open |

### Risks

| ID | Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|---|
| R1 | Scope creep into a full SSG rebuild | med | high | reuse plumbing; invent only the tile model |
| R2 | Inline rich-text modelling is harder than expected | med | med | adopt Portable Text's marks model rather than invent |

---

## 17. Future Work

- Native macOS and iOS visual editor over the tile model.
- Markdown import/export.
- Rich tile library: charts, Mermaid, forms, polls.
- GitHub Pages publishing, including an on-device path via the GitHub API.

---

## 19. References

### Internal

- [CONVENTIONS.md](CONVENTIONS.md): coding conventions.

### External

- Portable Text specification: structured, typed rich-text document model.
