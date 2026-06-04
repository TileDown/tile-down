# TileDown Everything Example

This site is the canonical browser fixture for TileDown. It is intentionally
small, but it exercises every shipped browser-visible feature: built-in layouts,
theme switching, hero images, Markdown, math, static and interactive tiles,
service forms, posts, tags, RSS, article PDFs, source disclosure, redirects,
404 fallback redirects, static passthrough, baseURL rewriting, social links, and
outbound link shims.

Build it from the repository root:

```sh
swift run --package-path Packages tiledown build-site Examples/everything/content /tmp/tiledown-everything
```

Serve it locally:

```sh
swift run --package-path Packages tiledown serve --port 8765 Examples/everything/content
```

Run the browser gate that builds this example in normal, drafts, system-theme,
and baseURL-subpath variants:

```sh
Packages/Tests/Browser/run.sh
```
