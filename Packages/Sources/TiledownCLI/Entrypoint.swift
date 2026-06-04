import Foundation

@main
struct Entrypoint {
    static func main() {
        do {
            try Command(
                arguments: Array(CommandLine.arguments.dropFirst()),
            )
            .run()
        } catch {
            FileHandle.standardError.write(
                Data((String(describing: error) + "\n").utf8),
            )
            exit(1)
        }
    }
}
