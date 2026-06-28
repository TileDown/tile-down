// swiftlint:disable line_length
// The built-in template lines cannot wrap without inserting whitespace into the
// generated HTML, so line length is disabled for this template-only file.
import TileCore

public extension TileKit.Site {
    /// A built-in page layout: the template bundle that arranges a page's regions
    /// (header, navigation, content, footer).
    ///
    /// The built-in layouts are top navigation and a left sidebar, the two primary
    /// placements the research supports (`docs/research/site-layout-navigation.md`).
    /// A layout is a template, not Swift that emits HTML, so each case exposes a
    /// Mustache `template`. The closed set of cases is the selection itself: the
    /// engine ships a curated few rather than an open extension point. A custom
    /// layout is a user-supplied template, a separate mechanism.
    ///
    /// Every layout uses the same data (`site.title`, `site.sections`,
    /// `page.contents.html`) and differs only in how it arranges the regions. Each
    /// builds its menu from `site.sections` and links the shared stylesheet from
    /// `site.stylesheetPath`, and expects each page to have a `title`. The `td-`
    /// classes are styling hooks for a theme; without one the page renders
    /// structurally correct but unstyled.
    enum Layout: Equatable, Sendable {
        /// Horizontal navigation across the top, with a footer repeating the
        /// sections.
        case topNav
        /// Vertical navigation in a left sidebar, with the content and footer in a
        /// column beside it. Scales better for many sections.
        case leftSidebar

        public var template: String {
            switch self {
            case .topNav:
                Self.topNavTemplate
            case .leftSidebar:
                Self.leftSidebarTemplate
            }
        }

