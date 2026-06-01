import TileCore
import TileService

extension TileKit.ServiceForm.Renderer {
    func html(
        binding: TileKit.ServiceForm.Binding,
        inputFields: [RenderField],
        outputFields: [RenderField],
        config: RuntimeConfig,
    ) throws -> String {
        let tileID = binding.request.id
        let fieldHTML = try inputFields
            .map { try inputFieldHTML($0, tileID: tileID) }
            .joined(separator: "\n")
        let outputHTML = outputFields
            .map(outputFieldHTML)
            .joined(separator: "\n")
        let submitLabel = binding.request.submitLabel ?? "Submit"
        let configJSON = try scriptSafeJSON(config)
        let rootAttributes = renderedAttributes(
            [
                .init(name: "class", value: "td-service-form"),
                .init(name: "data-td-service-form-root"),
                .init(name: "data-td-tile-id", value: tileID),
                .init(name: "data-td-service", value: binding.contract.id),
                .init(name: "data-td-operation", value: binding.operation.id),
                .init(name: "data-td-mode", value: binding.request.mode.rawValue),
            ],
        )
        let configAttributes = renderedAttributes(
            [
                .init(name: "type", value: "application/json"),
                .init(name: "data-td-config", value: tileID),
            ],
        )

        return """
        <div \(rootAttributes)>
        <form class="td-service-form__form" data-td-service-form novalidate>
        \(fieldHTML)
        <button class="td-service-form__submit" type="submit">\(TileKit.HTML.escape(submitLabel))</button>
        </form>
        <div class="td-service-form__states" aria-live="polite">
        \(stateHTML(name: "idle", text: "Ready.", hidden: false))
        \(stateHTML(name: "loading", text: "Loading...", hidden: true))
        \(stateHTML(name: "success", text: "Done.", hidden: true))
        \(stateHTML(name: "validation", text: "Check the highlighted fields.", hidden: true))
        \(stateHTML(name: "unavailable", text: "Service unavailable.", hidden: true))
        \(stateHTML(name: "error", text: "Something went wrong.", hidden: true))
        </div>
        <dl class="td-service-form__results" data-td-results>
        \(outputHTML)
        </dl>
        <script \(configAttributes)>
        \(configJSON)
        </script>
        </div>
        """
    }

    private func inputFieldHTML(
        _ field: RenderField,
        tileID: String,
    ) throws -> String {
        let inputID = htmlID(
            tileID: tileID,
            fieldID: field.id,
        )
        let messageID = inputID + "-message"
        let label = fieldLabel(field)
        let control = try inputControlHTML(
            field,
            inputID: inputID,
            messageID: messageID,
        )
        let unit = field.fieldUI.unit.map(unitHTML) ?? ""
        let messageAttributes = renderedAttributes(
            [
                .init(name: "class", value: "td-service-form__message"),
                .init(name: "id", value: messageID),
                .init(name: "data-td-field-message", value: field.id),
            ],
        )
        let escapedFieldID = TileKit.HTML.escapeAttribute(field.id)
        let escapedInputID = TileKit.HTML.escapeAttribute(inputID)
        let escapedLabel = TileKit.HTML.escape(label)

        return """
        <div class="td-service-form__field" data-td-field="\(escapedFieldID)">
        <label class="td-service-form__label" for="\(escapedInputID)">\(escapedLabel)</label>
        <div class="td-service-form__control">
        \(control)
        \(unit)
        </div>
        <p \(messageAttributes)></p>
        </div>
        """
    }

    private func inputControlHTML(
        _ field: RenderField,
        inputID: String,
        messageID: String,
    ) throws -> String {
        switch try inputControl(for: field) {
        case .text:
            inputHTML(
                field,
                inputID: inputID,
                messageID: messageID,
                type: textInputType(for: field.schema),
            )
        case .number:
            inputHTML(
                field,
                inputID: inputID,
                messageID: messageID,
                type: "number",
            )
        case .checkbox:
            inputHTML(
                field,
                inputID: inputID,
                messageID: messageID,
                type: "checkbox",
            )
        case .textarea:
            textareaHTML(
                field,
                inputID: inputID,
                messageID: messageID,
            )
        case .select:
            selectHTML(
                field,
                inputID: inputID,
                messageID: messageID,
            )
        case .hidden:
            inputHTML(
                field,
                inputID: inputID,
                messageID: messageID,
                type: "hidden",
            )
        }
    }

    private func inputHTML(
        _ field: RenderField,
        inputID: String,
        messageID: String,
        type: String,
    ) -> String {
        let attributes = inputAttributes(
            field,
            inputID: inputID,
            messageID: messageID,
            type: type,
        )

        return "<input \(renderedAttributes(attributes))>"
    }

    private func textareaHTML(
        _ field: RenderField,
        inputID: String,
        messageID: String,
    ) -> String {
        let attributes = baseAttributes(
            field,
            inputID: inputID,
            messageID: messageID,
        )
        return "<textarea \(renderedAttributes(attributes))></textarea>"
    }

    private func selectHTML(
        _ field: RenderField,
        inputID: String,
        messageID: String,
    ) -> String {
        let attributes = baseAttributes(
            field,
            inputID: inputID,
            messageID: messageID,
        )
        let options = field.schema.enumValues
            .map { value in
                #"<option value="\#(TileKit.HTML.escapeAttribute(value))">\#(TileKit.HTML.escape(value))</option>"#
            }
            .joined(separator: "\n")

        return """
        <select \(renderedAttributes(attributes))>
        \(options)
        </select>
        """
    }

    private func inputAttributes(
        _ field: RenderField,
        inputID: String,
        messageID: String,
        type: String,
    ) -> [HTMLAttribute] {
        var attributes = baseAttributes(
            field,
            inputID: inputID,
            messageID: messageID,
        )
        attributes.insert(
            .init(
                name: "type",
                value: type,
            ),
            at: 0,
        )

        if let inputMode = inputMode(for: field.schema) {
            attributes.append(
                .init(
                    name: "inputmode",
                    value: inputMode,
                ),
            )
        }
        if let pattern = field.schema.pattern {
            attributes.append(
                .init(
                    name: "pattern",
                    value: pattern,
                ),
            )
        }
        if field.schema.type == .integer {
            attributes.append(
                .init(
                    name: "step",
                    value: "1",
                ),
            )
        } else if field.schema.type == .number {
            attributes.append(
                .init(
                    name: "step",
                    value: "any",
                ),
            )
        }
        appendNumericBounds(
            field.schema,
            to: &attributes,
        )

        return attributes
    }

    private func outputFieldHTML(
        _ field: RenderField,
    ) -> String {
        let label = fieldLabel(field)
        let format = field.fieldUI.format ?? field.schema.semanticType?.rawValue
        var valueAttributes: [HTMLAttribute] = [
            .init(name: "class", value: "td-service-form__result-value"),
            .init(name: "data-td-output-value", value: field.id),
        ]
        if let format {
            valueAttributes.append(
                .init(
                    name: "data-td-output-format",
                    value: format,
                ),
            )
        }
        let unit = field.fieldUI.unit.map(unitHTML) ?? ""

        return """
        <div class="td-service-form__result" data-td-output-field="\(TileKit.HTML.escapeAttribute(field.id))">
        <dt class="td-service-form__result-label">\(TileKit.HTML.escape(label))</dt>
        <dd \(renderedAttributes(valueAttributes))></dd>
        \(unit)
        </div>
        """
    }
}
