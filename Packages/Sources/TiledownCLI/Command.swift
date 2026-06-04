import TileKit

struct Command {
    var arguments: [String]

    func run() throws {
        guard let subcommand = arguments.first else {
            print(CommandError.usage)
            return
        }

        switch subcommand {
        case "help", "--help", "-h":
            print(CommandError.usage)
        case "version", "--version", "-v":
            print("\(TileKit.Product.name) \(TileKit.Product.version)")
        case "build":
            try build()
        case "build-site":
            try buildSite()
        case "doctor":
            try doctor()
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
