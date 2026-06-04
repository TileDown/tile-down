import Testing
import TileCore
@testable import TileSite

extension SiteGeneratorTests {
    @Test("content builds emit a deterministic sitemap")
    func contentBuildWritesSitemap() throws {
        let fileSystem = sitemapFixture()

        let result = try makeGenerator(fileSystem: fileSystem).buildContent(
            .init(
                contentRootPath: "content",
                template: .file(path: "templates/page.html"),
                outputRootPath: "dist",
                configuration: .init(
                    baseURL: "https://example.com/site",
                    theme: nil,
                ),
            ),
        )

        #expect(result.outputPaths.contains("dist/sitemap.xml"))
        let sitemap = try #require(fileSystem.files["dist/sitemap.xml"])
        #expect(sitemap == expectedSitemap)
        #expect(sitemap.contains("/legacy-note/"))
    }

    @Test("preview content builds keep drafts out of the sitemap")
    func previewContentBuildExcludesDraftsFromSitemap() throws {
        let fileSystem = sitemapFixture()

        _ = try makeGenerator(fileSystem: fileSystem).buildContent(
            .init(
                contentRootPath: "content",
                template: .file(path: "templates/page.html"),
                outputRootPath: "dist",
                configuration: .init(theme: nil),
                includeDrafts: true,
            ),
        )

        #expect(fileSystem.files["dist/posts/draft/index.html"] != nil)
        let sitemap = try #require(fileSystem.files["dist/sitemap.xml"])
        #expect(!sitemap.contains("/posts/draft/"))
    }

    private func sitemapFixture() -> MemoryFileSystem {
        MemoryFileSystem(
            files: [
                "content/index.md": "---\ntitle: Home\n---\n# Home",
                "content/about/index.md": page(title: "About", date: "2026-05-01"),
                "content/posts/live/index.md": """
                ---
                title: Live Post
                date: 2026-05-20
                tags: release
                ---
                # Live Post
                """,
                "content/posts/draft/index.md": """
                ---
                title: Draft Post
                date: 2026-05-21
                draft: true
                ---
                # Draft Post
                """,
                "content/old-post/index.md": """
                ---
                title: Old Post
                type: redirect
                to: /posts/live/
                date: 2026-05-19
                ---
                # Old Post
                """,
                "content/legacy-note/index.md": """
                ---
                title: Legacy Note
                to: /posts/live/
                date: 2026-05-18
                ---
                # Legacy Note
                """,
                "templates/page.html": "{{{ page.contents.html }}}",
            ],
        )
    }

    private func page(
        title: String,
        date: String,
    ) -> String {
        """
        ---
        title: \(title)
        date: \(date)
        ---
        # \(title)
        """
    }

    private var expectedSitemap: String {
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
        <url>
        <loc>https://example.com/site/</loc>
        </url>
        <url>
        <loc>https://example.com/site/about/</loc>
        <lastmod>2026-05-01</lastmod>
        </url>
        <url>
        <loc>https://example.com/site/legacy-note/</loc>
        <lastmod>2026-05-18</lastmod>
        </url>
        <url>
        <loc>https://example.com/site/posts/live/</loc>
        <lastmod>2026-05-20</lastmod>
        </url>
        <url>
        <loc>https://example.com/site/tags/</loc>
        </url>
        <url>
        <loc>https://example.com/site/tags/release/</loc>
        </url>
        </urlset>

        """
    }
}
