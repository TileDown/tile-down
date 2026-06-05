# Getting started

This walks through building, previewing, and deploying a Tiledown site from
nothing. It assumes you can run the `tiledown` CLI. From a checkout of this
repository that means `swift run tiledown` from the `Packages/` directory; an
installed binary is just `tiledown`. The examples below use `swift run tiledown`.

Check it runs:

```sh
swift run tiledown version
```

## 1. Make a content directory

A site is a folder of Markdown. Create one with a config file and a home page:

```
mysite/
  tiledown.yml
  index.md
```

`tiledown.yml`:

```yaml
title: My Site
baseURL: https://example.com
postsDir: blog
postsLabel: Blog
```

`index.md`:

```markdown
---
title: My Site
---

# Hello

Welcome. This is the home page.
```

Every page is a folder with an `index.md`, except the root `index.md` which is the
home page. See [authoring.md](authoring.md) for the page model and front matter.

## 2. Add a post

Posts live under the directory named by `postsDir` (here, `blog`). Give the section
a listing page and add one post:

```
mysite/
  blog/
    index.md            (the listing)
    hello-world/
      index.md          (a post)
```

`blog/index.md`:

```markdown
---
title: Blog
postList: true
---
# Blog
```

`blog/hello-world/index.md`:

```markdown
---
slug: blog/hello-world
title: Hello, world
date: 2026-06-03
---

# Hello, world

My first post.
```

The `slug` is the published URL path, taken verbatim. See
[Slugs](authoring.md#slugs) for why that matters.

## 3. Build

```sh
swift run tiledown build-site mysite dist
```

This reads `mysite/tiledown.yml`, renders every page, generates the post listing,
the RSS feed (if enabled), the sitemap, and a single `styles.css`, and writes it all
into `dist/`. Add `--drafts` to include pages marked `draft: true`.

## 4. Preview locally

The built-in server builds and serves in one step:

```sh
swift run tiledown serve mysite --port 8000
```

Then open `http://localhost:8000/`.

### The base URL gotcha

`serve` builds with whatever `baseURL` your config has. If `baseURL` is a production
domain like `https://example.com`, every link, including the stylesheet, points at
that domain, so on `localhost` the browser tries to load CSS and images from
production. If production is not live yet, the page looks unstyled and images render
at full size.

Two ways to get a correct local preview:

- Leave `baseURL` empty while developing. Links become root-relative (`/styles.css`,
  `/blog/hello-world/`) and resolve on any host.
- Or set `baseURL` to your local URL for the preview build, and switch it back to
  the production domain for the deploy build.

Set the real production `baseURL` before you deploy, because canonical tags, RSS
items, and the sitemap need absolute URLs. See
[Base URL and local preview](config-reference.md#base-url-and-local-preview).

## 5. Add images and static files

Put images anywhere inside the content tree and reference them by their path:

```
mysite/
  images/blog/hello-world/hero.jpg
```

```markdown
image: /images/blog/hello-world/hero.jpg
```

Any non-Markdown file under `content/` is copied to the matching output path
automatically. For files that must land at a specific URL regardless of where you
keep them (a `CNAME`, `robots.txt`, `.nojekyll`), use `static.*` in the config:

```yaml
static.CNAME: assets/CNAME
static..nojekyll: assets/.nojekyll
```

See [Static passthrough](config-reference.md#static-passthrough).

## 6. Deploy

`dist/` is a plain static site. Host it anywhere that serves static files.

For GitHub Pages: build with the production `baseURL`, then publish `dist/`. Include
a `.nojekyll` file so Pages serves the output as-is, and a `CNAME` if you use a
custom domain. Both are easy to keep in your content and route to the site root with
`static.*` (above).

```sh
swift run tiledown build-site mysite dist
# then commit and push dist/ to your Pages branch, or point Pages at it
```

## Other commands

| Command | What it does |
| --- | --- |
| `tiledown build-site <content> [<template>] <output> [--drafts]` | Build a whole site. |
| `tiledown serve <content> [--output <dir>] [--port <n>] [--drafts]` | Build and serve on `127.0.0.1` (default port 8000). |
| `tiledown build <source.md> <template.html> <output>` | Render one Markdown file with an explicit template. |
| `tiledown json <source.md> <output.json>` | Emit the parsed tile model as JSON. |
| `tiledown fmt <file> [--write\|--check]` | Format a Tiledown Markdown file to canonical form. |
| `tiledown version` | Print the version. |

## See also

- [authoring.md](authoring.md) - front matter and content directives.
- [config-reference.md](config-reference.md) - every `tiledown.yml` key.
- [markdown-profile.md](markdown-profile.md) - full Markdown and tile syntax.
