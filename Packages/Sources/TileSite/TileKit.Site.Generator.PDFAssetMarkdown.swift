import TileCore

extension TileKit.Site.Generator {
    struct ImageReference {
        var sourceRange: Range<String.Index>
        var source: String
        var isAngleWrapped: Bool
    }

    func fenceMarker(
        _ trimmed: String,
    ) -> String? {
        let backticks = markerRun("`", in: trimmed)
        if backticks.count >= 3 {
            return backticks
        }
        let tildes = markerRun("~", in: trimmed)
        return tildes.count >= 3 ? tildes : nil
    }

    func nextImageReference(
        in line: String,
        from start: String.Index,
    ) -> ImageReference? {
        var index = start
        while let bang = line[index...].firstIndex(of: "!") {
            let bracket = line.index(after: bang)
            guard bracket < line.endIndex, line[bracket] == "[" else {
                index = bracket
                continue
            }
            if let reference = imageReference(in: line, bracket: bracket) {
                return reference
            }
            index = bracket
        }
        return nil
    }

    private func markerRun(
        _ marker: Character,
        in trimmed: String,
    ) -> String {
        String(trimmed.prefix { $0 == marker })
    }

    private func imageReference(
        in line: String,
        bracket: String.Index,
    ) -> ImageReference? {
        let labelStart = line.index(after: bracket)
        guard let labelEnd = firstUnescaped("]", in: line, from: labelStart) else {
            return nil
        }
        let opener = line.index(after: labelEnd)
        guard opener < line.endIndex, line[opener] == "(" else {
            return nil
        }
        let destinationStart = line.index(after: opener)
        guard let closer = firstUnescaped(")", in: line, from: destinationStart),
              let source = markdownImageSource(
                  in: line,
                  from: destinationStart,
                  to: closer,
              )
        else {
            return nil
        }
        return .init(
            sourceRange: source.range,
            source: String(line[source.range]),
            isAngleWrapped: source.isAngleWrapped,
        )
    }

    private func markdownImageSource(
        in line: String,
        from start: String.Index,
        to end: String.Index,
    ) -> MarkdownImageSource? {
        var sourceStart = start
        while sourceStart < end, line[sourceStart].isWhitespace {
            sourceStart = line.index(after: sourceStart)
        }
        guard sourceStart < end else {
            return nil
        }

        if line[sourceStart] == "<" {
            let innerStart = line.index(after: sourceStart)
            guard let innerEnd = line[innerStart ..< end].firstIndex(of: ">") else {
                return nil
            }
            return .init(
                range: innerStart ..< innerEnd,
                isAngleWrapped: true,
            )
        }

        var sourceEnd = sourceStart
        while sourceEnd < end, !line[sourceEnd].isWhitespace {
            sourceEnd = line.index(after: sourceEnd)
        }
        return sourceStart == sourceEnd
            ? nil
            : .init(
                range: sourceStart ..< sourceEnd,
                isAngleWrapped: false,
            )
    }

    private func firstUnescaped(
        _ character: Character,
        in source: String,
        from start: String.Index,
    ) -> String.Index? {
        var index = start
        var escaped = false
        while index < source.endIndex {
            let current = source[index]
            if escaped {
                escaped = false
            } else if current == "\\" {
                escaped = true
            } else if current == character {
                return index
            }
            index = source.index(after: index)
        }
        return nil
    }

    private struct MarkdownImageSource {
        var range: Range<String.Index>
        var isAngleWrapped: Bool
    }
}
