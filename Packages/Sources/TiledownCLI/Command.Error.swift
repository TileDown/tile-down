import TileKit

enum CommandError: Error, CustomStringConvertible {
    case invalidArguments
    case generatorFailed(name: String, status: Int32)

    static let usage = """
    usage:
      tiledown build <source.md> <template.html> <output.html>
      tiledown build-site [--drafts] <content-dir> <output-dir>
      tiledown build-site [--drafts] <content-dir> <template.html> <output-dir>
      tiledown doctor [--publish] [--strict] [--drafts] [--run-generators] [--json] [--keep-temp] [<content-dir>]
      tiledown serve [--drafts] [--port N] [--output DIR] <content-dir>
      tiledown json <source.md> <output.json>
      tiledown fmt [--write | --check] <source.md>
      tiledown help

    build-site reads optional tiledown.yml settings from <content-dir>.
    --drafts includes draft: true pages, for local preview.
    serve builds with the built-in layout, then serves the output on 127.0.0.1.
    """

    var description: String {
        switch self {
        case let .generatorFailed(name, status):
            "Content generator `\(name)` failed with exit code \(status)."
        case .invalidArguments:
            Self.usage
        }
    }
}