        private static let topNavTemplate = """
        <!doctype html>
        <html lang="en"{{#site.appearanceForced}} data-theme="{{ site.appearanceForced }}"{{/site.appearanceForced}}>
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        {{#site.appearanceToggle}}<script>
        (function () {
          var root = document.documentElement;
          function storedTheme() {
            try {
              var saved = localStorage.getItem('td-theme');
              return saved === 'dark' || saved === 'light' ? saved : '';
            } catch (e) {
              return '';
            }
          }
          function applyStoredTheme() {
            var saved = storedTheme();
            if (saved) root.setAttribute('data-theme', saved);
            else root.removeAttribute('data-theme');
          }
          // Apply a saved choice before paint so there is no flash. With no saved
          // choice the CSS follows the OS via prefers-color-scheme.
          applyStoredTheme();
          window.addEventListener('pageshow', applyStoredTheme);
          window.addEventListener('storage', function (event) {
            if (event.key === 'td-theme') applyStoredTheme();
          });
          document.addEventListener('DOMContentLoaded', function () {
            var button = document.querySelector('[data-td-theme-toggle]');
            if (!button) return;
            button.addEventListener('click', function () {
              var current = root.getAttribute('data-theme');
              var prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
              var next = current === 'dark' ? 'light' : current === 'light' ? 'dark' : (prefersDark ? 'light' : 'dark');
              root.setAttribute('data-theme', next);
              try { localStorage.setItem('td-theme', next); } catch (e) {}
            });
          });
        })();
        </script>{{/site.appearanceToggle}}
        \(metadataHead)
        {{#site.faviconPath}}<link rel="icon" href="{{ site.faviconPath }}">{{/site.faviconPath}}
        {{#site.stylesheetPath}}<link rel="stylesheet" href="{{ site.stylesheetPath }}">{{/site.stylesheetPath}}
        {{#site.feedPath}}<link rel="alternate" type="application/rss+xml" href="{{ site.feedPath }}">{{/site.feedPath}}
        {{#site.analyticsHead}}{{{ site.analyticsHead }}}{{/site.analyticsHead}}
        </head>
        <body>
        <header class="td-header">
        {{#site.subtitle}}<a class="td-brand td-brand-stacked" href="{{ site.homeURL }}"><span class="td-brand-title">{{ site.title }}</span><span class="td-brand-subtitle">{{ site.subtitle }}</span></a>{{/site.subtitle}}{{^site.subtitle}}<a class="td-brand" href="{{ site.homeURL }}">{{ site.title }}</a>{{/site.subtitle}}
        <nav class="td-nav">{{#site.sections}}<a class="td-nav-link" href="{{ url }}"{{#isCurrent}} aria-current="page"{{/isCurrent}}>{{ title }}</a>{{/site.sections}}</nav>
        {{#site.appearanceToggle}}<button class="td-theme-toggle" type="button" data-td-theme-toggle aria-label="Toggle dark mode" title="Toggle dark mode">&#9728;</button>{{/site.appearanceToggle}}
        </header>
        <main class="td-main">{{#page.standardPage}}{{#page.tagBar}}<h1 class="td-tagbar-title">{{ page.title }}</h1>{{#site.hasTags}}<nav class="td-tagbar" aria-label="All tags"><a class="td-tag td-tag-lg td-tag-clear" href="{{ site.tagsURL }}" aria-label="Show all articles">&#215; Clear</a>{{#site.tags}}{{#isVisibleInTagBar}}<a class="td-tag td-tag-lg{{#isCurrent}} td-tag-current{{/isCurrent}}" href="{{ url }}">{{ name }}</a>{{/isVisibleInTagBar}}{{/site.tags}}</nav>{{/site.hasTags}}{{/page.tagBar}}{{#page.heroImage}}{{{ heroHTML }}}{{/page.heroImage}}{{{ page.contents.htmlHead }}}{{#page.hasTags}}<nav class="td-tags" aria-label="Tags">{{#page.tags}}<a class="td-tag" href="{{ url }}">{{ name }}</a>{{/page.tags}}</nav>{{/page.hasTags}}{{#page.latest}}{{#site.hasLatestPosts}}<ul class="td-posts">{{#site.latestPosts}}<li class="td-post-card"><a class="td-post-thumb" href="{{ url }}">{{#heroImage}}{{{ thumbnailHTML }}}{{/heroImage}}</a><div class="td-post-body"><h3 class="td-post-title"><a href="{{ url }}">{{ title }}</a></h3>{{#date}}<time class="td-post-date">{{ date }}</time>{{/date}}{{#description}}<p class="td-post-desc">{{ description }}</p>{{/description}}{{#hasTags}}<nav class="td-tags td-tags-card" aria-label="Tags">{{#tags}}<a class="td-tag" href="{{ url }}">{{ name }}</a>{{/tags}}</nav>{{/hasTags}}</div></li>{{/site.latestPosts}}</ul>{{/site.hasLatestPosts}}{{/page.latest}}{{{ page.contents.htmlTail }}}{{#page.postList}}{{#page.hasPosts}}<ul class="td-posts">{{#page.posts}}<li class="td-post-card"><a class="td-post-thumb" href="{{ url }}">{{#heroImage}}{{{ thumbnailHTML }}}{{/heroImage}}</a><div class="td-post-body"><h3 class="td-post-title"><a href="{{ url }}">{{ title }}</a></h3>{{#date}}<time class="td-post-date">{{ date }}</time>{{/date}}{{#description}}<p class="td-post-desc">{{ description }}</p>{{/description}}{{#hasTags}}<nav class="td-tags td-tags-card" aria-label="Tags">{{#tags}}<a class="td-tag" href="{{ url }}">{{ name }}</a>{{/tags}}</nav>{{/hasTags}}</div></li>{{/page.posts}}</ul>{{/page.hasPosts}}{{#page.emptyPosts}}<p class="td-empty">No posts match this tag selection.</p>{{/page.emptyPosts}}{{/page.postList}}{{/page.standardPage}}{{#page.article}}<article class="td-article"><header class="td-article-header"><div class="td-article-meta"><span class="td-article-kicker">{{ kicker }}</span>{{#date}}<time class="td-article-date">{{ date }}</time>{{/date}}</div><h1 class="td-article-title">{{ title }}</h1>{{#description}}<p class="td-article-dek">{{ description }}</p>{{/description}}<nav class="td-article-actions" aria-label="Article actions"><a href="{{ url }}" data-td-copy-permalink title="Copy permalink">Permalink</a>{{#site.feedPath}}<a href="{{ site.feedPath }}">RSS</a>{{/site.feedPath}}{{#hasPDF}}<a href="{{ pdfURL }}" download>Download PDF</a>{{/hasPDF}}</nav>{{#hasShareLinks}}<nav class="td-article-share" aria-label="Share article">{{#shareLinks}}<a href="{{ url }}" target="_blank" rel="noopener">{{ label }}</a>{{/shareLinks}}</nav>{{/hasShareLinks}}{{#page.hasTags}}<nav class="td-tags td-article-tags" aria-label="Tags">{{#page.tags}}<a class="td-tag" href="{{ url }}">{{ name }}</a>{{/page.tags}}</nav>{{/page.hasTags}}</header>{{#heroImage}}<figure class="td-article-media">{{{ heroHTML }}}</figure>{{/heroImage}}<div class="td-article-body">{{{ contents.htmlHead }}}{{{ contents.htmlTail }}}</div>{{#hasRelatedPosts}}<aside class="td-related" aria-label="Related articles"><h2>More updates</h2><ul class="td-related-list">{{#relatedPosts}}<li><a href="{{ url }}">{{ title }}</a>{{#displayDate}}<time>{{ displayDate }}</time>{{/displayDate}}</li>{{/relatedPosts}}</ul></aside>{{/hasRelatedPosts}}{{#site.newsletterEndOfPost}}{{{ site.newsletterEndOfPost }}}{{/site.newsletterEndOfPost}}</article>{{/page.article}}\(
            sourceDisclosure
        )</main>
        <footer class="td-footer"><div class="td-footer-inner">{{#site.newsletterFooter}}<div class="td-footer-newsletter">{{{ site.newsletterFooter }}}</div>{{/site.newsletterFooter}}<nav class="td-footer-nav">{{#site.sections}}<a href="{{ url }}">{{ title }}</a>{{/site.sections}}</nav><nav class="td-socials">{{#site.socialLinks}}<a href="{{ url }}"{{#rel}} rel="{{ rel }}"{{/rel}}>{{ label }}</a>{{/site.socialLinks}}{{#site.feedPath}}<a href="{{ site.feedPath }}">RSS</a>{{/site.feedPath}}</nav><span class="td-built">Built with <a href="https://github.com/TileDown/tile-down">TileDown \(
            TileKit
                .Product.version
        )</a></span></div></footer>
        {{#page.assets.javascript}}<script>{{{ page.assets.javascript }}}</script>{{/page.assets.javascript}}
        \(permalinkCopyScript)
        \(sourceScript)
        {{#site.analyticsBodyEnd}}{{{ site.analyticsBodyEnd }}}{{/site.analyticsBodyEnd}}
        </body>
        </html>
        """

