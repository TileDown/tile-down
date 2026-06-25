# Changelog

All notable changes to Tiledown are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.6.1] - 2026-06-26

### Fixed

- Rendered Mermaid diagrams no longer keep a 12rem minimum height after they draw,
  so a short diagram (a single row of nodes) hugs its content instead of leaving a
  tall empty box. The minimum height now applies only to the pre-render placeholder.

## [0.6.0] - 2026-06-25

### Added

- The built-in site footer now shows the TileDown engine version beside the
  "Built with TileDown" credit.

### Fixed

- Line charts authored with a numeric `x:` axis now render on the web. Their
  points were collapsing to a single x because the renderer derived no labels
  for a numeric axis and then divided the plot width by zero. They now plot on a
  real numeric x-axis, positioned by x value with a connecting polyline, matching
  the PDF renderer. Category-based line and bar charts are unaffected.

## [0.5.0] - 2026-06-05

### Added

- Article PDFs now publish as root-level files named from each article slug, and
  the built-in article layout links them only after generation writes the file.
- Generated sites can configure a favicon through `favicon` or `faviconPath`.
- Built-in site chrome can show an optional brand subtitle or version label with
  `versionName` or `subtitle`.
- Site settings now support first-class `social.bluesky` and `social.mastodon`
  links. Mastodon profile links render with `rel="me"` for verification.
- The Everything example now covers article PDF generation, PDF image embedding,
  source disclosure, static source-code highlighting, configured Bluesky and
  Mastodon links, and the browser assertions for those surfaces.

### Changed

- Repository policy now documents that new features must not add external
  dependencies, build tools, package requirements, CDN assets, or hosted services.
- CI uses the current checkout action generation across macOS, Linux, and browser
  jobs.

### Fixed

- Article PDFs now embed local hero and body images by preparing local image URLs
  for MarkdownPDF, including root-relative and relative content assets.
- Article PDF generation no longer renders front matter as prose.
- Article permalink controls now copy the permalink instead of behaving only as a
  normal link.

## [0.4.1] - 2026-06-04

### Added

- The Everything example now includes a Source Code page with static highlighted
  fences for the supported language set, covered by the browser gate.

### Fixed

- Generated tag landing pages are hidden from normal site navigation while
  remaining available for tag Clear/chip links.

## [0.4.0] - 2026-06-04

### Added

- `tiledown doctor` checks a content directory without writing into it, reports
  config/content/build diagnostics, supports JSON output, and adds publish checks
  for production readiness.
- Static, build-time syntax highlighting now colors generated code fences and
  the Markdown source disclosure without requiring runtime JavaScript. It ships
  language profiles for Swift, JavaScript, TypeScript, Python, Ruby, Go, Rust,
  Kotlin, Java, C, C++, C#, HTML/XML, CSS, JSON, YAML, shell, and SQL. (#169)
