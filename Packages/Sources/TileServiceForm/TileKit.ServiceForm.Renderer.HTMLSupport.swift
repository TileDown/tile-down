import TileCore
import TileService

extension TileKit.ServiceForm.Renderer {
    func renderedAttributes(
        _ attributes: [HTMLAttribute],
    ) -> String {
        attributes
            .map { attribute in
                guard let value = attribute.value else {
                    return attribute.name
                }

                return #"\#(attribute.name)="\#(escapeAttribute(value))""#
            }
            .joined(separator: " ")
    }

    func escapeHTML(
        _ value: String,
    ) -> String {
        value
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }

    func escapeAttribute(
        _ value: String,
    ) -> String {
        escapeHTML(value)
    }

    func baseAttributes(
        _ field: RenderField,
        inputID: String,
        messageID: String,
    ) -> [HTMLAttribute] {
        var attributes: [HTMLAttribute] = [
            .init(
                name: "id",
                value: inputID,
            ),
            .init(
                name: "name",
                value: field.id,
            ),
            .init(
                name: "aria-describedby",
                value: messageID,
            ),
        ]

        if field.required {
            attributes.append(.init(name: "required"))
            attributes.append(
                .init(
                    name: "aria-required",
                    value: "true",
                ),
            )
        }
        if let placeholder = field.fieldUI.placeholder {
            attributes.append(
                .init(
                    name: "placeholder",
                    value: placeholder,
                ),
            )
        }

        return attributes
    }

    func appendNumericBounds(
        _ schema: TileKit.Service.Schema,
        to attributes: inout [HTMLAttribute],
    ) {
        if let minimum = schema.minimum {
            attributes.append(
                .init(
                    name: "min",
                    value: string(minimum),
                ),
            )
        }
        if let exclusiveMinimum = schema.exclusiveMinimum {
            attributes.append(
                .init(
                    name: "data-td-exclusive-minimum",
                    value: string(exclusiveMinimum),
                ),
            )
        }
        if let maximum = schema.maximum {
            attributes.append(
                .init(
                    name: "max",
                    value: string(maximum),
                ),
            )
        }
        if let exclusiveMaximum = schema.exclusiveMaximum {
            attributes.append(
                .init(
                    name: "data-td-exclusive-maximum",
                    value: string(exclusiveMaximum),
                ),
            )
        }
    }

    func stateHTML(
        name: String,
        text: String,
        hidden: Bool,
    ) -> String {
        var attributes: [HTMLAttribute] = [
            .init(name: "class", value: "td-service-form__state"),
            .init(name: "data-td-state", value: name),
        ]
        if hidden {
            attributes.append(.init(name: "hidden"))
        }

        return "<p \(renderedAttributes(attributes))>\(escapeHTML(text))</p>"
    }

    func unitHTML(
        _ value: String,
    ) -> String {
        #"<span class="td-service-form__unit">\#(escapeHTML(value))</span>"#
    }

    func htmlID(
        tileID: String,
        fieldID: String,
    ) -> String {
        "td-" + sanitizedID(tileID) + "-" + sanitizedID(fieldID)
    }

    func sanitizedID(
        _ value: String,
    ) -> String {
        let result = value
            .lowercased()
            .map { character -> Character in
                if character.isLetter || character.isNumber {
                    return character
                }

                return "-"
            }

        let id = String(result)
        return id.isEmpty ? "field" : id
    }

    func string(
        _ value: Double,
    ) -> String {
        if value.rounded() == value {
            return String(Int(value))
        }

        return String(value)
    }
}
