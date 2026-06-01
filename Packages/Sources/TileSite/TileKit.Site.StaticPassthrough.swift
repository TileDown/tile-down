import Foundation
import TileCore

public extension TileKit.Site {
    /// A configured static copy from the content tree to a stable public output
    /// path. `sourcePath` and `outputPath` are relative slash paths.
    struct StaticPassthrough: Equatable, Sendable {
        public var sourcePath: String
        public var outputPath: String

        public init(
            sourcePath: String,
            outputPath: String,
        ) {
            self.sourcePath = sourcePath
            self.outputPath = outputPath
        }
    }
}

extension TileKit.Site.StaticPassthrough {
    init(
        validatingSourcePath sourcePath: String,
        outputPath: String,
    ) throws {
        try self.init(
            sourcePath: Self.normalizedPath(sourcePath),
            outputPath: Self.normalizedPath(outputPath),
        )
    }

    /// Normalizes configured file paths to safe slash paths relative to the
    /// content/output root.
    static func normalizedPath(
        _ value: String,
    ) throws -> String {
        var path = value.trimmingCharacters(in: .whitespaces)[...]
        while path.hasPrefix("/") {
            path = path.dropFirst()
        }
        while path.hasSuffix("/") {
            path = path.dropLast()
        }
        let normalized = String(path)
        guard !normalized.isEmpty else {
            throw TileKit.Site.ConfigurationFileError.invalidPath(value)
        }
        let components = normalized.split(
            separator: "/",
            omittingEmptySubsequences: false,
        )
        guard components.allSatisfy({ !$0.isEmpty && $0 != "." && $0 != ".." }) else {
            throw TileKit.Site.ConfigurationFileError.invalidPath(value)
        }
        return normalized
    }
}
