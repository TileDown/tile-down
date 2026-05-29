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
  is handed to the CommonMark renderer, so prose never contains a tile fence.

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

The canonical serializer is the source of truth for "one official style". Today
it canonicalizes tile blocks (see `DirectiveSerializer`) and passes prose through
verbatim. Full Markdown-syntax normalization (ATX headings, `-` lists, fenced
code) arrives when the prose serializer is built on swift-markdown's
`MarkupFormatter`. Byte-identical round-trips are explicitly not a goal; the
round-trip is semantic, at the tile-tree level.
