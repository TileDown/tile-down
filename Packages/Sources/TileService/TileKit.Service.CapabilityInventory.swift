import TileCore

public extension TileKit.Service {
    /// The complete set of manifest capabilities supported by a runtime.
    struct CapabilityInventory: Equatable, Sendable {
        public var inputTypes: Set<InputCapability>
        public var outputTypes: Set<OutputCapability>
        public var layoutModes: Set<LayoutMode>
        public var validationRules: Set<ValidationCapability>

        public init(
            inputTypes: Set<InputCapability>,
            outputTypes: Set<OutputCapability>,
            layoutModes: Set<LayoutMode>,
            validationRules: Set<ValidationCapability>,
        ) {
            self.inputTypes = inputTypes
            self.outputTypes = outputTypes
            self.layoutModes = layoutModes
            self.validationRules = validationRules
        }

        /// The current manifest capability inventory implemented by Tiledown.
        public static let current = CapabilityInventory(
            inputTypes: Set(InputCapability.allCases),
            outputTypes: Set(OutputCapability.allCases),
            layoutModes: Set(LayoutMode.allCases),
            validationRules: Set(ValidationCapability.allCases),
        )
    }
}
