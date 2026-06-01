// swiftlint:disable line_length type_body_length
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
        --td-mono: ui-monospace, "SF Mono", Menlo, Monaco, Consolas, "Liberation Mono", monospace;
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
        body { background: var(--td-bg); color: var(--td-ink); font: 1rem/1.6 var(--td-font); -webkit-font-smoothing: antialiased; }
        a { color: var(--td-accent); }
        .td-header, .td-main, .td-content { max-width: var(--td-measure); margin-inline: auto; padding-inline: var(--td-space); }
        .td-header { display: flex; align-items: center; justify-content: space-between; gap: var(--td-space); padding-block: 1.25rem; border-bottom: 1px solid var(--td-border); }
        .td-brand { font-weight: 700; font-size: 1.25rem; color: var(--td-ink); text-decoration: none; }
        .td-nav { display: flex; gap: 1.25rem; flex-wrap: wrap; align-items: center; }
        .td-nav a, .td-footer a { color: var(--td-muted); text-decoration: none; }
        .td-nav a:hover, .td-footer a:hover { color: var(--td-ink); }
        .td-nav a[aria-current="page"] { color: var(--td-ink); font-weight: 700; }
        .td-theme-toggle { cursor: pointer; border: 1px solid var(--td-border); border-radius: var(--td-radius); background: var(--td-surface); color: var(--td-ink); padding: 0.35rem 0.6rem; font: inherit; line-height: 1; }
        .td-theme-toggle:hover { border-color: var(--td-accent); color: var(--td-accent); }
        .td-main { padding-block: 2.5rem; }
        .td-main h1 { font-size: 2rem; font-weight: 800; line-height: 1.1; letter-spacing: -0.02em; margin-block: 0 1rem; }
        .td-main h2 { font-size: 1.5rem; margin-block: 2.5rem 0.75rem; }
        .td-main p { margin-block: 0 1.25rem; }
        .td-main code { font-family: var(--td-mono); font-size: 0.92em; background: var(--td-surface); border: 1px solid var(--td-border); border-radius: 0.3rem; padding: 0.12em 0.4em; }
        .td-main pre { font-family: var(--td-mono); font-size: 0.875rem; line-height: 1.6; background: var(--td-surface); border: 1px solid var(--td-border); border-radius: var(--td-radius); padding: 1rem 1.25rem; margin-block: 0 1.5rem; overflow-x: auto; }
        .td-main pre code { background: none; border: 0; border-radius: 0; padding: 0; font-size: inherit; }
        .td-main img { display: block; max-width: 100%; max-height: 30rem; width: auto; height: auto; margin-inline: auto; border-radius: var(--td-radius); }
        .td-theme-image .td-theme-image-dark { display: none; }
        [data-theme="dark"] .td-theme-image .td-theme-image-light { display: none; }
        [data-theme="dark"] .td-theme-image .td-theme-image-dark { display: block; }
        @media (prefers-color-scheme: dark) { :root:not([data-theme="light"]) .td-theme-image .td-theme-image-light { display: none; } :root:not([data-theme="light"]) .td-theme-image .td-theme-image-dark { display: block; } }
        .td-main table { width: 100%; border-collapse: collapse; margin-block: 0 1.5rem; font-size: 0.95rem; }
        .td-main th, .td-main td { padding: 0.5rem 0.75rem; border: 1px solid var(--td-border); }
        .td-main thead th { background: var(--td-surface); font-weight: 700; }
        .td-main .td-hero { display: block; width: auto; max-width: 100%; max-height: clamp(14rem, 38vh, 24rem); object-fit: contain; margin: 0 auto clamp(3rem, 7vw, 5rem); }
        .td-main .td-theme-image.td-hero { display: block; }
        .td-main .td-theme-image.td-hero img { width: auto; max-width: 100%; max-height: clamp(14rem, 38vh, 24rem); object-fit: contain; margin: 0 auto; }
        .td-article { display: block; }
        .td-article-header { margin-block: 0 clamp(2.5rem, 7vw, 4.5rem); }
        .td-article-meta { display: flex; flex-wrap: wrap; gap: 0.6rem 1rem; align-items: center; margin-block: 0 1rem; color: var(--td-muted); font-size: 0.84rem; font-weight: 700; text-transform: uppercase; }
        .td-article-date { color: var(--td-muted); font-weight: 600; text-transform: none; }
        .td-main .td-article-title { max-width: 13ch; margin-block: 0 1.25rem; font-size: clamp(2.45rem, 8vw, 5rem); line-height: 0.98; letter-spacing: 0; }
        .td-article-dek { max-width: 40rem; color: var(--td-muted); font-size: clamp(1.15rem, 2.8vw, 1.65rem); line-height: 1.28; }
        .td-article-actions, .td-article-share { display: flex; flex-wrap: wrap; gap: 0.65rem; margin-block: 1.6rem 0; }
        .td-article-share { margin-block-start: 0.8rem; }
        .td-article-actions a, .td-article-share a { display: inline-flex; align-items: center; min-height: 2.35rem; padding: 0.4rem 0.9rem; border: 1px solid var(--td-border); border-radius: 999px; background: var(--td-surface); color: var(--td-ink); font-size: 0.9rem; font-weight: 700; text-decoration: none; }
        .td-article-actions a:hover, .td-article-share a:hover { border-color: var(--td-accent); color: var(--td-accent); }
        .td-article-tags { margin-block: 1.1rem 0; }
        .td-article-media { margin-block: 0 clamp(2rem, 6vw, 4rem); }
        .td-main .td-article-media .td-hero { max-height: clamp(18rem, 54vh, 34rem); margin: 0 auto; }
        .td-main .td-article-media .td-theme-image.td-hero img { max-height: clamp(18rem, 54vh, 34rem); }
        .td-article-body { max-width: 39rem; margin-inline: auto; }
        .td-article-body > :first-child { margin-top: 0; }
        .td-related { margin-block: clamp(3rem, 8vw, 5rem) 0; padding-block: 1.5rem 0; border-top: 1px solid var(--td-border); }
        .td-related h2 { margin-block: 0 1rem; font-size: 1.15rem; }
        .td-related-list { list-style: none; display: grid; gap: 0.9rem; padding: 0; margin: 0; }
        .td-related-list li { display: grid; gap: 0.15rem; padding-block: 0.85rem; border-bottom: 1px solid var(--td-border); }
        .td-related-list a { color: var(--td-ink); font-weight: 700; text-decoration: none; }
        .td-related-list a:hover { color: var(--td-accent); }
        .td-related-list time { color: var(--td-muted); font-size: 0.86rem; }
        .td-posts { list-style: none; padding: 6rem 0 0; margin: 0; display: flex; flex-direction: column; gap: 3rem; }
        .td-post-card { display: grid; grid-template-columns: 8rem 1fr; gap: 1.25rem; align-items: start; }
        .td-posts .td-post-thumb img { width: 8rem; height: 6rem; object-fit: cover; border-radius: var(--td-radius); margin: 0; }
        .td-posts .td-post-thumb .td-theme-image { display: block; width: 8rem; height: 6rem; }
        .td-posts .td-post-thumb .td-theme-image img { width: 100%; height: 100%; object-fit: cover; }
        .td-post-body { min-width: 0; }
        .td-main .td-post-title { margin: 0 0 0.25rem; font-size: 1.2rem; }
        .td-post-title a { color: var(--td-ink); text-decoration: none; }
        .td-post-date { display: block; color: var(--td-muted); font-size: 0.85rem; margin-bottom: 0.4rem; }
        .td-post-desc { margin: 0; color: var(--td-muted); }
        .td-empty { margin-block: 2rem 0; color: var(--td-muted); }
        @media (max-width: 36rem) { .td-post-card { grid-template-columns: 1fr; } .td-post-thumb img { width: 100%; height: auto; } .td-posts .td-post-thumb .td-theme-image { width: 100%; height: auto; } .td-posts .td-post-thumb .td-theme-image img { height: auto; } }
        .td-tags { display: flex; flex-wrap: wrap; align-items: center; gap: 0.5rem; margin-block: 1.75rem 0; padding: 0; list-style: none; }
        .td-tag { display: inline-block; padding: 0.2rem 0.7rem; border-radius: 999px; background: var(--td-surface); border: 1px solid var(--td-border); color: var(--td-muted); font-size: 0.8rem; line-height: 1.5; text-decoration: none; }
        .td-tag:hover { color: var(--td-ink); border-color: var(--td-accent); }
        .td-tags-card { margin-block: 0.6rem 0; gap: 0.4rem; }
        .td-tags-card .td-tag { font-size: 0.72rem; padding: 0.1rem 0.55rem; }
        .td-tagbar-title { text-align: center; margin: 0 0 1.25rem; }
        .td-tagbar { position: sticky; top: 3.5rem; z-index: 1; display: flex; flex-wrap: wrap; gap: 0.6rem; margin: 0 0 1.75rem; padding: 0.85rem 0; background: var(--td-surface); border-bottom: 1px solid var(--td-border); backdrop-filter: saturate(180%) blur(18px); -webkit-backdrop-filter: saturate(180%) blur(18px); }
        .td-tagbar .td-tag-lg { font-size: 1.05rem; padding: 0.5rem 1.1rem; }
        .td-tagbar .td-tag-current { color: var(--td-ink); border-color: var(--td-accent); font-weight: 600; }
        .td-tagbar .td-tag-clear { color: #fff; background: var(--td-accent); border-color: var(--td-accent); font-weight: 700; }
        .td-tagbar .td-tag-clear:hover { color: #fff; filter: brightness(1.1); }
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
        --td-mono: ui-monospace, "SF Mono", Menlo, Monaco, Consolas, "Liberation Mono", monospace;
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
        body { min-height: 100vh; background: var(--td-bg); color: var(--td-ink); font: 1.0625rem/1.58 var(--td-font); letter-spacing: 0; -webkit-font-smoothing: antialiased; text-rendering: optimizeLegibility; }
        a { color: var(--td-accent); text-decoration-thickness: 0.08em; text-underline-offset: 0.18em; }
        .td-header { position: sticky; top: 0; z-index: 1; display: flex; align-items: center; justify-content: space-between; gap: 1rem; min-height: 3.5rem; padding: 0.75rem max(1rem, calc((100vw - var(--td-measure)) / 2)); border-bottom: 1px solid var(--td-border); background: var(--td-surface); backdrop-filter: saturate(180%) blur(18px); -webkit-backdrop-filter: saturate(180%) blur(18px); }
        .td-brand { color: var(--td-ink); font-size: 0.95rem; font-weight: 700; text-decoration: none; }
        .td-nav { display: flex; flex-wrap: wrap; align-items: center; justify-content: flex-end; gap: 0.85rem; }
        .td-nav a, .td-footer a, .td-sidebar-nav a { color: var(--td-muted); font-size: 0.9rem; text-decoration: none; }
        .td-nav a:hover, .td-footer a:hover, .td-sidebar-nav a:hover { color: var(--td-accent); }
        .td-nav a[aria-current="page"], .td-sidebar-nav a[aria-current="page"] { color: var(--td-ink); font-weight: 700; }
        .td-theme-toggle { cursor: pointer; border: 1px solid var(--td-border); border-radius: var(--td-radius); background: var(--td-surface); color: var(--td-ink); padding: 0.4rem 0.65rem; font: inherit; font-size: 0.9rem; line-height: 1; }
        .td-theme-toggle:hover { border-color: var(--td-accent); color: var(--td-accent); }
        .td-main { max-width: var(--td-measure); margin-inline: auto; padding: clamp(3rem, 7vh, 5rem) var(--td-space) 4rem; }
        .td-main h1 { max-width: 20ch; margin-block: 0 1.2rem; font-size: clamp(1.9rem, 4vw, 2.6rem); font-weight: 700; line-height: 1.05; letter-spacing: 0; }
        .td-main h2 { margin-block: 3rem 0.85rem; font-size: 1.55rem; line-height: 1.16; letter-spacing: 0; }
        .td-main h3 { margin-block: 2rem 0.5rem; font-size: 1.15rem; line-height: 1.25; letter-spacing: 0; }
        .td-main p, .td-main li { color: var(--td-muted); }
        .td-main p { margin-block: 0 1.15rem; }
        .td-main ul, .td-main ol { margin-block: 0 1.25rem; }
        .td-main strong { color: var(--td-ink); }
        .td-main blockquote { margin-block: 2rem; padding: 1.25rem; border: 1px solid var(--td-border); border-radius: var(--td-radius); background: var(--td-surface); box-shadow: var(--td-shadow); }
        .td-main code { font-family: var(--td-mono); border-radius: 0.4rem; background: var(--td-elevated); border: 1px solid var(--td-border); padding: 0.12em 0.4em; font-size: 0.92em; }
        .td-main pre { font-family: var(--td-mono); font-size: 0.875rem; line-height: 1.6; overflow-x: auto; border: 1px solid var(--td-border); border-radius: var(--td-radius); background: var(--td-elevated); padding: 1rem 1.25rem; margin-block: 0 1.5rem; box-shadow: var(--td-shadow); }
        .td-main pre code { background: none; border: 0; border-radius: 0; padding: 0; font-size: inherit; box-shadow: none; }
        .td-main img { display: block; max-width: 100%; max-height: 30rem; width: auto; height: auto; margin-inline: auto; border-radius: var(--td-radius); box-shadow: var(--td-shadow); }
        .td-theme-image .td-theme-image-dark { display: none; }
        [data-theme="dark"] .td-theme-image .td-theme-image-light { display: none; }
        [data-theme="dark"] .td-theme-image .td-theme-image-dark { display: block; }
        @media (prefers-color-scheme: dark) { :root:not([data-theme="light"]) .td-theme-image .td-theme-image-light { display: none; } :root:not([data-theme="light"]) .td-theme-image .td-theme-image-dark { display: block; } }
        .td-main table { width: 100%; border-collapse: collapse; margin-block: 0 1.5rem; font-size: 0.95rem; }
        .td-main th, .td-main td { padding: 0.55rem 0.8rem; border-bottom: 1px solid var(--td-border); }
        .td-main thead th { color: var(--td-ink); font-weight: 700; border-bottom-width: 2px; }
        .td-main .td-hero { display: block; width: auto; max-width: 100%; max-height: clamp(14rem, 38vh, 24rem); object-fit: contain; margin: 0 auto clamp(3rem, 7vw, 5rem); }
        .td-main .td-theme-image.td-hero { display: block; }
        .td-main .td-theme-image.td-hero img { width: auto; max-width: 100%; max-height: clamp(14rem, 38vh, 24rem); object-fit: contain; margin: 0 auto; }
        .td-article { display: block; }
        .td-article-header { margin-block: 0 clamp(2.5rem, 7vw, 4.5rem); }
        .td-article-meta { display: flex; flex-wrap: wrap; gap: 0.6rem 1rem; align-items: center; margin-block: 0 1rem; color: var(--td-muted); font-size: 0.84rem; font-weight: 700; text-transform: uppercase; }
        .td-article-date { color: var(--td-muted); font-weight: 600; text-transform: none; }
        .td-main .td-article-title { max-width: 13ch; margin-block: 0 1.25rem; font-size: clamp(2.45rem, 8vw, 5rem); line-height: 0.98; letter-spacing: 0; }
        .td-article-dek { max-width: 40rem; color: var(--td-muted); font-size: clamp(1.15rem, 2.8vw, 1.65rem); line-height: 1.28; }
        .td-article-actions, .td-article-share { display: flex; flex-wrap: wrap; gap: 0.65rem; margin-block: 1.6rem 0; }
        .td-article-share { margin-block-start: 0.8rem; }
        .td-article-actions a, .td-article-share a { display: inline-flex; align-items: center; min-height: 2.35rem; padding: 0.4rem 0.95rem; border: 1px solid var(--td-border); border-radius: 999px; background: var(--td-elevated); color: var(--td-ink); font-size: 0.9rem; font-weight: 700; text-decoration: none; box-shadow: none; }
        .td-article-actions a:hover, .td-article-share a:hover { border-color: var(--td-accent); color: var(--td-accent); }
        .td-article-tags { margin-block: 1.1rem 0; }
        .td-article-media { margin-block: 0 clamp(2rem, 6vw, 4rem); }
        .td-main .td-article-media .td-hero { max-height: clamp(18rem, 54vh, 34rem); margin: 0 auto; }
        .td-main .td-article-media .td-theme-image.td-hero img { max-height: clamp(18rem, 54vh, 34rem); }
        .td-article-body { max-width: 39rem; margin-inline: auto; }
        .td-article-body > :first-child { margin-top: 0; }
        .td-related { margin-block: clamp(3rem, 8vw, 5rem) 0; padding-block: 1.5rem 0; border-top: 1px solid var(--td-border); }
        .td-related h2 { margin-block: 0 1rem; font-size: 1.15rem; }
        .td-related-list { list-style: none; display: grid; gap: 0.9rem; padding: 0; margin: 0; }
        .td-related-list li { display: grid; gap: 0.15rem; padding-block: 0.85rem; border-bottom: 1px solid var(--td-border); }
        .td-related-list a { color: var(--td-ink); font-weight: 700; text-decoration: none; }
        .td-related-list a:hover { color: var(--td-accent); }
        .td-related-list time { color: var(--td-muted); font-size: 0.86rem; }
        .td-posts { list-style: none; padding: 6rem 0 0; margin: 0; display: flex; flex-direction: column; gap: 3rem; }
        .td-post-card { display: grid; grid-template-columns: 9rem 1fr; gap: 1.25rem; align-items: start; }
        .td-posts .td-post-thumb img { width: 9rem; height: 6.5rem; object-fit: cover; border-radius: var(--td-radius); margin: 0; box-shadow: var(--td-shadow); }
        .td-posts .td-post-thumb .td-theme-image { display: block; width: 9rem; height: 6.5rem; }
        .td-posts .td-post-thumb .td-theme-image img { width: 100%; height: 100%; object-fit: cover; }
        .td-post-body { min-width: 0; }
        .td-main .td-post-title { margin: 0 0 0.25rem; font-size: 1.25rem; }
        .td-post-title a { color: var(--td-ink); text-decoration: none; }
        .td-post-date { display: block; color: var(--td-muted); font-size: 0.85rem; margin-bottom: 0.4rem; }
        .td-post-desc { margin: 0; color: var(--td-muted); }
        .td-empty { margin-block: 2rem 0; color: var(--td-muted); }
        @media (max-width: 36rem) { .td-post-card { grid-template-columns: 1fr; } .td-post-thumb img { width: 100%; height: auto; } .td-posts .td-post-thumb .td-theme-image { width: 100%; height: auto; } .td-posts .td-post-thumb .td-theme-image img { height: auto; } }
        .td-tags { display: flex; flex-wrap: wrap; align-items: center; gap: 0.5rem; margin-block: 1.75rem 0; padding: 0; list-style: none; }
        .td-tag { display: inline-block; padding: 0.2rem 0.7rem; border-radius: 999px; background: var(--td-surface); border: 1px solid var(--td-border); color: var(--td-muted); font-size: 0.8rem; line-height: 1.5; text-decoration: none; }
        .td-tag:hover { color: var(--td-ink); border-color: var(--td-accent); }
        .td-tags-card { margin-block: 0.6rem 0; gap: 0.4rem; }
        .td-tags-card .td-tag { font-size: 0.72rem; padding: 0.1rem 0.55rem; }
        .td-tagbar-title { text-align: center; margin: 0 0 1.25rem; }
        .td-tagbar { position: sticky; top: 3.5rem; z-index: 1; display: flex; flex-wrap: wrap; gap: 0.6rem; margin: 0 0 1.75rem; padding: 0.85rem 0; background: var(--td-surface); border-bottom: 1px solid var(--td-border); backdrop-filter: saturate(180%) blur(18px); -webkit-backdrop-filter: saturate(180%) blur(18px); }
        .td-tagbar .td-tag-lg { font-size: 1.05rem; padding: 0.5rem 1.1rem; }
        .td-tagbar .td-tag-current { color: var(--td-ink); border-color: var(--td-accent); font-weight: 600; }
        .td-tagbar .td-tag-clear { color: #fff; background: var(--td-accent); border-color: var(--td-accent); font-weight: 700; }
        .td-tagbar .td-tag-clear:hover { color: #fff; filter: brightness(1.1); }
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

// swiftlint:enable line_length type_body_length
