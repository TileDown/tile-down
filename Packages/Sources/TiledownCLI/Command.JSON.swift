import Foundation
import TileKit

extension Command {
    func json() throws {
        guard arguments.count == 3 else {
            throw CommandError.invalidArguments
        }

        let fileSystem = TileKit.Site.LocalFileSystem(
            fileManager: .default,
        )
        let source = try fileSystem.readTextFile(at: arguments[1])
        let document = try TileKit.Source.FrontMatterParser().parse(source)
        let blocks = try TileKit.Tile.DirectiveParser().parseBlocks(document.body)

        let artifact = try makeOutputRegistry().render(
            .init(
                frontMatter: document.frontMatter,
                blocks: blocks,
                slug: "",
            ),
            format: TileKit.Output.JSONRenderer.formatID,
        )

        try fileSystem.writeTextFile(
            artifact.contents,
            at: arguments[2],
        )
    }

    func makeOutputRegistry() -> TileKit.Output.Registry {
        TileKit.Output.Registry()
            .registering(makeHTMLRenderer())
            .registering(TileKit.Output.JSONRenderer())
    }
}
