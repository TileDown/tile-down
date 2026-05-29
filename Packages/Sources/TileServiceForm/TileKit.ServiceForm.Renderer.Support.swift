import TileCore
import TileService

extension TileKit.ServiceForm.Renderer {
    enum FieldRole {
        case input
        case output
    }

    enum InputControl {
        case text
        case number
        case checkbox
        case textarea
        case select
        case hidden
    }

    struct RenderField: Equatable {
        var id: String
        var schema: TileKit.Service.Schema
        var fieldUI: TileKit.Service.FieldUI
        var required: Bool
    }

    struct HTMLAttribute: Equatable {
        var name: String
        var value: String?

        init(
            name: String,
            value: String? = nil,
        ) {
            self.name = name
            self.value = value
        }
    }

    struct RuntimeConfig: Encodable {
        var tileID: String
        var service: String
        var operation: String
        var mode: String
        var endpoint: String
        var method: String
        var inputFields: [RuntimeField]
        var outputFields: [RuntimeField]
    }

    struct RuntimeField: Encodable {
        var name: String
        var required: Bool
        var schemaType: String
        var format: String?
        var semanticType: String?
        var pattern: String?
        var enumValues: [String]
        var minimum: Double?
        var exclusiveMinimum: Double?
        var maximum: Double?
        var exclusiveMaximum: Double?
        var outputFormat: String?
    }
}
