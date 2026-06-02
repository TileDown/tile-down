import Testing
import TileCore
@testable import TileSite

@Suite("Site service binding configuration")
struct SiteConfigurationFileServiceTests {
    @Test("parses service binding configuration")
    func parsesServiceBindingConfiguration() throws {
        let file = try TileKit.Site.ConfigurationFile.parse(
            """
            service.calculator.contract: contracts/calculator.json
            service.calculator.mode: proxy
            service.calculator.proxyRoute: /_td/services/calculator
            service.calculator.availability: optional
            """,
        )

        #expect(
            file.serviceBindings == [
                .init(
                    serviceID: "calculator",
                    contractPath: "contracts/calculator.json",
                    mode: "proxy",
                    proxyRoute: "/_td/services/calculator",
                    availability: "optional",
                ),
            ],
        )
    }

    @Test("rejects invalid service binding configuration")
    func rejectsInvalidServiceBindingConfiguration() {
        #expect(throws: TileKit.Site.ConfigurationFileError.invalidServiceBindingKey("service..mode")) {
            try TileKit.Site.ConfigurationFile.parse("service..mode: proxy")
        }
        #expect(
            throws: TileKit.Site.ConfigurationFileError.invalidServiceBindingMode(
                serviceID: "calculator",
                mode: "browser",
            ),
        ) {
            try TileKit.Site.ConfigurationFile.parse("service.calculator.mode: browser")
        }
        #expect(
            throws: TileKit.Site.ConfigurationFileError.missingServiceBindingField(
                serviceID: "calculator",
                field: "contract",
            ),
        ) {
            try TileKit.Site.ConfigurationFile.parse("service.calculator.mode: proxy")
        }
    }
}
