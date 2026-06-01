# Tiledown

A Swift static site generator with a Markdown-canonical source format and a typed
tile model. Authors write a constrained Markdown profile; the parser turns it into
a tree of typed tiles, which render to static HTML, CSS, and (for interactive
tiles) browser JavaScript. The engine library is `TileKit`, the CLI is `tiledown`.

> The repository is named `tile-down`; the product and CLI are `tiledown`.

## Status: early, not usable yet

Tiledown is at version `0.1.0` and is **not yet a usable static site generator.**
Do not adopt it for a real site.

What works today is a real but partial slice. The engine builds, and the CLI can
build a single Markdown file through a Mustache-style template, or build a folder
of `index.md` files into a styled site using a built-in layout and theme selected
from `tiledown.yml`. It can also emit derived JSON of the parsed tile tree
(`tiledown json`) and rewrite a document to its canonical form (`tiledown fmt`).
Markdown is real CommonMark via
[swift-markdown](https://github.com/apple/swift-markdown). Tile CSS is wrapped in
CSS cascade layers and deduplicated into one shared site stylesheet, site-wide
configuration reaches templates as `site.*`, and configured content builds can
write an RSS feed from pages under `posts/`.

Still missing before it is a usable static site generator: project scaffolding
(`tiledown init`), a dev server and watch mode, named tile types (`youtube-video`,
`poll`, and the rest), and a full asset pipeline
(transforms, minification). The internals for typed tiles and a service-backed
form exist and are tested, but only the service-form tile is wired in; the rest
are not yet a usable authoring workflow.

The architecture and the planned road are real and written down:

- [docs/DESIGN.md](docs/DESIGN.md) - design, goals, and current-state snapshot.
- [docs/NEXT_STEPS.md](docs/NEXT_STEPS.md) - the ordered work queue.
- [docs/decisions/](docs/decisions/) - accepted architecture decisions.
- [docs/research/](docs/research/) - the research behind the source-model pivot.

## What actually runs today

From `Packages/`:

```sh
swift run tiledown version
# Tiledown 0.1.0
```

Build one page from Markdown and a template:

```sh
# source.md
# ---
# title: Hello
# ---
# # Welcome
#
# This is a page.

# template.html
# <!doctype html><title>{{ page.title }}</title>{{{ page.contents.html }}}

swift run tiledown build source.md template.html out.html
```

Build a content directory with the built-in top-nav layout and standard theme
(each `index.md` becomes a slugged `index.html`, and a shared `styles.css` is
written once for the whole site):

```sh
swift run tiledown build-site content/ dist/
```

Add `content/tiledown.yml` to select site settings:

```yaml
title: Minimal Site
baseURL: https://example.com
layout: top-nav
theme: system
rss: true
rssPath: feed.xml
shareLinks: true
social.github: https://github.com/TileDown/tile-down
social.linkedin: https://www.linkedin.com/
```

When `shareLinks: true` is set, built-in article pages include static share links
for X, LinkedIn, Facebook, and email. Set `baseURL` for absolute share URLs on a
published site.

Posts can declare tags in front matter:

```markdown
---
title: Notes from the renderer
date: 2026-05-31
tags: swift, rendering
---
```

Tiledown generates static tag pages. Single-tag pages keep `/tags/swift/`.
Two-tag AND filters are always generated, and larger filters use canonical nested
URLs such as `/tags/rendering/swift/testing/` when those tags co-occur on a post.
Higher-order generated filters are capped at three selected tags so a densely
tagged post cannot expand to every possible tag subset.
Custom tag bars should render only `site.tags` items with `isVisibleInTagBar` on
multi-tag pages; the built-in layouts already do this.

Pages can set a hero image in front matter. Add `imageDark` when a screenshot or
diagram needs a separate dark-mode asset:

```markdown
---
title: Demo
image: /assets/demo-light.png
imageDark: /assets/demo-dark.png
---
```

Built-in layouts use the same pair for post-card thumbnails. If `imageDark` is
omitted, the generated page keeps the plain single-image markup.

Or pass a custom template explicitly:

```sh
swift run tiledown build-site content/ template.html dist/
```

Emit derived JSON of the parsed tile tree, or rewrite a document to canonical form:

```sh
swift run tiledown json source.md out.json
swift run tiledown fmt source.md            # prints canonical form to stdout
swift run tiledown fmt --write source.md    # rewrites in place
swift run tiledown fmt --check source.md    # non-zero exit if not canonical
```

That is the user-facing surface right now. Markdown is CommonMark (headings,
paragraphs, emphasis, strong, inline and fenced code, links, images, lists, block
quotes), with raw HTML escaped; templates are a Mustache-style subset.

See [Examples/minimal-site](Examples/minimal-site) for a small site with home,
about, contact, three posts, footer social links, the `system` theme, and RSS.

## Build and test

```sh
cd Packages
swift build
swift test
```

The engine targets macOS and Linux. To build and test on Linux, see
[docs/linux-testing.md](docs/linux-testing.md).

The full local verification stack is:

```sh
scripts/check-local.sh
```

It runs style checks, namespacing checks, SwiftFormat in lint mode, SwiftLint,
`swift build`, `swift test`, and the local Playwright browser gate.
The same browser fixture runs on Linux in the GitHub workflow.

For generated-site behavior that needs a real browser, such as computed styles,
image decoding, client-side tile JavaScript, and the theme toggle, run the local
Playwright gate from the repo root:

```sh
Packages/Tests/Browser/run.sh
```

That script builds the browser fixture site, serves it locally, and drives
Chromium through Playwright. It requires Python Playwright and Chromium; see
[Packages/Tests/Browser](Packages/Tests/Browser).

## Project conventions

Swift only, except JavaScript emitted as browser runtime for client-side tiles.
Dependencies injected through initializers, types namespaced under `TileKit`, one
type per file. See [AGENTS.md](AGENTS.md) and [docs/rules/](docs/rules/) for the
full conventions, and [CONTRIBUTING.md](CONTRIBUTING.md) to contribute.

## License

[AGPL-3.0](LICENSE).
