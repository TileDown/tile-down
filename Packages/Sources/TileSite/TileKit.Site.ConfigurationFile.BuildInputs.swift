import TileCore

extension TileKit.Site.ConfigurationFile {
    static func applyBuildInputSetting(
        _ item: (key: String, value: String),
        to result: inout Self,
        serviceBindings: inout [String: ServiceBindingBuilder],
    ) throws -> Bool {
        if try applyGenerator(item, to: &result) {
            return true
        }
        if try applyServiceBinding(item, to: &serviceBindings) {
            return true
        }
        return false
    }
}
