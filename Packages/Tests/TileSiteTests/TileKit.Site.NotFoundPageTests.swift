import Testing
import TileCore
@testable import TileSite

extension SiteGeneratorTests {
    @Test("content builds emit a default 404 page at the output root")
    func defaultNotFoundPage() throws {
        let fileSystem = MemoryFileSystem(
            files: [
                "content/index.md": "---\ntitle: Home\n---\n# Home",
            ],
        )

        let result = try makeGenerator(fileSystem: fileSystem).buildContent(
            .init(
                contentRootPath: "content",
                template: .layout(.topNav),
                outputRootPath: "dist",
                configuration: .init(title: "Demo"),
            ),
        )

        #expect(result.outputPaths.contains("dist/404.html"))
        let html = try #require(fileSystem.files["dist/404.html"])
        #expect(html.contains("<title>Page not found</title>"))
        #expect(html.contains(#"<link rel="stylesheet" href="/styles.css">"#))
        #expect(html.contains("<h1>Page not found</h1>"))
        #expect(html.contains("The page you requested could not be found."))
    }

    @Test("content 404 source overrides the generated 404 page")
    func sourceNotFoundPage() throws {
        let template = [
            #"<nav>{{#pages}}<a href="{{ url }}">{{ title }}</a>{{/pages}}</nav>"#,
            #"<title>{{ page.title }}</title>{{{ page.contents.html }}}"#,
        ].joined()
        let fileSystem = MemoryFileSystem(
            files: [
                "content/index.md": "---\ntitle: Home\n---\n# Home",
                "content/404/index.md": """
                ---
                title: Custom Missing
                ---
                # Custom Missing

                This is the site-specific missing page.

                ![Missing diagram](missing.svg)
                """,
                "content/404/missing.svg": "<svg/>",
                "templates/page.html": template,
            ],
        )

        let result = try makeGenerator(fileSystem: fileSystem).buildContent(
            .init(
                contentRootPath: "content",
                template: .file(path: "templates/page.html"),
                outputRootPath: "dist",
                configuration: .init(theme: nil),
            ),
        )

        #expect(result.outputPaths.contains("dist/404.html"))
        #expect(result.outputPaths.contains("dist/missing.svg"))
        #expect(fileSystem.files["dist/404/index.html"] == nil)
        #expect(fileSystem.files["dist/404/missing.svg"] == nil)
        #expect(fileSystem.files["dist/missing.svg"] == "<svg/>")
        let html = try #require(fileSystem.files["dist/404.html"])
        #expect(html.contains(#"<nav><a href="/">Home</a></nav>"#))
        #expect(!html.contains(#"href="/404/""#))
        #expect(html.contains(#"<img src="missing.svg" alt="Missing diagram">"#))
        #expect(html.contains("<title>Custom Missing</title><h1>Custom Missing</h1>"))
        #expect(html.contains("This is the site-specific missing page."))
    }
}
