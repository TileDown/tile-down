# Tiledown

A Swift static site generator with a Markdown-canonical source format and a typed
tile model. Authors write a constrained Markdown profile; the parser turns it into
a tree of typed tiles, which render to static HTML, CSS, and (for interactive
tiles) browser JavaScript. The engine library is `TileKit`, the CLI is `tiledown`.

> The repository is named `tile-down`; the product and CLI are `tiledown`.

## Status: early, not usable yet

Tiledown is at version `0.1.0` and is **not yet a usable static site generator.**
Do not adopt it for a real site.

What works today is a thin vertical slice: the engine builds, and the CLI can turn
a single Markdown file (or a folder of `index.md` files) into HTML through a
Mustache-style template. There is **no** project scaffolding, config loading, dev
server, watch mode, asset pipeline, JSON output, or canonical Markdown serializer
yet, and most tile types are not implemented. The internals for typed tiles and
service-backed forms exist and are tested, but they are not wired into a usable
authoring workflow.

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

Build a content directory (each `index.md` becomes a slugged `index.html`):

```sh
swift run tiledown build-site content/ template.html dist/
```

That is the whole user-facing surface right now. Markdown support is limited to
headings, paragraphs, and escaped text; templates are a Mustache-style subset.

## Build and test

```sh
cd Packages
swift build
swift test
```

The engine targets macOS and Linux. To build and test on Linux, see
[docs/linux-testing.md](docs/linux-testing.md). Every push runs build and test on
both platforms in CI.

## Project conventions

Swift only, except JavaScript emitted as browser runtime for client-side tiles.
Dependencies injected through initializers, types namespaced under `TileKit`, one
type per file. See [AGENTS.md](AGENTS.md) and [docs/rules/](docs/rules/) for the
full conventions, and [CONTRIBUTING.md](CONTRIBUTING.md) to contribute.

## License

[AGPL-3.0](LICENSE).
