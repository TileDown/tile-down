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
        <html lang="en">
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>{{ page.title }}</title>
        {{#site.stylesheetPath}}<link rel="stylesheet" href="{{ site.stylesheetPath }}">{{/site.stylesheetPath}}
        {{#site.feedPath}}<link rel="alternate" type="application/rss+xml" href="{{ site.feedPath }}">{{/site.feedPath}}
        </head>
        <body>
        <header class="td-header">
        <a class="td-brand" href="{{ site.homeURL }}">{{ site.title }}</a>
        <nav class="td-nav">{{#site.sections}}<a class="td-nav-link" href="{{ url }}">{{ title }}</a>{{/site.sections}}</nav>
        </header>
        <main class="td-main">{{{ page.contents.html }}}</main>
        <footer class="td-footer"><div class="td-footer-inner"><nav class="td-footer-nav">{{#site.sections}}<a href="{{ url }}">{{ title }}</a>{{/site.sections}}</nav><nav class="td-socials">{{#site.socialLinks}}<a href="{{ url }}">{{ label }}</a>{{/site.socialLinks}}{{#site.feedPath}}<a href="{{ site.feedPath }}">RSS</a>{{/site.feedPath}}</nav><span class="td-built">Built with <a href="https://github.com/TileDown/tile-down">TileKit</a></span></div></footer>
        </body>
        </html>
        """

        private static let leftSidebarTemplate = """
        <!doctype html>
        <html lang="en">
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>{{ page.title }}</title>
        {{#site.stylesheetPath}}<link rel="stylesheet" href="{{ site.stylesheetPath }}">{{/site.stylesheetPath}}
        {{#site.feedPath}}<link rel="alternate" type="application/rss+xml" href="{{ site.feedPath }}">{{/site.feedPath}}
        </head>
        <body class="td-layout-sidebar">
        <aside class="td-sidebar">
        <a class="td-brand" href="{{ site.homeURL }}">{{ site.title }}</a>
        <nav class="td-sidebar-nav">{{#site.sections}}<a class="td-nav-link" href="{{ url }}">{{ title }}</a>{{/site.sections}}</nav>
        </aside>
        <div class="td-content">
        <main class="td-main">{{{ page.contents.html }}}</main>
        <footer class="td-footer"><div class="td-footer-inner"><nav class="td-footer-nav">{{#site.sections}}<a href="{{ url }}">{{ title }}</a>{{/site.sections}}</nav><nav class="td-socials">{{#site.socialLinks}}<a href="{{ url }}">{{ label }}</a>{{/site.socialLinks}}{{#site.feedPath}}<a href="{{ site.feedPath }}">RSS</a>{{/site.feedPath}}</nav><span class="td-built">Built with <a href="https://github.com/TileDown/tile-down">TileKit</a></span></div></footer>
        </div>
        </body>
        </html>
        """
    }
}

// swiftlint:enable line_length
