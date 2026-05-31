import Testing
import TileCore
@testable import TileSite

@Suite("Post collection")
struct SitePostCollectionTests {
    @Test("selects dated posts under the directory, newest first")
    func selectionAndOrder() {
        let posts = TileKit.Site.PostCollection(
            among: pages(),
            postsDirectory: "posts",
        )
        #expect(posts.count == 3)
        #expect(posts.map(\.slug) == ["posts/newest", "posts/middle", "posts/older"])
    }

    @Test("is a collection: prefix and filter come for free")
    func collectionOperations() {
        let posts = TileKit.Site.PostCollection(
            among: pages(),
            postsDirectory: "posts",
        )
        #expect(Array(posts.prefix(2)).map(\.slug) == ["posts/newest", "posts/middle"])
        #expect(posts.first?.slug == "posts/newest")
        let tagged = posts.filter { $0.document.frontMatter["tags"]?.contains("swift") ?? false }
        #expect(tagged.map(\.slug) == ["posts/newest", "posts/older"])
    }

    @Test("a custom posts directory changes the selection")
    func customDirectory() {
        let posts = TileKit.Site.PostCollection(
            among: pages(),
            postsDirectory: "blog",
        )
        #expect(posts.map(\.slug) == ["blog/only"])
    }

    @Test("Page is Hashable and Comparable, keyed on slug")
    func pageConformances() {
        let postA = page("posts/a", date: "2026-05-01")
        let postB = page("posts/b", date: "2026-05-02")
        let postAAgain = page("posts/a", date: "2026-05-09")
        #expect(postA == postAAgain)
        #expect(Set([postA, postB, postAAgain]).count == 2)
        #expect(postA < postB)
    }

    private func pages() -> [TileKit.Site.Page] {
        [
            page("", date: nil),
            page("posts", date: nil),
            page("posts/older", date: "2026-05-01", tags: "swift"),
            page("posts/middle", date: "2026-05-10"),
            page("posts/newest", date: "2026-05-20", tags: "swift, ios"),
            page("posts/broken", date: "soon"),
            page("blog/only", date: "2026-05-15"),
        ]
    }

    private func page(
        _ slug: String,
        date: String?,
        tags: String? = nil,
    ) -> TileKit.Site.Page {
        var frontMatter: [String: String] = ["title": slug.isEmpty ? "Home" : slug]
        if let date {
            frontMatter["date"] = date
        }
        if let tags {
            frontMatter["tags"] = tags
        }
        return .init(
            sourcePath: slug + "/index.md",
            outputPath: "dist/" + slug + "/index.html",
            slug: slug,
            document: .init(frontMatter: frontMatter, body: ""),
            html: "",
        )
    }
}
