import Testing
import TileCore
import TileTile

extension SiteGeneratorTests {
    @Test("buttondown tiles generate default redirect target pages")
    func buttondownGeneratesRedirectPages() throws {
        let fileSystem = MemoryFileSystem(
            files: [
                "content/newsletter/index.md": """
                ---
                title: Newsletter
                ---
                :::tile buttondown
                username: mihaela
                title: Apple Frameworks
                thanksBody: Confirm from your inbox.
                confirmedBody: You are subscribed.
                :::
                """,
                "templates/page.html": "{{ page.title }}|{{{ page.contents.html }}}",
            ],
        )
        let generator = makeGenerator(
            fileSystem: fileSystem,
            tileRegistry: .init(
                renderers: [
                    "buttondown": TileKit.Tile.ButtondownRenderer(),
                ],
            ),
        )

        let result = try generator.buildContent(
            .init(
                contentRootPath: "content",
                template: .file(path: "templates/page.html"),
                outputRootPath: "dist",
                configuration: .init(theme: nil),
            ),
        )

        #expect(result.outputPaths.contains("dist/newsletter/thanks/index.html"))
        #expect(result.outputPaths.contains("dist/newsletter/confirmed/index.html"))
        #expect(
            fileSystem.files["dist/newsletter/index.html"]?.contains(
                #"action="https://buttondown.com/api/emails/embed-subscribe/mihaela""#,
            ) == true,
        )
        #expect(
            fileSystem.files["dist/newsletter/thanks/index.html"] ==
                "Check your email|<h1>Check your email</h1>\n<p>Confirm from your inbox.</p>",
        )
        #expect(
            fileSystem.files["dist/newsletter/confirmed/index.html"] ==
                "Subscription confirmed|<h1>Subscription confirmed</h1>\n<p>You are subscribed.</p>",
        )
    }

    @Test("authored buttondown redirect pages override generated defaults")
    func authoredButtondownPagesWin() throws {
        let fileSystem = MemoryFileSystem(
            files: [
                "content/index.md": """
                ---
                title: Home
                ---
                :::tile buttondown
                username: mihaela
                redirectBasePath: newsletter
                :::
                """,
                "content/newsletter/thanks/index.md": """
                ---
                title: Custom thanks
                ---
                # Custom thanks
                """,
                "templates/page.html": "{{ page.slug }}|{{ page.title }}|{{{ page.contents.html }}}",
            ],
        )
        let generator = makeGenerator(
            fileSystem: fileSystem,
            tileRegistry: .init(
                renderers: [
                    "buttondown": TileKit.Tile.ButtondownRenderer(),
                ],
            ),
        )

        _ = try generator.buildContent(
            .init(
                contentRootPath: "content",
                template: .file(path: "templates/page.html"),
                outputRootPath: "dist",
                configuration: .init(theme: nil),
            ),
        )

        #expect(
            fileSystem.files["dist/newsletter/thanks/index.html"]
                == "newsletter/thanks|Custom thanks|<h1>Custom thanks</h1>",
        )
        #expect(
            fileSystem.files["dist/newsletter/confirmed/index.html"]?
                .contains("newsletter/confirmed|Subscription confirmed") == true,
        )
    }
}
