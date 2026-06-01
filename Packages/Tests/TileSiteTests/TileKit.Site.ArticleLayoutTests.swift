import Testing
import TileCore
@testable import TileSite

extension SiteGeneratorTests {
    @Test("built-in layouts render dated posts with the article shell")
    func articleLayoutForPosts() throws {
        let fileSystem = articleLayoutFileSystem()
        try buildArticleLayoutFixture(fileSystem: fileSystem)

        let post = try #require(fileSystem.files["dist/posts/first/index.html"])
        assertArticleHeader(post)
        assertArticleShareLinks(post)
        assertArticleBodyAndRelatedPosts(post)

        let home = try #require(fileSystem.files["dist/index.html"])
        #expect(home.contains(#"<main class="td-main"><h1>Home</h1>"#))
        #expect(!home.contains(#"<article class="td-article">"#))

        let css = try #require(fileSystem.files["dist/styles.css"])
        #expect(css.contains(".td-article-header"))
        #expect(css.contains(".td-main .td-article-title"))
        #expect(css.contains(".td-article-share"))
        #expect(css.contains(".td-related-list"))
    }

    @Test("type front matter selects built-in article behavior")
    func articleLayoutForExplicitPostType() throws {
        let fileSystem = MemoryFileSystem(
            files: [
                "content/index.md": "---\ntitle: Home\n---\n# Home",
                "content/writing/typed/index.md": """
                ---
                title: Typed Article
                type: blog-post
                date: 2026-05-30
                description: Article selected by type.
                ---
                # Typed Article

                The article shell comes from type metadata.
                """,
                "content/posts/forced-page/index.md": """
                ---
                title: Forced Page
                type: page
                date: 2026-05-31
                ---
                # Forced Page

                This remains a standard page.
                """,
                "content/posts/unknown/index.md": """
                ---
                title: Unknown Type
                type: essay
                date: 2026-06-01
                ---
                # Unknown Type

                Unknown explicit types fall back to page behavior.
                """,
            ],
        )

        try buildArticleLayoutFixture(fileSystem: fileSystem)

        let article = try #require(fileSystem.files["dist/writing/typed/index.html"])
        #expect(article.contains(#"<article class="td-article">"#))
        #expect(article.contains(#"<span class="td-article-kicker">Blog Post</span>"#))
        #expect(article.contains(#"<h1 class="td-article-title">Typed Article</h1>"#))

        let forcedPage = try #require(fileSystem.files["dist/posts/forced-page/index.html"])
        #expect(forcedPage.contains(#"<main class="td-main"><h1>Forced Page</h1>"#))
        #expect(!forcedPage.contains(#"<article class="td-article">"#))

        let unknownType = try #require(fileSystem.files["dist/posts/unknown/index.html"])
        #expect(unknownType.contains(#"<main class="td-main"><h1>Unknown Type</h1>"#))
        #expect(!unknownType.contains(#"<article class="td-article">"#))
    }

    private func articleLayoutFileSystem() -> MemoryFileSystem {
        MemoryFileSystem(
            files: [
                "content/index.md": "---\ntitle: Home\n---\n# Home",
                "content/posts/index.md": "---\ntitle: Posts\npostList: true\n---\n# Posts",
                "content/posts/first/index.md": """
                ---
                title: First Post
                date: 2026-05-28
                kicker: Release
                description: A concise article summary for the dek.
                tags: swift, release
                image: /assets/first-light.svg
                imageDark: /assets/first-dark.svg
                ---
                # Body title that should not duplicate

                ## What changed

                The article body starts after the generated headline.
                """,
                "content/posts/second/index.md": """
                ---
                title: Second Post
                date: 2026-05-29
                description: Another post for related articles.
                ---
                # Second Post
                """,
            ],
        )
    }

    private func buildArticleLayoutFixture(
        fileSystem: MemoryFileSystem,
    ) throws {
        _ = try makeGenerator(fileSystem: fileSystem).buildContent(
            .init(
                contentRootPath: "content",
                template: .layout(.topNav),
                outputRootPath: "dist",
                configuration: .init(
                    baseURL: "https://example.com",
                    feed: .init(
                        path: "feed.xml",
                        title: "Updates",
                        description: "Project updates.",
                    ),
                    shareLinks: true,
                ),
            ),
        )
    }

    private func assertArticleHeader(
        _ post: String,
    ) {
        #expect(post.contains(#"<article class="td-article">"#))
        #expect(post.contains(#"<span class="td-article-kicker">Release</span>"#))
        #expect(post.contains(#"<time class="td-article-date">May 28, 2026</time>"#))
        #expect(post.contains(#"<h1 class="td-article-title">First Post</h1>"#))
        #expect(post.contains(#"<p class="td-article-dek">A concise article summary for the dek.</p>"#))
        #expect(post.contains(#"<nav class="td-article-actions" aria-label="Article actions">"#))
        #expect(post.contains(#"<a href="https://example.com/posts/first/">Permalink</a>"#))
        #expect(post.contains(#"<a href="https://example.com/feed.xml">RSS</a>"#))
        #expect(post.contains(#"<nav class="td-article-share" aria-label="Share article">"#))
    }

    private func assertArticleShareLinks(
        _ post: String,
    ) {
        let encodedURL = "https%3A%2F%2Fexample.com%2Fposts%2Ffirst%2F"
        let xShare = "https://twitter.com/intent/tweet?url=\(encodedURL)&amp;text=First%20Post"
        let linkedInShare = "https://www.linkedin.com/sharing/share-offsite/?url=\(encodedURL)"
        let facebookShare = "https://www.facebook.com/sharer/sharer.php?u=\(encodedURL)"
        let mailShare = "mailto:?subject=First%20Post&amp;body=\(encodedURL)"
        let shareTarget = #"target="_blank" rel="noopener""#
        #expect(post.contains(xShare))
        #expect(post.contains(linkedInShare))
        #expect(post.contains(facebookShare))
        #expect(post.contains(mailShare))
        #expect(post.contains(shareTarget))
    }

    private func assertArticleBodyAndRelatedPosts(
        _ post: String,
    ) {
        #expect(post.contains(#"<figure class="td-article-media">"#))
        #expect(post.contains(#"<span class="td-theme-image td-hero" role="img" aria-label="First Post">"#))
        #expect(post.contains(#"<nav class="td-tags td-article-tags" aria-label="Tags">"#))
        #expect(post.contains("<h2>What changed</h2>"))
        #expect(!post.contains("<h1>Body title that should not duplicate</h1>"))
        #expect(post.contains(#"<aside class="td-related" aria-label="Related articles">"#))
        #expect(post.contains(#"<a href="https://example.com/posts/second/">Second Post</a>"#))
        #expect(post.contains("<time>May 29, 2026</time>"))
    }
}
