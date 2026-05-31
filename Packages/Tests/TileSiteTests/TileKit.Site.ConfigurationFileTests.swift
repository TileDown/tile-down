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
}
