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
            sourcePath: Self.normalizedSourcePath(sourcePath),
            outputPath: Self.normalizedOutputPath(outputPath),
        )
    }

    /// Normalizes configured file paths to safe slash paths relative to the
    /// content/output root.
    static func normalizedSourcePath(
        _ value: String,
    ) throws -> String {
        var path = value.trimmingCharacters(in: .whitespacesAndNewlines)[...]
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

    static func normalizedOutputPath(
        _ value: String,
    ) throws -> String {
        let normalized = try normalizedSourcePath(value)
        guard normalized.unicodeScalars.allSatisfy({ scalar in
            scalar.value > 0x1F && scalar.value != 0x7F
        }),
            !normalized.contains(where: { character in
                character == "#" || character == "%" || character == "?" || character == "\\"
            })
        else {
            throw TileKit.Site.ConfigurationFileError.invalidPath(value)
        }
        return normalized
    }
}
