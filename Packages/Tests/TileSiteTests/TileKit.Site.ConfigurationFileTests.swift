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
            generate.cv: swift run GenerateCV --title "My CV" --out 'content/cv page/index.md'
            generate.escaped: printf escaped\\ value
            """,
        )
        // Ordered by name (cv before zed), command split into parts.
        #expect(file.generators.map(\.name) == ["cv", "escaped", "zed"])
        #expect(
            file.generators.first?.command == [
                "swift",
                "run",
                "GenerateCV",
                "--title",
                "My CV",
                "--out",
                "content/cv page/index.md",
            ],
        )
        #expect(file.generators[1].command == ["printf", "escaped value"])
    }

    @Test("rejects malformed content generator commands")
    func rejectsMalformedContentGeneratorCommands() {
        #expect(throws: TileKit.Site.ConfigurationFileError.invalidGeneratorCommand(#"swift run "broken"#)) {
            try TileKit.Site.ConfigurationFile.parse(#"generate.cv: swift run "broken"#)
        }

        #expect(throws: TileKit.Site.ConfigurationFileError.invalidGeneratorCommand(#"swift run \"#)) {
            try TileKit.Site.ConfigurationFile.parse(#"generate.cv: swift run \"#)
        }
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

    @Test("parses 404 fallback redirect rules")
    func parsesNotFoundRedirects() throws {
        let file = try TileKit.Site.ConfigurationFile.parse(
            """
            notFoundRedirect.exact./cvbuilder: /blog/c-v-builder/
            notFoundRedirect.exact./external: https://codeweaver.info/
            notFoundRedirect.prefix./tag/: /
            """,
        )

        #expect(
            try file.configuration.notFoundRedirects.exact == [
                .init(source: "/cvbuilder", target: "/blog/c-v-builder/"),
                .init(source: "/external", target: "https://codeweaver.info/"),
            ],
        )
        #expect(
            try file.configuration.notFoundRedirects.prefixes == [
                .init(source: "/tag/", target: "/"),
            ],
        )
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

    @Test("rejects unsafe 404 fallback redirect rules")
    func rejectsUnsafeNotFoundRedirects() {
        #expect(throws: TileKit.Site.ConfigurationFileError.invalidRedirectPath("tag")) {
            try TileKit.Site.ConfigurationFile.parse("notFoundRedirect.prefix.tag: /")
        }
        #expect(throws: TileKit.Site.ConfigurationFileError.invalidRedirectTarget("http://example.com")) {
            try TileKit.Site.ConfigurationFile.parse("notFoundRedirect.exact./old: http://example.com")
        }
        #expect(throws: TileKit.Site.ConfigurationFileError.invalidRedirectPath("//example.com")) {
            try TileKit.Site.ConfigurationFile.parse("notFoundRedirect.exact./old: //example.com")
        }
        #expect(throws: TileKit.Site.ConfigurationFileError.invalidRedirectTarget("https://example.com/\\old")) {
            try TileKit.Site.ConfigurationFile.parse("notFoundRedirect.exact./old: https://example.com/\\old")
        }
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

    @Test("rejects static passthrough output URL syntax characters", arguments: [
        "images?preview",
        "images#hero",
        "images%2Fhero",
        #"images\hero"#,
        "images\u{0007}hero",
    ])
    func rejectsStaticPassthroughOutputURLSyntaxCharacters(outputPath: String) {
        #expect(throws: TileKit.Site.ConfigurationFileError.invalidPath(outputPath)) {
            try TileKit.Site.ConfigurationFile.parse("static.\(outputPath): public/images")
        }
    }

    @Test("parses theme property overrides")
    func parsesThemeProperties() throws {
        let file = try TileKit.Site.ConfigurationFile.parse(
            """
            theme.light.accent: #0057d8
            theme.light.surface: rgba(255, 255, 255, 0.92)
            theme.dark.accent: #66aaff
            theme.dark.font: ui-serif, Georgia, serif
            """,
        )

        let expected = try TileKit.Site.ThemeProperties(
            light: [
                "accent": "#0057d8",
                "surface": "rgba(255, 255, 255, 0.92)",
            ],
            dark: [
                "accent": "#66aaff",
                "font": "ui-serif, Georgia, serif",
            ],
        )
        #expect(file.configuration.themeProperties == expected)
    }

    @Test("rejects unknown or unsafe theme property overrides")
    func rejectsBadThemeProperties() {
        #expect(throws: TileKit.Site.ConfigurationFileError.unknownThemeProperty("brand")) {
            try TileKit.Site.ConfigurationFile.parse("theme.light.brand: #123456")
        }

        #expect(throws: TileKit.Site.ConfigurationFileError.invalidThemePropertyValue("red; body { color: blue }")) {
            try TileKit.Site.ConfigurationFile.parse("theme.dark.accent: red; body { color: blue }")
        }

        #expect(throws: TileKit.Site.ConfigurationFileError.invalidThemePropertyValue("red /* broken")) {
            try TileKit.Site.ConfigurationFile.parse("theme.dark.accent: red /* broken")
        }
    }
}
