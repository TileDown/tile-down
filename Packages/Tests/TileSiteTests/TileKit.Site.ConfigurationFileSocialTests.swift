import Testing
import TileCore
@testable import TileSite

@Suite("Site social configuration")
struct SiteConfigurationFileSocialTests {
    @Test("parses first-class Bluesky and Mastodon settings")
    func parsesBlueskyAndMastodonSettings() throws {
        let file = try TileKit.Site.ConfigurationFile.parse(
            """
            social.bluesky: https://bsky.app/profile/tiledown.com
            social.mastodon: https://mastodon.social/@tiledown
            """,
        )

        #expect(
            file.configuration.socialLinks == [
                .init(label: "Bluesky", url: "https://bsky.app/profile/tiledown.com"),
                .init(label: "Mastodon", url: "https://mastodon.social/@tiledown", rel: "me"),
            ],
        )
    }
}
