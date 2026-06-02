import TileCore

extension TileKit.Site.ConfigurationFile {
    /// Records a `generate.<name>: <command>` content generator, returning true
    /// when the line is a generator setting so the parser stops dispatching it.
    static func applyGenerator(
        _ item: (key: String, value: String),
        to result: inout Self,
    ) throws -> Bool {
        guard item.key.hasPrefix("generate.") else {
            return false
        }
        let name = String(item.key.dropFirst("generate.".count))
        guard !name.isEmpty else {
            return false
        }
        let command = try generatorCommandArguments(from: item.value)
        guard !command.isEmpty, command[0].isEmpty == false else {
            throw TileKit.Site.ConfigurationFileError.invalidGeneratorCommand(item.value)
        }
        result.generators.append(TileKit.Site.ContentGenerator(name: name, command: command))
        return true
    }

    private static func generatorCommandArguments(
        from value: String,
    ) throws -> [String] {
        var arguments: [String] = []
        var current = ""
        var hasCurrent = false
        var quote: Character?
        var isEscaping = false

        for character in value {
            if isEscaping {
                current.append(character)
                hasCurrent = true
                isEscaping = false
                continue
            }

            if character == "\\", quote != "'" {
                isEscaping = true
                continue
            }

            if let activeQuote = quote {
                if character == activeQuote {
                    quote = nil
                } else {
                    current.append(character)
                    hasCurrent = true
                }
                continue
            }

            if character == "\"" || character == "'" {
                quote = character
                hasCurrent = true
            } else if character.isWhitespace {
                flushArgument(
                    current: &current,
                    hasCurrent: &hasCurrent,
                    arguments: &arguments,
                )
            } else {
                current.append(character)
                hasCurrent = true
            }
        }

        guard quote == nil, !isEscaping else {
            throw TileKit.Site.ConfigurationFileError.invalidGeneratorCommand(value)
        }

        flushArgument(
            current: &current,
            hasCurrent: &hasCurrent,
            arguments: &arguments,
        )
        return arguments
    }

    private static func flushArgument(
        current: inout String,
        hasCurrent: inout Bool,
        arguments: inout [String],
    ) {
        guard hasCurrent else {
            return
        }
        arguments.append(current)
        current = ""
        hasCurrent = false
    }
}
