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
        /// A crisp platform-native theme with system typography, soft materials,
        /// and light and dark modes.
        case system

        /// The theme property definitions (light on `:root`, dark via
        /// `prefers-color-scheme` and `[data-theme]`). Sits outside the cascade
        /// layers, since custom properties cascade on their own.
        public var tokens: String {
            switch self {
            case .standard:
                Self.standardTokens
            case .system:
                Self.systemTokens
            }
        }

        /// Reset rules, placed in the `reset` cascade layer.
        public var reset: String {
            switch self {
            case .standard:
                Self.standardReset
            case .system:
                Self.systemReset
            }
        }

        /// Base and layout-region styles that read the theme properties, placed in
        /// the `theme` cascade layer beside the tiles' themed CSS.
        public var base: String {
            switch self {
            case .standard:
                Self.standardBase
            case .system:
                Self.systemBase
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
        .td-footer-inner { display: grid; grid-template-columns: 1fr auto; gap: 1rem; max-width: var(--td-measure); margin-inline: auto; padding-inline: var(--td-space); }
        .td-footer-nav, .td-socials { display: flex; gap: 1rem; flex-wrap: wrap; }
        .td-built { font-size: 0.9rem; }
        .td-layout-sidebar { display: grid; grid-template-columns: 16rem 1fr; min-height: 100vh; }
        .td-sidebar { padding: 1.5rem; border-right: 1px solid var(--td-border); background: var(--td-surface); }
        .td-sidebar-nav { display: flex; flex-direction: column; gap: 0.5rem; margin-top: 1rem; }
        @media (max-width: 48rem) { .td-layout-sidebar { grid-template-columns: 1fr; } .td-sidebar { border-right: 0; border-bottom: 1px solid var(--td-border); } }
        """

        private static let systemTokens = """
        :root {
        --td-bg: #f5f5f7;
        --td-surface: rgba(255, 255, 255, 0.78);
        --td-elevated: #ffffff;
        --td-ink: #1d1d1f;
        --td-muted: #6e6e73;
        --td-accent: #0066cc;
        --td-border: rgba(0, 0, 0, 0.12);
        --td-shadow: 0 18px 50px rgba(0, 0, 0, 0.08);
        --td-radius: 18px;
        --td-space: 1rem;
        --td-measure: 45rem;
        --td-font: ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
        }
        .td-dark-tokens, [data-theme="dark"] {
        --td-bg: #000000;
        --td-surface: rgba(28, 28, 30, 0.82);
        --td-elevated: #1c1c1e;
        --td-ink: #f5f5f7;
        --td-muted: #a1a1a6;
        --td-accent: #2997ff;
        --td-border: rgba(255, 255, 255, 0.16);
        --td-shadow: 0 18px 50px rgba(0, 0, 0, 0.36);
        }
        @media (prefers-color-scheme: dark) {
        :root:not([data-theme="light"]) {
        --td-bg: #000000;
        --td-surface: rgba(28, 28, 30, 0.82);
        --td-elevated: #1c1c1e;
        --td-ink: #f5f5f7;
        --td-muted: #a1a1a6;
        --td-accent: #2997ff;
        --td-border: rgba(255, 255, 255, 0.16);
        --td-shadow: 0 18px 50px rgba(0, 0, 0, 0.36);
        }
        }
        """

        private static let systemReset = """
        *, *::before, *::after { box-sizing: border-box; }
        body, h1, h2, h3, p, ul, ol, figure, blockquote { margin: 0; }
        ul, ol { padding-inline-start: 1.25rem; }
        """

        private static let systemBase = """
        html { background: var(--td-bg); }
        body { min-height: 100vh; background: var(--td-bg); color: var(--td-ink); font: 17px/1.58 var(--td-font); letter-spacing: 0; -webkit-font-smoothing: antialiased; text-rendering: optimizeLegibility; }
        a { color: var(--td-accent); text-decoration-thickness: 0.08em; text-underline-offset: 0.18em; }
        .td-header { position: sticky; top: 0; z-index: 1; display: flex; align-items: center; justify-content: space-between; gap: 1rem; min-height: 3.5rem; padding: 0.75rem max(1rem, calc((100vw - var(--td-measure)) / 2)); border-bottom: 1px solid var(--td-border); background: var(--td-surface); backdrop-filter: saturate(180%) blur(18px); -webkit-backdrop-filter: saturate(180%) blur(18px); }
        .td-brand { color: var(--td-ink); font-size: 0.95rem; font-weight: 700; text-decoration: none; }
        .td-nav { display: flex; flex-wrap: wrap; align-items: center; justify-content: flex-end; gap: 0.85rem; }
        .td-nav a, .td-footer a, .td-sidebar-nav a { color: var(--td-muted); font-size: 0.9rem; text-decoration: none; }
        .td-nav a:hover, .td-footer a:hover, .td-sidebar-nav a:hover { color: var(--td-accent); }
        .td-main { max-width: var(--td-measure); margin-inline: auto; padding: 5rem var(--td-space) 4rem; }
        .td-main h1 { max-width: 12ch; margin-block: 0 1.2rem; font-size: clamp(3rem, 11vw, 5.8rem); font-weight: 700; line-height: 0.98; letter-spacing: 0; }
        .td-main h2 { margin-block: 3rem 0.85rem; font-size: 1.55rem; line-height: 1.16; letter-spacing: 0; }
        .td-main h3 { margin-block: 2rem 0.5rem; font-size: 1.15rem; line-height: 1.25; letter-spacing: 0; }
        .td-main p, .td-main li { color: var(--td-muted); }
        .td-main p { margin-block: 0 1.15rem; }
        .td-main ul, .td-main ol { margin-block: 0 1.25rem; }
        .td-main strong { color: var(--td-ink); }
        .td-main blockquote { margin-block: 2rem; padding: 1.25rem; border: 1px solid var(--td-border); border-radius: var(--td-radius); background: var(--td-surface); box-shadow: var(--td-shadow); }
        .td-main code { border-radius: 0.4rem; background: var(--td-elevated); padding: 0.12rem 0.28rem; font-size: 0.92em; }
        .td-main pre { overflow: auto; border: 1px solid var(--td-border); border-radius: var(--td-radius); background: var(--td-elevated); padding: 1rem; box-shadow: var(--td-shadow); }
        .td-main img { display: block; max-width: 100%; height: auto; border-radius: var(--td-radius); box-shadow: var(--td-shadow); }
        .td-footer { border-top: 1px solid var(--td-border); background: var(--td-surface); color: var(--td-muted); }
        .td-footer-inner { display: grid; grid-template-columns: 1fr auto; gap: 1rem; max-width: var(--td-measure); margin-inline: auto; padding: 1.5rem var(--td-space); }
        .td-footer-nav, .td-socials { display: flex; flex-wrap: wrap; gap: 0.85rem; }
        .td-built { font-size: 0.9rem; }
        .td-layout-sidebar { display: grid; grid-template-columns: 17rem 1fr; min-height: 100vh; }
        .td-layout-sidebar .td-main { padding-top: 4rem; }
        .td-sidebar { position: sticky; top: 0; align-self: start; min-height: 100vh; padding: 1.25rem; border-right: 1px solid var(--td-border); background: var(--td-surface); backdrop-filter: saturate(180%) blur(18px); -webkit-backdrop-filter: saturate(180%) blur(18px); }
        .td-sidebar-nav { display: flex; flex-direction: column; gap: 0.65rem; margin-top: 1.5rem; }
        @media (max-width: 48rem) { .td-header { position: static; align-items: flex-start; flex-direction: column; } .td-main { padding-top: 3.5rem; } .td-footer-inner { grid-template-columns: 1fr; } .td-layout-sidebar { grid-template-columns: 1fr; } .td-sidebar { position: static; min-height: auto; border-right: 0; border-bottom: 1px solid var(--td-border); } }
        """
    }
}

// swiftlint:enable line_length
