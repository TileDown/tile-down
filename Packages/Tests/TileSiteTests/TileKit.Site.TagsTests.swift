import Testing
import TileCore
import TileMarkdown
import TileOutput
@testable import TileSite
import TileSource
import TileTemplate
import TileTile

@Suite("Tags")
struct SiteTagsTests {
    @Test("a tag page lists exactly that tag's posts, newest first")
    func tagPageListsItsPosts() throws {
        let fileSystem = MemoryFileSystem(files: taggedFixtureFiles())

        _ = try makeGenerator(fileSystem: fileSystem).buildContent(
            .init(
                contentRootPath: "content",
                template: .file(path: "templates/page.html"),
                outputRootPath: "dist",
                configuration: .init(theme: nil),
            ),
        )

        // /tags/swift/ has both swift posts, newest (Beta, 05-30) before older
        // (Alpha, 05-28), and not the untagged post.
        let swift = try #require(fileSystem.files["dist/tags/swift/index.html"])
        let beta = try #require(swift.range(of: "<li>Beta</li>")?.lowerBound)
        let alpha = try #require(swift.range(of: "<li>Alpha</li>")?.lowerBound)
        #expect(beta < alpha)
        #expect(!swift.contains("<li>Gamma</li>"))

        // /tags/ios/ has only the one ios post.
        let ios = try #require(fileSystem.files["dist/tags/ios/index.html"])
        #expect(ios.contains("<li>Alpha</li>"))
        #expect(!ios.contains("<li>Beta</li>"))
        #expect(!ios.contains("<li>Gamma</li>"))
    }

    @Test("an untagged post produces no tag page and appears on none")
    func untaggedPostHasNoTagPage() throws {
        let fileSystem = MemoryFileSystem(
            files: [
                "content/index.md": "---\ntitle: Home\n---\n# Home",
                "content/posts/index.md": "---\ntitle: Posts\n---\n# Posts",
                "content/posts/lonely/index.md": "---\ntitle: Lonely\ndate: 2026-05-20\n---\n# Lonely",
                "templates/page.html": tagListingTemplate(),
            ],
        )

        _ = try makeGenerator(fileSystem: fileSystem).buildContent(
            .init(
                contentRootPath: "content",
                template: .file(path: "templates/page.html"),
                outputRootPath: "dist",
                configuration: .init(theme: nil),
            ),
        )

        // No tags anywhere, so no tag pages are synthesized.
        let tagPages = fileSystem.files.keys.filter { $0.hasPrefix("dist/tags/") }
        #expect(tagPages.isEmpty)
    }

    @Test("site.tags and per-post tags are exposed to templates")
    func exposesTags() throws {
        var files = taggedFixtureFiles()
        files["templates/page.html"] = "{{#site.tags}}{{name}}:{{count}} {{/site.tags}}"
        let fileSystem = MemoryFileSystem(files: files)

        _ = try makeGenerator(fileSystem: fileSystem).buildContent(
            .init(
                contentRootPath: "content",
                template: .file(path: "templates/page.html"),
                outputRootPath: "dist",
                configuration: .init(theme: nil),
            ),
        )

        // Tags are ordered by slug (ios before swift) with per-tag post counts.
        let home = try #require(fileSystem.files["dist/index.html"])
        #expect(home == "ios:1 swift:2 ")
    }

    @Test("tag parsing splits on commas, trims, and de-duplicates by slug")
    func tagParsing() {
        let page = makePage(tags: "Swift, ios , swift,, Swift")
        #expect(TileKit.Site.Tags.tags(of: page) == ["Swift", "ios"])
    }

    @Test("tag slugs lowercase and hyphenate")
    func tagSlugs() {
        #expect(TileKit.Site.Tags.slug(for: "Swift") == "swift")
        #expect(TileKit.Site.Tags.slug(for: "Swift on iOS") == "swift-on-ios")
        #expect(TileKit.Site.Tags.slug(for: "  C++  ") == "c")
        #expect(TileKit.Site.Tags.slug(for: "!!!") == "")
    }

    private func taggedFixtureFiles() -> [String: String] {
        [
            "content/index.md": "---\ntitle: Home\n---\n# Home",
            "content/posts/index.md": "---\ntitle: Posts\n---\n# Posts",
            "content/posts/alpha/index.md": "---\ntitle: Alpha\ndate: 2026-05-28\ntags: swift, ios\n---\n# Alpha",
            "content/posts/beta/index.md": "---\ntitle: Beta\ndate: 2026-05-30\ntags: swift\n---\n# Beta",
            "content/posts/gamma/index.md": "---\ntitle: Gamma\ndate: 2026-05-29\n---\n# Gamma",
            "templates/page.html": tagListingTemplate(),
        ]
    }

    private func tagListingTemplate() -> String {
        [
            "<title>{{ page.title }}</title>",
            "{{#page.postList}}{{#page.posts}}<li>{{ title }}</li>{{/page.posts}}{{/page.postList}}",
        ].joined()
    }

    private func makePage(
        tags: String,
    ) -> TileKit.Site.Page {
        .init(
            sourcePath: "posts/x/index.md",
            outputPath: "dist/posts/x/index.html",
            slug: "posts/x",
            document: .init(
                frontMatter: ["title": "X", "tags": tags],
                body: "",
            ),
            html: "",
        )
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
