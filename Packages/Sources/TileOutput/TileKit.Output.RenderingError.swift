import TileCore

public extension TileKit.Output {
    /// Errors produced while selecting or running an output renderer.
    enum RenderingError: Error, Equatable, Sendable, CustomStringConvertible {
        /// No renderer is registered for the requested output format id.
        case unknownFormat(String)
        /// A renderer produced bytes that are not valid UTF-8 text.
        case invalidTextEncoding(format: String)

        public var description: String {
            switch self {
            case let .unknownFormat(formatID):
                "No output renderer is registered for format \"\(formatID)\"."
            case let .invalidTextEncoding(format):
                "The \"\(format)\" renderer produced output that is not valid UTF-8 text."
            }
        }
    }
}