- Article pages can publish a PDF generated from their Markdown source, reusing
  the MarkdownPDF pipeline. (#162)
- Sites can opt into a "View Markdown source" disclosure that renders each page's
  escaped, syntax-highlighted source. (#160)
- Built-in site navigation and tag bars gained configurable controls for blog
  and tag-filter workflows.

### Fixed

- `tiledown help`, `tiledown --help`, `tiledown -h`, and bare `tiledown` now
  print usage cleanly, and invalid CLI arguments no longer escape to Swift's
  top-level fatal error handler.
- `tiledown doctor --publish` now checks generated local URLs in links and asset
  references without failing on article prose that mentions localhost examples.
- Clearing a generated tag filter now lands on `/tags/` and shows all articles
  instead of an empty or missing page. (#168)
- Article PDFs now render `:::chart` directive tiles instead of dropping them.
  (#167)
- Chart labels, ticks, and axes render with cleaner spacing and normal-weight
  text. (#165, #166)
- Display math renders at a readable size and handles the current MathTypeset
  space-node output. (#156, #164)

## [0.3.0] - 2026-06-03

### Added

- Display math: a paragraph that is a single `$$...$$` block is recognized as
  display math and routed through a new `MathRendering` seam, instead of leaking
  its source as literal text. (#127)
- MathML rendering for display math, built on the shared `MathTypeset` engine: TeX
  is parsed and emitted as native MathML Core, which modern browsers render with
  no bundled font and no runtime script. Malformed input degrades to its escaped
  source. A pixel-consistent SVG renderer (using the engine's positioned layout,
  with this MathML kept as the accessible companion) and inline `$...$` follow. (#127)
- Foundation for the SVG math renderer: the Latin Modern Math font (OFL/GUST) is
  vendored and a pure-Swift OpenType reader parses its `cmap`/`hmtx`/`head` for
  glyph advances (the engine's `measureText` contract) and its `MATH` table for
  layout metrics. Verified against the font's own metrics. (#127)
- A pure-Swift CFF Type2 charstring interpreter that turns glyph ids into outline
  paths (cubic curves and lines, following local and global subroutines and the
  flex operators). This lets the SVG renderer draw self-contained glyph outlines
  with no shipped font or runtime. Verified against fontTools: exact outlines for
  reference glyphs and matching control bounds across letters, digits, delimiters,
  and large math symbols (sum, integral, radical, pi, partial). (#127)
- SVG rendering of display math, now the default: `$$...$$` is laid out by the
  shared `MathTypeset` engine and emitted as a self-contained `<svg>` of glyph
  outlines (`<path>`) and rules (`<rect>`) at the engine's exact coordinates, so it
  renders identically in every browser with no shipped font and no runtime script.
  Fill is `currentColor`, so the math follows the text color in light and dark
  themes, and dimensions are in `em`, so it scales with the surrounding font. A
  visually hidden MathML companion carries the accessible, copyable form. (#127)
- Full Unicode symbol coverage for math, via `MathTypeset` 0.3.0: operators,
  relations, set and logic symbols, arrows, and the full Greek alphabet now
  render as their glyphs (for example `\sum` as the summation sign and `\pm` as
  the plus-minus sign) in both the SVG and the MathML, instead of their command
  names. (#127)
- Radical signs scale to their radicand, via `MathTypeset` 0.4.0: `\sqrt` is drawn
  as scaling vector strokes (a new `line` layout element) so the radical sign
  grows to enclose tall content like `\sqrt{x^2 + y^2}` and meets the overbar,
  instead of a fixed small sign. The SVG renderer emits the strokes as themed
  `<line>` elements. (#127)

### Fixed

- Display math now reads its TeX from the raw Markdown source, so backslash
  sequences such as `\\` (matrix and cases row separators) and `\{` survive
  instead of being collapsed by CommonMark's escape processing. Matrices, cases,
  and similar constructs render correctly. Verified against MarkdownPDF's own
  `math-formulas.md` witness corpus, vendored as a parity fixture. (#127)

## [0.2.2] - 2026-06-03

### Fixed

- Chart axis, value, and legend labels were faux-bold (medium weight plus font
  synthesis), which read as fat and slightly distorted. Set them to normal
  weight with `font-synthesis: none`, keeping the 16px size from 0.2.1. (#141)

## [0.2.1] - 2026-06-03

### Fixed

- Chart labels no longer collide at the bottom of the plot: category labels, the
  x-axis caption, and the legend are stacked a full line apart and the SVG height
  grows to contain them (pie/doughnut legends grow when they wrap). (#137)
- Chart axis, value, and legend text is enlarged from 13px to 16px medium weight,
  which scaled down to ~10px and was hard to read in a content column. (#138)

### Changed

- The browser gate now measures chart text geometry: it flags text-on-text
  overlap and unreadable label sizes, not only text escaping the SVG bounds, so
  these regressions cannot return unseen. (#136)

## [0.2.0] - 2026-06-03

### Added

- Charts in Markdown: a `chart` fenced code block renders a static SVG chart
  from the same authoring DSL the sibling MarkdownPDF project uses (`type`,
  `title`, `categories`, numeric `x`, `x-label`/`y-label`, repeatable
  `series`/`points`, and pie `slice` entries), with the same portable-profile
  limits. Not a tile; it renders through the prose pipeline. (#125)
- Diagrams in Markdown: a `mermaid` fenced code block renders `graph`/`flowchart`
  diagrams through the client mermaid runtime, while a `pie`/`pie title` block
  renders as a static SVG chart, matching MarkdownPDF. (#126)
- Chart hovers, in two modes: the static chart fence gains native `<title>`
  tooltips and a CSS hover highlight with no script; the interactive `chart`
  tile adds a styled cursor-following tooltip with keyboard-focus support.
  (#133)

### Changed

- Chart legends measure label width and wrap to new rows, fixing the overlap
  that fixed-width columns caused for long series or slice names.
- Article share and action links render as buttons (rounded rectangles) instead
  of pills, and tag chips gain a leading accent `#`, so share links and tags are
  no longer visually identical.

### Added

- Service-form contract bindings in `tiledown.yml`: `service.<id>.contract`,
  `service.<id>.mode`, optional `service.<id>.proxyRoute`, and optional
  `service.<id>.availability` now populate the CLI's local contract resolver for
  `build-site`. Contract files under the content root are treated as private
  build inputs and are not copied into the generated output. (#120)
- Local preview server: `tiledown serve [--drafts] [--port N] [--output DIR]
  <content-dir>` builds a content directory and serves the generated static files
  from `127.0.0.1`, with directory `index.html` resolution, common content types,
  and 404 responses for misses. (#33)
- Redirect content items: a page with `type: redirect` and `to: <url>` now
  emits a static redirect page at its slug while staying out of navigation, post
  listings, tag pages, and feeds. (#45)
- 404 fallback redirects: `notFoundRedirect.exact.<path>` and
  `notFoundRedirect.prefix.<path>` in `tiledown.yml` inject safe static-host
  redirect rules into generated `404.html`, preserving query strings and
  fragments for migrated legacy routes. (#97)
- Generated 404 pages: content builds now emit root `404.html`, using a
  built-in default page or a site-specific `content/404/index.md` override
  rendered through the same layout and theme as the rest of the site. Local
  assets beside the override publish beside `404.html`, so relative images load
  without creating a browsable `/404/` page. (#47)
- Sitemap output: content builds now emit `sitemap.xml` with deterministic
  page URLs, baseURL-aware locations, and optional `lastmod` values from valid
  page dates. Draft and redirect content is excluded. (#46)
- Content-type page behavior: `type: blog-post` and `type: post` now select
  built-in post/article behavior, while `type: page` and unknown explicit values
  use the standard page path. (#49)
- Static passthrough configuration: `static.<public-path>: <source-path>` in
  `tiledown.yml` copies files or directories from the content tree to stable
  public output paths, preserving root deployment files, migrated asset URLs,
  and explicitly configured hidden deployment paths such as `.nojekyll` and
  `.well-known`. (#79)
- Built-in layouts now treat `hero` front matter as a migration-friendly fallback
  for the canonical `image` field when rendering page hero media, post-card
  thumbnails, and metadata images. `image` keeps precedence when both are present.
  (#103)
- Site theme property overrides in `tiledown.yml`: `theme.light.<name>` and
  `theme.dark.<name>` can tune the curated `--td-*` custom property surface for
  built-in themes without replacing a layout or template. Values are validated
  and emitted after the selected theme's defaults. (#20)
- Mustache inverted sections: `{{^key}}...{{/key}}` now render fallback blocks
  when a value is absent or falsey, including empty strings, `false`, `0`, `no`,
  and empty lists. (#114)
- Built-in layouts now emit SEO and social preview metadata from page front
  matter and site configuration: descriptions, canonical links when `baseURL` is
  set, Open Graph and Twitter card tags, absolute preview images, and
  article-published metadata for dated posts. (#100)
- Static SVG charts through the built-in `chart` tile, with exact `:::chart`
  shorthand parsing, typed inline data validation, themed bar/line/pie/doughnut
  and scatter SVG output, no browser JavaScript, docs, examples, and Playwright
  coverage. (#57)
- Mermaid diagrams through the built-in `mermaid` tile, with exact
  `:::mermaid` shorthand parsing, canonical `:::tile mermaid` serialization,
  escaped diagram source, a pinned client-side Mermaid runtime, and Playwright
  coverage for browser rendering. (#56)
- Safe responsive embeds through `:::tile embed`, with required `url`, optional
  `title`, optional `aspectRatio`, YouTube and Vimeo iframe normalization, direct
  HTTPS video-file output, and typed failures for unsafe schemes, unsupported
  providers, and malformed ratios. (#80)
- Default article pages for dated posts in the built-in layouts, with a
  newsroom-style header, dek, hero media, body, related posts, and optional
  static share links controlled by `shareLinks: true` in `tiledown.yml`. (#74)
- Multi-tag AND filtering: generated tag pages now include canonical static
  paths for one-tag and two-tag filters, plus larger filters when all selected
  tags co-occur on at least one post, capped at three selected tags to keep
  static generation bounded. Pages such as `/tags/ios/swift/` list only posts
  carrying all selected tags. The tag bar marks every selected tag, selected tags
  link to remove themselves, unselected tags link to available narrower AND
  selections, and empty two-tag combinations render an explicit empty state.
  Custom tag bars can use `isVisibleInTagBar` on each `site.tags` item to hide
  links to ungenerated higher-order filters. Existing single-tag URLs remain
  unchanged. (#62)
- Theme-aware page images: pages can pair `image` with `imageDark` in front
  matter. Built-in hero images and post-card thumbnails switch to the dark
  variant when the site is in dark mode, including system preference and the
  manual theme toggle. Pages with only `image` keep the current single-image
  markup. (#63)
- Opt-in analytics: `analytics.head` and `analytics.bodyEnd` in `tiledown.yml`
  inject a provider snippet verbatim into every page's `<head>` and end of
  `<body>` in the built-in layouts. Empty by default, so a build emits no
  analytics; works with any provider (Plausible, GoatCounter, Umami, ...) and is
  an allowed third-party-JS exception like client-side tile output.
- Content generators: declare `generate.<name>: <command>` in `tiledown.yml` and
  `build-site` runs each command (as a subprocess, in the content directory,
  ordered by name) before reading content, so a custom Swift package or any
  executable can write Tiledown Markdown into the content tree from structured
  data (e.g. a CV page from JSON). Generator commands support shell-style
  quoting and backslash escaping for arguments with spaces. A generator that
  exits non-zero fails the build. The generated page is ordinary content from
  then on. (#119)
- A sticky tag bar on the tags landing and every per-tag page: all tags as
  larger pills, the current tag marked, an accent `Clear` pill that returns to
  all articles, and tapping the current tag toggles it off. Hidden when the site
  has no tags. Exposed via `site.hasTags`, per-tag `isCurrent`, `site.tagsURL`,
  and a `page.tagBar` gate.
- A recent-posts placement marker: `:::recent:::` on its own line in a page that
  opts in with `latest: true` renders the recent block at that spot, so content
  after the marker (e.g. a "see also" line) lands below the cards. The split is
  exposed as `page.contents.htmlHead` / `htmlTail`; with no marker, behavior is
  unchanged.
- Markdown reference links that the engine resolves to the URLs it owns:
  `[text](page:slug)`, `[text](post:key)` (a key relative to the posts directory,
  so it survives renaming `postsDir`), `[text](tag:name)`, `[text](social:key)`
  (a configured social link, used verbatim), and `[text](link:key)`. Internal
  target URLs are computed at build time, an empty anchor (`[](page:slug)`) fills
  with the target's title, tag, or social label, and an unknown reference fails
  the build with one aggregated error naming every broken link and its file.
- Outbound link shims: `links.<key>: <url>` in `tiledown.yml` generates a stable
  `/out/<key>/` redirect page (a canonical link plus meta refresh) that forwards
  to the external URL, so `[text](link:key)` points at a location-independent
  local link you can repoint in one place.
- The recent-posts block is hidden entirely when `latestPosts` is `0` (or there
  are no posts), via a `site.hasLatestPosts` flag gating the built-in layouts.
- Site customization in `tiledown.yml`: `postsLabel` overrides the posts
  section's name in navigation and its heading (e.g. `Writings`), and `fontScale`
  multiplies the base font size site-wide (e.g. `1.1` for 10% larger, emitted as
  a root `font-size` so the whole rem-based type scale grows together; a positive
  number, validated at parse time).
- The navigation marks the current section with `aria-current="page"` (styled
  bold in both themes), including when viewing any page beneath that section.

### Fixed

- Root-relative Markdown `href` and `src` values rewritten with `baseURL` now
  escape the configured base URL before emitting HTML attributes, preserving
  already-escaped query strings while preventing a malformed base URL from
  breaking out of the attribute. (#118)
- Redirect pages now reject unsafe target URL schemes before emitting meta
  refresh or fallback links. (#45)
- Migrated posts with a custom `slug` outside `postsDir` now remain posts. Post
  listings, tag pages, RSS items, and `post:` references use the canonical custom
  URL while selection still follows the source folder. (#87)
- Slug overrides now reject `.`, `..`, interior empty path segments, URL
  delimiters, percent escapes, backslashes, and control characters before writing
  output, so a content file cannot publish outside the output root or generate a
  link that browsers resolve to a different path. (#87)
- Redirect content now ignores unused body tile syntax, so legacy redirect-only
  pages cannot fail a build because of stale body content. (#45)
- Outbound link shims now fail the build instead of overwriting an already
  generated page or redirect at the same output path. (#45)
- RSS `content:encoded` now rewrites generated post links and image sources to
  absolute public URLs when `baseURL` is configured. (#78)
- Generated root-relative `href` and `src` URLs now honor `baseURL`, so
  Markdown-authored images and asset links keep working when a site is deployed
  under a subpath. Built-in hero and post thumbnail image URLs use the same
  prefixing. (#37)
- Theme toggles now reapply the saved appearance on page restore and cross-page
  storage updates, so light/dark selections remain stable across navigation.
  (#77)
- Static passthrough output paths now reject URL syntax characters before
  writing public files. (#79)
- Mustache string sections now treat empty, whitespace-only, or
  (case-insensitively) `false`, `0`, or `no` values as falsey, so front-matter
  gates such as `postList: false` suppress built-in listing output. This applies
  to every string-valued section, not only `postList`. (#36)
- Missing Mustache section keys now fail the build the same way missing
  interpolation values do, so template typos surface instead of silently
  rendering nothing. Built-in site contexts declare their known optional
  sections as falsey values, so optional fields still render nothing rather
  than erroring. (#38)
- Built-in layouts now render the generated footer credit as `TileDown`.
- Built-in hero images now render as block media with room below them, so
  theme-aware image wrappers do not run directly into the page heading.
- Post-listing card titles no longer pick up the prose-heading top margin, so the
  title aligns with the top of its thumbnail.

### Changed

- HTML escaping now routes through one shared `TileKit.HTML` helper used by
  template, tile, Markdown, service-form, and site-output renderers. Attribute
  contexts now consistently escape `>` and `'` alongside `&`, `<`, and `"`, and
  the generated redirect page escapes its target separately for attribute and
  text contexts, closing a markup-injection gap where a redirect target
  containing `<` or `>` was previously emitted raw into the page. (#40)
- Demo tile renderers now use scoped `line_length` exceptions around embedded
  CSS payloads so CSS can stay authored as CSS. (#35)
- Site content builds now list the content tree once and reuse that path list for
  page discovery, image checks, and asset copying. (#41)
- Posts are modeled as `TileKit.Site.PostCollection`, a `RandomAccessCollection`
  that owns the newest-first, date-valid selection once. The listing, the RSS
  feed, per-tag filtering, and the latest-posts block derive from it via
  `prefix`, `filter`, and iteration instead of separate helpers; `PostSelection`
  keeps only `parsedDate`. `TileKit.Site.Page` now conforms to `Hashable` and
  `Comparable` (keyed on its unique slug), so pages sort, dedup, and key a set or
  dictionary directly. Behavior is unchanged (generated output is byte-identical).
  (#51)

- The post listing (`site.posts`) and the RSS feed now share one post-selection
  helper, so they never diverge on what counts as a post. A post must have a
  `date` that parses as `yyyy-MM-dd`; a page with a missing or malformed date is
  excluded from both (previously it could appear in the listing but not the
  feed). (#39)

### Added

- Tags: a post declares `tags: swift, ios` in its front matter and the generator
  synthesizes a listing page per tag at `/tags/<tag>/` showing only that tag's
  posts, newest first, reusing the post-listing card UI. Tags are exposed to
  templates as `site.tags` (name, url, count) and per-post `tags` (name, url). A
  post with no tags appears on no tag page; tag slugs are lowercased and
  hyphenated. (#50)

- Configurable posts directory: `postsDir` in `tiledown.yml` selects which
  content directory's dated pages count as posts for both the listing
  (`site.posts`) and the RSS feed. Defaults to `posts`; a site that keeps posts
  under `blog/` sets `postsDir: blog`. Surrounding slashes are trimmed. The feed
  and listing share the setting, so they always agree on what is a post. (#48)

- Browser tests: an end-to-end Playwright suite (`Packages/Tests/Browser/`)
  builds a fixture site and drives it in a real Chromium, asserting the rendered
  output that the Swift unit tests cannot reach: table alignment, image loading,
  the client-side counter tile, the dark/light toggle and its persistence, draft
  exclusion, slug overrides, the post listing, and the RSS feed. It is a
  documented exception to the Swift-only rule (Playwright has no Swift binding)
  and ships as test tooling, never in the product. (#23)

- Slug override: a non-empty `slug` value in a page's front matter overrides the
  folder-derived slug, deciding the output path the page publishes under.
  Surrounding slashes are trimmed, so `slug: /custom/` and `slug: custom` agree,
  and two pages that resolve to the same slug raise a typed build error rather
  than silently clobbering each other's output. (#44)

- GFM tables: pipe tables render to a real `<table>` with `<thead>`/`<tbody>`
  and per-column alignment from the `:--`/`--:`/`:-:` markers (emitted as inline
  `text-align`, so alignment works without theme CSS). Cells render inline
  markup; both built-in themes style tables. (#43)

- Drafts: a page with `draft: true` in its front matter is excluded from the
  whole build, no output file, and absent from navigation, the post listing, and
  the feed. Unset or any non-truthy value publishes as normal. The
  `build-site --drafts` flag includes drafts for local preview. (#42)

- `appearance` site setting: choose how the site offers dark and light. `toggle`
  (default) shows a control that follows the OS until the visitor picks, then
  remembers it; `auto` follows the OS with no control; `light` and `dark` pin one
  appearance and emit no toggle. Set it in `tiledown.yml` as `appearance: <mode>`.
  Forced modes set `data-theme` on the document; `toggle` emits the button and
  its no-flash script only when selected.

### Fixed

- Asset copying no longer clobbers generated output or publishes build inputs.
  A content file whose destination collides with a generated page, stylesheet,
  or feed is skipped, and `tiledown.yml`/`tiledown.yaml` and `.DS_Store` are
  never copied into the output.
- Identical tile JavaScript is now deduplicated per page (mirroring tile CSS), so
  a runtime that binds every instance by a shared selector is emitted once and
  does not double-bind when the same tile type repeats on a page.
- The RSS feed strips XML-1.0-illegal control characters from post content and
  metadata, so a stray control byte in a post no longer makes the whole feed
  not-well-formed.

### Added

- Two built-in demo tiles. `callout` is a static titled box (HTML plus themed
  CSS, no runtime) and `counter` is a `local`-mode button that counts clicks in
  the browser, demonstrating a tile that emits scoped JavaScript. Both are
  registered by the CLI. The built-in layouts now emit a page's collected tile
  JavaScript in a `<script>` before `</body>`, so a `local` tile actually runs.

- Post listing: a page with `postList: true` in its front matter renders a card
  list of the site's posts after its content, in both built-in layouts. Each card
  is a thumbnail (the post's `image`) on the left with the title, date, and
  description on the right. Templates get `site.posts`, every page under `posts/`
  with a `date`, newest first (the same selection the RSS feed uses). The hero on
  a post and the thumbnail in the listing are now capped in size by the theme so
  an image no longer renders full-bleed.

### Changed

- Mustache sections over a missing key now render nothing (falsey), per the
  Mustache spec, instead of throwing. This makes an optional field such as
  `page.image` safe in a shared layout. A missing plain interpolation
  (`{{ x }}`) still throws, since that is an authoring error.

### Added

- Post hero images: a page with an `image` front-matter value renders it as a
  hero at the top of the content in both built-in layouts (`<img class="td-hero">`).
  A page without `image` is unchanged.

- Full-text RSS: each feed item now carries the whole rendered post body in a
  `<content:encoded>` element (CDATA), not just the front-matter summary, so
  readers show the complete article. The feed declares the
  `content` namespace; `<description>` remains the summary.

- Asset copying: `tiledown build-site` now copies every non-Markdown file under
  the content root verbatim into the output, preserving its relative path. One
  rule serves both a site-level `assets/` tree and a page-local file beside its
  `index.md`, so a Markdown image such as `![logo](/assets/images/logo.png)`
  resolves once its file lands in the output. Markdown stays source: an
  `index.md` becomes a page and any other `.md` is ignored, neither is copied.
  `TileKit.Site.FileSystem` gains a binary-safe `copyFile(from:to:)`.

- Image-checking pass: the generator runs an injected
  `TileKit.Site.ImageChecking` over the content's image assets on every build.
  The default `TileKit.Site.PassthroughImageChecker` accepts everything, so the
  step is inert until a real checker (missing references, oversize files,
  missing alt text) replaces it. A checker can reject a build by throwing.

- Minimal demo site support: `tiledown build-site` now reads an optional
  `tiledown.yml` or `tiledown.yaml` file from the content root. The flat config
  format supports `title`, `baseURL`, `layout`, `theme`, `rss`, RSS metadata, and
  `social.*` footer links. Built-in layouts render footer social links, an RSS
  link, and a "Built with TileKit" footer credit. When RSS is enabled, content
  builds write `feed.xml` from dated pages under `posts/`. The new
  `TileKit.Site.Theme.system` theme provides a crisp platform-native light and
  dark design. A minimal example site lives in `Examples/minimal-site/`.

- CLI site builds now work without a hand-written template:
  `tiledown build-site <content-dir> <output-dir>` uses the built-in top-nav
  layout and the standard theme by default, producing a styled, navigable site
  from content alone. The explicit custom-template form remains available as
  `tiledown build-site <content-dir> <template.html> <output-dir>`.
  `TileKit.Site.TemplateSource` models this choice as `.layout(Layout)` or
  `.file(path:)`, replacing raw template paths on `ContentBuildRequest`.
  `Configuration.theme` now defaults to `.standard`; pass `theme: nil` for an
  unstyled build where tiles still carry their own CSS.

- Built-in theme: `TileKit.Site.Theme.standard` is the first built-in theme, a warm,
  readable design with a centered measure. It defines its semantic theme properties
  (`--td-*`) twice, a light set on `:root` and a dark set under `prefers-color-scheme:
  dark` and `[data-theme="dark"]`, so light and dark are a mode of the theme rather than
  separate themes, plus reset and base styles for the layout regions. A theme is
  orthogonal to a layout: any layout wears any theme. It is the default site
  theme; pass `Configuration.theme: nil` for an unstyled build. The generator
  composes the theme's properties, reset, and base into the shared stylesheet's
  cascade layers, so a themed site always emits a `styles.css`. See
  [docs/decisions/theming.md](docs/decisions/theming.md) and
  [docs/decisions/site-structure-navigation.md](docs/decisions/site-structure-navigation.md).

- Built-in layouts: `TileKit.Site.Layout` ships two page layouts, `topNav`
  (horizontal nav across the top) and `leftSidebar` (vertical nav in a left
  sidebar), the two primary placements the research supports. Each is a Mustache
  template that arranges header/sidebar, navigation (built from `site.sections`),
  main content, and a footer, and links the shared stylesheet. A layout is a
  template, not Swift that emits HTML; all layouts use the same data and differ only
  in how they arrange the regions. The closed enum of cases is the selection itself
  (the engine ships a curated few, not an open extension point), and
  `TemplateSource.layout(_:)` wires that selection into content builds. See
  [docs/decisions/site-structure-navigation.md](docs/decisions/site-structure-navigation.md).

- Site navigation: templates can build a menu from `site.sections`, the site's top-level
  sections (each section's `index.md` landing page, i.e. the depth-1 pages), ordered by a
  front-matter `weight` (pages without a weight sort last, then alphabetically by title,
  then by slug for a fully deterministic order).
  The root page is the home page, not a section. The engine derives sections (the content
  tree is encoded in slugs) because logic-less Mustache cannot filter or sort. See
  [docs/decisions/site-structure-navigation.md](docs/decisions/site-structure-navigation.md).

- Site-level shared stylesheet: a multi-page build now collects every tile's CSS into one
  `styles.css` at the output root, deduplicated across the whole site, so a tile type used
  on many pages emits its CSS once (not per page). `TileKit.Output.Stylesheet` carries the
  per-layer CSS fragments and merges across pages; `TileKit.Output.Assets` exposes it (with a
  computed `css` for the inline form). The stylesheet path is exposed to templates as
  `site.stylesheetPath` (baseURL-joined) for a `<link>`. Single-page `build` still inlines.
  Part of #17.

- Site-wide configuration: `TileKit.Site.Configuration` (`title`, `baseURL`) is carried
  on the build requests and exposed to templates under `site` (`site.title`,
  `site.baseURL`). The first-class site-scoped counterpart to per-page front matter, the
  foundation for site-level assets and theming (#17). Carried as direct values; loading
  it from a config file is a later concern.

- Tiles can now reject the site theme. `TileKit.Tile.Rendered` carries a
  `TileKit.Tile.StylePosture` (`themed` by default, or `overriding`), and
  `TileKit.Output.HTMLRenderer` places `themed` CSS in the `theme` layer and
  `overriding` CSS in the later `tile-override` layer, which wins over the theme
  regardless of specificity. Existing tiles are unaffected (posture defaults to
  `themed`). See [docs/decisions/theming.md](docs/decisions/theming.md).

- Tile CSS is now wrapped in CSS cascade layers and deduplicated. `TileKit.Output.HTMLRenderer`
  emits the canonical layer order `@layer reset, theme, tile-override;` and places tile
  component CSS inside the `theme` layer, so no tile rule can sit unlayered and silently
  outrank the theme. Identical CSS fragments are emitted once per page (a tile type repeated
  on a page no longer duplicates its CSS). See
  [docs/decisions/theming.md](docs/decisions/theming.md) and
  [docs/research/theming-styling-api.md](docs/research/theming-styling-api.md).

- HTML rendering now flows through the output renderer seam: `TileKit.Output.HTMLRenderer`
  is the first output renderer (beside `TileKit.Output.JSONRenderer`), projecting a
  parsed document's block tree to body HTML and collecting page-local CSS and
  JavaScript into the new `TileKit.Output.Artifact.assets` (`TileKit.Output.Assets`).
  `TileKit.Site.Generator` no longer renders HTML inline; it parses the document,
  delegates body rendering to an injected `TileKit.Output.Rendering`, and composes the
  page template as before. HTML output is byte-identical to the previous inline path.

- `tiledown fmt` command: rewrites a Tiledown Markdown document to its canonical
  form, the CLI consumer of the serializer's fixed-point law. `TileKit.Site.DocumentFormatter`
  splits the raw front matter off (preserved verbatim, since front matter has no
  canonical serializer yet), canonicalizes the body through
  `TileKit.Site.DocumentSerializer`, and recomposes; `isCanonical(_:)` is exactly
  `format(x) == x`. A new `TileKit.Source.FrontMatterSplitting` seam returns the raw
  split (`TileKit.Source.Split`), and `FrontMatterParser.parse` now decodes that same
  split, so there is one definition of where front matter ends. The command prints the
  canonical form to stdout by default, `--write` rewrites in place, and `--check` exits
  non-zero (cleanly) when a file is not already canonical, for use as a CI gate.

- Derived JSON output: a new `TileOutput` target carrying the output renderer seam
  (DESIGN G7, § 8.3). `TileKit.Output.Rendering` is the renderer Strategy (a
  `formatID` plus `render(_:) -> Artifact`), `TileKit.Output.Registry` is the
  injected registry that dispatches a `TileKit.Output.Document` by format id (the
  structural twin of `TileKit.Tile.Registry`; an unregistered format throws
  `TileKit.Output.RenderingError.unknownFormat` rather than guessing).
  `TileKit.Output.JSONRenderer` is the second output renderer (HTML is the first),
  projecting the parsed tile tree into deterministic JSON: tile type ids, source
  property order (properties are an ordered array, not an object), both value kinds
  (tagged `string`/`list`), and unknown tile data all survive. JSON is a derived
  view, never canonical. A `tiledown json <source.md> <output.json>` command writes
  it. See [docs/DESIGN.md](docs/DESIGN.md) § 7.2 and § 8.3.

- Canonical serialization for the whole document: `TileKit.Markdown.CommonMarkFormatter`
  normalizes prose via swift-markdown's `MarkupFormatter` (ATX headings, `-` markers,
  fenced code, `*` emphasis), behind a `TileKit.Markdown.Formatting` seam, and
  `TileKit.Site.DocumentSerializer` composes prose and tile canonicalization into a
  fixed-point Tiledown Markdown document. Custom ordered-list start is normalized to
  1 (a documented profile property; swift-markdown #76). See
  [docs/markdown-profile.md](docs/markdown-profile.md).

- Real CommonMark rendering via [swift-markdown](https://github.com/apple/swift-markdown):
  `TileKit.Markdown.CommonMarkRenderer` parses prose into swift-markdown's typed
  tree and emits HTML for headings, paragraphs, emphasis, strong, inline and
  fenced code, links, images, lists, block quotes, and breaks. Raw HTML is escaped,
  not passed through. The first external dependency. See
  [docs/markdown-profile.md](docs/markdown-profile.md).
- `TileKit.Tile.DirectiveSerializer`: serializes the parsed tile block tree back
  to Tiledown Markdown (tile blocks in one canonical form, preserving unknown tile
  types and properties; Markdown blocks verbatim), the `put` inverse of the
  directive parser. Round-trip law tests assert the research's semantic invariant:
  PutGet (`parse(serialize(parse(x))) == parse(x)`) and PutPut (canonical output is
  a fixed point). Byte identity is not a goal.

### Changed

- `TileKit.Markdown.Rendering` now refines `Sendable`, matching the other render and
  parse seams, so output renderers that hold one can be `Sendable`.

### Fixed

- `TileKit.Tile.DirectiveParser` now tracks fenced code blocks, so a `:::tile`
  line inside a ``` or `~~~` code fence is treated as Markdown content instead of
  being mis-parsed as a tile directive (which previously threw
  `missingClosingFence`). This lets documents show tile examples in code blocks.
  Fence detection follows CommonMark's rule that a backtick fence's info string
  may not contain a backtick, so an inline code span like ```` ```inline``` ````
  is not treated as a fence opener.

### Removed

- `TileKit.Markdown.BasicHTMLRenderer`, the placeholder heading/paragraph renderer,
  replaced by `CommonMarkRenderer`.

## [0.1.0] - 2026-05-29

### Added

- First site-generation slice: `tiledown build <source.md> <template.html>
  <output.html>` loads one Markdown file with simple front matter, renders
  heading/paragraph HTML through a Mustache-style template, and writes an HTML
  output file.
- Content-directory generation with `tiledown build-site <content-dir>
  <template.html> <output-dir>`, discovering `index.md` and `index.markdown`
  files and writing slugged `index.html` outputs.
- Mustache-style list sections and nested object lookups, including a `pages`
  collection in content-directory builds.
- A typed content query core with filters, ordering, offset, and limit support
  for future site collections and tile function manifests.
- A `TileTile` domain target with typed tile blocks, source-ordered properties,
  directive parsing, injected tile renderer registry, unknown-tile diagnostics,
  typed `service-form` requests, and tests for structured Tiledown Markdown tile
  blocks.
- A `TileService` domain target with manifest models, capability inventory, and
  validation for manifest-driven provider integrations.
- Service operation contracts for service-backed tiles, including health,
  transport, input/output schema, UI hints, auth references, errors, cache, and
  validation.
- A `TileServiceForm` composition target that binds typed `service-form` tile
  requests to service contract operations and rejects unsafe remote credentials.
- A `TileKit.ServiceForm.Renderer` that emits deterministic generated form HTML,
  scoped CSS, and browser JavaScript for remote and proxy service forms without
  emitting credential ids or secrets.
- A `TileKit.ServiceForm.TileRenderer` adapter that registers `service-form`
  through the tile registry, resolving the referenced contract via an injected
  `TileKit.Service.ContractResolving` seam, with an in-memory resolver first.
- `TileKit.Service.Binding` site bindings (contract source, mode, proxy route,
  availability policy, declarative auth binding), kept separate from contracts,
  plus a `TileServiceImpl` target with `TileKit.Service.LocalFileContractResolver`
  for file-backed contract loading.
- `tiledown version` (and `--version`) reports the product version.
- `docs/linux-testing.md`: how to build and test on Linux through Docker/Colima,
  Podman, a Lima VM, a native toolchain, or cross-compilation.
- `Packages/`: initial Swift package scaffold with `TileKit`, `TiledownCLI`, and
  Swift Testing coverage.
- `docs/research/`: research notes for Markdown-canonical tiles, tile functions,
  service-backed tiles, and Toucan parity.
- Community and governance docs: contributing guide, code of conduct, security
  policy, support guide, issue forms, pull request template, and git style hooks.
- `docs/CONVENTIONS.md`: the project's Swift coding conventions.
- `docs/DESIGN.md`: the Tiledown architecture design doc (draft).
- `docs/rules/`: the full per-area coding rules (engineering, code style,
  namespacing, dependency injection, concurrency, cross-platform, testing,
  verification, and more), with an index.
- `AGENTS.md` and `CLAUDE.md`: agent guides pointing to the rules and workflow.
- Mechanical enforcement, local and CI: `scripts/check-style.sh` and
  `scripts/check-namespacing.sh`, a `pre-push` hook running the format, lint,
  namespacing, build, and test gates, and `.github/workflows/ci.yml` mirroring all
  gates on macOS and Linux.

### Changed

- Split the Swift package into focused domain targets for content, source,
  Markdown, templates, and site generation, with `TileCore` limited to the root
  namespace and product metadata, `TileSiteImpl` holding concrete filesystem I/O,
  and `TileKit` acting as a facade target.
- Changed site generation to receive content discovery through the injected
  `TileKit.Source.ContentDiscovering` protocol.
- Changed site generation to render Markdown and tile directive blocks in source
  order through injected `TileKit.Tile.Parsing` and `TileKit.Tile.Registry`
  values, exposing collected tile CSS and JavaScript as `page.assets`.
- Updated the architecture and agent guidance for Tiledown Markdown as the
  canonical source format, the `tiledown` CLI name, Toucan-parity SSG goals, and
  dependency-injected registries.
- Updated SwiftLint settings to ignore SwiftPM build artifacts and align trailing
  comma handling with SwiftFormat.
- Restructured the coding rules: `engineering.md` now holds only judgment
  principles; agent-interaction rules moved to `AGENTS.md`; the no-force-unwrap
  rule is enforced by `.swiftlint.yml`; formatting by `.swiftformat`.
