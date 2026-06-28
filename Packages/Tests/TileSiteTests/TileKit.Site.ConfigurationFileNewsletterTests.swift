import Testing
import TileCore
@testable import TileSite

@Suite("Site newsletter configuration")
struct SiteConfigurationFileNewsletterTests {
    @Test("parses newsletter fields, defaulting the unset ones")
    func parsesNewsletterFields() throws {
        let file = try TileKit.Site.ConfigurationFile.parse(
            """
            newsletter.username: tiledown
            newsletter.title: TileDown Updates
            newsletter.body: Field notes.
            newsletter.buttonLabel: Join
            newsletter.placeholder: dev@example.com
            newsletter.note: No spam.
            newsletter.footer: false
            """,
        )

        #expect(
            file.configuration.newsletter == .init(
                username: "tiledown",
                title: "TileDown Updates",
                body: "Field notes.",
                buttonLabel: "Join",
                placeholder: "dev@example.com",
                note: "No spam.",
                endOfPost: true,
                footer: false,
            ),
        )
    }

    @Test("a site without a newsletter block has no newsletter")
    func defaultsToNoNewsletter() throws {
        let file = try TileKit.Site.ConfigurationFile.parse("title: Site")
        #expect(file.configuration.newsletter == nil)
    }

    @Test("newsletter fields without a username are rejected")
    func newsletterWithoutUsernameThrows() {
        #expect(throws: TileKit.Site.ConfigurationFileError.newsletterMissingUsername) {
            _ = try TileKit.Site.ConfigurationFile.parse("newsletter.title: Updates")
        }
    }
}
