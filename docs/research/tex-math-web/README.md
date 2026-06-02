# Rendering TeX math on the web, close to the metal

Research pass, 2026-06-02. Background for the formula-tile epic. The brief:
add a formula tile that authors math in the **same Markdown format as the sibling
[`MarkdownPDF`](../../../../MarkdownPDF) project**, rendered for the web, with **no
large runtime dependency** (no bundled KaTeX/MathJax) and **as close to the metal
as possible**.

This doc records what actually does the work under every web math renderer, why
"close to the metal" points at a pure-Swift build-time engine, and what we
vendored as reference. The vendored source lives in [`references/`](references/);
see [`references/PROVENANCE.md`](references/PROVENANCE.md) for licenses.

## Decisions (locked 2026-06-02)

- **Integration: a Markdown rendering capability, not a tile.** Math is static,
  so it lives in the prose / Markdown-to-HTML pipeline (inline `$...$`, display
  `$$...$$`), rendered as ordinary Markdown. It is **not** a `:::tile`. Tiles are
  reserved for **interactive** output; a tile wrapper can be added later only if
  something interactive (e.g. an equation editor) is ever wanted. Existing tiles
  (chart, mermaid, embed) are left exactly as they are. This work only **expands
  Markdown capabilities**. The same principle applies going forward: static
  charts/graphs belong in Markdown too; the tile system is for interactivity.
- **Reuse: shared SPM package.** Extract the math core into a standalone,
  dependency-free Swift package that both `MarkdownPDF` and Tiledown depend on,
  rather than copying it. This is the "abstract at the second real consumer"
  rule landing: Tiledown is the second consumer.
- **Shared boundary: parse to a neutral box model.** The package owns
  `parse -> layout -> MathBox`, where a `MathBox` is pure geometry: positioned
  runs (`{ text, font, size, color, baselineOffset }`) and rules (rectangles).
  **Emitters stay per-consumer**: MarkdownPDF keeps its PDF emitter, Tiledown
  adds the web emitters. The only coupling to break in MarkdownPDF is the run
  type inside `MarkdownMathLayoutElement` (today `PDFTextRun`); it becomes a
  neutral run, with a thin `MathRun -> PDFTextRun` adapter on the PDF side. The
  layout algorithm is unchanged.
- **MarkdownPDF must not regress.** Its `math-formulas.md` witness corpus plus
  `MarkdownMathParserTests`/`MarkdownMathLayoutTests` are the gate; held green at
  every extraction step. Extract leaves first (AST, metrics: zero coupling),
  then layout with the neutral run + adapter.
- **Web output: SVG with embedded glyph outlines, plus hidden MathML for a11y.**
  Reasoned from first principles in section 5. SVG-with-outlines is the only form
  that simultaneously keeps the layout ours, renders identically on every
  browser, and needs zero runtime dependency. MathML is emitted alongside as a
  screen-reader layer, never as the visual render (it would hand layout back to
  the browser). Build order: SVG `<text>` + one bundled OFL math font first
  (fastest correct render), then swap to embedded outlines to drop the font.

## 1. The one algorithm everyone reimplements

There is no canonical C "math layout library" to bind to. Math typesetting is an
**algorithm**, specified once by Knuth in **the TeXbook, Appendix G**
("Generating boxes from math lists", the `mlist_to_hlist` routine), and then
re-implemented from scratch in every ecosystem that needs it. Appendix G defines:

- a **box-and-glue** model: every sub-formula is a box with `width`, `height`
  (above baseline), and `depth` (below baseline), glued together with stretchable
  spacing;
- **atom types** (Ord, Op, Bin, Rel, Open, Close, Punct, Inner) whose pairwise
  combinations set inter-atom spacing;
- seven **styles** (display, text, script, scriptscript, each with a "cramped"
  variant) that shrink scripts and tighten layout as you nest;