        private static let leftSidebarTemplate = """
        <!doctype html>
        <html lang="en"{{#site.appearanceForced}} data-theme="{{ site.appearanceForced }}"{{/site.appearanceForced}}>
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        {{#site.appearanceToggle}}<script>
        (function () {
          var root = document.documentElement;
          function storedTheme() {
            try {
              var saved = localStorage.getItem('td-theme');
              return saved === 'dark' || saved === 'light' ? saved : '';
            } catch (e) {
              return '';
            }
          }
          function applyStoredTheme() {
            var saved = storedTheme();
            if (saved) root.setAttribute('data-theme', saved);
            else root.removeAttribute('data-theme');
          }
          // Apply a saved choice before paint so there is no flash. With no saved
          // choice the CSS follows the OS via prefers-color-scheme.
          applyStoredTheme();
          window.addEventListener('pageshow', applyStoredTheme);
          window.addEventListener('storage', function (event) {
            if (event.key === 'td-theme') applyStoredTheme();
          });
          document.addEventListener('DOMContentLoaded', function () {
            var button = document.querySelector('[data-td-theme-toggle]');
            if (!button) return;
            button.addEventListener('click', function () {
              var current = root.getAttribute('data-theme');
              var prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
              var next = current === 'dark' ? 'light' : current === 'light' ? 'dark' : (prefersDark ? 'light' : 'dark');
              root.setAttribute('data-theme', next);
              try { localStorage.setItem('td-theme', next); } catch (e) {}
            });
          });
        })();
        </script>{{/site.appearanceToggle}}
        \(metadataHead)
        {{#site.faviconPath}}<link rel="icon" href="{{ site.faviconPath }}">{{/site.faviconPath}}
        {{#site.stylesheetPath}}<link rel="stylesheet" href="{{ site.stylesheetPath }}">{{/site.stylesheetPath}}
        {{#site.feedPath}}<link rel="alternate" type="application/rss+xml" href="{{ site.feedPath }}">{{/site.feedPath}}
        {{#site.analyticsHead}}{{{ site.analyticsHead }}}{{/site.analyticsHead}}
        </head>
        <body class="td-layout-sidebar">
        <aside class="td-sidebar">
        {{#site.subtitle}}<a class="td-brand td-brand-stacked" href="{{ site.homeURL }}"><span class="td-brand-title">{{ site.title }}</span><span class="td-brand-subtitle">{{ site.subtitle }}</span></a>{{/site.subtitle}}{{^site.subtitle}}<a class="td-brand" href="{{ site.homeURL }}">{{ site.title }}</a>{{/site.subtitle}}
        <nav class="td-sidebar-nav">{{#site.sections}}<a class="td-nav-link" href="{{ url }}"{{#isCurrent}} aria-current="page"{{/isCurrent}}>{{ title }}</a>{{/site.sections}}</nav>
        {{#site.appearanceToggle}}<button class="td-theme-toggle" type="button" data-td-theme-toggle aria-label="Toggle dark mode" title="Toggle dark mode">&#9728;</button>{{/site.appearanceToggle}}
        </aside>
        <div class="td-content">
        <main class="td-main">{{#page.standardPage}}{{#page.tagBar}}<h1 class="td-tagbar-title">{{ page.title }}</h1>{{#site.hasTags}}<nav class="td-tagbar" aria-label="All tags"><a class="td-tag td-tag-lg td-tag-clear" href="{{ site.tagsURL }}" aria-label="Show all articles">&#215; Clear</a>{{#site.tags}}{{#isVisibleInTagBar}}<a class="td-tag td-tag-lg{{#isCurrent}} td-tag-current{{/isCurrent}}" href="{{ url }}">{{ name }}</a>{{/isVisibleInTagBar}}{{/site.tags}}</nav>{{/site.hasTags}}{{/page.tagBar}}{{#page.heroImage}}{{{ heroHTML }}}{{/page.heroImage}}{{{ page.contents.htmlHead }}}{{#page.hasTags}}<nav class="td-tags" aria-label="Tags">{{#page.tags}}<a class="td-tag" href="{{ url }}">{{ name }}</a>{{/page.tags}}</nav>{{/page.hasTags}}{{#page.latest}}{{#site.hasLatestPosts}}<ul class="td-posts">{{#site.latestPosts}}<li class="td-post-card"><a class="td-post-thumb" href="{{ url }}">{{#heroImage}}{{{ thumbnailHTML }}}{{/heroImage}}</a><div class="td-post-body"><h3 class="td-post-title"><a href="{{ url }}">{{ title }}</a></h3>{{#date}}<time class="td-post-date">{{ date }}</time>{{/date}}{{#description}}<p class="td-post-desc">{{ description }}</p>{{/description}}{{#hasTags}}<nav class="td-tags td-tags-card" aria-label="Tags">{{#tags}}<a class="td-tag" href="{{ url }}">{{ name }}</a>{{/tags}}</nav>{{/hasTags}}</div></li>{{/site.latestPosts}}</ul>{{/site.hasLatestPosts}}{{/page.latest}}{{{ page.contents.htmlTail }}}{{#page.postList}}{{#page.hasPosts}}<ul class="td-posts">{{#page.posts}}<li class="td-post-card"><a class="td-post-thumb" href="{{ url }}">{{#heroImage}}{{{ thumbnailHTML }}}{{/heroImage}}</a><div class="td-post-body"><h3 class="td-post-title"><a href="{{ url }}">{{ title }}</a></h3>{{#date}}<time class="td-post-date">{{ date }}</time>{{/date}}{{#description}}<p class="td-post-desc">{{ description }}</p>{{/description}}{{#hasTags}}<nav class="td-tags td-tags-card" aria-label="Tags">{{#tags}}<a class="td-tag" href="{{ url }}">{{ name }}</a>{{/tags}}</nav>{{/hasTags}}</div></li>{{/page.posts}}</ul>{{/page.hasPosts}}{{#page.emptyPosts}}<p class="td-empty">No posts match this tag selection.</p>{{/page.emptyPosts}}{{/page.postList}}{{/page.standardPage}}{{#page.article}}<article class="td-article"><header class="td-article-header"><div class="td-article-meta"><span class="td-article-kicker">{{ kicker }}</span>{{#date}}<time class="td-article-date">{{ date }}</time>{{/date}}</div><h1 class="td-article-title">{{ title }}</h1>{{#description}}<p class="td-article-dek">{{ description }}</p>{{/description}}<nav class="td-article-actions" aria-label="Article actions"><a href="{{ url }}" data-td-copy-permalink title="Copy permalink">Permalink</a>{{#site.feedPath}}<a href="{{ site.feedPath }}">RSS</a>{{/site.feedPath}}{{#hasPDF}}<a href="{{ pdfURL }}" download>Download PDF</a>{{/hasPDF}}</nav>{{#hasShareLinks}}<nav class="td-article-share" aria-label="Share article">{{#shareLinks}}<a href="{{ url }}" target="_blank" rel="noopener">{{ label }}</a>{{/shareLinks}}</nav>{{/hasShareLinks}}{{#page.hasTags}}<nav class="td-tags td-article-tags" aria-label="Tags">{{#page.tags}}<a class="td-tag" href="{{ url }}">{{ name }}</a>{{/page.tags}}</nav>{{/page.hasTags}}</header>{{#heroImage}}<figure class="td-article-media">{{{ heroHTML }}}</figure>{{/heroImage}}<div class="td-article-body">{{{ contents.htmlHead }}}{{{ contents.htmlTail }}}</div>{{#hasRelatedPosts}}<aside class="td-related" aria-label="Related articles"><h2>More updates</h2><ul class="td-related-list">{{#relatedPosts}}<li><a href="{{ url }}">{{ title }}</a>{{#displayDate}}<time>{{ displayDate }}</time>{{/displayDate}}</li>{{/relatedPosts}}</ul></aside>{{/hasRelatedPosts}}{{#site.newsletterEndOfPost}}{{{ site.newsletterEndOfPost }}}{{/site.newsletterEndOfPost}}</article>{{/page.article}}\(
            sourceDisclosure
        )</main>
        <footer class="td-footer"><div class="td-footer-inner">{{#site.newsletterFooter}}<div class="td-footer-newsletter">{{{ site.newsletterFooter }}}</div>{{/site.newsletterFooter}}<nav class="td-footer-nav">{{#site.sections}}<a href="{{ url }}">{{ title }}</a>{{/site.sections}}</nav><nav class="td-socials">{{#site.socialLinks}}<a href="{{ url }}"{{#rel}} rel="{{ rel }}"{{/rel}}>{{ label }}</a>{{/site.socialLinks}}{{#site.feedPath}}<a href="{{ site.feedPath }}">RSS</a>{{/site.feedPath}}</nav><span class="td-built">Built with <a href="https://github.com/TileDown/tile-down">TileDown \(
            TileKit
                .Product.version
        )</a></span></div></footer>
        </div>
        {{#page.assets.javascript}}<script>{{{ page.assets.javascript }}}</script>{{/page.assets.javascript}}
        \(permalinkCopyScript)
        \(sourceScript)
        {{#site.analyticsBodyEnd}}{{{ site.analyticsBodyEnd }}}{{/site.analyticsBodyEnd}}
        </body>
        </html>
        """

