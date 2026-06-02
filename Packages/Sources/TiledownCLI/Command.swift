import TileKit

struct Command {
    var arguments: [String]

    func run() throws {
        guard let subcommand = arguments.first else {
            print(TileKit.Product.commandName)
            return
        }

        switch subcommand {
        case "version", "--version", "-v":
            print("\(TileKit.Product.name) \(TileKit.Product.version)")
        case "build":
            try build()
        case "build-site":
            try buildSite()
        case "serve":
            try serve()
        case "json":
            try json()
        case "fmt":
            try format()
        default:
            throw CommandError.invalidArguments
        }
    }
}
