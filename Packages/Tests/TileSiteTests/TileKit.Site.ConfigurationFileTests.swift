import Testing
import TileCore
@testable import TileSite

@Suite("Site configuration file")
struct SiteConfigurationFileTests {
    @Test("parses layout theme feed and footer social links")
    func parsesConfigurationFile() throws {
        let file = try TileKit.Site.ConfigurationFile.parse(
            """
            # Minimal site settings
            title: Minimal Demo
            baseURL: https://example.com
            layout: left-sidebar
            theme: system
            rss: true
            rssPath: feed.xml
            rssTitle: Minimal Notes
            rssDescription: Three short posts from the demo.
            social.github: https://github.com/TileDown/tile-down
            social.linkedin: https://www.linkedin.com/
            """,
        )

        #expect(file.layout == .leftSidebar)
        #expect(file.configuration.title == "Minimal Demo")
        #expect(file.configuration.baseURL == "https://example.com")
        #expect(file.configuration.theme == .system)
        #expect(
            file.configuration.feed == .init(
                path: "feed.xml",
                title: "Minimal Notes",
                description: "Three short posts from the demo.",
            ),
        )
        #expect(
            file.configuration.socialLinks == [
                .init(label: "GitHub", url: "https://github.com/TileDown/tile-down"),
                .init(label: "LinkedIn", url: "https://www.linkedin.com/"),
            ],
        )
    }

    @Test("reports unknown themes")
    func unknownTheme() {
        #expect(throws: TileKit.Site.ConfigurationFileError.unknownTheme("neon")) {
            try TileKit.Site.ConfigurationFile.parse("theme: neon")
        }
    }

    @Test("rss false disables later feed metadata")
    func rssFalseWinsOverFeedMetadata() throws {
        let file = try TileKit.Site.ConfigurationFile.parse(
            """
            rss: false
            rssPath: feed.xml
            rssTitle: Disabled Feed
            rssDescription: This should not enable RSS.
            """,
        )

        #expect(file.configuration.feed == nil)
    }

    @Test("appearance defaults to toggle and parses every mode")
    func appearance() throws {
        let defaultFile = try TileKit.Site.ConfigurationFile.parse("title: Demo")
        #expect(defaultFile.configuration.appearance == .toggle)

        for (value, expected): (String, TileKit.Site.Appearance) in [
            ("toggle", .toggle),
            ("auto", .auto),
            ("light", .light),
            ("dark", .dark),
        ] {
            let file = try TileKit.Site.ConfigurationFile.parse("appearance: \(value)")
            #expect(file.configuration.appearance == expected)
        }
    }

    @Test("an unknown appearance is a typed error")
    func unknownAppearance() {
        #expect(throws: TileKit.Site.ConfigurationFileError.unknownAppearance("sepia")) {
            try TileKit.Site.ConfigurationFile.parse("appearance: sepia")
        }
    }

    @Test("parses content generators under generate.* and orders them by name")
    func parsesContentGenerators() throws {
        let file = try TileKit.Site.ConfigurationFile.parse(
            """
            generate.zed: swift run Zed
            generate.cv: swift run GenerateCV --out content/cv/index.md
            """,
        )
        // Ordered by name (cv before zed), command split into parts.
        #expect(file.generators.map(\.name) == ["cv", "zed"])
        #expect(file.generators.first?.command == ["swift", "run", "GenerateCV", "--out", "content/cv/index.md"])
    }

    @Test("parses opt-in analytics snippets")
    func parsesAnalytics() throws {
        let file = try TileKit.Site.ConfigurationFile.parse(
            """
            analytics.head: <script defer data-domain="x.com" src="https://plausible.io/js/script.js"></script>
            analytics.bodyEnd: <noscript>no js</noscript>
            """,
        )
        #expect(file.configuration.analyticsHead.contains("plausible.io/js/script.js"))
        #expect(file.configuration.analyticsBodyEnd == "<noscript>no js</noscript>")

        // Absent by default.
        let bare = try TileKit.Site.ConfigurationFile.parse("title: Demo")
        #expect(bare.configuration.analyticsHead.isEmpty)
        #expect(bare.configuration.analyticsBodyEnd.isEmpty)
    }

    @Test("share links are an opt-in site setting")
    func parsesShareLinks() throws {
        let off = try TileKit.Site.ConfigurationFile.parse("title: Demo")
        #expect(!off.configuration.shareLinks)

        let enabled = try TileKit.Site.ConfigurationFile.parse("shareLinks: true")
        #expect(enabled.configuration.shareLinks)

        #expect(throws: TileKit.Site.ConfigurationFileError.invalidBoolean("sometimes")) {
            try TileKit.Site.ConfigurationFile.parse("shareLinks: sometimes")
        }
    }

    @Test("parses static passthrough paths")
    func parsesStaticPassthroughs() throws {
        let file = try TileKit.Site.ConfigurationFile.parse(
            """
            static.CNAME: deployment/CNAME
            static.robots.txt: deployment/robots.txt
            static.images: public/images/
            static..nojekyll: deployment/.nojekyll
            static..well-known: public/.well-known
            """,
        )

        #expect(
            file.configuration.staticPassthroughs == [
                .init(sourcePath: "deployment/CNAME", outputPath: "CNAME"),
                .init(sourcePath: "deployment/robots.txt", outputPath: "robots.txt"),
                .init(sourcePath: "public/images", outputPath: "images"),
                .init(sourcePath: "deployment/.nojekyll", outputPath: ".nojekyll"),
                .init(sourcePath: "public/.well-known", outputPath: ".well-known"),
            ],
        )
    }

    @Test("rejects unsafe static passthrough paths")
    func rejectsUnsafeStaticPassthroughPaths() {
        #expect(throws: TileKit.Site.ConfigurationFileError.invalidPath("../CNAME")) {
            try TileKit.Site.ConfigurationFile.parse("static.../CNAME: deployment/CNAME")
        }
        #expect(throws: TileKit.Site.ConfigurationFileError.invalidPath("../secret")) {
            try TileKit.Site.ConfigurationFile.parse("static.CNAME: ../secret")
        }
    }
}