        private static let metadataHead = """
        <title>{{ page.metadata.title }}</title>
        {{#page.metadata.description}}<meta name="description" content="{{ page.metadata.description }}">{{/page.metadata.description}}
        {{#page.metadata.canonicalURL}}<link rel="canonical" href="{{ page.metadata.canonicalURL }}">{{/page.metadata.canonicalURL}}
        <meta property="og:title" content="{{ page.metadata.title }}">
        <meta property="og:type" content="{{ page.metadata.openGraphType }}">
        {{#page.metadata.description}}<meta property="og:description" content="{{ page.metadata.description }}">{{/page.metadata.description}}
        {{#page.metadata.canonicalURL}}<meta property="og:url" content="{{ page.metadata.canonicalURL }}">{{/page.metadata.canonicalURL}}
        {{#page.metadata.siteTitle}}<meta property="og:site_name" content="{{ page.metadata.siteTitle }}">{{/page.metadata.siteTitle}}
        {{#page.metadata.imageURL}}<meta property="og:image" content="{{ page.metadata.imageURL }}">{{/page.metadata.imageURL}}
        <meta name="twitter:card" content="{{ page.metadata.twitterCard }}">
        <meta name="twitter:title" content="{{ page.metadata.title }}">
        {{#page.metadata.description}}<meta name="twitter:description" content="{{ page.metadata.description }}">{{/page.metadata.description}}
        {{#page.metadata.imageURL}}<meta name="twitter:image" content="{{ page.metadata.imageURL }}">{{/page.metadata.imageURL}}
        {{#page.metadata.articlePublishedTime}}<meta property="article:published_time" content="{{ page.metadata.articlePublishedTime }}">{{/page.metadata.articlePublishedTime}}
        """

