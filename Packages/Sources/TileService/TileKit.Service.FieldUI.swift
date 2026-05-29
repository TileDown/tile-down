import TileCore

public extension TileKit.Service {
    /// Presentation hints for a generated service input or output field.
    struct FieldUI: Codable, Equatable, Sendable {
        public var label: String?
        public var control: Control?
        public var placeholder: String?
        public var unit: String?
        public var order: Int?
        public var format: String?

        public init(
            label: String? = nil,
            control: Control? = nil,
            placeholder: String? = nil,
            unit: String? = nil,
            order: Int? = nil,
            format: String? = nil,
        ) {
            self.label = label
            self.control = control
            self.placeholder = placeholder
            self.unit = unit
            self.order = order
            self.format = format
        }
    }
}
