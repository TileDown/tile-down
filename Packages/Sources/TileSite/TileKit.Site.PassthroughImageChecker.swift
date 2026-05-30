import TileCore

public extension TileKit.Site {
    /// The default `ImageChecking` pass: it accepts every image and never
    /// throws. It keeps the generator's image-check step wired while real
    /// validation is still a future slice.
    struct PassthroughImageChecker: ImageChecking {
        public init() {}

        public func check(
            imagePaths _: [String],
        ) throws {}
    }
}
