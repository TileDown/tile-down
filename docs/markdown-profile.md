# Tiledown Markdown profile

The constrained Markdown profile Tiledown parses and renders. A first cut of
[DESIGN.md](DESIGN.md) Q1. It will tighten as the structural model and the
canonical serializer mature.

## Two surfaces, one document

A Tiledown document interleaves two kinds of block in source order:

- **Prose**: standard CommonMark, parsed and rendered by
  [swift-markdown](https://github.com/apple/swift-markdown) (Apple's CommonMark
  parser, the `Markdown` module). `TileKit.Markdown.CommonMarkRenderer` walks the
  tree and emits HTML.
- **Tiles**: directive blocks `:::tile <type>` ... `:::` with `key: value` lines
  and `-` list values, parsed by `TileKit.Tile.DirectiveParser` and serialized by
  `TileKit.Tile.DirectiveSerializer`. Tile directives are extracted before prose
  is handed to the CommonMark renderer, so prose never contains a tile fence. A
  `:::tile` line inside a fenced code block (``` or `~~~`) is Markdown content,
  not a directive, so documents can show tile examples in code.

Known limitation: the directive parser is line-based and whitespace-lenient (it
trims leading whitespace before recognizing both `:::tile` and code fences), so
CommonMark's 0-3 space indentation rule is not enforced. A code fence or tile
fence indented four or more spaces is still recognized rather than treated as an
indented code block. Full indentation-aware parsing is future work.

## Prose: supported CommonMark

Rendered today: headings, paragraphs, emphasis, strong, inline code, fenced code
blocks (with a language class), links, images, unordered and ordered lists,
block quotes, thematic breaks, and line/soft breaks. swift-markdown parses the
full CommonMark grammar; this list is what the HTML renderer emits. Anything not
listed falls through to its child content.

## Escaping and raw HTML

Text is escaped by default (`&`, `<`, `>`; attributes also escape `"`). Raw HTML,
block or inline, is **escaped rather than passed through**: authored or remote
HTML never executes in generated output. This is Tiledown's escape-by-default
security posture, not a CommonMark default.

## Canonical form

`TileKit.Site.DocumentSerializer` is the source of truth for "one official
style". It canonicalizes tile blocks through `TileKit.Tile.DirectiveSerializer`
and prose through `TileKit.Markdown.CommonMarkFormatter` (swift-markdown's
`MarkupFormatter`), joined in source order.

Prose normalizes to: ATX headings (`# H`, never Setext), `-` for unordered-list
and thematic-break markers, fenced code blocks, and `*` for emphasis. The output
is a fixed point: serializing it again yields the same string.

Known normalization, by design: custom ordered-list start indices are not
preserved (swift-markdown #76), so `3.`/`4.` become `1.`/`1.`. The renderer still
honors `<ol start>` for non-canonical authored source; the canonical form simply
does not carry a custom start. Byte-identical round-trips are explicitly not a
goal; the round-trip is semantic, and the canonical form is the normalized
profile. The laws that hold are idempotence (the canonical form is a fixed point)
and, once a document is canonical, tile-tree round-trip (`parse(serialize(x)) ==
x`).
