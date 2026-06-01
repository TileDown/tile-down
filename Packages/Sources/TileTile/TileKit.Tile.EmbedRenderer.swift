import Foundation
import TileCore

public extension TileKit.Tile {
    /// A static responsive embed tile for constrained iframe and video sources.
    ///
    /// Reads required `url`, optional `title`, and optional `aspectRatio`
    /// properties. Iframe output is limited to YouTube and Vimeo. Video output is
    /// limited to direct HTTPS mp4, webm, or ogg files.
    struct EmbedRenderer: Rendering {
        public static let typeID = "embed"

        public init() {}

        public func render(
            _ tile: Instance,
        ) throws -> Rendered {
            guard tile.typeID == Self.typeID else {
                throw EmbedRendererError.invalidTileType(actual: tile.typeID)
            }

            let url = try Self.requiredString(named: "url", from: tile)
            let title = Self.string(tile.property(named: "title")) ?? "Embedded content"
            let aspectRatio = try Self.aspectRatio(tile.property(named: "aspectRatio"))
            let source = try EmbedSource(url)

            return .init(
                html: Self.html(
                    source: source,
                    title: title,
                    aspectRatio: aspectRatio,
                ),
                css: Self.css,
            )
        }

        private static func html(
            source: EmbedSource,
            title: String,
            aspectRatio: String,
        ) -> String {
            let escapedTitle = escapeAttribute(title)
            switch source {
            case let .iframe(src):
                let allowPolicy = [
                    "accelerometer",
                    "autoplay",
                    "clipboard-write",
                    "encrypted-media",
                    "gyroscope",
                    "picture-in-picture",
                    "web-share",
                ].joined(separator: "; ")
                let escapedSrc = escapeAttribute(src)
                return """
                <figure class="td-embed" style="--td-embed-aspect-ratio: \(aspectRatio);">
                <div class="td-embed-frame">
                <iframe
                  class="td-embed-iframe"
                  src="\(escapedSrc)"
                  title="\(escapedTitle)"
                  loading="lazy"
                  allowfullscreen
                  referrerpolicy="strict-origin-when-cross-origin"
                  allow="\(allowPolicy)"
                ></iframe>
                </div>
                </figure>
                """
            case let .video(src, mediaType):
                let escapedSrc = escapeAttribute(src)
                return """
                <figure class="td-embed" style="--td-embed-aspect-ratio: \(aspectRatio);">
                <div class="td-embed-frame">
                <video class="td-embed-video" controls preload="none" title="\(escapedTitle)">
                <source src="\(escapedSrc)" type="\(escapeAttribute(mediaType))">
                Your browser does not support the video tag.
                </video>
                </div>
                </figure>
                """
            }
        }

        private static let css = """
        .td-embed {
          margin-block: 1.5rem;
        }
        .td-embed-frame {
          aspect-ratio: var(--td-embed-aspect-ratio, 16 / 9);
          background: var(--td-surface);
          border: 1px solid var(--td-border);
          border-radius: var(--td-radius);
          overflow: hidden;
          width: 100%;
        }
        .td-embed-iframe,
        .td-embed-video {
          border: 0;
          display: block;
          height: 100%;
          width: 100%;
        }
        .td-embed-video {
          background: #000;
          object-fit: contain;
        }
        """

        private static func requiredString(
            named key: String,
            from tile: Instance,
        ) throws -> String {
            guard let value = string(tile.property(named: key)),
                  !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            else {
                throw EmbedRendererError.missingProperty(key)
            }
            return value.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        private static func string(
            _ value: Value?,
        ) -> String? {
            guard case let .string(string) = value else {
                return nil
            }
            return string
        }

        private static func aspectRatio(
            _ value: Value?,
        ) throws -> String {
            guard let raw = string(value) else {
                return "16 / 9"
            }

            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            let parts = trimmed.split(separator: "/", omittingEmptySubsequences: false)
            guard parts.count == 2,
                  let width = Int(parts[0].trimmingCharacters(in: .whitespaces)),
                  let height = Int(parts[1].trimmingCharacters(in: .whitespaces)),
                  width > 0,
                  height > 0
            else {
                throw EmbedRendererError.invalidAspectRatio(raw)
            }

            return "\(width) / \(height)"
        }

        private static func escapeAttribute(
            _ value: String,
        ) -> String {
            value
                .replacingOccurrences(of: "&", with: "&amp;")
                .replacingOccurrences(of: "<", with: "&lt;")
                .replacingOccurrences(of: ">", with: "&gt;")
                .replacingOccurrences(of: "\"", with: "&quot;")
                .replacingOccurrences(of: "'", with: "&#39;")
        }
    }
}

private enum EmbedSource: Equatable {
    case iframe(String)
    case video(String, mediaType: String)

