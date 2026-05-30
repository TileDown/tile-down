// swiftlint:disable line_length
// The built-in template lines cannot wrap without inserting whitespace into the
// generated HTML, so line length is disabled for this template-only file.
import TileCore

public extension TileKit.Site {
    /// A built-in page layout: the template bundle that arranges a page's regions
    /// (header, navigation, content, footer).
    ///
    /// The first layout is top navigation, the placement the research supports as a
    /// default (`docs/research/site-layout-navigation.md`). A layout is a template,
    /// not Swift that emits HTML, so each case exposes a Mustache `template`. With
    /// only one case there is no selection mechanism yet; a second layout
    /// (left sidebar) is what earns it.
    ///
    /// The template builds its menu from `site.sections` and links the shared
    /// stylesheet from `site.stylesheetPath`. It expects each page to have a
    /// `title`. The `td-` classes are styling hooks for a theme; without one the
    /// page renders structurally correct but unstyled.
    enum Layout: Equatable, Sendable {
        /// Horizontal navigation across the top, with a footer repeating the
        /// sections.
        case topNav

        public var template: String {
            switch self {
            case .topNav:
                Self.topNavTemplate
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
        </head>
        <body>
        <header class="td-header">
        <a class="td-brand" href="/">{{ site.title }}</a>
        <nav class="td-nav">{{#site.sections}}<a class="td-nav-link" href="{{ url }}">{{ title }}</a>{{/site.sections}}</nav>
        </header>
        <main class="td-main">{{{ page.contents.html }}}</main>
        <footer class="td-footer"><nav class="td-footer-nav">{{#site.sections}}<a href="{{ url }}">{{ title }}</a>{{/site.sections}}</nav></footer>
        </body>
        </html>
        """
    }
}

// swiftlint:enable line_length
