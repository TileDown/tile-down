# Research: Markdown as source of truth for a tile-native document model

| Field | Value |
|---|---|
| **Created** | 2026-05-29 16:54 CEST |
| **Iteration** | 1 of N (scientific-literature pass) |
| **Status** | in progress; industry/prior-art pass pending (deep-research workflow running) |
| **Question** | How do others use Markdown as the canonical source for a structured, block/tile document model, and what does the literature say about lossless round-trip with a visual editor? |
| **Context** | Tiledown design pivot: Markdown becomes the source of truth on disk, with special typed tags carrying tile properties, parsed into one typed tile tree, rendered to static HTML. A future native macOS/iOS visual editor must round-trip the tree without loss. |

---

## Headline

There is almost **no peer-reviewed literature on Markdown-the-format** itself (its rigor lives
in the CommonMark spec, not journals). But the actual hard problem, "a visual editor edits the
structured tree and writes it back to the text source without loss," has a deep, 20-year formal
literature under a different name: the **view-update problem** and **bidirectional
transformations (lenses)**. That is the science that governs this design, and it both validates
and constrains the recommendation.

---

## Core scientific sources (round-trip / editor side)

### 1. Lenses, the founding paper

Foster, Greenwald, Moore, Pierce, Schmitt. "Combinators for bidirectional tree transformations:
A linguistic approach to the view-update problem." *ACM TOPLAS* 29(3), 2007.
DOI [10.1145/1232420.1232424](https://dl.acm.org/doi/10.1145/1232420.1232424).

A lens is one program read two ways: forward maps source to view (Markdown to tile tree),
backward takes a *modified view plus the original source* and produces a correspondingly
modified source (edited tree back to Markdown). Defines the round-trip correctness laws
(GetPut, PutGet, PutPut). These are exactly the properties the serializer must satisfy to be
provably lossless. This is the formal spine of the editor.

### 2. Boomerang, round-tripping string data

Bohannon, Foster, Pierce, Pilkiewicz, Schmitt. "Boomerang: resourceful lenses for string
data." *POPL 2008* / SIGPLAN Notices 43(1).
DOI [10.1145/1328438.1328487](https://dl.acm.org/doi/10.1145/1328438.1328487).
[PDF](https://www.cis.upenn.edu/~bcpierce/papers/boomerang.pdf).

Directly on point: round-tripping text/string data, with explicit support for "reorderable
chunks" identified by **keys**, so reordering items in the view does not corrupt the source on
the way back. That stable-key-per-chunk idea maps precisely onto the tile `id`: it is the
mechanism that lets the editor reorder tiles and still serialize back correctly.

### 3. Most on-point: a structured-document editor built on bidirectional transformations

Hu, Mu, Takeichi. "A programmable editor for developing structured documents based on
bidirectional transformations." *Higher-Order and Symbolic Computation* 21:89-118, 2008
(orig. *PEPM 2004*, DOI [10.1145/1014007.1014025](https://dl.acm.org/doi/10.1145/1014007.1014025)).
DOI [10.1007/s10990-008-9025-5](https://link.springer.com/article/10.1007/s10990-008-9025-5).
[Free PDF](https://scm.iis.sinica.edu.tw/pub/hosc06.pdf).

Essentially a prototype of the future editor: the user performs editing operations on a *view*
of a structured document, and the editor automatically derives the document *source* and the
transformation that produced the view, using the database view-update technique. Read this one
before designing the editor.

---

## Context sources (markup-as-source / literate programming side)

### 4. Literate programming, the origin of one-source-many-outputs

Knuth. "Literate Programming." *The Computer Journal* 27(2):97-111, 1984.
DOI [10.1093/comjnl/27.2.97](https://academic.oup.com/comjnl/article/27/2/97/343244).

Origin of "one canonical source, multiple derived outputs" (tangle/weave). "Markdown source to
HTML plus tile tree" is the same lineage.

### 5. Quarto, the closest living large-scale example

Allaire, Teague, Xie, Dervieux. Quarto (2022).
DOI [10.5281/zenodo.5960048](https://zenodo.org/records/5960048).

State of the art in markup-as-source scholarly publishing: Pandoc Markdown extended with typed
constructs (cross-refs, callouts, layout panels, sub-figures). Ships a **ProseMirror-based
visual editor with bidirectional Markdown conversion**, a live example of the exact round-trip
wanted here. Built on Yihui Xie's R Markdown / knitr line (Xie, *Dynamic Documents with R and
knitr*, 2015), the reproducible-research literature.

### 6. Single-source publishing / structured authoring (XML lineage)

The academic and industry framing of "one structured source, many outputs" predates Markdown
and lives mostly in the XML/DITA/DocBook world.
[Single-source publishing with XML](https://www.researchgate.net/publication/3426599_Single-source_publishing_with_XML).
Recurring finding: enforced structure (schemas) buys reliable reuse, which is the trade-off made
when tags carry typed props.

### 7. Tangential but current

"Layout-Aware Text Editing for Efficient Transformation of Academic PDFs to Markdown," arXiv
[2512.18115](https://arxiv.org/abs/2512.18115) (2025). PDF to Markdown via an edit-then-generate
model; relevant only as evidence that "Markdown as the structured target for documents" is an
active research direction.

---

## What the science says for the decision

- The editor round-trip is a known, formally-studied problem (view-update), not uncharted
  territory. Lens theory gives correctness laws to design against, not just intuition.
- The theory proves there is **no fully general lossless round-trip for an arbitrary text
  format.** Well-behaved lenses exist only under constraints (the lens laws force it). This is
  the formal version of the canonical-serializer argument: Markdown must be constrained to a
  canonical/normalized form, and the serializer must be a well-behaved lens. The science says
  this is the *only* way to get provable round-trip.
- Boomerang's keyed chunks ≈ the tile `id`. Give every tile a stable id and the
  reorder-without-corruption problem has a published solution.
- Quarto is the closest large-scale living proof that "extended-Markdown source + typed
  constructs + visual editor with bidirectional conversion" works in production.
- Peer-reviewed work on "Markdown + typed block tags" specifically is essentially none. That
  part of the space is governed by specs and engineering write-ups (Markdoc, MDX, Pandoc,
  CommonMark directives), covered in the industry pass (iteration 2).

---

## Working recommendation (carried from discussion, to be confirmed against iteration 2)

Lock the model to:

1. **Markdown is canonical on disk.** The tile tree is the parse product; JSON is a
   derived/in-memory form plus optional export.
2. **One typed tile tree, two surface syntaxes.** Plain Markdown is shorthand for the common
   tile types (heading, paragraph, list, code); Markdoc-style typed tags are the surface for
   tiles that need typed props (chart, form, poll, custom). Same model, two notations.
3. **Canonical serializer (a lens).** Define tree to normalized-Markdown so the editor always
   writes one canonical form. Satisfy PutGet/GetPut. Hand-written Markdown normalizes on first
   parse-and-save (gofmt/Prettier style).
4. **Stable tile `id` per node** for reorder-safe round-trip (Boomerang keyed chunks).

This dissolves the original DESIGN.md §15.1 objection (lossy visual round-trip): the canonical
serializer is the published mitigation.

---

## Consequences for existing docs (not yet applied)

- `DESIGN.md` TL;DR, §5 diagram, §6.1 say "a tree of typed tiles **rather than** Markdown" and
  "the tile tree is canonical." These invert.
- `DESIGN.md` NG1 ("Being a Markdown processor" is a non-goal) flips: Tiledown now is one.
- `DESIGN.md` G1/F1 change from "round-trips through JSON" to "round-trips through canonical
  Markdown" (JSON round-trip demotes to secondary).
- `DESIGN.md` §15.1 changes from "rejected" to "adopted, with the canonical-serializer
  mitigation."
- R1 (scope creep into a full SSG) rises from medium to high: a Markdown parser (block + inline)
  plus canonical serializer is a larger engine than JSON-only. Reusing a Markdown parsing
  library rather than writing one becomes important.
- Memory note `project_tiledown.md` (currently "not Markdown") needs correcting.

---

## Open threads / next iterations

- **Iteration 2 (pending):** industry/prior-art pass from the deep-research workflow (Markdoc,
  MDX, Portable Text, Pandoc fenced divs/attributes, CommonMark generic directives +
  remark-directive, AsciiDoc, reStructuredText, Djot, ProseMirror/Lexical/Tiptap/Milkdown,
  Notion block model). Merge findings here; flag contradictions with iteration 1.
- Decide the tag syntax family (Markdoc `{% %}`, Pandoc `{.class key=val}`, directives
  `:::name{...}`). Deferred by request.
- Pull Boomerang and Hu/Mu/Takeichi PDFs in full and extract the concrete round-trip algorithm
  as an implementation-level reference for when editor work starts.

---

## Sources

- Foster et al., TOPLAS 2007: https://dl.acm.org/doi/10.1145/1232420.1232424
- Bohannon et al., Boomerang, POPL 2008: https://dl.acm.org/doi/10.1145/1328438.1328487 ·
  PDF: https://www.cis.upenn.edu/~bcpierce/papers/boomerang.pdf
- Hu, Mu, Takeichi, HOSC 2008: https://link.springer.com/article/10.1007/s10990-008-9025-5 ·
  PDF: https://scm.iis.sinica.edu.tw/pub/hosc06.pdf · PEPM 2004:
  https://dl.acm.org/doi/10.1145/1014007.1014025
- Knuth, Literate Programming, Computer Journal 1984:
  https://academic.oup.com/comjnl/article/27/2/97/343244
- Quarto, Zenodo 2022: https://zenodo.org/records/5960048
- Single-source publishing with XML:
  https://www.researchgate.net/publication/3426599_Single-source_publishing_with_XML
- Layout-Aware Text Editing (PDF to Markdown), arXiv 2025: https://arxiv.org/abs/2512.18115
- Round-trip format conversion (definitional): https://en.wikipedia.org/wiki/Round-trip_format_conversion
- Milkdown (ProseMirror + Remark, bidirectional md editor): https://deepwiki.com/Milkdown/milkdown
