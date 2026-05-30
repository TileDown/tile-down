import TileCore

public extension TileKit.Site {
    /// How a site offers dark and light appearance.
    ///
    /// The themes define both a light and a dark palette; this chooses how a
    /// visitor lands on one. It is a site-wide setting (`appearance:` in the
    /// project file), separate from the `Theme` (which look) and the `Layout`
    /// (which arrangement).
    enum Appearance: String, Equatable, Sendable {
        /// Show a toggle control; follow the OS until the visitor picks, then
        /// remember the choice. The default.
        case toggle
        /// Follow the OS appearance with no control to override it.
        case auto
        /// Always light, ignoring the OS.
        case light
        /// Always dark, ignoring the OS.
        case dark
    }
}
