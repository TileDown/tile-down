import TileCore
import TileService
import TileTile

extension TileKit.ServiceForm.Renderer {
    func validateMode(
        _ mode: TileKit.Tile.Mode,
    ) throws {
        guard mode == .remote || mode == .proxy else {
            throw TileKit.ServiceForm.RenderError.unsupportedMode(mode: mode.rawValue)
        }
    }

    func fields(
        schema: TileKit.Service.Schema,
        fieldUI: [String: TileKit.Service.FieldUI],
        role: FieldRole,
    ) throws -> [RenderField] {
        guard schema.type == .object else {
            switch role {
            case .input:
                throw TileKit.ServiceForm.RenderError.unsupportedInputSchema(
                    kind: schema.type.rawValue,
                )
            case .output:
                throw TileKit.ServiceForm.RenderError.unsupportedOutputSchema(
                    kind: schema.type.rawValue,
                )
            }
        }

        let required = Set(schema.required)
        let fields = schema.properties.map { item in
            RenderField(
                id: item.key,
                schema: item.value,
                fieldUI: fieldUI[item.key] ?? .init(),
                required: required.contains(item.key),
            )
        }

        return try fields
            .sorted(by: compareFields)
            .map { field in
                try validate(
                    field,
                    role: role,
                )
                return field
            }
    }

    func inputControl(
        for field: RenderField,
    ) throws -> InputControl {
        if field.fieldUI.control == .hidden {
            return .hidden
        }
        if !field.schema.enumValues.isEmpty {
            return .select
        }
        if field.schema.semanticType == .decimal || field.schema.semanticType == .positiveDecimal {
            return .text
        }

        switch field.fieldUI.control {
        case .multilineText:
            return .textarea
        case .number:
            return .number
        case .checkbox:
            guard field.schema.type == .boolean else {
                throw TileKit.ServiceForm.RenderError.unsupportedInputField(
                    fieldID: field.id,
                    kind: field.schema.type.rawValue,
                )
            }
            return .checkbox
        case .select, .radio, .segmented:
            throw TileKit.ServiceForm.RenderError.unsupportedInputField(
                fieldID: field.id,
                kind: "empty-enum",
            )
        case .text, .hidden:
            return .text
        case nil:
            return try defaultInputControl(for: field)
        }
    }

    func textInputType(
        for schema: TileKit.Service.Schema,
    ) -> String {
        switch schema.format {
        case "email":
            "email"
        case "uri", "url":
            "url"
        default:
            "text"
        }
    }

    func inputMode(
        for schema: TileKit.Service.Schema,
    ) -> String? {
        if schema.semanticType == .decimal || schema.semanticType == .positiveDecimal {
            return "decimal"
        }
        if schema.type == .integer {
            return "numeric"
        }
        if schema.type == .number {
            return "decimal"
        }

        return nil
    }

    func fieldLabel(
        _ field: RenderField,
    ) -> String {
        field.fieldUI.label ?? generatedLabel(from: field.id)
    }

    private func validate(
        _ field: RenderField,
        role: FieldRole,
    ) throws {
        switch role {
        case .input:
            _ = try inputControl(for: field)
        case .output:
            switch field.schema.type {
            case .string, .number, .integer, .boolean:
                return
            case .object, .array, .null:
                throw TileKit.ServiceForm.RenderError.unsupportedOutputField(
                    fieldID: field.id,
                    kind: field.schema.type.rawValue,
                )
            }
        }
    }

    private func compareFields(
        _ lhs: RenderField,
        _ rhs: RenderField,
    ) -> Bool {
        let lhsOrder = lhs.fieldUI.order ?? Int.max
        let rhsOrder = rhs.fieldUI.order ?? Int.max
        if lhsOrder != rhsOrder {
            return lhsOrder < rhsOrder
        }

        return lhs.id < rhs.id
    }

    private func defaultInputControl(
        for field: RenderField,
    ) throws -> InputControl {
        switch field.schema.type {
        case .string:
            return .text
        case .number, .integer:
            return .number
        case .boolean:
            return .checkbox
        case .object, .array, .null:
            throw TileKit.ServiceForm.RenderError.unsupportedInputField(
                fieldID: field.id,
                kind: field.schema.type.rawValue,
            )
        }
    }

    private func generatedLabel(
        from fieldID: String,
    ) -> String {
        let words = fieldID
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .split(separator: " ")
        let label = words
            .map { word in
                word.prefix(1).uppercased() + String(word.dropFirst())
            }
            .joined(separator: " ")

        return label.isEmpty ? fieldID : label
    }
}
