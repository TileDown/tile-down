import TileCore

public extension TileKit.Site {
    /// A site-wide newsletter signup rendered into the layout's end-of-post and
    /// footer regions, so a site offers one signup everywhere without repeating a
    /// tile in every page. Backed by the Buttondown embedded subscribe endpoint,
    /// the same renderer as the inline `buttondown` tile.
    struct Newsletter: Equatable, Sendable {
        /// The Buttondown username whose list the embedded form subscribes to.
        public var username: String
        /// The signup heading. Defaults to `Subscribe`.
        public var title: String
        /// An optional sentence above the form. Empty by default.
        public var body: String
        /// The submit button label. Defaults to `Subscribe`.
        public var buttonLabel: String
        /// The email field placeholder. Defaults to `you@example.com`.
        public var placeholder: String
        /// An optional reassurance line below the form. Empty by default.
        public var note: String
        /// Whether the signup renders at the end of every article. Defaults to true.
        public var endOfPost: Bool
        /// Whether the signup renders in the footer on every page. Defaults to true.
        public var footer: Bool

        public init(
            username: String,
            title: String = "Subscribe",
            body: String = "",
            buttonLabel: String = "Subscribe",
            placeholder: String = "you@example.com",
            note: String = "",
            endOfPost: Bool = true,
            footer: Bool = true,
        ) {
            self.username = username
            self.title = title
            self.body = body
            self.buttonLabel = buttonLabel
            self.placeholder = placeholder
            self.note = note
            self.endOfPost = endOfPost
            self.footer = footer
        }
    }
}