- per-construct rules driven by **font parameters** (axis height, rule
  thickness, sub/superscript shift, fraction gaps, big-op spacing) and per-glyph
  **metrics** (height, depth, italic correction, accent skew).

Knuth's original is WEB/Pascal, compiled to C by `web2c` into the `tex` binary.
The math lives in `mlist_to_hlist`. Everything below is a re-expression of the
same rules.

## 2. What the web renderers actually are, and what they depend on

| Renderer | Language | Output | Math layout done by | External math dep |
|---|---|---|---|---|
| **KaTeX** | TypeScript (pure JS) | HTML+CSS spans, parallel hidden MathML | itself (Appendix G in JS) | **none** - metrics baked into `fontMetricsData.js`, ships its own webfonts |
| **MathJax** | pure JS | HTML+CSS, SVG, or MathML | itself; internal format is MathML | **none** |
| **Native MathML Core** | none (markup) | browser renders `<math>` | the **browser's C++ engine** | reads the font's **OpenType MATH table** via **HarfBuzz** (C/C++) |
| **TeX / LuaTeX / XeTeX** | C (web2c) / C+Lua / C++ | DVI/PDF | the TeX engine (`mlist_to_hlist`) | TFM metrics; XeTeX/LuaTeX also read OpenType MATH via HarfBuzz |
| **matplotlib mathtext** | pure Python | raster/vector | itself (Appendix G in Python) | FreeType (C) for glyph metrics only |

Key findings:

- **KaTeX and MathJax have no C dependency.** They are self-contained JS. KaTeX
  in particular is the closest thing to "TeX math, no runtime engine": it
  pre-extracts TeX font metrics offline (`katex-fonts/extract_tfms.py` reads
  `.tfm` files) into a static data table and does pure arithmetic at render time.
  It can render server-side to a plain HTML string. The cost is ~350 KB of JS +
  webfonts, which is exactly the "huge dependency" the brief rules out.

- **The only shared C/C++ in the whole stack is glyph-level, not layout-level.**
  When you emit MathML and let the browser render it, the actual layout is done
  by the browser engine (Blink/WebKit/Gecko, C++), which calls **HarfBuzz**
  (`hb-ot-math`, C/C++) to read the font's **OpenType MATH table** and to build
  stretchy-glyph **assemblies** (tall braces, radicals). HarfBuzz itself "does
  not implement a math layout solution"; it just exposes font data. This MathML
  Core + HarfBuzz path was built by Igalia and Frederic Wang specifically to
  bring TeX rules to browsers. FreeType (C) supplies glyph metrics/outlines.

- So "the C library underneath" is, at most, **HarfBuzz (reads OpenType MATH) +
  FreeType (glyph metrics)**. There is no C library that *does the math layout*.
  Everyone codes Appendix G themselves.

## 3. The OpenType MATH table (the modern "metal")

The modern data source that replaced TFM-only metrics is the **OpenType MATH
table** (Microsoft/ISO spec, current OT 1.9.1). A math-capable font (Latin Modern
Math, STIX Two Math, Cambria Math) carries:

- **MathConstants** - the Appendix G font parameters as font data: axis height,
  fraction rule thickness and gaps, radical gaps, script shift-downs, big-op
  spacing, etc.
- **MathGlyphInfo** - per-glyph italic correction, top-accent attachment, and
  math kerning (the cut-in around scripts).
- **MathVariants** - larger size variants of a base glyph, and **glyph
  assemblies**: the recipe for building an arbitrarily tall delimiter or radical
  from top/middle/bottom/extender pieces.

`references/harfbuzz/hb-ot-math-table.hh` is the byte-level parser for this table
and is the reference for a Swift reader. The sibling `MarkdownPDF` repo already
ships exactly such a reader in `TrueTypeFontParser.swift`, feeding its
`MarkdownMathLayoutMetrics`.

## 4. What MarkdownPDF already does (the in-house starting point)

