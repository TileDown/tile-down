// swiftlint:disable line_length
// The theme is CSS; its lines cannot wrap without changing the stylesheet, so line
// length is disabled for this CSS-only file.
import TileCore

public extension TileKit.Site {
    /// A built-in theme: the look (colors, typography, spacing) applied to a layout.
    ///
    /// A theme is orthogonal to a `Layout`: it provides the values and base styles
    /// that style the layout's `td-` hooks, so any layout can wear any theme. Each
    /// theme defines its semantic theme properties (named CSS custom properties)
    /// twice, a light set on `:root` and a dark set under `prefers-color-scheme:
    /// dark` and `[data-theme="dark"]`, so light and dark are a mode of the theme,
    /// not separate themes. The site generator composes a theme's `tokens`, `reset`,
    /// and `base` into the shared stylesheet's cascade layers.
    enum Theme: Equatable, Sendable {
        /// The standard built-in theme: a warm, readable design with a centered
        /// measure, available in light and dark.
        case standard

        /// The theme property definitions (light on `:root`, dark via
        /// `prefers-color-scheme` and `[data-theme]`). Sits outside the cascade
        /// layers, since custom properties cascade on their own.
        public var tokens: String {
            switch self {
            case .standard:
                Self.standardTokens
            }
        }

        /// Reset rules, placed in the `reset` cascade layer.
        public var reset: String {
            switch self {
            case .standard:
                Self.standardReset
            }
        }

        /// Base and layout-region styles that read the theme properties, placed in
        /// the `theme` cascade layer beside the tiles' themed CSS.
        public var base: String {
            switch self {
            case .standard:
                Self.standardBase
            }
        }

        private static let standardTokens = """
        :root {
        --td-bg: #ffffff;
        --td-surface: #f5f5f4;
        --td-ink: #1c1917;
        --td-muted: #57534e;
        --td-accent: #b45309;
        --td-border: #e7e5e4;
        --td-radius: 12px;
        --td-space: 1rem;
        --td-measure: 46rem;
        --td-font: ui-sans-serif, system-ui, -apple-system, "Segoe UI", sans-serif;
        }
        .td-dark-tokens, [data-theme="dark"] {
        --td-bg: #0a0a0a;
        --td-surface: #18181b;
        --td-ink: #fafaf9;
        --td-muted: #a1a1aa;
        --td-accent: #f59e0b;
        --td-border: #27272a;
        }
        @media (prefers-color-scheme: dark) {
        :root:not([data-theme="light"]) {
        --td-bg: #0a0a0a;
        --td-surface: #18181b;
        --td-ink: #fafaf9;
        --td-muted: #a1a1aa;
        --td-accent: #f59e0b;
        --td-border: #27272a;
        }
        }
        """

        private static let standardReset = """
        *, *::before, *::after { box-sizing: border-box; }
        body, h1, h2, h3, p, ul, figure { margin: 0; }
        """

        private static let standardBase = """
        body { background: var(--td-bg); color: var(--td-ink); font: 16px/1.6 var(--td-font); -webkit-font-smoothing: antialiased; }
        a { color: var(--td-accent); }
        .td-header, .td-main, .td-content { max-width: var(--td-measure); margin-inline: auto; padding-inline: var(--td-space); }
        .td-header { display: flex; align-items: center; justify-content: space-between; gap: var(--td-space); padding-block: 1.25rem; border-bottom: 1px solid var(--td-border); }
        .td-brand { font-weight: 700; font-size: 1.25rem; color: var(--td-ink); text-decoration: none; }
        .td-nav { display: flex; gap: 1.25rem; flex-wrap: wrap; }
        .td-nav a, .td-footer a { color: var(--td-muted); text-decoration: none; }
        .td-nav a:hover, .td-footer a:hover { color: var(--td-ink); }
        .td-main { padding-block: 2.5rem; }
        .td-main h1 { font-size: 2.5rem; font-weight: 800; line-height: 1.1; letter-spacing: -0.02em; margin-block: 0 1rem; }
        .td-main h2 { font-size: 1.5rem; margin-block: 2.5rem 0.75rem; }
        .td-main p { margin-block: 0 1.25rem; }
        .td-main img { max-width: 100%; height: auto; border-radius: var(--td-radius); }
        .td-footer { border-top: 1px solid var(--td-border); padding-block: 2rem; color: var(--td-muted); }
        .td-footer-nav { display: flex; gap: 1rem; flex-wrap: wrap; max-width: var(--td-measure); margin-inline: auto; padding-inline: var(--td-space); }
        .td-layout-sidebar { display: grid; grid-template-columns: 16rem 1fr; min-height: 100vh; }
        .td-sidebar { padding: 1.5rem; border-right: 1px solid var(--td-border); background: var(--td-surface); }
        .td-sidebar-nav { display: flex; flex-direction: column; gap: 0.5rem; margin-top: 1rem; }
        @media (max-width: 48rem) { .td-layout-sidebar { grid-template-columns: 1fr; } .td-sidebar { border-right: 0; border-bottom: 1px solid var(--td-border); } }
        """
    }
}

// swiftlint:enable line_length