        /// Progressive enhancement for article permalink actions. The link keeps
        /// its normal `href` fallback, but browsers with clipboard access copy the
        /// canonical article URL in place.
        private static let permalinkCopyScript = """
        {{#page.article}}<script>
        (function () {
          function setup() {
            document.querySelectorAll('[data-td-copy-permalink]').forEach(function (link) {
              link.addEventListener('click', function (event) {
                if (!navigator.clipboard) return;
                var url = link.getAttribute('href');
                if (!url) return;
                event.preventDefault();
                navigator.clipboard.writeText(url).then(function () {
                  var label = link.textContent;
                  link.textContent = 'Copied';
                  link.setAttribute('data-td-copy-state', 'copied');
                  setTimeout(function () {
                    link.textContent = label;
                    link.removeAttribute('data-td-copy-state');
                  }, 1500);
                }, function () {
                  window.location.href = url;
                });
              });
            });
          }
          document.addEventListener('DOMContentLoaded', setup);
        })();
        </script>{{/page.article}}
        """

        /// The "View Markdown source" disclosure, shown at the end of the content on
        /// every page when `site.showSource` is set and the page has a backing source
        /// file. The toggle is a native `<details>`, so it needs no JavaScript. The
        /// body is a code-window panel with a title bar (the source file name) and a
        /// syntax-highlighted listing. `page.sourceHTML` is highlighted HTML built at
        /// build time (its text already escaped), so it is emitted with a raw `{{{ }}}`
        /// tag. The copy affordance is added by `sourceCopyScript` as an enhancement.
        private static let sourceDisclosure = """
        {{#site.showSource}}{{#page.hasSource}}<details class="td-source"><summary class="td-source-summary">View Markdown source</summary><div class="td-source-window"><div class="td-source-titlebar"><span class="td-source-dots" aria-hidden="true"><i></i><i></i><i></i></span><span class="td-source-name">{{ page.sourceName }}</span></div><pre class="td-source-pre"><code class="td-source-code">{{{ page.sourceHTML }}}</code></pre></div></details>{{/page.hasSource}}{{/site.showSource}}
        """

