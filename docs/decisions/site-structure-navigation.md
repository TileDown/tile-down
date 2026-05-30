# Decision: site structure, navigation, and layout

How Tiledown models a site's sections, builds navigation, and arranges page
layout. The counterpart to [theming.md](theming.md): that doc covers *look* (CSS
cascade layers and theme properties); this one covers *structure* (the tree, the
menu, and where regions sit).

**Status: architecture decided; the first slice (sections) is specified and
ready to build.** The layout and theme-bundle parts are mapped but deliberately
deferred (see Sequencing). Backed by [the layout research](../research/site-layout-navigation.md)
and a first-principles plus Gang-of-Four analysis (2026-05-30). Graduates into a
rule once the first built-in layout ships.

## Two orthogonal tracks

"Site theme" bundles two concerns that do not depend on each other, and conflating
them is how a slice becomes a swamp:

- **Structure track**: content hierarchy, **sections**, navigation, then
  **layouts** (top-nav, left-sidebar). This is page structure.
- **Presentation track**: the default theme content (base CSS plus `--td-*` theme
  properties), then light/dark switching. This is look, covered by
  [theming.md](theming.md).

The color theme works with any layout; a layout works with any colors. They land
independently.

## First principles

- **Navigation is a derived projection of the content tree, never primary data.**
  The menu, breadcrumbs, prev/next, and sitemap are all *views* of one hierarchy.
- **Single source of truth.** Sections are *derived* from the content structure,
  not declared in a separate config list (a second list drifts from the tree).
- **The hierarchy is already encoded in slugs.** `IndexContentDiscovery` flattens
  `content/blog/index.md` into a `Page` with slug `blog`, so the tree is recoverable
  by grouping pages on slug depth. There is no separate tree to build.
- **A section is represented by its landing page.** `content/blog/index.md` already
  carries the section's title and URL. A section without an `index.md` produces no
  page and is simply invisible today, so no synthetic section node is needed yet.
- **Mustache is logic-less.** A template cannot filter, sort, or group, so it
  cannot compute the menu itself. The engine is therefore *forced* to pre-compute
  and expose the navigation. This is why navigation is an engine concern, not a
  template trick.

## The sections slice (next)

Expose **`site.sections`**: the **depth-1 pages** (each section's landing page),
deterministically **ordered by a front-matter `weight`** (default alphabetical),
reusing the existing per-page context shape (title, url, slug). The root page
(slug `""`, "Home") is depth-0, not a section; the template decides whether to show
a Home link.

This needs **no new type, no new model, and no design pattern**: it is a sorted
filter over the existing `[Page]`, exposed because the template language cannot
derive it. A template can then build its own menu from `site.sections` before any
built-in layout exists. The only new authoring concept is the `weight` front-matter
field, a small content contract.

## Gang-of-Four map (all gated on a second consumer)

The patterns the full system wants are pre-mapped, but each is introduced only at
its second real consumer, the same rule that earned `TileKit.Output.Registry` when
JSON became output number two. Building any of them now would be machinery for
consumers that do not exist.

- **Strategy, as named template bundles** for **layouts** (top-nav vs left-sidebar
  are interchangeable arrangements of the same regions). An SSG's layout is
  templates, not Swift that emits HTML, so a layout is a *template* and the Strategy
  is *which one*, riding the existing `TileKit.Template.Rendering` seam. Realized at
  the second layout: with both `topNav` and `leftSidebar` shipped, the
  `TileKit.Site.Layout` enum is the selection. It is a **closed enum, not an open
  protocol**, because the engine deliberately ships a curated few layouts; a custom
  layout is a user-supplied template (a separate mechanism), not a new Strategy.
- **Composite** for the content tree (leaf = page, composite = section). Earned by
  the second hierarchy consumer: breadcrumbs or nested/dropdown menus.
- **Abstract Factory** for a **theme** as a bundle (template set plus stylesheet).
  Earned at the second theme (named themes), which also needs config-file loading.
- **Visitor** for the different nav projections (menu, breadcrumb, sitemap from one
  tree). Earned at the second projection.

## The one real pipeline change (done)

The user no longer has to supply a single template for a content build. The
content-build request carries a `TileKit.Site.TemplateSource`, either a custom file
(`.file(path:)`) or a built-in layout (`.layout(Layout)`). The CLI uses
`.layout(.topNav)` for `tiledown build-site <content-dir> <output-dir>`, while
the three-path form remains the custom-template override.

## Sequencing

1. **Sections** (this doc's slice): `site.sections` derived from pages. No pattern.
2. **Top-nav layout**: `Layout.topNav`, a built-in template consuming `site.sections`.
3. **Left-sidebar layout**: `Layout.leftSidebar`, the second layout, which realizes
   the selection as the closed `Layout` enum. (Done.)
4. **Presentation track** (default theme content, then switching): orthogonal, on
   its own `--td-*` contract. The standard theme is now the default.
5. Gated later: Composite (breadcrumbs, nesting), Abstract Factory (named themes),
   Visitor (sitemap).

## Open sub-decisions

- ~~The `weight` front-matter field name and its default ordering.~~ Settled with
  the sections slice: the field is `weight` (Hugo-style), pages without it sort last,
  and the tiebreak is alphabetical by title (falling back to slug).
- Whether `site.sections` marks the current section active (derivable from slug
  prefix; add when a layout needs it). Still open.