    init(
        _ rawURL: String,
    ) throws {
        let url = rawURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let components = URLComponents(string: url),
              let scheme = components.scheme?.lowercased()
        else {
            throw TileKit.Tile.EmbedRendererError.unsupportedProvider(rawURL)
        }
        guard scheme == "https" else {
            throw TileKit.Tile.EmbedRendererError.unsupportedScheme(scheme)
        }
        guard components.user == nil, components.password == nil else {
            throw TileKit.Tile.EmbedRendererError.unsupportedProvider(rawURL)
        }
        guard let host = components.host?.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: ".")) else {
            throw TileKit.Tile.EmbedRendererError.unsupportedProvider(rawURL)
        }

        if let youtubeID = Self.youtubeID(components: components, host: host) {
            self = .iframe("https://www.youtube-nocookie.com/embed/\(youtubeID)")
            return
        }

        if let vimeoID = Self.vimeoID(components: components, host: host) {
            self = .iframe("https://player.vimeo.com/video/\(vimeoID)")
            return
        }

        let mediaType = Self.mediaType(path: components.path)
        if let mediaType, let src = components.string {
            self = .video(src, mediaType: mediaType)
            return
        }

        throw TileKit.Tile.EmbedRendererError.unsupportedProvider(rawURL)
    }

    private static func youtubeID(
        components: URLComponents,
        host: String,
    ) -> String? {
        let path = pathComponents(components)
        let id: String? = switch host {
        case "youtu.be", "www.youtu.be":
            path.first
        case "youtube.com", "www.youtube.com", "m.youtube.com",
             "youtube-nocookie.com", "www.youtube-nocookie.com":
            if path.first == "watch" {
                components.queryItems?.first { $0.name == "v" }?.value
            } else if path.first == "embed", path.count >= 2 {
                path[1]
            } else if path.first == "shorts", path.count >= 2 {
                path[1]
            } else if path.first == "live", path.count >= 2 {
                path[1]
            } else {
                nil
            }
        default:
            nil
        }

        guard let id,
              isAllowedIdentifier(id, characters: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-")
        else {
            return nil
        }
        return id
    }

    private static func vimeoID(
        components: URLComponents,
        host: String,
    ) -> String? {
        let path = pathComponents(components)
        let id: String? = switch host {
        case "vimeo.com", "www.vimeo.com":
            path.first
        case "player.vimeo.com":
            if path.first == "video", path.count >= 2 {
                path[1]
            } else {
                nil
            }
        default:
            nil
        }

        guard let id,
              isAllowedIdentifier(id, characters: "0123456789")
        else {
            return nil
        }
        return id
    }

    private static func mediaType(
        path: String,
    ) -> String? {
        guard let fileName = path.split(separator: "/").last else {
            return nil
        }

        switch fileName.split(separator: ".").last?.lowercased() {
        case "mp4":
            return "video/mp4"
        case "webm":
            return "video/webm"
        case "ogg":
            return "video/ogg"
        default:
            return nil
        }
    }

    private static func pathComponents(
        _ components: URLComponents,
    ) -> [String] {
        components.path.split(separator: "/").map(String.init)
    }

    private static func isAllowedIdentifier(
        _ value: String,
        characters: String,
    ) -> Bool {
        !value.isEmpty && value.count <= 128 && value.allSatisfy { characters.contains($0) }
    }
}
