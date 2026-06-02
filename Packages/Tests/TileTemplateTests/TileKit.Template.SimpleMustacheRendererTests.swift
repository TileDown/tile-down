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

    @Test("throws on missing section values")
    func throwsOnMissingSectionValues() {
        let renderer = TileKit.Template.SimpleMustacheRenderer()

        #expect(throws: TileKit.Template.SimpleMustacheRendererError.missingValue("site.postss")) {
            try renderer.render(
                template: "{{#site.postss}}Post{{/site.postss}}",
                context: [
                    "site": .object(
                        [
                            "posts": .list([]),
                        ],
                    ),
                ],
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

    @Test("renders string sections only when truthy")
    func rendersStringSectionsOnlyWhenTruthy() throws {
        let renderer = TileKit.Template.SimpleMustacheRenderer()

        let html = try renderer.render(
            template: [
                "{{#enabled}}enabled{{/enabled}}",
                "{{#disabledFalse}}false{{/disabledFalse}}",
                "{{#disabledZero}}zero{{/disabledZero}}",
                "{{#disabledNo}}no{{/disabledNo}}",
                "{{#disabledEmpty}}empty{{/disabledEmpty}}",
            ].joined(separator: "|"),
            context: [
                "enabled": "true",
                "disabledFalse": "false",
                "disabledZero": "0",
                "disabledNo": "no",
                "disabledEmpty": "",
            ],
        )

        #expect(html == "enabled||||")
    }

    @Test("renders inverted sections when absent or falsey")
    func rendersInvertedSectionsWhenAbsentOrFalsey() throws {
        let renderer = TileKit.Template.SimpleMustacheRenderer()

        let html = try renderer.render(
            template: [
                "{{^missing}}missing{{/missing}}",
                "{{^disabled}}disabled{{/disabled}}",
                "{{^disabledZero}}zero{{/disabledZero}}",
                "{{^disabledNo}}no{{/disabledNo}}",
                "{{^emptyText}}empty text{{/emptyText}}",
                "{{^emptyItems}}empty items{{/emptyItems}}",
            ].joined(separator: "|"),
            context: [
                "disabled": " false ",
                "disabledZero": "0",
                "disabledNo": "NO",
                "emptyText": "",
                "emptyItems": .list([]),
            ],
        )

        #expect(html == "missing|disabled|zero|no|empty text|empty items")
    }

    @Test("skips inverted sections when truthy")
    func skipsInvertedSectionsWhenTruthy() throws {
        let renderer = TileKit.Template.SimpleMustacheRenderer()

        let html = try renderer.render(
            template: [
                "{{^enabled}}enabled{{/enabled}}",
                "{{^items}}items{{/items}}",
                "{{^metadata}}metadata{{/metadata}}",
            ].joined(separator: "|"),
            context: [
                "enabled": "true",
                "items": .list([["title": "Post"]]),
                "metadata": .object(["title": "Home"]),
            ],
        )

        #expect(html == "||")
    }

    @Test("renders nested and mixed sections")
    func rendersNestedAndMixedSections() throws {
        let renderer = TileKit.Template.SimpleMustacheRenderer()

        let html = try renderer.render(
            template: """
            {{#groups}}{{^items}}empty:{{name}};{{/items}}{{#items}}{{name}}={{label}};{{/items}}{{/groups}}
            {{^missing}}outer {{^missing}}inner{{/missing}} end{{/missing}}
            """,
            context: [
                "groups": .list(
                    [
                        [
                            "name": "A",
                            "items": .list([]),
                        ],
                        [
                            "name": "B",
                            "items": .list([["label": "One"]]),
                        ],
                    ],
                ),
            ],
        )

        #expect(html == "empty:A;B=One;\nouter inner end")
    }

    @Test(
        "string section truthiness folds case and trims whitespace",
        arguments: [
            ("true", true),
            ("yes", true),
            ("1", true),
            ("  hello  ", true),
            ("FALSE", false),
            ("False", false),
            (" false ", false),
            ("NO", false),
            ("No", false),
            ("0", false),
            (" 0 ", false),
            ("", false),
            ("   ", false),
        ] as [(value: String, expected: Bool)],
    )
    func stringSectionTruthinessEdgeCases(_ testCase: (value: String, expected: Bool)) {
        #expect(
            TileKit.Template.SimpleMustacheRenderer.stringSectionIsTruthy(testCase.value) == testCase.expected,
        )
    }

    @Test("absent string section is falsey")
    func absentStringSectionIsFalsey() {
        #expect(!TileKit.Template.SimpleMustacheRenderer.stringSectionIsTruthy(nil))
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
