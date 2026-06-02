@main
struct Entrypoint {
    static func main() throws {
        try Command(
            arguments: Array(CommandLine.arguments.dropFirst()),
        )
        .run()
    }
}
