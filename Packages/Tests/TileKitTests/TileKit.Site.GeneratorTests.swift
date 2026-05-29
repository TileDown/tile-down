import Testing
@testable import TileKit

@Suite("Site generator")
struct SiteGeneratorTests {
    @Test("builds one page from markdown and a template")
    func buildsOnePage() throws {
        let fileSystem = MemoryFileSystem(
            files: [
                "content/index.md": """
                ---
                title: Hello <Tiledown>
                ---
                # Welcome

                This is the first page.
                """,
                "templates/page.html": """
                <html><head><title>{{ page.title }}</title></head><body>{{{ page.contents.html }}}</body></html>
                """,
            ],
        )

        let generator = TileKit.Site.Generator(
            fileSystem: fileSystem,
            markdownParser: TileKit.Source.FrontMatterParser(),
            markdownRenderer: TileKit.Markdown.BasicHTMLRenderer(),
            templateRenderer: TileKit.Template.SimpleMustacheRenderer(),
        )

        let result = try generator.build(
            .init(
                sourcePath: "content/index.md",
                templatePath: "templates/page.html",
                outputPath: "dist/index.html",
            ),
        )

        #expect(result.outputPath == "dist/index.html")
        #expect(
            fileSystem.files["dist/index.html"] == """
            <html><head><title>Hello &lt;Tiledown&gt;</title></head><body><h1>Welcome</h1>
            <p>This is the first page.</p></body></html>
            """,
        )
    }

    @Test("builds content directory pages from index markdown files")
    func buildsContentDirectoryPages() throws {
        let fileSystem = MemoryFileSystem(
            files: [
                "content/index.md": """
                ---
                title: Home
                ---
                # Home
                """,
                "content/blog/index.md": """
                ---
                title: Blog
                ---
                # Blog
                """,
                "content/blog/draft.md": """
                # Draft
                """,
                "templates/page.html": """
                <title>{{ page.title }}</title>{{{ page.contents.html }}}
                """,
            ],
        )

        let generator = TileKit.Site.Generator(
            fileSystem: fileSystem,
            markdownParser: TileKit.Source.FrontMatterParser(),
            markdownRenderer: TileKit.Markdown.BasicHTMLRenderer(),
            templateRenderer: TileKit.Template.SimpleMustacheRenderer(),
        )

        let result = try generator.buildContent(
            .init(
                contentRootPath: "content",
                templatePath: "templates/page.html",
                outputRootPath: "dist",
            ),
        )

        #expect(result.outputPaths == ["dist/index.html", "dist/blog/index.html"])
        #expect(fileSystem.files["dist/index.html"] == "<title>Home</title><h1>Home</h1>")
        #expect(fileSystem.files["dist/blog/index.html"] == "<title>Blog</title><h1>Blog</h1>")
        #expect(fileSystem.files["dist/blog/draft/index.html"] == nil)
    }
}

private final class MemoryFileSystem: TileKit.Site.FileSystem {
    enum Error: Swift.Error {
        case missingFile(String)
    }

    var files: [String: String]

    init(
        files: [String: String],
    ) {
        self.files = files
    }

    func listFilesRecursively(
        at path: String,
    ) throws -> [String] {
        let prefix = path.hasSuffix("/") ? path : path + "/"
        return files.keys
            .filter { $0.hasPrefix(prefix) }
            .map { String($0.dropFirst(prefix.count)) }
            .filter { !$0.isEmpty }
            .sorted()
    }

    func readTextFile(
        at path: String,
    ) throws -> String {
        guard let file = files[path] else {
            throw Error.missingFile(path)
        }
        return file
    }

    func writeTextFile(
        _ contents: String,
        at path: String,
    ) throws {
        files[path] = contents
    }
}
