import Foundation
import TileCore

public extension TileKit.Serve {
    /// Resolves HTTP request paths to files under one output root.
    struct StaticFileResponder {
        private static let contentTypes = [
            "html": "text/html; charset=utf-8",
            "htm": "text/html; charset=utf-8",
            "css": "text/css; charset=utf-8",
            "js": "text/javascript; charset=utf-8",
            "png": "image/png",
            "jpg": "image/jpeg",
            "jpeg": "image/jpeg",
            "gif": "image/gif",
            "svg": "image/svg+xml",
            "webp": "image/webp",
            "xml": "application/xml; charset=utf-8",
            "json": "application/json; charset=utf-8",
            "pdf": "application/pdf",
        ]

        private let rootURL: URL
        private let fileManager: FileManager

        public init(
            rootPath: String,
            fileManager: FileManager,
        ) {
            rootURL = URL(fileURLWithPath: rootPath)
                .standardizedFileURL
                .resolvingSymlinksInPath()
            self.fileManager = fileManager
        }

        public func response(
            for request: Request,
        ) throws -> Response {
            guard request.method == "GET" || request.method == "HEAD" else {
                return .init(
                    statusCode: 405,
                    reasonPhrase: "Method Not Allowed",
                    headers: [
                        .init(name: "Allow", value: "GET, HEAD"),
                        .init(name: "Content-Type", value: "text/plain; charset=utf-8"),
                    ],
                    body: Data("Method Not Allowed\n".utf8),
                )
            }

            guard let fileURL = try fileURL(for: request.target) else {
                return notFound()
            }

            let body = try Data(contentsOf: fileURL)
            let responseBody = request.method == "HEAD" ? Data() : body
            return .init(
                statusCode: 200,
                reasonPhrase: "OK",
                headers: [
                    .init(name: "Content-Type", value: contentType(for: fileURL)),
                    .init(name: "Content-Length", value: "\(body.count)"),
                ],
                body: responseBody,
            )
        }

        private func fileURL(
            for target: String,
        ) throws -> URL? {
            let path = target
                .split(separator: "?", maxSplits: 1, omittingEmptySubsequences: false)
                .first
                .map(String.init) ?? ""
            let trimmed = path.hasPrefix("/") ? String(path.dropFirst()) : path
            guard let decoded = trimmed.removingPercentEncoding else {
                throw ServerError.invalidRequestTarget(target)
            }
            let components = decoded
                .split(separator: "/", omittingEmptySubsequences: true)
                .map(String.init)
            guard components.allSatisfy(isSafePathComponent(_:)) else {
                return nil
            }

            let relativePath = components.joined(separator: "/")
            var candidate = relativePath.isEmpty
                ? rootURL
                : rootURL.appendingPathComponent(relativePath)
            candidate = candidate.standardizedFileURL
                .resolvingSymlinksInPath()
            guard isInsideRoot(candidate) else {
                return nil
            }

            var isDirectory = ObjCBool(false)
            guard fileManager.fileExists(atPath: candidate.path, isDirectory: &isDirectory) else {
                return nil
            }
            if isDirectory.boolValue {
                candidate = candidate.appendingPathComponent("index.html")
                    .standardizedFileURL
                    .resolvingSymlinksInPath()
                guard isInsideRoot(candidate) else {
                    return nil
                }
                guard fileManager.fileExists(atPath: candidate.path) else {
                    return nil
                }
            }
            return candidate
        }

        private func isSafePathComponent(
            _ component: String,
        ) -> Bool {
            !component.isEmpty
                && component != "."
                && component != ".."
                && !component.contains("\\")
                && !component.unicodeScalars.contains { $0.value < 32 }
        }

        private func isInsideRoot(
            _ url: URL,
        ) -> Bool {
            let root = rootURL.path
            let path = url.path
            return path == root || path.hasPrefix(root + "/")
        }

        private func notFound() -> Response {
            .init(
                statusCode: 404,
                reasonPhrase: "Not Found",
                headers: [
                    .init(name: "Content-Type", value: "text/plain; charset=utf-8"),
                ],
                body: Data("Not Found\n".utf8),
            )
        }

        private func contentType(
            for url: URL,
        ) -> String {
            Self.contentTypes[url.pathExtension.lowercased()]
                ?? "application/octet-stream"
        }
    }
}
