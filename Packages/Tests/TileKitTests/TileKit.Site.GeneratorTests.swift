import Testing
@testable import TileKit

@Suite("Site generator")
struct SiteGeneratorTests {
    @Test("can be constructed")
    func construction() {
        _ = TileKit.Site.Generator()
    }
}
