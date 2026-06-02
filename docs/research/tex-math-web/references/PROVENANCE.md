# Vendored reference sources: provenance and licenses

These files are **reference material only**. They are not built, imported, or
linked by Tiledown. Tiledown takes no runtime or build dependency on any of
them. They are committed so the formula-tile implementation has the canonical
algorithms and data layouts to port from, in-tree, pinned, and offline-readable.

All four upstreams are permissively licensed and allow verbatim redistribution
with their copyright and license notice retained. Each project's license file
is committed alongside its sources.

Fetched 2026-06-02 from the pinned commits below.

| Folder | Upstream | Branch | Pinned commit | License |
|---|---|---|---|---|
| `katex/` | [KaTeX/KaTeX](https://github.com/KaTeX/KaTeX) | `main` | `4784331e41400d7521b7aaff67c075885040d3e4` | MIT (`katex/LICENSE`) |
| `katex-fonts/` | [KaTeX/katex-fonts](https://github.com/KaTeX/katex-fonts) | `master` | `56e79c93c88c9054b017cc92e496b383e0bf82d7` | MIT (`katex-fonts/LICENSE`) |
| `harfbuzz/` | [harfbuzz/harfbuzz](https://github.com/harfbuzz/harfbuzz) | `main` | `56feae4035bdd48f62ba2b8d8c16232d4d89b3a4` | Old MIT (`harfbuzz/COPYING`) |
| `matplotlib/` | [matplotlib/matplotlib](https://github.com/matplotlib/matplotlib) | `main` | `17dbcbe851cc27dbcdd178535450c209b1b9b20d` | Matplotlib License, BSD-style (`matplotlib/LICENSE`) |

## What each file is, and why it is here

### `katex/` (TypeScript) - the canonical readable port of TeXbook Appendix G to HTML + MathML

KaTeX is the closest existing implementation to what Tiledown needs: it takes a
TeX-math string and emits self-contained HTML+CSS (and parallel MathML), with no
runtime dependency and no external math library. It is Knuth's Appendix G
(`mlist_to_hlist`) re-expressed in readable code. We port the *algorithm*, not
the bytes.

- `buildHTML.ts` - the main box-and-glue builder: turns a parsed math list into
  a positioned DOM tree. The spacing, atom-type, and cramped-style logic here is
  the Appendix G core.
- `buildCommon.ts` - glyph/box construction primitives: `makeSymbol`, vlists,
  font selection, metric lookups. The "how a box gets its height/depth/width"
  layer.
- `buildMathML.ts` + `mathMLTree.ts` - the parallel MathML emitter. Reference for
  the MathML-output strategy (option B in the research doc).
- `buildTree.ts` - the top-level entry tying HTML and MathML builders together.
- `Style.ts` - the seven TeX math styles (display, text, script, scriptscript,
  cramped variants) and the transitions between them.
- `Options.ts` - rendering context (current style, size, color, font) threaded
  through the builder.
- `fontMetrics.ts` - the metric accessor + the small set of global TeX font
  parameters (`sigma`/`xi` constants from Appendix G, e.g. axis height, rule
  thickness, sub/superscript drops).
- `fontMetricsData.js` - **the data we most need**: per-glyph height, depth,
  italic correction, skew, and width for the Computer Modern / AMS families,
  keyed by font and code point. This is the porting target for Tiledown's metric
  table if we ship our own fonts rather than read an OpenType MATH table.
- `delimiter.ts` - delimiter sizing and the `\left`/`\right` auto-sizing plus
  glyph-assembly logic (stacking pieces to build tall braces/radicals).
- `stretchy.ts` - stretchy accents and arrows.
- `domTree.ts` - the DOM node model KaTeX positions (spans with em offsets).
- `units.ts` - TeX unit conversions (pt, em, mu, ex).

### `katex-fonts/` - how TeX TFM metrics become the data table

- `extract_tfms.py` - the offline pipeline that reads TeX `.tfm` (TeX Font
  Metric) files and emits the metric JSON that becomes `fontMetricsData.js`. If
  Tiledown ships Computer Modern web fonts, this is the recipe for generating
  our own metric table from the canonical TeX source rather than copying KaTeX's.

### `harfbuzz/` (C/C++) - the reference reader for the OpenType MATH table

HarfBuzz's `hb-ot-math` is the de-facto reference implementation for *reading*
the OpenType MATH table (the table browsers and LuaTeX/XeTeX consume). It does
not do layout; it exposes the font data layout needs. This is the porting target
for a Swift OpenType MATH parser (option C / the font-metrics path) and mirrors
what the sibling `MarkdownPDF` repo already does in `TrueTypeFontParser.swift`.

- `hb-ot-math.h` - the public API surface: constants, italic correction, top
  accent attachment, glyph variants, glyph assemblies, min-connector-overlap.
  The shape of the data a layout engine asks the font for.
- `hb-ot-math-table.hh` - the actual binary table parser: `MathConstants`,
  `MathGlyphInfo`, `MathVariants`, `MathKern`, `GlyphAssembly`. The byte-level
  layout of the table, which a Swift parser must replicate.
- `hb-ot-math.cc` - the glue exposing the table through the API.

### `matplotlib/` (Python) - a complete, readable, pure-language Appendix G engine

- `_mathtext.py` - matplotlib's `mathtext` is a self-contained TeX-math-subset
  layout engine written in pure Python (its only "math" dependency is FreeType
  for glyph metrics). It implements the Appendix G box model directly: `Box`,
  `Hlist`, `Vlist`, `Glue`, `Kern`, `Char`, the `Ship` walker, fraction and
  radical and script layout. Because it is one self-contained file in a
  high-level language, it is the single most readable end-to-end reference for
  "implement TeX math layout yourself without a TeX binary." Closest in spirit
  to the pure-Swift engine Tiledown intends to build.

## Not vendored (and why)

- **The TeXbook, Appendix G** (Knuth, Addison-Wesley) - the original
  specification of the math layout algorithm. Copyrighted; cannot be committed.
  Cited in the research doc; the algorithm is reconstructed from the MIT/BSD
  re-implementations above.
- **OpenType MATH table spec** and **MathML Core spec** - vendor/standards-body
  documentation, linked and summarized in the research doc rather than copied.
- **The sibling `MarkdownPDF` repo's Swift math engine** - already in-house under
  the same owner; referenced by path in the research doc, not duplicated here.
