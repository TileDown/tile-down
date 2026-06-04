import Testing
import TileCore
@testable import TileSite

@Suite("Site configuration file article PDFs")
struct SiteConfigurationFileArticlePDFTests {
    @Test("article PDFs are an opt-in site setting")
    func parsesArticlePDF() throws {
        let off = try TileKit.Site.ConfigurationFile.parse("title: Demo")
        #expect(!off.configuration.articlePDF)

        let enabled = try TileKit.Site.ConfigurationFile.parse("articlePDF: true")
        #expect(enabled.configuration.articlePDF)

        #expect(throws: TileKit.Site.ConfigurationFileError.invalidBoolean("sometimes")) {
            try TileKit.Site.ConfigurationFile.parse("articlePDF: sometimes")
        }
    }
}
