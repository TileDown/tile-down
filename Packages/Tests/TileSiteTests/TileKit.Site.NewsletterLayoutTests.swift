import Testing
import TileCore
@testable import TileSite
import TileTile

extension SiteGeneratorTests {
    @Test("site newsletter renders at the end of posts and in the footer")
    func siteNewsletterRendersEndOfPostAndFooter() throws {
        let fileSystem = MemoryFileSystem(
            files: [
                "content/index.md": "---\ntitle: Home\n---\n# Home",
                "content/posts/index.md": "---\ntitle: Posts\npostList: true\n---\n# Posts",
                "content/posts/first/index.md": """
                ---
                title: First Post
                date: 2026-05-28
                ---
                # First Post

                Body.
                """,
            ],
        )

        _ = try makeGenerator(fileSystem: fileSystem).buildContent(
            .init(
                contentRootPath: "content",
                template: .layout(.topNav),
                outputRootPath: "dist",
                configuration: .init(
                    newsletter: .init(username: "tiledown", title: "TileDown Updates"),
                ),
            ),
        )

        let post = try #require(fileSystem.files["dist/posts/first/index.html"])
        let home = try #require(fileSystem.files["dist/index.html"])
        let css = try #require(fileSystem.files["dist/styles.css"])

        let endpoint = "embed-subscribe/tiledown"
        // A post renders the signup twice: end-of-post inside the article, and the
        // footer that every page carries.
        #expect(post.components(separatedBy: endpoint).count - 1 == 2)
        // A non-post page renders it once: the footer only, with no article shell.
        #expect(home.components(separatedBy: endpoint).count - 1 == 1)
        #expect(!home.contains(#"<article class="td-article">"#))
        #expect(post.contains(#"<div class="td-footer-newsletter">"#))
        // The form CSS ships in the shared stylesheet even though no page uses the
        // buttondown tile in its content.
        #expect(css.contains(".td-buttondown"))
    }
}
