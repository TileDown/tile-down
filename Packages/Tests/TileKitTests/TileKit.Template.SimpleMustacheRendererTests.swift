import Testing
@testable import TileKit

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
}