        /// Progressive enhancement for the source disclosure, emitted only when the
        /// site opts in. It remembers whether the reader has the source open, in
        /// localStorage, so the choice follows them across pages; and it adds a Copy
        /// button to the title bar when the browser has a clipboard. With no
        /// JavaScript the disclosure still opens via the native `<details>` and the
        /// source stays selectable, so nothing breaks; the persistence and the button
        /// are purely additive, which is why the button is created here, not in markup.
        private static let sourceScript = """
        {{#site.showSource}}<script>
        (function () {
          var KEY = 'td-source-open';
          function setup() {
            var open = false;
            try { open = localStorage.getItem(KEY) === 'true'; } catch (e) {}
            document.querySelectorAll('.td-source').forEach(function (details) {
              if (open) details.open = true;
              details.addEventListener('toggle', function () {
                try { localStorage.setItem(KEY, details.open ? 'true' : 'false'); } catch (e) {}
              });
              var code = details.querySelector('.td-source-code');
              var bar = details.querySelector('.td-source-titlebar');
              if (!code || !bar || !navigator.clipboard) return;
              var button = document.createElement('button');
              button.type = 'button';
              button.className = 'td-source-copy';
              button.textContent = 'Copy';
              bar.appendChild(button);
              button.addEventListener('click', function () {
                navigator.clipboard.writeText(code.textContent).then(function () {
                  button.textContent = 'Copied';
                  setTimeout(function () { button.textContent = 'Copy'; }, 1500);
                });
              });
            });
          }
          document.addEventListener('DOMContentLoaded', setup);
        })();
        </script>{{/site.showSource}}
        """
    }
}

// swiftlint:enable line_length
