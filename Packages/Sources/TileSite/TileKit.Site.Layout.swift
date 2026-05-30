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
          // Apply a saved choice before paint so there is no flash. With no saved
          // choice the CSS follows the OS via prefers-color-scheme.
          try { var saved = localStorage.getItem('td-theme'); if (saved === 'dark' || saved === 'light') root.setAttribute('data-theme', saved); } catch (e) {}
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
        </head>
        <body>
        <header class="td-header">
        <a class="td-brand" href="{{ site.homeURL }}">{{ site.title }}</a>
        <nav class="td-nav">{{#site.sections}}<a class="td-nav-link" href="{{ url }}">{{ title }}</a>{{/site.sections}}</nav>
        {{#site.appearanceToggle}}<button class="td-theme-toggle" type="button" data-td-theme-toggle aria-label="Toggle dark mode" title="Toggle dark mode">&#9728;</button>{{/site.appearanceToggle}}
        </header>
        <main class="td-main">{{#page.image}}<img class="td-hero" src="{{ page.image }}" alt="{{ page.title }}">{{/page.image}}{{{ page.contents.html }}}{{#page.hasTags}}<nav class="td-tags" aria-label="Tags">{{#page.tags}}<a class="td-tag" href="{{ url }}">{{ name }}</a>{{/page.tags}}</nav>{{/page.hasTags}}{{#page.postList}}<ul class="td-posts">{{#page.posts}}<li class="td-post-card"><a class="td-post-thumb" href="{{ url }}">{{#image}}<img src="{{ image }}" alt="{{ title }}">{{/image}}</a><div class="td-post-body"><h3 class="td-post-title"><a href="{{ url }}">{{ title }}</a></h3>{{#date}}<time class="td-post-date">{{ date }}</time>{{/date}}{{#description}}<p class="td-post-desc">{{ description }}</p>{{/description}}{{#hasTags}}<nav class="td-tags td-tags-card" aria-label="Tags">{{#tags}}<a class="td-tag" href="{{ url }}">{{ name }}</a>{{/tags}}</nav>{{/hasTags}}</div></li>{{/page.posts}}</ul>{{/page.postList}}</main>
        <footer class="td-footer"><div class="td-footer-inner"><nav class="td-footer-nav">{{#site.sections}}<a href="{{ url }}">{{ title }}</a>{{/site.sections}}</nav><nav class="td-socials">{{#site.socialLinks}}<a href="{{ url }}">{{ label }}</a>{{/site.socialLinks}}{{#site.feedPath}}<a href="{{ site.feedPath }}">RSS</a>{{/site.feedPath}}</nav><span class="td-built">Built with <a href="https://github.com/TileDown/tile-down">Tiledown</a></span></div></footer>
        {{#page.assets.javascript}}<script>{{{ page.assets.javascript }}}</script>{{/page.assets.javascript}}
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
          // Apply a saved choice before paint so there is no flash. With no saved
          // choice the CSS follows the OS via prefers-color-scheme.
          try { var saved = localStorage.getItem('td-theme'); if (saved === 'dark' || saved === 'light') root.setAttribute('data-theme', saved); } catch (e) {}
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
        </head>
        <body class="td-layout-sidebar">
        <aside class="td-sidebar">
        <a class="td-brand" href="{{ site.homeURL }}">{{ site.title }}</a>
        <nav class="td-sidebar-nav">{{#site.sections}}<a class="td-nav-link" href="{{ url }}">{{ title }}</a>{{/site.sections}}</nav>
        {{#site.appearanceToggle}}<button class="td-theme-toggle" type="button" data-td-theme-toggle aria-label="Toggle dark mode" title="Toggle dark mode">&#9728;</button>{{/site.appearanceToggle}}
        </aside>
        <div class="td-content">
        <main class="td-main">{{#page.image}}<img class="td-hero" src="{{ page.image }}" alt="{{ page.title }}">{{/page.image}}{{{ page.contents.html }}}{{#page.hasTags}}<nav class="td-tags" aria-label="Tags">{{#page.tags}}<a class="td-tag" href="{{ url }}">{{ name }}</a>{{/page.tags}}</nav>{{/page.hasTags}}{{#page.postList}}<ul class="td-posts">{{#page.posts}}<li class="td-post-card"><a class="td-post-thumb" href="{{ url }}">{{#image}}<img src="{{ image }}" alt="{{ title }}">{{/image}}</a><div class="td-post-body"><h3 class="td-post-title"><a href="{{ url }}">{{ title }}</a></h3>{{#date}}<time class="td-post-date">{{ date }}</time>{{/date}}{{#description}}<p class="td-post-desc">{{ description }}</p>{{/description}}{{#hasTags}}<nav class="td-tags td-tags-card" aria-label="Tags">{{#tags}}<a class="td-tag" href="{{ url }}">{{ name }}</a>{{/tags}}</nav>{{/hasTags}}</div></li>{{/page.posts}}</ul>{{/page.postList}}</main>
        <footer class="td-footer"><div class="td-footer-inner"><nav class="td-footer-nav">{{#site.sections}}<a href="{{ url }}">{{ title }}</a>{{/site.sections}}</nav><nav class="td-socials">{{#site.socialLinks}}<a href="{{ url }}">{{ label }}</a>{{/site.socialLinks}}{{#site.feedPath}}<a href="{{ site.feedPath }}">RSS</a>{{/site.feedPath}}</nav><span class="td-built">Built with <a href="https://github.com/TileDown/tile-down">Tiledown</a></span></div></footer>
        </div>
        </body>
        </html>
        """
    }
}

// swiftlint:enable line_length
