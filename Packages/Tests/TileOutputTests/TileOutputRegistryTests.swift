import Testing
import TileCore
@testable import TileOutput
import TileTile

@Suite("Output registry")
struct TileOutputRegistryTests {
    /// A renderer whose only job is to make dispatch observable.
    private struct StubRenderer: TileKit.Output.Rendering {
        let formatID: String
        let marker: String

        func render(
            _: TileKit.Output.Document,
        ) -> TileKit.Output.Artifact {
            .init(contents: marker, fileExtension: formatID)
        }
    }

    private let document = TileKit.Output.Document(blocks: [.markdown("x")])

    @Test("registering by explicit format id dispatches to that renderer")
    func explicitFormatID() throws {
        let registry = TileKit.Output.Registry()
            .registering(StubRenderer(formatID: "html", marker: "H"), for: "html")
            .registering(StubRenderer(formatID: "json", marker: "J"), for: "json")

        #expect(try registry.render(document, format: "html").contents == "H")
        #expect(try registry.render(document, format: "json").contents == "J")
    }

    @Test("registering without a format id uses the renderer's own format id")
    func selfDescribedFormatID() throws {
        let registry = TileKit.Output.Registry()
            .registering(StubRenderer(formatID: "rss", marker: "R"))

        #expect(try registry.render(document, format: "rss").contents == "R")
    }

    @Test("an unregistered format throws unknownFormat")
    func unknownFormat() {
        let registry = TileKit.Output.Registry()
            .registering(StubRenderer(formatID: "json", marker: "J"))

        #expect(throws: TileKit.Output.RenderingError.unknownFormat("html")) {
            try registry.render(document, format: "html")
        }
    }

    @Test("the last registration for a format id wins")
    func lastRegistrationWins() throws {
        let registry = TileKit.Output.Registry()
            .registering(StubRenderer(formatID: "json", marker: "first"))
            .registering(StubRenderer(formatID: "json", marker: "second"))

        #expect(try registry.render(document, format: "json").contents == "second")
    }

    @Test("the json renderer renders through the registry")
    func jsonRendererThroughRegistry() throws {
        let registry = TileKit.Output.Registry()
            .registering(TileKit.Output.JSONRenderer())

        let artifact = try registry.render(
            document,
            format: TileKit.Output.JSONRenderer.formatID,
        )
        #expect(artifact.fileExtension == "json")
        #expect(artifact.contents.contains("\"tile-document\""))
    }
}