`MarkdownPDF` (sibling repo, same owner) already implements a pure-Swift,
dependency-free TeX-math subset for PDF output. Reusable pieces:

- **Authoring format** (the parity target): inline `$...$`, display `$$...$$`
  (single-line or fenced across lines). Opt-in via `MarkdownParser.Options`.
- `MarkdownMathParser` - TeX subset string to a `MarkdownMathNode` AST
  (sequence, text, symbol, fraction, radical, scripts, accent). ~100 symbols,
  Greek, relations, arrows, big operators, accents, `\left`/`\right` delimiters.
- `MarkdownMathLayout` / `MarkdownMathLayoutBox` / `MarkdownMathLayoutMetrics` -
  the Appendix G box-and-glue layout, with font-agnostic defaults and OpenType
  MATH constants when available.
- `TrueTypeFontParser` - reads the OpenType MATH table (mirrors HarfBuzz above).
- `MarkdownMathLinearizer` - AST to text, for accessibility/fallback.
- Witness corpus: `Packages/Tests/MarkdownPDFTests/Fixtures/math-formulas.md`.

What it does **not** have, and what the formula tile must add, is a **web
emitter**: the layout produces PDF primitives, not HTML/CSS/SVG/MathML.

## 5. Strategies for Tiledown, ranked against the brief

Tiledown's posture (from `CLAUDE.md` and the tile catalog): Swift-only build
logic, static output, JS allowed only where intrinsic to a client-side tile. The
`chart` tile already proves the **server-side-SVG** pattern (`TileKit.Tile.ChartSVGRenderer`);
the `mermaid` tile proves the **client-side-JS** pattern.

**A. Pure-Swift build-time layout, emit SVG (recommended primary).**
Port MarkdownPDF's `MarkdownMathParser` + `MarkdownMathLayout` into TileKit, add
an SVG emitter over the existing box tree. Zero runtime dependency, zero JS,
byte-identical across browsers, self-contained output, full control. Mirrors the
`chart` tile precisely. Closest to the metal and the only option that satisfies
"no large dependency" with no quality caveat. Cost: we own the layout engine and
its font metrics (ship Latin Modern Math or a Computer Modern web subset, or read
an OpenType MATH font at build time).

**B. Pure-Swift parse, emit MathML, let the browser render (recommended
companion / fallback).**
Emit a `<math>` tree (reference: `references/katex/buildMathML.ts`) and rely on
native browser MathML Core. Zero JS, near-zero output weight, and the actual
layout runs in the browser's C++ engine + HarfBuzz - genuinely "on the metal" of
the platform. Caveat: MathML rendering quality still varies across browsers and
depends on a math font being available. Good as an accessibility layer beside (A),
or as a no-font-shipping option. KaTeX itself ships MathML *and* HTML for this
reason.

