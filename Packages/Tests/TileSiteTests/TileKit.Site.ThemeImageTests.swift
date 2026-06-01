import Testing
import TileCore
import TileMarkdown
import TileOutput
@testable import TileSite
import TileSource
import TileTemplate
import TileTile

@Suite("Site theme images")
struct SiteThemeImageTests {
    @Test("built-in layouts render theme-aware hero images")
    func themeAwareHeroImage() throws {
        let fileSystem = MemoryFileSystem(
            files: [
                "content/index.md": """
                ---
                title: Home
                image: /assets/hero-light.png
                imageDark: /assets/hero-dark.png
                ---
                # Home
                """,
            ],
        )

        _ = try makeGenerator(fileSystem: fileSystem).buildContent(
            .init(
                contentRootPath: "content",
                template: .layout(.topNav),
                outputRootPath: "dist",
            ),
        )

        let home = try #require(fileSystem.files["dist/index.html"])
        #expect(home.contains(#"<span class="td-theme-image td-hero" role="img" aria-label="Home">"#))
        #expect(home.contains(
            #"<img class="td-theme-image-light" src="/assets/hero-light.png" alt="" aria-hidden="true">"#,
        ))
        #expect(home.contains(
            #"<img class="td-theme-image-dark" src="/assets/hero-dark.png" alt="" aria-hidden="true">"#,
        ))

        let css = try #require(fileSystem.files["dist/styles.css"])
        #expect(css.contains(#"[data-theme="dark"] .td-theme-image .td-theme-image-light"#))
        #expect(css.contains("prefers-color-scheme: dark"))
        #expect(css.contains(".td-main .td-theme-image.td-hero { display: block; }"))
        #expect(css.contains("max-height: clamp(14rem, 38vh, 24rem)"))
        #expect(css.contains("margin: 0 auto clamp(3rem, 7vw, 5rem);"))
    }

    @Test("single hero images keep the plain image markup")
    func singleHeroImageMarkup() throws {
        let fileSystem = MemoryFileSystem(
            files: [
                "content/index.md": """
                ---
                title: Home
                image: /assets/hero.png
                ---
                # Home
                """,
            ],
        )

        _ = try makeGenerator(fileSystem: fileSystem).buildContent(
            .init(
                contentRootPath: "content",
                template: .layout(.topNav),
                outputRootPath: "dist",
            ),
        )

        let home = try #require(fileSystem.files["dist/index.html"])
        #expect(home.contains(#"<img class="td-hero" src="/assets/hero.png" alt="Home">"#))
        #expect(!home.contains("td-theme-image"))
    }

    @Test("built-in layouts omit hero media when no image field is present")
    func noHeroImageMarkup() throws {
        let fileSystem = MemoryFileSystem(
            files: [
                "content/index.md": """
                ---
                title: Home
                ---
                # Home
                """,
            ],
        )

        _ = try makeGenerator(fileSystem: fileSystem).buildContent(
            .init(
                contentRootPath: "content",
                template: .layout(.topNav),
                outputRootPath: "dist",
            ),
        )

        let home = try #require(fileSystem.files["dist/index.html"])
        #expect(!home.contains(#"class="td-hero""#))
        #expect(!home.contains("td-theme-image"))
    }

    @Test("hero front matter falls back to built-in hero image")
    func heroFrontMatterFallback() throws {
        let fileSystem = MemoryFileSystem(
            files: [
                "content/index.md": """
                ---
                title: Home
                hero: /assets/home-hero.png
                ---
                # Home
                """,
            ],
        )

        _ = try makeGenerator(fileSystem: fileSystem).buildContent(
            .init(
                contentRootPath: "content",
                template: .layout(.topNav),
                outputRootPath: "dist",
            ),
        )

        let home = try #require(fileSystem.files["dist/index.html"])
        #expect(home.contains(#"<img class="td-hero" src="/assets/home-hero.png" alt="Home">"#))
    }

    @Test("image front matter wins over hero fallback")
    func imageFrontMatterPrecedence() throws {
        let fileSystem = MemoryFileSystem(
            files: [
                "content/index.md": """
                ---
                title: Home
                image: /assets/canonical.png
                hero: /assets/migration.png
                ---
                # Home
                """,
            ],
        )

        _ = try makeGenerator(fileSystem: fileSystem).buildContent(
            .init(
                contentRootPath: "content",
                template: .layout(.topNav),
                outputRootPath: "dist",
            ),
        )

        let home = try #require(fileSystem.files["dist/index.html"])
        #expect(home.contains(#"<img class="td-hero" src="/assets/canonical.png" alt="Home">"#))
        #expect(!home.contains(#"/assets/migration.png"#))
    }

    @Test("theme-aware images escape generated attributes")
    func themeAwareImageEscaping() throws {
        let fileSystem = MemoryFileSystem(
            files: [
                "content/index.md": """
                ---
                title: A "B" & <C>
                image: /assets/hero"light.png
                imageDark: /assets/hero&dark.png
                ---
                # Home
                """,
            ],
        )

        _ = try makeGenerator(fileSystem: fileSystem).buildContent(
            .init(
                contentRootPath: "content",
                template: .layout(.topNav),
                outputRootPath: "dist",
            ),
        )

        let home = try #require(fileSystem.files["dist/index.html"])
        #expect(home.contains(#"aria-label="A &quot;B&quot; &amp; &lt;C&gt;""#))
        #expect(home.contains(#"src="/assets/hero&quot;light.png""#))
        #expect(home.contains(#"src="/assets/hero&amp;dark.png""#))
    }

    @Test("post cards use theme-aware thumbnail images")
    func themeAwarePostCardThumbnail() throws {
        let fileSystem = MemoryFileSystem(
            files: [
                "content/index.md": "---\ntitle: Home\n---\n# Home",
                "content/posts/index.md": "---\ntitle: Posts\npostList: true\n---\n# Posts",
                "content/posts/first/index.md": """
                ---
                title: First
                date: 2026-05-01
                image: /assets/first-light.png
                imageDark: /assets/first-dark.png
                ---
                # First
                """,
            ],
        )

        _ = try makeGenerator(fileSystem: fileSystem).buildContent(
            .init(
                contentRootPath: "content",
                template: .layout(.topNav),
                outputRootPath: "dist",
            ),
        )

        let listing = try #require(fileSystem.files["dist/posts/index.html"])
        #expect(listing.contains(
            #"<span class="td-theme-image td-post-thumb-image" role="img" aria-label="First">"#,
        ))
        #expect(listing.contains(
            #"<img class="td-theme-image-light" src="/assets/first-light.png" alt="" aria-hidden="true">"#,
        ))
        #expect(listing.contains(
            #"<img class="td-theme-image-dark" src="/assets/first-dark.png" alt="" aria-hidden="true">"#,
        ))
    }

    @Test("post cards and articles use hero front matter fallback")
    func postCardAndArticleHeroFallback() throws {
        let fileSystem = MemoryFileSystem(
            files: [
                "content/index.md": "---\ntitle: Home\n---\n# Home",
                "content/posts/index.md": "---\ntitle: Posts\npostList: true\n---\n# Posts",
                "content/posts/first/index.md": """
                ---
                title: First
                date: 2026-05-01
                hero: /assets/first-hero.png
                ---
                # First
                """,
            ],
        )

        _ = try makeGenerator(fileSystem: fileSystem).buildContent(
            .init(
                contentRootPath: "content",
                template: .layout(.topNav),
                outputRootPath: "dist",
            ),
        )

        let listing = try #require(fileSystem.files["dist/posts/index.html"])
        #expect(listing.contains(
            #"<img class="td-post-thumb-image" src="/assets/first-hero.png" alt="First">"#,
        ))

        let article = try #require(fileSystem.files["dist/posts/first/index.html"])
        let expectedHero = [
            #"<figure class="td-article-media">"#,
            #"<img class="td-hero" src="/assets/first-hero.png" alt="First">"#,
            "</figure>",
        ].joined()
        #expect(article.contains(expectedHero))
    }

    private func makeGenerator(
        fileSystem: MemoryFileSystem,
    ) -> TileKit.Site.Generator {
        .init(
            fileSystem: fileSystem,
            markdownParser: TileKit.Source.FrontMatterParser(),
            tileParser: TileKit.Tile.DirectiveParser(),
            htmlRenderer: TileKit.Output.HTMLRenderer(
                markdownRenderer: TileKit.Markdown.CommonMarkRenderer(),
                tileRegistry: .init(),
            ),
            templateRenderer: TileKit.Template.SimpleMustacheRenderer(),
            contentDiscovery: TileKit.Source.IndexContentDiscovery(),
        )
    }
}
