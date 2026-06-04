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

        // /tags/ios/swift/ has only posts carrying both tags.
        let iosSwift = try #require(fileSystem.files["dist/tags/ios/swift/index.html"])
        #expect(iosSwift.contains("<li>Alpha</li>"))
        #expect(!iosSwift.contains("<li>Beta</li>"))
        #expect(!iosSwift.contains("<li>Gamma</li>"))
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

    @Test("a tag page shows the sticky tag bar with the current tag marked")
    func tagPageShowsTagBar() throws {
        var files = taggedFixtureFiles()
        files["templates/page.html"] = [
            "{{#page.tagBar}}{{#site.hasTags}}<nav class=\"bar\">",
            "<a class=\"clear\" href=\"{{ site.tagsURL }}\">Clear</a>{{#site.tags}}",
            "<a class=\"t{{#isCurrent}} cur{{/isCurrent}}\" href=\"{{ url }}\">{{ name }}</a>",
            "{{/site.tags}}</nav>{{/site.hasTags}}{{/page.tagBar}}",
        ].joined()
        let fileSystem = MemoryFileSystem(files: files)

        _ = try makeGenerator(fileSystem: fileSystem).buildContent(
            .init(
                contentRootPath: "content",
                template: .file(path: "templates/page.html"),
                outputRootPath: "dist",
                configuration: .init(theme: nil),
            ),
        )

        // The /tags/swift/ page shows every tag with the bar, ios not current and
        // linking to the narrowed AND filter; swift toggles back to /tags/.
        let swift = try #require(fileSystem.files["dist/tags/swift/index.html"])
        #expect(swift.contains("<nav class=\"bar\">"))
        #expect(swift.contains(#"<a class="t cur" href="/tags/">swift</a>"#))
        #expect(swift.contains(#"<a class="t" href="/tags/ios/swift/">ios</a>"#))
        #expect(swift.contains(#"<a class="clear" href="/tags/">Clear</a>"#))

        // A non-tag page (home) does not show the bar.
        let home = try #require(fileSystem.files["dist/index.html"])
        #expect(!home.contains("<nav class=\"bar\">"))
    }

    @Test("a source page can opt into the built-in tag bar")
    func sourcePageCanOptIntoTagBar() throws {
        let fileSystem = MemoryFileSystem(
            files: [
                "content/index.md": "---\ntitle: Home\n---\n# Home",
                "content/posts/index.md": "---\ntitle: Posts\npostList: true\ntagBar: true\n---\n# Posts",
                "content/posts/alpha/index.md": "---\ntitle: Alpha\ndate: 2026-05-28\ntags: swift, ios\n---\n# Alpha",
                "content/posts/beta/index.md": "---\ntitle: Beta\ndate: 2026-05-29\ntags: docs\n---\n# Beta",
            ],
        )

        _ = try makeGenerator(fileSystem: fileSystem).buildContent(
            .init(
                contentRootPath: "content",
                template: .layout(.topNav),
                outputRootPath: "dist",
                configuration: .init(theme: nil),
            ),
        )

        let posts = try #require(fileSystem.files["dist/posts/index.html"])
        #expect(posts.contains(#"<nav class="td-tagbar" aria-label="All tags">"#))
        #expect(posts.contains(#"href="/tags/swift/">swift</a>"#))
        #expect(posts.contains(#"href="/tags/docs/">docs</a>"#))
    }

    @Test("a multi-tag page marks selected tags and links each one to remove it")
    func multiTagPageShowsSelectedTagLinks() throws {
        var files = taggedFixtureFiles()
        files["templates/page.html"] = [
            "{{#page.tagBar}}{{#site.hasTags}}<nav class=\"bar\">",
            "{{#site.tags}}<a class=\"t{{#isCurrent}} cur{{/isCurrent}}\" href=\"{{ url }}\">{{ name }}</a>",
            "{{/site.tags}}</nav>{{/site.hasTags}}{{/page.tagBar}}",
        ].joined()
        let fileSystem = MemoryFileSystem(files: files)

        _ = try makeGenerator(fileSystem: fileSystem).buildContent(
            .init(
                contentRootPath: "content",
                template: .file(path: "templates/page.html"),
                outputRootPath: "dist",
                configuration: .init(theme: nil),
            ),
        )

        let iosSwift = try #require(fileSystem.files["dist/tags/ios/swift/index.html"])
        #expect(iosSwift.contains(#"<a class="t cur" href="/tags/swift/">ios</a>"#))
        #expect(iosSwift.contains(#"<a class="t cur" href="/tags/ios/">swift</a>"#))
    }

    @Test("empty multi-tag pages render an empty post state")
    func emptyMultiTagPagesRenderEmptyState() throws {
        let fileSystem = MemoryFileSystem(
            files: [
                "content/index.md": "---\ntitle: Home\n---\n# Home",
                "content/posts/index.md": "---\ntitle: Posts\npostList: true\n---\n# Posts",
                "content/posts/alpha/index.md": "---\ntitle: Alpha\ndate: 2026-05-28\ntags: swift\n---\n# Alpha",
                "content/posts/beta/index.md": "---\ntitle: Beta\ndate: 2026-05-29\ntags: ios\n---\n# Beta",
            ],
        )

        _ = try makeGenerator(fileSystem: fileSystem).buildContent(
            .init(
                contentRootPath: "content",
                template: .layout(.topNav),
                outputRootPath: "dist",
                configuration: .init(theme: nil),
            ),
        )

        let empty = try #require(fileSystem.files["dist/tags/ios/swift/index.html"])
        #expect(empty.contains("No posts match this tag selection."))
        #expect(!empty.contains("td-post-card"))
    }

    @Test("the tag bar is absent when the site has no tags")
    func tagBarAbsentWithoutTags() throws {
        let fileSystem = MemoryFileSystem(
            files: [
                "content/index.md": "---\ntitle: Home\n---\n# Home",
                "content/tags/index.md": "---\ntitle: Tags\n---\nBrowse.",
                "templates/page.html": [
                    "{{#page.tagBar}}{{#site.hasTags}}<nav class=\"bar\"></nav>",
                    "{{/site.hasTags}}{{/page.tagBar}}OK",
                ].joined(),
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

        // The tags landing exists and renders, but with no tags the bar is gone.
        let tags = try #require(fileSystem.files["dist/tags/index.html"])
        #expect(tags.contains("OK"))
        #expect(!tags.contains("<nav class=\"bar\">"))
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
                markdownRenderer: TileKit.Markdown.CommonMarkRenderer(
                    passthroughSchemes: TileKit.Site.Reference.schemes,
                ),
                tileRegistry: .init(),
            ),
            templateRenderer: TileKit.Template.SimpleMustacheRenderer(),
            contentDiscovery: TileKit.Source.IndexContentDiscovery(),
        )
    }
}

