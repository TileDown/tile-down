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
        <title>{{ page.title }}</title>
        {{#site.stylesheetPath}}<link rel="stylesheet" href="{{ site.stylesheetPath }}">{{/site.stylesheetPath}}
        {{#site.feedPath}}<link rel="alternate" type="application/rss+xml" href="{{ site.feedPath }}">{{/site.feedPath}}
        {{#site.analyticsHead}}{{{ site.analyticsHead }}}{{/site.analyticsHead}}
        </head>
        <body>
        <header class="td-header">
        <a class="td-brand" href="{{ site.homeURL }}">{{ site.title }}</a>
        <nav class="td-nav">{{#site.sections}}<a class="td-nav-link" href="{{ url }}"{{#isCurrent}} aria-current="page"{{/isCurrent}}>{{ title }}</a>{{/site.sections}}</nav>
        {{#site.appearanceToggle}}<button class="td-theme-toggle" type="button" data-td-theme-toggle aria-label="Toggle dark mode" title="Toggle dark mode">&#9728;</button>{{/site.appearanceToggle}}
        </header>
        <main class="td-main">{{#page.standardPage}}{{#page.tagBar}}<h1 class="td-tagbar-title">{{ page.title }}</h1>{{#site.hasTags}}<nav class="td-tagbar" aria-label="All tags"><a class="td-tag td-tag-lg td-tag-clear" href="{{ site.tagsURL }}" aria-label="Show all articles">&#215; Clear</a>{{#site.tags}}{{#isVisibleInTagBar}}<a class="td-tag td-tag-lg{{#isCurrent}} td-tag-current{{/isCurrent}}" href="{{ url }}">{{ name }}</a>{{/isVisibleInTagBar}}{{/site.tags}}</nav>{{/site.hasTags}}{{/page.tagBar}}{{#page.heroImage}}{{{ heroHTML }}}{{/page.heroImage}}{{{ page.contents.htmlHead }}}{{#page.hasTags}}<nav class="td-tags" aria-label="Tags">{{#page.tags}}<a class="td-tag" href="{{ url }}">{{ name }}</a>{{/page.tags}}</nav>{{/page.hasTags}}{{#page.latest}}{{#site.hasLatestPosts}}<ul class="td-posts">{{#site.latestPosts}}<li class="td-post-card"><a class="td-post-thumb" href="{{ url }}">{{#heroImage}}{{{ thumbnailHTML }}}{{/heroImage}}</a><div class="td-post-body"><h3 class="td-post-title"><a href="{{ url }}">{{ title }}</a></h3>{{#date}}<time class="td-post-date">{{ date }}</time>{{/date}}{{#description}}<p class="td-post-desc">{{ description }}</p>{{/description}}{{#hasTags}}<nav class="td-tags td-tags-card" aria-label="Tags">{{#tags}}<a class="td-tag" href="{{ url }}">{{ name }}</a>{{/tags}}</nav>{{/hasTags}}</div></li>{{/site.latestPosts}}</ul>{{/site.hasLatestPosts}}{{/page.latest}}{{{ page.contents.htmlTail }}}{{#page.postList}}{{#page.hasPosts}}<ul class="td-posts">{{#page.posts}}<li class="td-post-card"><a class="td-post-thumb" href="{{ url }}">{{#heroImage}}{{{ thumbnailHTML }}}{{/heroImage}}</a><div class="td-post-body"><h3 class="td-post-title"><a href="{{ url }}">{{ title }}</a></h3>{{#date}}<time class="td-post-date">{{ date }}</time>{{/date}}{{#description}}<p class="td-post-desc">{{ description }}</p>{{/description}}{{#hasTags}}<nav class="td-tags td-tags-card" aria-label="Tags">{{#tags}}<a class="td-tag" href="{{ url }}">{{ name }}</a>{{/tags}}</nav>{{/hasTags}}</div></li>{{/page.posts}}</ul>{{/page.hasPosts}}{{#page.emptyPosts}}<p class="td-empty">No posts match this tag selection.</p>{{/page.emptyPosts}}{{/page.postList}}{{/page.standardPage}}{{#page.article}}<article class="td-article"><header class="td-article-header"><div class="td-article-meta"><span class="td-article-kicker">{{ kicker }}</span>{{#date}}<time class="td-article-date">{{ date }}</time>{{/date}}</div><h1 class="td-article-title">{{ title }}</h1>{{#description}}<p class="td-article-dek">{{ description }}</p>{{/description}}<nav class="td-article-actions" aria-label="Article actions"><a href="{{ url }}">Permalink</a>{{#site.feedPath}}<a href="{{ site.feedPath }}">RSS</a>{{/site.feedPath}}</nav>{{#hasShareLinks}}<nav class="td-article-share" aria-label="Share article">{{#shareLinks}}<a href="{{ url }}" target="_blank" rel="noopener">{{ label }}</a>{{/shareLinks}}</nav>{{/hasShareLinks}}{{#page.hasTags}}<nav class="td-tags td-article-tags" aria-label="Tags">{{#page.tags}}<a class="td-tag" href="{{ url }}">{{ name }}</a>{{/page.tags}}</nav>{{/page.hasTags}}</header>{{#heroImage}}<figure class="td-article-media">{{{ heroHTML }}}</figure>{{/heroImage}}<div class="td-article-body">{{{ contents.htmlHead }}}{{{ contents.htmlTail }}}</div>{{#hasRelatedPosts}}<aside class="td-related" aria-label="Related articles"><h2>More updates</h2><ul class="td-related-list">{{#relatedPosts}}<li><a href="{{ url }}">{{ title }}</a>{{#displayDate}}<time>{{ displayDate }}</time>{{/displayDate}}</li>{{/relatedPosts}}</ul></aside>{{/hasRelatedPosts}}</article>{{/page.article}}</main>
        <footer class="td-footer"><div class="td-footer-inner"><nav class="td-footer-nav">{{#site.sections}}<a href="{{ url }}">{{ title }}</a>{{/site.sections}}</nav><nav class="td-socials">{{#site.socialLinks}}<a href="{{ url }}">{{ label }}</a>{{/site.socialLinks}}{{#site.feedPath}}<a href="{{ site.feedPath }}">RSS</a>{{/site.feedPath}}</nav><span class="td-built">Built with <a href="https://github.com/TileDown/tile-down">TileDown</a></span></div></footer>
        {{#page.assets.javascript}}<script>{{{ page.assets.javascript }}}</script>{{/page.assets.javascript}}
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
        <title>{{ page.title }}</title>
        {{#site.stylesheetPath}}<link rel="stylesheet" href="{{ site.stylesheetPath }}">{{/site.stylesheetPath}}
        {{#site.feedPath}}<link rel="alternate" type="application/rss+xml" href="{{ site.feedPath }}">{{/site.feedPath}}
        {{#site.analyticsHead}}{{{ site.analyticsHead }}}{{/site.analyticsHead}}
        </head>
        <body class="td-layout-sidebar">
        <aside class="td-sidebar">
        <a class="td-brand" href="{{ site.homeURL }}">{{ site.title }}</a>
        <nav class="td-sidebar-nav">{{#site.sections}}<a class="td-nav-link" href="{{ url }}"{{#isCurrent}} aria-current="page"{{/isCurrent}}>{{ title }}</a>{{/site.sections}}</nav>
        {{#site.appearanceToggle}}<button class="td-theme-toggle" type="button" data-td-theme-toggle aria-label="Toggle dark mode" title="Toggle dark mode">&#9728;</button>{{/site.appearanceToggle}}
        </aside>
        <div class="td-content">
        <main class="td-main">{{#page.standardPage}}{{#page.tagBar}}<h1 class="td-tagbar-title">{{ page.title }}</h1>{{#site.hasTags}}<nav class="td-tagbar" aria-label="All tags"><a class="td-tag td-tag-lg td-tag-clear" href="{{ site.tagsURL }}" aria-label="Show all articles">&#215; Clear</a>{{#site.tags}}{{#isVisibleInTagBar}}<a class="td-tag td-tag-lg{{#isCurrent}} td-tag-current{{/isCurrent}}" href="{{ url }}">{{ name }}</a>{{/isVisibleInTagBar}}{{/site.tags}}</nav>{{/site.hasTags}}{{/page.tagBar}}{{#page.heroImage}}{{{ heroHTML }}}{{/page.heroImage}}{{{ page.contents.htmlHead }}}{{#page.hasTags}}<nav class="td-tags" aria-label="Tags">{{#page.tags}}<a class="td-tag" href="{{ url }}">{{ name }}</a>{{/page.tags}}</nav>{{/page.hasTags}}{{#page.latest}}{{#site.hasLatestPosts}}<ul class="td-posts">{{#site.latestPosts}}<li class="td-post-card"><a class="td-post-thumb" href="{{ url }}">{{#heroImage}}{{{ thumbnailHTML }}}{{/heroImage}}</a><div class="td-post-body"><h3 class="td-post-title"><a href="{{ url }}">{{ title }}</a></h3>{{#date}}<time class="td-post-date">{{ date }}</time>{{/date}}{{#description}}<p class="td-post-desc">{{ description }}</p>{{/description}}{{#hasTags}}<nav class="td-tags td-tags-card" aria-label="Tags">{{#tags}}<a class="td-tag" href="{{ url }}">{{ name }}</a>{{/tags}}</nav>{{/hasTags}}</div></li>{{/site.latestPosts}}</ul>{{/site.hasLatestPosts}}{{/page.latest}}{{{ page.contents.htmlTail }}}{{#page.postList}}{{#page.hasPosts}}<ul class="td-posts">{{#page.posts}}<li class="td-post-card"><a class="td-post-thumb" href="{{ url }}">{{#heroImage}}{{{ thumbnailHTML }}}{{/heroImage}}</a><div class="td-post-body"><h3 class="td-post-title"><a href="{{ url }}">{{ title }}</a></h3>{{#date}}<time class="td-post-date">{{ date }}</time>{{/date}}{{#description}}<p class="td-post-desc">{{ description }}</p>{{/description}}{{#hasTags}}<nav class="td-tags td-tags-card" aria-label="Tags">{{#tags}}<a class="td-tag" href="{{ url }}">{{ name }}</a>{{/tags}}</nav>{{/hasTags}}</div></li>{{/page.posts}}</ul>{{/page.hasPosts}}{{#page.emptyPosts}}<p class="td-empty">No posts match this tag selection.</p>{{/page.emptyPosts}}{{/page.postList}}{{/page.standardPage}}{{#page.article}}<article class="td-article"><header class="td-article-header"><div class="td-article-meta"><span class="td-article-kicker">{{ kicker }}</span>{{#date}}<time class="td-article-date">{{ date }}</time>{{/date}}</div><h1 class="td-article-title">{{ title }}</h1>{{#description}}<p class="td-article-dek">{{ description }}</p>{{/description}}<nav class="td-article-actions" aria-label="Article actions"><a href="{{ url }}">Permalink</a>{{#site.feedPath}}<a href="{{ site.feedPath }}">RSS</a>{{/site.feedPath}}</nav>{{#hasShareLinks}}<nav class="td-article-share" aria-label="Share article">{{#shareLinks}}<a href="{{ url }}" target="_blank" rel="noopener">{{ label }}</a>{{/shareLinks}}</nav>{{/hasShareLinks}}{{#page.hasTags}}<nav class="td-tags td-article-tags" aria-label="Tags">{{#page.tags}}<a class="td-tag" href="{{ url }}">{{ name }}</a>{{/page.tags}}</nav>{{/page.hasTags}}</header>{{#heroImage}}<figure class="td-article-media">{{{ heroHTML }}}</figure>{{/heroImage}}<div class="td-article-body">{{{ contents.htmlHead }}}{{{ contents.htmlTail }}}</div>{{#hasRelatedPosts}}<aside class="td-related" aria-label="Related articles"><h2>More updates</h2><ul class="td-related-list">{{#relatedPosts}}<li><a href="{{ url }}">{{ title }}</a>{{#displayDate}}<time>{{ displayDate }}</time>{{/displayDate}}</li>{{/relatedPosts}}</ul></aside>{{/hasRelatedPosts}}</article>{{/page.article}}</main>
        <footer class="td-footer"><div class="td-footer-inner"><nav class="td-footer-nav">{{#site.sections}}<a href="{{ url }}">{{ title }}</a>{{/site.sections}}</nav><nav class="td-socials">{{#site.socialLinks}}<a href="{{ url }}">{{ label }}</a>{{/site.socialLinks}}{{#site.feedPath}}<a href="{{ site.feedPath }}">RSS</a>{{/site.feedPath}}</nav><span class="td-built">Built with <a href="https://github.com/TileDown/tile-down">TileDown</a></span></div></footer>
        </div>
        </body>
        </html>
        """
    }
}

// swiftlint:enable line_length