**C. Read an OpenType MATH font at build time (extension of A).**
Add a Swift OpenType MATH reader (port `references/harfbuzz/hb-ot-math-table.hh`,
or reuse MarkdownPDF's `TrueTypeFontParser`) so layout constants come from a real
math font rather than hardcoded defaults. Higher fidelity for tall delimiters and
radicals via glyph assemblies. Layers on top of A; not a separate path.

**D. Bundle KaTeX/MathJax (rejected).** Off the shelf, best quality, but it is the
large client-side dependency the brief explicitly refuses, and it puts layout in
JS rather than Swift.

**Decision (see top of doc):** A as the renderer, specifically **SVG with
embedded glyph outlines** (the self-contained form: layout ours, identical
everywhere, zero runtime dependency), with B's MathML emitted **hidden, for
accessibility only** (never as the visual render, since that hands layout to the
browser), and C as a fidelity upgrade once the box model is in. The engine is
shared via an extracted package, not ported in place. Build order: SVG `<text>`
+ one bundled OFL math font first, then swap to embedded outlines to drop the
font dependency.

## 6. Authoring format: parity with MarkdownPDF

The format requirement is delimiter parity, not engine parity:

Both surfaces are **Markdown capabilities**, integrated into the prose pipeline.
Neither is a tile (see Decisions).

| Construct | Syntax | MarkdownPDF | Tiledown surface |
|---|---|---|---|
| Inline math | `$ ... $` | inline parser, woven into prose | **new inline extension** over swift-markdown prose |
| Display math | `$$ ... $$` (one line or fenced across lines) | block parser | **new block extension**, recognized in source order before prose handoff |

The integration points:

1. **Inline `$...$`** appears *inside* paragraphs. swift-markdown has no `$...$`
   concept, so this needs a custom inline scan over text runs that extracts
   `$...$` (honoring code spans and escaped `\$`) and replaces it with rendered
   math, the same role MarkdownPDF's `InlineParser.parseInlineMath()` plays. This
   is the larger piece of work.

2. **Display `$$...$$`** is recognized as a block before prose is handed to the
   CommonMark renderer (the same extract-first approach the directive parser
   already uses for `:::tile`), then rendered inline in source order. Spelling is
   `$$...$$` for MarkdownPDF parity; there is no `:::tile formula` (a tile would
   only be justified by interactivity, which static math does not have).

Escape-by-default still applies: the TeX source is escaped into the output
container; we render structure, never pass raw author HTML through.

## 7. Reference inventory

Vendored under [`references/`](references/) (reference only, never built or
linked; licenses in [`PROVENANCE.md`](references/PROVENANCE.md)):

- `katex/` - the readable Appendix G port to HTML+MathML (`buildHTML.ts`,
  `buildCommon.ts`, `buildMathML.ts`, `Style.ts`, `Options.ts`, `delimiter.ts`,
  `stretchy.ts`, `units.ts`, `domTree.ts`, `mathMLTree.ts`) plus the metric data
  (`fontMetrics.ts`, `fontMetricsData.js`).
- `katex-fonts/extract_tfms.py` - TFM-to-metric-table pipeline.
- `harfbuzz/` - the reference OpenType MATH table reader (`hb-ot-math-table.hh`,
  `hb-ot-math.h`, `hb-ot-math.cc`).
- `matplotlib/_mathtext.py` - a complete pure-Python Appendix G engine, the most
  readable end-to-end "do it yourself" reference.

## 8. Open decisions (for the epic)

Resolved (see Decisions at top): integration (Markdown capability, not a tile),
reuse path (shared package), shared boundary (neutral `MathBox`), web output
(SVG-outlines + hidden MathML), display spelling (`$$...$$`, no tile). Still open:

- Font story: ship Latin Modern Math / Computer Modern web subset for the
  `<text>` step; whether embedded outlines also come from that font's `glyf`/`CFF`
  or a separate subset.
- Scope of the TeX subset for v1 (match MarkdownPDF's, or trim/extend).
- The new shared package's name, repo home, and ownership across the two
  products.

## Sources

- TeXbook, Appendix G (Knuth) - the math layout algorithm. Not vendored (©).
- KaTeX: <https://katex.org/>, <https://github.com/KaTeX/KaTeX>,
  <https://github.com/KaTeX/katex-fonts>
- MathJax: <https://www.mathjax.org/>
- OpenType MATH table spec:
  <https://learn.microsoft.com/en-us/typography/opentype/spec/math>
- MathML Core (W3C): <https://www.w3.org/TR/mathml-core/>
- OpenType MATH in HarfBuzz (Frederic Wang):
  <https://frederic-wang.fr/2016/04/16/opentype-math-in-harfbuzz/>
- HarfBuzz `hb-ot-math` manual:
  <https://harfbuzz.github.io/harfbuzz-hb-ot-math.html>
- matplotlib mathtext: <https://github.com/matplotlib/matplotlib>
- KaTeX vs MathJax vs native MathML comparison:
  <https://biggo.com/news/202511040733_KaTeX_MathJax_Web_Rendering_Comparison>
