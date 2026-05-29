---
created: 2026-05-29 16:57 CEST
iteration: 2 of N
source: external research pass provided by user; saved below the synthesis note
companion: 2026-05-29-1654-markdown-tile-source-model.md (iteration 1, scientific-literature pass)
status: industry + implementation pass; converges with iteration 1
---

# Synthesis note (added on import)

This external research pass is saved as iteration 2. It **converges with
iteration 1** (the scientific-literature pass) on every load-bearing point:

- Same scientific frame: the editor round-trip is the **view-update problem**, governed by
  **bidirectional transformations / lenses**, not Markdown research.
- Same three core papers: Foster et al. (lenses, TOPLAS 2007), Bohannon et al. (Boomerang,
  POPL 2008), Hu/Mu/Takeichi (programmable structured-document editor, HOSC 2008).
- Same dictated constraint: no general lossless round-trip for arbitrary text; you must define a
  **normalized Markdown profile** and treat the serializer as a **well-behaved lens**.
- Same architectural primitive: **stable tile `id`** per node (Boomerang keyed chunks).
- Same build order: **canonical serializer before visual editor.**

Where iteration 2 adds beyond iteration 1 (and what to decide on):

- **Syntax recommendation:** directive-style `:::tile <type>` with `key: value` lines, chosen
  over Markdoc `{% %}`. Iteration 1 named Markdoc as the closest *precedent* but deferred the
  syntax choice. This is the first concrete syntax proposal; still the deferred open decision.
- **Concrete Swift AST shape** (`TileNode`, `TileBlock`, `TileValue`).
- **Preserve unknown attributes and unknown tile types** on serialization (forward-compat
  round-trip). Not in iteration 1; worth adopting.
- **5-phase implementation order** (parser/AST, canonical serializer, schema, source mapping,
  editor).
- **Decision criteria for when Markdown should NOT be canonical** (collaboration, deep nesting,
  Notion-style editing, frequent schema migration).
- Adds **MyST** to the directive-style references; adds R Markdown: The Definitive Guide (2018,
  DOI 10.1201/9781138359444).

Net: no contradictions between the two passes. Open item carried forward is the **tag syntax
family** (directive `:::` vs Markdoc `{% %}` vs Pandoc `{.class key=val}`), now with a concrete
directive-style proposal on the table.

---

# Tiledown Research Notes

## Overview

Tiledown is a Swift-based static site generator where Markdown is the canonical source format, custom typed blocks ("tiles") carry structured properties, all content parses into a single typed AST, and a future visual editor edits that AST and writes it back to Markdown.

The key architectural goal is not byte-identical Markdown preservation. The realistic and useful goal is semantic round-trip preservation:

```text
Markdown → Tile AST → Markdown → Tile AST
```

The final AST should remain equivalent to the original AST.

The important realization is that there is almost no peer-reviewed literature on Markdown-the-format itself. Markdown's rigor lives mostly in specifications, implementations, and engineering practice, especially CommonMark, Pandoc, MDX, Markdoc, MyST, Quarto, and remark/unified. But Tiledown's hardest problem is not simply "Markdown syntax." The hard problem is:

> A visual editor edits a structured tree and writes it back to the textual source without losing structure.

That problem has a deep formal literature under another name: the view-update problem and bidirectional transformations, especially lenses. This literature gives Tiledown a scientific foundation for the editor and serializer design.

---

## Prior Art Survey

### Markdoc

Markdoc is probably the closest existing system to Tiledown among Markdown-derived systems. It extends Markdown with schema-defined tags and attributes.

```markdoc
{% chart
   id="revenue-q1"
   type="bar"
   data="./revenue.csv"
/%}
```

Characteristics:

- Markdown remains canonical.
- Tags are explicitly typed.
- Attributes are structured.
- Schema validation is built in.
- Well suited for visual editing because the structure is explicit.

Reference:

- https://markdoc.dev/docs/tags

### MDX

MDX combines Markdown with JSX components.

```mdx
<Chart
  id="revenue-q1"
  type="bar"
  data="./revenue.csv"
/>
```

Characteristics:

- Markdown is canonical.
- Components are fully programmable.
- Strong React ecosystem support.
- AST combines Markdown and JavaScript constructs.
- Less suitable for a Swift-native editor because component semantics are tied to JavaScript.

Reference:

- https://mdxjs.com

### Pandoc Fenced Divs

Pandoc extends Markdown with generic attribute-bearing blocks.