extension SiteTagsTests {
    @Test("tag pages do not include unrelated global higher-order combinations")
    func tagPagesAvoidUnrelatedGlobalHigherOrderCombinations() throws {
        let fileSystem = MemoryFileSystem(
            files: [
                "content/index.md": "---\ntitle: Home\n---\n# Home",
                "content/posts/index.md": "---\ntitle: Posts\n---\n# Posts",
                "content/posts/alpha/index.md": [
                    "---",
                    "title: Alpha",
                    "date: 2026-05-28",
                    "tags: alpha, beta, epsilon, zeta",
                    "---",
                    "# Alpha",
                ].joined(separator: "\n"),
                "content/posts/gamma/index.md": [
                    "---",
                    "title: Gamma",
                    "date: 2026-05-29",
                    "tags: gamma, delta",
                    "---",
                    "# Gamma",
                ].joined(separator: "\n"),
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

        #expect(fileSystem.files["dist/tags/alpha/gamma/index.html"] != nil)
        #expect(fileSystem.files["dist/tags/alpha/beta/epsilon/index.html"] != nil)
        #expect(fileSystem.files["dist/tags/alpha/beta/epsilon/zeta/index.html"] == nil)
        #expect(fileSystem.files["dist/tags/alpha/gamma/delta/index.html"] == nil)
    }

    @Test("the built-in tag bar hides unavailable and over-depth additions")
    func builtInTagBarHidesUnavailableAndOverDepthAdditions() throws {
        let fileSystem = MemoryFileSystem(
            files: [
                "content/index.md": "---\ntitle: Home\n---\n# Home",
                "content/posts/index.md": "---\ntitle: Posts\npostList: true\n---\n# Posts",
                "content/posts/alpha/index.md": [
                    "---",
                    "title: Alpha",
                    "date: 2026-05-28",
                    "tags: ios, swift, testing, release",
                    "---",
                    "# Alpha",
                ].joined(separator: "\n"),
                "content/posts/beta/index.md": [
                    "---",
                    "title: Beta",
                    "date: 2026-05-29",
                    "tags: ios, swift",
                    "---",
                    "# Beta",
                ].joined(separator: "\n"),
                "content/posts/gamma/index.md": "---\ntitle: Gamma\ndate: 2026-05-30\ntags: docs\n---\n# Gamma",
            ],
        )

        _ = try makeGenerator(fileSystem: fileSystem).buildContent(
            .init(
                contentRootPath: "content",
                template: .layout(.topNav),
                outputRootPath: "dist",
                configuration: .init(theme: nil),
            ),
        )

        let iosSwift = try #require(fileSystem.files["dist/tags/ios/swift/index.html"])
        #expect(iosSwift.contains(#"href="/tags/swift/">ios</a>"#))
        #expect(iosSwift.contains(#"href="/tags/ios/">swift</a>"#))
        #expect(iosSwift.contains(#"href="/tags/ios/swift/testing/">testing</a>"#))
        #expect(!iosSwift.contains(#">docs</a>"#))

        let iosSwiftTesting = try #require(fileSystem.files["dist/tags/ios/swift/testing/index.html"])
        #expect(iosSwiftTesting.contains(#"href="/tags/swift/testing/">ios</a>"#))
        #expect(iosSwiftTesting.contains(#"href="/tags/ios/testing/">swift</a>"#))
        #expect(iosSwiftTesting.contains(#"href="/tags/ios/swift/">testing</a>"#))
        #expect(!iosSwiftTesting.contains(#"href="/tags/ios/swift/testing/release/">release</a>"#))
    }
}
