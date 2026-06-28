# tiledown.yml configuration reference

`tiledown.yml` (or `tiledown.yaml`) lives at the root of your content directory.
It is read once at the start of every `build-site` and `serve`. The file is a flat
list of `key: value` lines. Keys use dots to group related settings (for example
`social.github` or `theme.dark.accent`); there is no nested indentation.

An unknown key is a build error, not a silent no-op. A typo fails fast rather than
publishing a site that quietly ignores a setting.

A minimal file:

```yaml
title: My Site
baseURL: https://example.com
postsDir: blog
```

Everything else has a default and can be omitted.

## Site basics

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `title` | string | `""` | Site title, used in the header and in page titles. |
| `baseURL` | string | `""` (empty) | Absolute base for every generated link, canonical tag, RSS item, and sitemap entry. See [Base URL and local preview](#base-url-and-local-preview). |
| `layout` | enum | `top-nav` | Page chrome. `top-nav` (alias `topNav`) or `left-sidebar` (alias `leftSidebar`). |
| `fontScale` | number | `1` | Multiplier on the base font size. `1.1` makes everything 10% larger. |

## Posts

A "post" is any page inside the posts directory. Posts get date ordering, the post
listing, and the RSS feed. Everything outside that directory is a standalone page.

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `postsDir` | string | `posts` | Directory under `content/` that holds posts. Leading and trailing slashes are trimmed, so `blog`, `/blog`, and `blog/` are equivalent. |
| `postsLabel` | string | `""` | Label for the posts section in the navigation (for example `Blog`). |
| `latestPosts` | integer | `3` | How many posts the latest/recent listing shows. Must be a non-negative integer. |

## Theme and appearance

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `theme` | enum | `standard` | `standard` (the built-in stylesheet), `system`, or `none`/`unstyled` to emit no stylesheet at all. |
| `appearance` | enum | `toggle` | `toggle` shows a light/dark control that follows the OS until the visitor chooses. `auto` follows the OS with no control. `light` and `dark` force one mode. |

### Theme property overrides

Override individual design tokens per mode with `theme.light.<property>` and
`theme.dark.<property>`. Only the curated token surface is accepted; an unknown
property name is a build error.

Accepted properties: `accent`, `bg`, `border`, `elevated`, `font`, `ink`,
`measure`, `mono`, `muted`, `radius`, `shadow`, `space`, `surface`.

```yaml
theme.light.accent: #2b6cb0
theme.dark.accent: #63b3ed
theme.dark.bg: #0b0f14
```

## Feed (RSS)

The feed is off until you turn it on with `rss: true` or set any `rss*` value.

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `rss` | boolean | `false` | Enable or disable the feed. |
| `rssPath` | string | `rss.xml` | Output path for the feed file. |
| `rssTitle` | string | site title | Feed title. |
| `rssDescription` | string | `""` | Feed description. |

```yaml
rss: true
rssPath: rss.xml
rssTitle: My Site
rssDescription: Notes on whatever I am building.
```

## Social and outbound links

`social.<network>: <url>` adds a labeled social link to the chrome. `github`,
`linkedin`, `bluesky`, and `mastodon` get the labels "GitHub", "LinkedIn",
"Bluesky", and "Mastodon"; any other network uses the key as its label.
Mastodon links render with `rel="me"` for profile verification.

```yaml
social.github: https://github.com/you
social.linkedin: https://www.linkedin.com/in/you
social.bluesky: https://bsky.app/profile/you.example.com
social.mastodon: https://mastodon.social/@you
```

`links.<name>: <url>` defines a named outbound link you can reference from content
as `link:<name>`, so a URL that appears in many pages lives in one place.

```yaml
links.docs: https://example.com/docs
```

## Analytics

Inject a raw HTML snippet into the page. `analytics.head` goes in `<head>`,
`analytics.bodyEnd` goes just before `</body>`. The value is emitted verbatim, so
it is your responsibility to keep it valid and trusted.

```yaml
analytics.head: <script defer src="https://cloud.umami.is/script.js" data-website-id="..."></script>
```

## Page features

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `shareLinks` | boolean | `false` | Show share links on posts. |
| `showSource` | boolean | `false` | Expose the Markdown source of a page. |
| `articlePDF` | boolean | `false` | Generate a per-article PDF and link to it. |

## Newsletter

A site-wide signup form, rendered into the layout at the end of every article and
in the footer of every page, backed by [Buttondown](https://buttondown.com)'s
embedded subscribe endpoint. It uses the same renderer as the inline `buttondown`
tile, so the markup and styling match. Set `newsletter.username` to turn it on; a
site with no `newsletter.*` keys emits no form.

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `newsletter.username` | string | required | Buttondown username whose list the form subscribes to. |
| `newsletter.title` | string | `Subscribe` | Heading above the form. |
| `newsletter.body` | string | `""` | A sentence above the form. |
| `newsletter.buttonLabel` | string | `Subscribe` | Submit button label. |
| `newsletter.placeholder` | string | `you@example.com` | Email field placeholder. |
| `newsletter.note` | string | `""` | A reassurance line below the form. |
| `newsletter.endOfPost` | boolean | `true` | Render the form at the end of every article. |
| `newsletter.footer` | boolean | `true` | Render the form in the footer of every page. |

```yaml
newsletter.username: tiledown
newsletter.title: TileDown Updates
newsletter.body: Stay updated with every new feature we bring to TileDown.
```

## Static passthrough

`static.<outputPath>: <sourcePath>` copies a file or directory from inside the
content tree to a fixed public path. Use it for files that must land at a specific
URL regardless of where you keep them, such as `CNAME`, `robots.txt`, `.nojekyll`,
or an image tree you want served from `/images/`.

```yaml
static.CNAME: assets/CNAME
static.robots.txt: assets/robots.txt
static..nojekyll: deployment/.nojekyll
static.images: public/images/
```

The source path is relative to the content root; the output path is relative to the
site root. Both reject `..` and unsafe characters.

Note: any non-Markdown file already inside `content/` is copied to the matching
output path automatically, preserving its relative location. You only need
`static.*` when the public path must differ from the source path, or for root files
like `CNAME` that you would rather keep in a subfolder.

## Content generators

`generate.<name>: <command>` runs a command as a subprocess in the content
directory before the build, so the command can write Markdown into the content tree
first. Generators run in name order. A generator that exits non-zero fails the
build.

```yaml
generate.cv: swift run --package-path ../cv-generator GenerateCV --output cv/index.md
```

## Redirects

Define redirects handled by the generated 404 page. Use these when a URL changed
and you want the old one to forward.

| Key | Maps to |
| --- | --- |
| `notFoundRedirect.exact.<oldPath>: <target>` | Redirect one exact path. |
| `notFoundRedirect.prefix.<oldPrefix>: <targetPrefix>` | Redirect every path under a prefix. |

```yaml
notFoundRedirect.exact./cvbuilder: /blog/c-v-builder/
notFoundRedirect.prefix./posts/: /blog/
```

If you are keeping a URL the same, you do not need a redirect. Redirects are only
for URLs you are changing.

## Base URL and local preview

`baseURL` is prepended to every generated link. This matters for local preview:

- With `baseURL: https://example.com`, the stylesheet is linked as
  `https://example.com/styles.css`, so opening the built site on `localhost` fetches
  CSS and images from the production domain. If production is not serving them, the
  page looks unstyled and images render at full size.
- With `baseURL` empty or omitted, links are root-relative (`/styles.css`,
  `/blog/post/`), which resolve correctly on any host, including `localhost`. The
  cost is that canonical tags, RSS items, and the sitemap have no absolute URL,
  which production SEO wants.

So: leave `baseURL` empty while developing, or point it at your local URL for a
preview build, and set the real production `baseURL` for the deploy build. See
[getting-started.md](getting-started.md) for the preview workflow.

## See also

- [getting-started.md](getting-started.md) - build your first site.
- [authoring.md](authoring.md) - front matter and content directives.
- [markdown-profile.md](markdown-profile.md) - the full Markdown and tile syntax.