````markdown
::: {#revenue-q1 .chart type="bar" data="./revenue.csv"}
Quarterly Revenue
:::
````

Characteristics:

- Markdown remains canonical.
- Generic attribute mechanism.
- Native AST support through Div and Span nodes.
- Strong publishing ecosystem.
- Typing must be layered on top of generic Div nodes.

References:

- https://pandoc.org
- https://pandoc.org/MANUAL.html

### CommonMark Directives / remark-directive

Directive syntax introduces typed block and inline constructs.

````markdown
:::chart{#revenue-q1 type="bar" data="./revenue.csv"}
Quarterly Revenue
:::
````

Characteristics:

- Very close to Tiledown requirements.
- Built on mdast.
- Supports typed blocks naturally.
- Widely used in unified/remark ecosystems.
- Not officially part of CommonMark.

Reference:

- https://github.com/remarkjs/remark-directive

### AsciiDoc

AsciiDoc supports block attributes directly.

```asciidoc
[chart,type=bar,data=revenue.csv]
====
Quarterly Revenue
====
```

Characteristics:

- Rich structured document model.
- Mature publishing ecosystem.
- Not Markdown.

Reference:

- https://docs.asciidoctor.org

### reStructuredText

reStructuredText uses directives as its primary extension mechanism.

```rst
.. chart:: revenue.csv
   :type: bar
   :title: Quarterly Revenue
```

Characteristics:

- Strongly structured.
- Backed by Docutils doctree.
- Excellent extension model.
- Not Markdown.

Reference:

- https://docutils.sourceforge.io

### Djot

Djot is a modern markup language designed to eliminate many Markdown ambiguities.

````djot
::: chart
{type=bar data=revenue.csv}
Quarterly Revenue
:::
````

Characteristics:

- Tree-oriented design.
- Cleaner parsing model than Markdown.
- Small ecosystem.
- Interesting technical influence for Tiledown.

Reference:

- https://djot.net

### Portable Text

Portable Text is fundamentally different because Markdown is not canonical. The canonical document is a JSON block tree.

```json
{
  "_type": "chart",
  "kind": "bar",
  "data": "./revenue.csv"
}
```

Characteristics:

- JSON is canonical.
- Explicit structured content model.
- Excellent editor support.
- Markdown becomes import/export only.

Reference:

- https://portabletext.org

---

## Comparison Table

| System | Block Property Syntax | Canonical Model / AST | Markdown Canonical | Visual Editor Round-Trip Story |
|---|---|---|---|---|
| Markdoc | `{% tag key="value" %}` | Markdoc AST plus transform/render tree | Yes | Strong candidate; schema-defined tags and attributes make visual editing plausible |
| MDX | `<Component prop="value" />` | Markdown + JSX/ESM AST pipeline | Yes | Strong in React, weaker for neutral native editing |
| Pandoc | `::: {#id .class key="value"}` | Pandoc AST with Div/Span attributes | Yes | Excellent syntax precedent; typed semantics must be layered on top |
| CommonMark directives / remark-directive | `:::name{#id key="value"}` | mdast directive nodes | Yes, as extension | Very close to Tiledown, but not official CommonMark |
| AsciiDoc | `[name,key=value]` before block | Processor-specific structured document tree | No | Mature structured authoring, but not Markdown |
| reStructuredText | `.. directive:: arg` plus `:key: value` options | Docutils doctree | No | Mature directive model, not Markdown |
| Djot | block attributes and fenced div-like structures | Tree-oriented markup model | Yes-like, but not Markdown | Technically attractive, small ecosystem |
| Portable Text | JSON objects with `_type` and fields | JSON block tree | No | Best editor model; Markdown is projection/import/export |

---

## Closest Existing Matches

### First Place: Markdoc

Markdoc most closely matches:

```text
Markdown + Typed Tags + Structured Attributes + Schema Validation + AST
```

```markdoc
{% chart
   id="revenue-q1"
   type="bar"
   title="Q1 Revenue"
   data="./revenue.csv"
   x="month"
   y="amount"
/%}
```

Markdoc is the strongest industry precedent for explicit typed tags inside Markdown.

### Second Place: Directive-Based Markdown

````markdown
:::chart{
  id="revenue-q1"
  type="bar"
  title="Q1 Revenue"
  data="./revenue.csv"
}
Quarterly Revenue
:::
````

This is arguably more Markdown-native than Markdoc. It is also closer to Pandoc and MyST-style block extensions.

### Third Place: Pandoc / Quarto

Pandoc-style fenced divs are less explicitly typed, but the ecosystem is stronger and Quarto proves this approach can scale to serious publishing workflows.

````markdown
::: {#revenue-q1 .chart type="bar" title="Q1 Revenue" data="./revenue.csv" x="month" y="amount"}
Quarterly Revenue
:::
````

---

## Attribute Syntax Conventions

### Pandoc Attribute Lists

```markdown
{#id .class key="value"}
```

Pros:

- Broad real-world adoption.
- Strong publishing tooling.
- Used or echoed by Pandoc, Quarto, kramdown-style systems, and related Markdown extensions.

Cons:

- Semantically generic.
- A schema layer is still needed to turn `.chart` or `.tile` into a typed component.

### Directive Attributes

````markdown
:::chart{type="bar"}
Content
:::
````

Pros:

- Explicitly typed.
- Good fit for custom components.
- Close to remark-directive, MyST, and CommonMark directive proposals.

Cons:

- Not standardized by CommonMark.
- Requires custom tooling if used outside the JS/unified ecosystem.

### Markdoc Tags

```markdoc
{% chart type="bar" %}
```

Pros:

- Strong typing.
- Schema validation.
- Production-proven for documentation systems.

Cons:

- Less Markdown-like.
- Looks more like a template language than Markdown.

### JSX / MDX

```mdx
<Chart type="bar" />
```

Pros:

- Very expressive.
- Huge React/docs adoption.

Cons:

- Tightly coupled to JavaScript.
- Harder to make Swift-native and neutral.
- JavaScript expressions complicate safe visual editing.

### HTML in Markdown

```html
<div data-type="chart">
```

Pros:

- Universally accepted by many Markdown parsers.

Cons:

- Often opaque to Markdown tooling.
- Weak typed AST story unless the parser deeply understands the HTML.

### YAML Front Matter

```yaml
---
title: Example
---
```

Pros:

- Excellent for document-level metadata.

Cons:

- Not appropriate for many embedded block-level tiles.

### Key-Value Fence Blocks

````markdown
:::tile chart
id: revenue-q1
type: bar
:::
````

Pros:

- Human readable.
- Easy to parse in Swift.
- Strongly typed.
- Better for multiline structured properties than compact `{}` attributes.

Cons:

- Custom.
- Requires Tiledown-specific parser, formatter, syntax highlighter, and editor support.

---

## The Round-Trip Problem

Perfect Markdown round-trip is generally impossible if the requirement is byte identity.

The following examples represent the same document structure:

```markdown
# Title
```

and:

```markdown
Title
=====
```

Likewise:

```markdown
* item
```

and:

```markdown
- item
```

parse into equivalent AST structures.

Because of this, byte-identical preservation cannot be guaranteed once a document has been parsed, structurally edited, and rewritten.

The realistic goal is semantic preservation:

```text
Markdown → Tile AST → Markdown → Tile AST
```

where the final AST remains equivalent to the original AST.

This should be tested as an invariant:

```text
parse → serialize → parse

AST₁ == AST₂
```

---

## The Scientific Frame: View-Update and Bidirectional Transformations

Tiledown's editor problem is a classic instance of the view-update problem.

The source is the Markdown file.

The view is the structured tile tree shown in the visual editor.

The user edits the view.

The system must propagate that edit back to the source.

This is exactly what bidirectional transformations, especially lenses, were designed to model.

### Lens Laws

A well-behaved bidirectional transformation should satisfy round-trip laws.

The key laws are usually expressed as:

```text
GetPut
PutGet
PutPut
```

For Tiledown, these laws translate roughly into:

- Parsing and serializing without edits should not change the document semantically.
- Editing a tile in the visual editor and writing it back should preserve that edit when the file is parsed again.
- Repeated editor edits should not accumulate corruption.

This is the formal justification for treating the serializer as more than a printer. It should behave like the backward direction of a lens.

---

## Core Academic Sources for the Editor and Round-Trip Problem

### Combinators for Bidirectional Tree Transformations

Authors:

- J. Nathan Foster
- Michael B. Greenwald
- Jonathan T. Moore
- Benjamin C. Pierce
- Alan Schmitt

Title:

*Combinators for bidirectional tree transformations: A linguistic approach to the view-update problem*

Venue:

ACM Transactions on Programming Languages and Systems, 29(3), 2007

DOI:

```text
10.1145/1232420.1232424
```

URL:

https://dl.acm.org/doi/10.1145/1232420.1232424

Relevance to Tiledown:

This is the foundational lenses paper. A lens is one program read in two directions: forward from source to view, backward from modified view plus original source to updated source. For Tiledown, that maps directly to:

```text
Markdown → Tile AST
```

and:

```text
Edited Tile AST + Original Markdown → Updated Markdown
```

The paper defines the round-trip correctness laws that Tiledown should design and test against.

### Boomerang: Resourceful Lenses for String Data

Authors:

- Aaron Bohannon
- J. Nathan Foster
- Benjamin C. Pierce
- Alexandre Pilkiewicz
- Alan Schmitt

Title:

*Boomerang: resourceful lenses for string data*

Venue:

POPL 2008 / ACM SIGPLAN Notices 43(1)

DOI:

```text
10.1145/1328438.1328487
```

URLs:

https://dl.acm.org/doi/10.1145/1328438.1328487

https://www.cis.upenn.edu/~bcpierce/papers/boomerang.pdf

Relevance to Tiledown:

This is directly relevant because it deals with round-tripping string/text data. It includes the idea of reorderable chunks identified by keys. That maps strongly to Tiledown's need for stable tile IDs.

A stable tile ID is not just a convenience. It is the mechanism that lets a visual editor reorder tiles without corrupting the source on write-back.

For Tiledown, every significant tile should have a stable identity:

````markdown
:::tile chart
id: revenue-q1
title: Q1 Revenue
:::
````

That `id` is the editor and serializer's anchor.

### A Programmable Editor for Developing Structured Documents Based on Bidirectional Transformations

Authors:

- Zhenjiang Hu
- Shin-Cheng Mu
- Masato Takeichi

Title:

*A programmable editor for developing structured documents based on bidirectional transformations*

Venue:

Higher-Order and Symbolic Computation 21:89–118, 2008

Original version:

PEPM 2004

DOI:

```text
10.1007/s10990-008-9025-5
```

URLs:

https://link.springer.com/article/10.1007/s10990-008-9025-5

https://scm.iis.sinica.edu.tw/pub/hosc06.pdf

Relevance to Tiledown:

This is probably the single most directly relevant academic paper for the future Tiledown visual editor. It describes an editor where the user edits a structured view of a document and the system propagates those edits back to the source using bidirectional transformations.

This is almost exactly the Tiledown editor problem.

---

## Context Sources: Markup as Source and Single-Source Publishing

### Literate Programming

Author:

Donald E. Knuth

Title:

*Literate Programming*

Venue:

The Computer Journal 27(2):97–111, 1984

DOI:

```text
10.1093/comjnl/27.2.97
```

URL:

https://academic.oup.com/comjnl/article/27/2/97/343244

Relevance to Tiledown:

Knuth's tangle/weave split is the classic origin of one canonical source producing multiple derived outputs. Tiledown fits this lineage:

```text
Markdown source → Tile AST → HTML / editor view / other outputs
```

### Quarto

Authors:

- J. J. Allaire
- Charles Teague
- Yihui Xie
- Christophe Dervieux

Title:

*Quarto*

Year:

2022

DOI:

```text
10.5281/zenodo.5960048
```

URL:

https://zenodo.org/records/5960048

Relevance to Tiledown:

Quarto is a state-of-the-art example of markup-as-source publishing. It extends Pandoc Markdown with typed constructs such as callouts, cross-references, layout panels, subfigures, executable code cells, and more.

It is especially important because it also ships a ProseMirror-based visual editor with bidirectional Markdown conversion. This makes Quarto the closest large-scale living proof that extended Markdown source plus typed constructs plus a visual editor can work in production.

### R Markdown and knitr

Author:

Yihui Xie

Title:

*Dynamic Documents with R and knitr*

Year:

2015

Publisher:

Chapman and Hall/CRC

URL:

https://yihui.org/knitr/

Related reference:

Yihui Xie, J. J. Allaire, Garrett Grolemund

*R Markdown: The Definitive Guide*

Year:

2018

DOI:

```text
10.1201/9781138359444
```

URL:

https://www.taylorfrancis.com/books/mono/10.1201/9781138359444/markdown-yihui-xie-allaire-garrett-grolemund

Relevance to Tiledown:

R Markdown and knitr show the practical success of Markdown-like documents as executable, reproducible, single-source documents.

### Single-Source Publishing with XML

Title:

*Single-source publishing with XML*

URL:

https://www.researchgate.net/publication/3426599_Single-source_publishing_with_XML

Relevance to Tiledown:

The XML/DITA/DocBook lineage predates Markdown and frames the trade-off clearly: enforced structure and schemas make reuse, validation, and multi-output publishing more reliable. Tiledown makes a similar trade-off by adding typed tiles to Markdown.

### Layout-Aware Text Editing for Efficient Transformation of Academic PDFs to Markdown

Title:

*Layout-Aware Text Editing for Efficient Transformation of Academic PDFs to Markdown*

Year:

2025

URL:

https://arxiv.org/abs/2512.18115

Relevance to Tiledown:

This is only tangentially related. It is relevant as evidence that Markdown remains an active target format for structured document workflows, including academic publishing pipelines.

---

## What the Science Says for Tiledown

The editor round-trip is a known formal problem, not uncharted territory.

Lens theory gives Tiledown correctness laws to design against:

- GetPut
- PutGet
- PutPut

The theory also clarifies that a fully general lossless round-trip for arbitrary text is not achievable without constraints. Well-behaved lenses exist only when the source and view relationship is controlled enough for the laws to hold.

Therefore Tiledown should not attempt to support arbitrary Markdown as an editable structured tree. It should define a normalized Tiledown Markdown profile.

Boomerang's keyed chunks map directly to Tiledown tile IDs. Stable tile IDs should be treated as part of the architecture, not as optional metadata.

Quarto is the closest production-scale proof that extended Markdown source plus typed constructs plus visual editing can work.

Peer-reviewed work on "Markdown plus typed block tags" specifically is thin. The syntax side of the design is governed mostly by specs and engineering systems: Markdoc, MDX, Pandoc, CommonMark directives, remark-directive, MyST, and Quarto. The editor correctness side is where the serious academic literature lives.

---

## What Existing Editors Actually Do

### ProseMirror

Canonical representation:

```text
Schema Tree
```

Markdown is imported and exported.

Relevance:

ProseMirror is a strong architectural model for Tiledown's future editor: schema-driven document tree, parser, serializer, and controlled editing operations.

### Tiptap

Tiptap is built on ProseMirror and follows the same architectural model.

### Lexical

Canonical representation:

```text
Editor JSON
```

Markdown is a projection/import/export format rather than the canonical document.

### Obsidian

Markdown files remain canonical.

Live Preview hides syntax while editing but does not fully abstract Markdown away into a Notion-like block model.

### Notion

Structured block model is canonical.

Markdown is import/export only.

### iA Writer

Primarily a Markdown text editor with preview capabilities.

It is not a schema-driven block editor.

### Quarto Visual Editor

Quarto is especially relevant because it uses extended Markdown as the source format while offering a visual editor. This is close to Tiledown's intended product shape.

---

## Recommendation

Tiledown should use Markdown as the canonical source format, but only as a constrained, normalized Markdown profile.

The tile syntax should be directive-style and Markdown-native:

````markdown
:::tile chart
id: revenue-q1
title: Q1 Revenue
kind: bar
data: ./data/revenue.csv
x: month
y: amount
:::
````

This syntax has several advantages:

- More Markdown-native than Markdoc tags.
- More structured than generic Pandoc divs.
- Easier to parse in Swift than full MDX/JSX.
- Better for multiline attributes than compact `{}` syntax.
- Close enough to directive and Pandoc conventions to feel familiar.

### AST Shape

A possible Swift model:

```swift
enum TileNode {
    case document(children: [TileNode])
    case heading(level: Int, children: [InlineNode])
    case paragraph([InlineNode])
    case list(ListBlock)
    case codeBlock(CodeBlock)
    case tile(TileBlock)
}

struct TileBlock {
    var type: String
    var id: String?
    var attributes: OrderedDictionary<String, TileValue>
    var children: [TileNode]
    var sourceInfo: SourceInfo?
    var unknownAttributes: OrderedDictionary<String, TileValue>
}

enum TileValue {
    case string(String)
    case number(Double)
    case bool(Bool)
    case array([TileValue])
    case object(OrderedDictionary<String, TileValue>)
    case null
}
```

Unknown attributes and unknown tile types should always be preserved during serialization.

### Round-Trip Strategy

The pipeline should be:

```text
Markdown → Parser → Tile AST → Visual Editor → Lens-like Update → Canonical Markdown
```

The core invariant should be:

```text
parse(markdown) = ast1

serialize(ast1) = markdown2

parse(markdown2) = ast2

ast1 == ast2
```

For visual editing, the stronger invariant is:

```text
get(source) = view1

edit(view1) = view2

put(source, view2) = source2

get(source2) = view2
```

This is the PutGet law adapted to Tiledown.

### Stable IDs

Every structurally significant tile should have a stable ID.

Good:

````markdown
:::tile chart
id: revenue-q1
title: Q1 Revenue
:::
````

Bad:

````markdown
:::tile chart
title: Q1 Revenue
:::
````

The editor may auto-generate IDs for new tiles.

Stable IDs are necessary for:

- Reordering tiles.
- Preserving comments or surrounding whitespace where possible.
- Merging edits.
- Mapping editor nodes back to source ranges.
- Implementing Boomerang-style keyed chunk behavior.

---

## Recommended Implementation Direction

### Phase 1: Parser and AST

Build a parser that converts Tiledown Markdown into a typed AST.

Do not begin with a visual editor.

First prove:

```text
Markdown → AST → Markdown → AST
```

### Phase 2: Canonical Serializer

Build a formatter/serializer that emits normalized Tiledown Markdown.

The serializer should have one official style.

Examples:

- Always ATX headings, not Setext headings.
- Always `-` for unordered lists.
- Always fenced code blocks.
- Always quote string attributes only when needed, or always quote them if consistency matters more.
- Always emit tile attributes in stable order.

### Phase 3: Schema Layer

Define schemas for tile types.

Example:

```yaml
chart:
  required:
    - id
    - kind
    - data
  optional:
    - title
    - x
    - y
```

The schema should validate:

- Required attributes.
- Attribute types.
- Unknown attributes.
- Deprecated attributes.
- Migration rules.

### Phase 4: Source Mapping

Preserve source ranges for nodes where possible.

This is useful for diagnostics and incremental edits, but it should not be the only round-trip strategy.

Source maps are helpful but not sufficient for arbitrary visual edits.

### Phase 5: Visual Editor

Build the visual editor on the typed AST.

Treat the editor as operating on a view of the source, not raw Markdown.

The editor should preserve the lens-like invariant:

```text
Edited AST + Original Markdown → Updated Markdown → Same Edited AST
```

---

## Top Risks

### 1. Markdown Ambiguity

Risk:

Different Markdown forms collapse into the same AST.

Mitigation:

Define a normalized Tiledown Markdown profile.

Do not promise byte-identical source preservation.

### 2. Tooling Isolation

Risk:

A custom syntax may not be understood by existing Markdown tools.

Mitigation:

Stay close to directive/Pandoc conventions.

Provide:

- VS Code extension or TextMate grammar.
- Swift parser.
- LSP diagnostics.
- Prettier-like formatter.
- HTML fallback renderer.

### 3. Broken Round-Trip in the Visual Editor

Risk:

The editor silently loses unknown attributes, comments, ordering, or future tile data.

Mitigation:

Use lens laws as test names and test architecture:

```text
testGetPut()
testPutGet()
testPutPut()
```

Also preserve:

- Unknown attributes.
- Unknown tile types.
- Stable IDs.
- Source ranges where possible.
- Raw fallback payloads for unknown structures.

---

## When Markdown Should Not Be Canonical

Consider a Portable Text or JSON-first architecture if any of the following become primary requirements:

- Real-time collaborative editing.
- Arbitrary nested object graphs.
- Rich cross-block references.
- Frequent schema migrations.
- Complex inline annotations.
- Heavy Notion-like visual editing.
- Users primarily interact through visual editing rather than source editing.

In that world, the better architecture is:

```text
JSON / Portable Text canonical model → Markdown projection
```

not:

```text
Markdown canonical model → JSON projection
```

For a developer-focused static site generator whose users expect readable files on disk, Markdown remains a reasonable and defensible canonical format.

---

## Final Recommendation

Use Markdown as canonical source, but define Tiledown Markdown as a constrained profile.

Use directive-style tile blocks:

````markdown
:::tile chart
id: revenue-q1
title: Q1 Revenue
kind: bar
data: ./data/revenue.csv
x: month
y: amount
:::
````

Use a typed AST with stable tile IDs.

Build a canonical serializer before building the visual editor.

Treat the parser/serializer/editor as a practical lens:

```text
get: Markdown → Tile AST
put: Original Markdown + Edited Tile AST → Updated Markdown
```

Test against lens-inspired laws.

The scientific foundation is not Markdown research. It is bidirectional transformation research. That is the right theory for Tiledown's hardest problem.
