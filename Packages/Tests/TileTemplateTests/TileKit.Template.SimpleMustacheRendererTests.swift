import Testing
import TileCore
@testable import TileTemplate

@Suite("Simple Mustache renderer")
struct SimpleMustacheRendererTests {
    @Test("renders escaped and raw values")
    func rendersEscapedAndRawValues() throws {
        let renderer = TileKit.Template.SimpleMustacheRenderer()

        let html = try renderer.render(
            template: "<title>{{ title }}</title>{{{ html }}}",
            context: [
                "title": "Hello <Tiledown>",
                "html": "<p>Body</p>",
            ],
        )

        #expect(html == "<title>Hello &lt;Tiledown&gt;</title><p>Body</p>")
    }

    @Test("throws on missing values")
    func throwsOnMissingValues() {
        let renderer = TileKit.Template.SimpleMustacheRenderer()

        #expect(throws: TileKit.Template.SimpleMustacheRendererError.missingValue("title")) {
            try renderer.render(
                template: "{{ title }}",
                context: [:],
            )
        }
    }

    @Test("renders list sections with local item scope")
    func rendersListSections() throws {
        let renderer = TileKit.Template.SimpleMustacheRenderer()

        let html = try renderer.render(
            template: "{{# pages }}<a href=\"{{ url }}\">{{ title }}</a>{{ /pages }}",
            context: [
                "pages": .list(
                    [
                        [
                            "title": "Home",
                            "url": "/",
                        ],
                        [
                            "title": "Blog <News>",
                            "url": "/blog/",
                        ],
                    ],
                ),
            ],
        )

        #expect(html == "<a href=\"/\">Home</a><a href=\"/blog/\">Blog &lt;News&gt;</a>")
    }

    @Test("renders nested object values")
    func rendersNestedObjectValues() throws {
        let renderer = TileKit.Template.SimpleMustacheRenderer()

        let html = try renderer.render(
            template: "<h1>{{ page.title }}</h1>{{{ page.contents.html }}}",
            context: [
                "page": .object(
                    [
                        "title": "Home",
                        "contents": .object(
                            [
                                "html": "<p>Body</p>",
                            ],
                        ),
                    ],
                ),
            ],
        )

        #expect(html == "<h1>Home</h1><p>Body</p>")
    }
}
