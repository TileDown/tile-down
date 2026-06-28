import Foundation

// The per-language keyword and token tables are long but cohesive; they belong in one file.
// swiftlint:disable file_length

public extension TileKit {
    /// Fast build-time syntax highlighting for generated static HTML.
    ///
    /// The highlighter is intentionally lexical. It follows the token categories
    /// used by browser highlighters, but emits static spans during the build so a
    /// published site does not need a client-side highlighting runtime.
    enum SyntaxHighlighter {
        public static let supportedLanguages = [
            "bash", "c", "cpp", "csharp", "css", "go", "html", "java",
            "javascript", "json", "kotlin", "python", "ruby", "rust", "sql",
            "swift", "typescript", "xml", "yaml",
        ]

        public static func html(
            for source: String,
            language: String?,
        ) -> String {
            guard let language = normalized(language) else {
                return escape(source)
            }

            switch language {
            case "html", "xml":
                return markupHTML(source)
            case "css":
                return cssHTML(source)
            case "json":
                return jsonHTML(source)
            case "yaml", "yml", "chart":
                return keyedLineHTML(source)
            default:
                return commonHTML(source, profile: profile(for: language))
            }
        }

        public static func html(
            for source: String,
            language: String,
        ) -> String {
            html(for: source, language: Optional(language))
        }
    }
}

private extension TileKit.SyntaxHighlighter {
    static let languageAliases = [
        "c++": "cpp",
        "cc": "cpp",
        "cjs": "javascript",
        "cs": "csharp",
        "h": "cpp",
        "hpp": "cpp",
        "js": "javascript",
        "jsx": "javascript",
        "kt": "kotlin",
        "mjs": "javascript",
        "py": "python",
        "rb": "ruby",
        "rs": "rust",
        "sh": "bash",
        "shell": "bash",
        "ts": "typescript",
        "tsx": "typescript",
        "yml": "yaml",
        "zsh": "bash",
    ]

    struct LanguageProfile {
        var keywords: Set<String>
        var types: Set<String> = []
        var literals: Set<String> = []
        var lineComments: [String] = []
        var blockComments: [(open: String, close: String)] = []
        var strings: Set<Character> = ["\"", "'"]
        var shellVariables = false
        var highlightsUppercaseTypes = true
    }

    struct HighlightToken {
        var html: String
        var end: Int
    }

    static func normalized(_ language: String?) -> String? {
        guard let language else {
            return nil
        }
        let raw = language
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(whereSeparator: { $0.isWhitespace })
            .first?
            .lowercased()
        guard let raw, !raw.isEmpty else {
            return nil
        }

        return languageAliases[raw] ?? raw
    }

    // swiftlint:disable:next cyclomatic_complexity function_body_length
    static func profile(for language: String) -> LanguageProfile {
        switch language {
        case "bash":
            return .init(
                keywords: [
                    "case", "do", "done", "elif", "else", "esac", "export",
                    "fi", "for", "function", "if", "in", "local", "then",
                    "while",
                ],
                literals: ["false", "true"],
                lineComments: ["#"],
                strings: ["\"", "'"],
                shellVariables: true,
                highlightsUppercaseTypes: false,
            )
        case "c":
            return cLike(
                keywords: [
                    "break", "case", "const", "continue", "default", "do",
                    "else", "enum", "extern", "for", "goto", "if", "inline",
                    "return", "sizeof", "static", "struct", "switch",
                    "typedef", "union", "volatile", "while",
                ],
                types: [
                    "bool", "char", "double", "float", "int", "long", "short",
                    "size_t", "ssize_t", "uint32_t", "uint64_t", "void",
                ],
            )
        case "cpp":
            var profile = profile(for: "c")
            profile.keywords.formUnion([
                "catch", "class", "concept", "constexpr", "delete",
                "explicit", "friend", "namespace", "new", "noexcept",
                "operator", "private", "protected", "public", "requires",
                "template", "this", "throw", "try", "typename", "using",
                "virtual",
            ])
            profile.types.formUnion(["auto", "string", "vector"])
            profile.literals.formUnion(["false", "nullptr", "true"])
            return profile
        case "csharp":
            return cLike(
                keywords: [
                    "async", "await", "break", "case", "catch", "class",
                    "const", "continue", "default", "delegate", "do", "else",
                    "enum", "event", "for", "foreach", "if", "interface",
                    "internal", "is", "lock", "namespace", "new", "out",
                    "override", "private", "protected", "public", "readonly",
                    "return", "sealed", "static", "switch", "this", "throw",
                    "try", "using", "var", "virtual", "void", "while",
                ],
                types: ["bool", "decimal", "double", "float", "int", "long", "object", "string"],
            )
        case "go":
            return cLike(
                keywords: [
                    "break", "case", "chan", "const", "continue", "defer",
                    "else", "fallthrough", "for", "func", "go", "goto", "if",
                    "import", "interface", "map", "package", "range", "return",
                    "select", "struct", "switch", "type", "var",
                ],
                types: [
                    "bool", "byte", "error", "float64", "int", "int64", "rune",
                    "string", "uint64",
                ],
            )
        case "java":
            return cLike(
                keywords: [
                    "abstract", "break", "case", "catch", "class", "continue",
                    "default", "do", "else", "extends", "final", "finally",
                    "for", "if", "implements", "import", "instanceof",
                    "interface", "new", "package", "private", "protected",
                    "public", "return", "static", "super", "switch", "this",
                    "throw", "throws", "try", "while",
                ],
                types: ["boolean", "char", "double", "float", "int", "long", "String", "void"],
            )
        case "javascript", "typescript":
            var keywords: Set = [
                "async", "await", "break", "case", "catch", "class", "const",
                "continue", "default", "do", "else", "export", "extends",
                "finally", "for", "from", "function", "if", "import", "in",
                "instanceof", "let", "new", "of", "return", "static",
                "super", "switch", "this", "throw", "try", "typeof", "var",
                "void", "while", "yield",
            ]
            var types: Set = [
                "Array", "Boolean", "Date", "Map", "Number", "Object", "Promise",
                "Set", "String",
            ]
            if language == "typescript" {
                keywords.formUnion([
                    "as", "declare", "enum", "implements", "interface", "keyof",
                    "namespace", "private", "protected", "public", "readonly",
                    "type",
                ])
                types.formUnion(["any", "boolean", "never", "number", "string", "unknown"])
            }
            return cLike(keywords: keywords, types: types, strings: ["\"", "'", "`"])
        case "kotlin":
            return cLike(
                keywords: [
                    "as", "break", "by", "catch", "class", "companion", "const",
                    "continue", "data", "do", "else", "enum", "false", "for",
                    "fun", "if", "import", "in", "interface", "is", "null",
                    "object", "package", "private", "protected", "public",
                    "return", "sealed", "super", "this", "throw", "true",
                    "try", "typealias", "val", "var", "when", "while",
                ],
                types: ["Any", "Boolean", "Double", "Float", "Int", "Long", "String", "Unit"],
            )
        case "python":
            return .init(
                keywords: [
                    "and", "as", "assert", "async", "await", "break", "class",
                    "continue", "def", "del", "elif", "else", "except",
                    "finally", "for", "from", "global", "if", "import", "in",
                    "is", "lambda", "nonlocal", "not", "or", "pass", "raise",
                    "return", "try", "while", "with", "yield",
                ],
                types: ["bool", "dict", "float", "int", "list", "set", "str", "tuple"],
                literals: ["False", "None", "True"],
                lineComments: ["#"],
                strings: ["\"", "'"],
            )
        case "ruby":
            return .init(
                keywords: [
                    "alias", "and", "begin", "break", "case", "class", "def",
                    "do", "else", "elsif", "end", "ensure", "for", "if", "in",
                    "module", "next", "nil", "not", "or", "redo", "rescue",
                    "retry", "return", "self", "super", "then", "unless",
                    "until", "when", "while", "yield",
                ],
                literals: ["false", "nil", "true"],
                lineComments: ["#"],
                strings: ["\"", "'"],
            )
        case "rust":
            return cLike(
                keywords: [
                    "as", "async", "await", "break", "const", "continue",
                    "crate", "else", "enum", "extern", "fn", "for", "if",
                    "impl", "in", "let", "loop", "match", "mod", "move",
                    "mut", "pub", "ref", "return", "self", "Self", "static",
                    "struct", "super", "trait", "type", "unsafe", "use",
                    "where", "while",
                ],
                types: ["bool", "char", "f64", "i32", "i64", "Option", "Result", "String", "str", "u32", "u64", "Vec"],
            )
        case "sql":
            return .init(
                keywords: [
                    "and", "as", "by", "case", "create", "delete", "desc",
                    "distinct", "drop", "else", "end", "from", "group",
                    "having", "in", "insert", "into", "is", "join", "left",
                    "limit", "not", "null", "on", "or", "order", "outer",
                    "right", "select", "set", "table", "then", "union",
                    "update", "values", "when", "where",
                ],
                types: ["bigint", "boolean", "date", "integer", "numeric", "text", "timestamp", "varchar"],
                literals: ["false", "null", "true"],
                lineComments: ["--"],
                blockComments: [("/*", "*/")],
                strings: ["'"],
                highlightsUppercaseTypes: false,
            )
        case "swift":
            return cLike(
                keywords: [
                    "actor", "any", "as", "associatedtype", "async", "await",
                    "break", "case", "catch", "class", "continue", "default",
                    "defer", "deinit", "do", "else", "enum", "extension",
                    "fallthrough", "fileprivate", "final", "for", "func",
                    "guard", "if", "import", "in", "init", "inout", "internal",
                    "is", "let", "mutating", "nonisolated", "open", "operator",
                    "private", "protocol", "public", "repeat", "rethrows",
                    "return", "self", "Self", "static", "struct", "subscript",
                    "super", "switch", "throw", "throws", "try", "typealias",
                    "var", "where", "while",
                ],
                types: [
                    "Array",
                    "Bool",
                    "Character",
                    "Data",
                    "Date",
                    "Dictionary",
                    "Double",
                    "Error",
                    "Float",
                    "Int",
                    "Never",
                    "Optional",
                    "Result",
                    "Set",
                    "String",
                    "URL",
                    "Void",
                ],
            )
        default:
            return cLike(
                keywords: [
                    "class", "const", "false", "for", "function", "if", "let",
                    "null", "return", "true", "var", "while",
                ],
                types: [],
            )
        }
    }

    static func cLike(
        keywords: Set<String>,
        types: Set<String>,
        strings: Set<Character> = ["\"", "'"],
    ) -> LanguageProfile {
        .init(
            keywords: keywords,
            types: types,
            literals: ["false", "nil", "null", "true"],
            lineComments: ["//"],
            blockComments: [("/*", "*/")],
            strings: strings,
        )
    }

    static func commonHTML(_ source: String, profile: LanguageProfile) -> String {
        highlightCode(source) { chars, cursor in
            if let comment = lineComment(in: chars, at: cursor, profile: profile) {
                return token("tok-comment", chars, cursor ..< comment)
            }
            if let comment = blockComment(in: chars, at: cursor, profile: profile) {
                return token("tok-comment", chars, cursor ..< comment)
            }
            if profile.strings.contains(chars[cursor]) {
                return token("tok-string", chars, cursor ..< quotedStringEnd(in: chars, from: cursor))
            }
            if chars[cursor] == "@", cursor + 1 < chars.count, isIdentifierStart(chars[cursor + 1]) {
                return token("tok-attribute", chars, cursor ..< identifierEnd(in: chars, from: cursor + 1))
            }
            if profile.shellVariables, chars[cursor] == "$" {
                return token("tok-property", chars, cursor ..< shellVariableEnd(in: chars, from: cursor))
            }
            if isNumberStart(in: chars, at: cursor) {
                return token("tok-number", chars, cursor ..< numberEnd(in: chars, from: cursor))
            }
            if isIdentifierStart(chars[cursor]) {
                return identifierToken(in: chars, at: cursor, profile: profile)
            }
            if isOperator(chars[cursor]) {
                return token("tok-operator", chars, cursor ..< (cursor + 1))
            }
            return nil
        }
    }

    static func identifierToken(
        in chars: [Character],
        at cursor: Int,
        profile: LanguageProfile,
    ) -> HighlightToken? {
        let end = identifierEnd(in: chars, from: cursor)
        let raw = String(chars[cursor ..< end])
        let folded = raw.lowercased()

        if profile.keywords.contains(raw) || profile.keywords.contains(folded) {
            return token("tok-keyword", raw, end)
        }
        if profile.literals.contains(raw) || profile.literals.contains(folded) {
            return token("tok-literal", raw, end)
        }
        if profile.types.contains(raw) || profile.types.contains(folded) {
            return token("tok-type", raw, end)
        }
        if profile.highlightsUppercaseTypes, raw.first?.isUppercase == true {
            return token("tok-type", raw, end)
        }
        if isFunctionCall(in: chars, after: end) {
            return token("tok-function", raw, end)
        }
        return nil
    }

    static func jsonHTML(_ source: String) -> String {
        highlightCode(source) { chars, cursor in
            if chars[cursor] == "\"" {
                let end = quotedStringEnd(in: chars, from: cursor)
                let className = nextNonWhitespace(in: chars, from: end) == ":" ? "tok-property" : "tok-string"
                return token(className, chars, cursor ..< end)
            }
            if isNumberStart(in: chars, at: cursor) {
                return token("tok-number", chars, cursor ..< numberEnd(in: chars, from: cursor))
            }
            if isIdentifierStart(chars[cursor]) {
                let end = identifierEnd(in: chars, from: cursor)
                let raw = String(chars[cursor ..< end])
                if ["false", "null", "true"].contains(raw) {
                    return token("tok-literal", raw, end)
                }
            }
            if "{}[],:".contains(chars[cursor]) {
                return token("tok-operator", chars, cursor ..< (cursor + 1))
            }
            return nil
        }
    }

    static func keyedLineHTML(_ source: String) -> String {
        source.components(separatedBy: "\n")
            .map(highlightKeyedLine)
            .joined(separator: "\n")
    }

    static func highlightKeyedLine(_ line: String) -> String {
        let chars = Array(line)
        guard !chars.isEmpty else {
            return ""
        }

        let bodyStart = chars.firstIndex { !$0.isWhitespace } ?? chars.count
        guard bodyStart < chars.count else {
            return escape(line)
        }
        if chars[bodyStart] == "#" {
            return escape(String(chars[..<bodyStart])) + span("tok-comment", String(chars[bodyStart...]))
        }
        if let colon = firstColon(in: chars, from: bodyStart) {
            return escape(String(chars[..<bodyStart]))
                + span("tok-property", String(chars[bodyStart ..< colon]))
                + span("tok-operator", ":")
                + scalarHTML(String(chars[(colon + 1)...]))
        }
        return scalarHTML(line)
    }

    static func scalarHTML(_ source: String) -> String {
        highlightCode(source) { chars, cursor in
            if chars[cursor] == "#" {
                return token("tok-comment", chars, cursor ..< lineEnd(in: chars, from: cursor))
            }
            if chars[cursor] == "\"" || chars[cursor] == "'" {
                return token("tok-string", chars, cursor ..< quotedStringEnd(in: chars, from: cursor))
            }
            if isNumberStart(in: chars, at: cursor) {
                return token("tok-number", chars, cursor ..< numberEnd(in: chars, from: cursor))
            }
            if isIdentifierStart(chars[cursor]) {
                let end = identifierEnd(in: chars, from: cursor)
                let raw = String(chars[cursor ..< end])
                if ["false", "no", "null", "true", "yes"].contains(raw.lowercased()) {
                    return token("tok-literal", raw, end)
                }
            }
            if "[]{}:,".contains(chars[cursor]) {
                return token("tok-operator", chars, cursor ..< (cursor + 1))
            }
            return nil
        }
    }

    static func cssHTML(_ source: String) -> String {
        highlightCode(source) { chars, cursor in
            if hasPrefix("/*", in: chars, at: cursor) {
                return token("tok-comment", chars, cursor ..< blockCommentEnd(in: chars, from: cursor, close: "*/"))
            }
            if chars[cursor] == "\"" || chars[cursor] == "'" {
                return token("tok-string", chars, cursor ..< quotedStringEnd(in: chars, from: cursor))
            }
            if chars[cursor] == "@", cursor + 1 < chars.count {
                return token("tok-keyword", chars, cursor ..< cssNameEnd(in: chars, from: cursor + 1))
            }
            if chars[cursor] == "#", cursor + 1 < chars.count, chars[cursor + 1].isHexDigit {
                return token("tok-number", chars, cursor ..< cssNameEnd(in: chars, from: cursor + 1))
            }
            if isNumberStart(in: chars, at: cursor) {
                return token("tok-number", chars, cursor ..< cssNumberEnd(in: chars, from: cursor))
            }
            if isCSSNameStart(chars[cursor]) {
                let end = cssNameEnd(in: chars, from: cursor)
                let className = nextNonWhitespace(in: chars, from: end) == ":" ? "tok-property" : "tok-function"
                return token(className, chars, cursor ..< end)
            }
            if "{}[]():;,.>+~=*|".contains(chars[cursor]) {
                return token("tok-operator", chars, cursor ..< (cursor + 1))
            }
            return nil
        }
    }

    static func markupHTML(_ source: String) -> String {
        let chars = Array(source)
        var output = ""
        var cursor = 0

        while cursor < chars.count {
            if hasPrefix("<!--", in: chars, at: cursor) {
                let end = blockCommentEnd(in: chars, from: cursor, close: "-->")
                output += span("tok-comment", String(chars[cursor ..< end]))
                cursor = end
            } else if chars[cursor] == "<" {
                let highlighted = markupTag(in: chars, from: cursor)
                output += highlighted.html
                cursor = highlighted.end
            } else {
                output += escape(String(chars[cursor]))
                cursor += 1
            }
        }

        return output
    }

    static func markupTag(in chars: [Character], from start: Int) -> HighlightToken {
        var output = span("tok-operator", "<")
        var cursor = start + 1

        if cursor < chars.count, chars[cursor] == "/" {
            output += span("tok-operator", "/")
            cursor += 1
        }
        if cursor < chars.count, isMarkupNameStart(chars[cursor]) {
            let end = markupNameEnd(in: chars, from: cursor)
            output += span("tok-keyword", String(chars[cursor ..< end]))
            cursor = end
        }

        while cursor < chars.count {
            if chars[cursor] == ">" {
                output += span("tok-operator", ">")
                return .init(html: output, end: cursor + 1)
            }
            if hasPrefix("/>", in: chars, at: cursor) {
                output += span("tok-operator", "/>")
                return .init(html: output, end: cursor + 2)
            }
            if chars[cursor] == "\"" || chars[cursor] == "'" {
                let end = quotedStringEnd(in: chars, from: cursor)
                output += span("tok-string", String(chars[cursor ..< end]))
                cursor = end
            } else if isMarkupNameStart(chars[cursor]) {
                let end = markupNameEnd(in: chars, from: cursor)
                output += span("tok-property", String(chars[cursor ..< end]))
                cursor = end
            } else if "=!?:".contains(chars[cursor]) {
                output += span("tok-operator", String(chars[cursor]))
                cursor += 1
            } else {
                output += escape(String(chars[cursor]))
                cursor += 1
            }
        }

        return .init(html: output, end: chars.count)
    }

    static func highlightCode(
        _ source: String,
        tokenProvider: ([Character], Int) -> HighlightToken?,
    ) -> String {
        let chars = Array(source)
        var output = ""
        var cursor = 0

        while cursor < chars.count {
            if let highlighted = tokenProvider(chars, cursor), highlighted.end > cursor {
                output += highlighted.html
                cursor = highlighted.end
            } else {
                output += escape(String(chars[cursor]))
                cursor += 1
            }
        }

        return output
    }

    static func lineComment(
        in chars: [Character],
        at cursor: Int,
        profile: LanguageProfile,
    ) -> Int? {
        for marker in profile.lineComments where hasPrefix(marker, in: chars, at: cursor) {
            return lineEnd(in: chars, from: cursor)
        }
        return nil
    }

    static func blockComment(
        in chars: [Character],
        at cursor: Int,
        profile: LanguageProfile,
    ) -> Int? {
        for marker in profile.blockComments where hasPrefix(marker.open, in: chars, at: cursor) {
            return blockCommentEnd(in: chars, from: cursor, close: marker.close)
        }
        return nil
    }

    static func firstColon(in chars: [Character], from start: Int) -> Int? {
        var cursor = start
        while cursor < chars.count {
            if chars[cursor] == ":" {
                return cursor
            }
            if chars[cursor] == "\"" || chars[cursor] == "'" {
                cursor = quotedStringEnd(in: chars, from: cursor)
            } else {
                cursor += 1
            }
        }
        return nil
    }

    static func quotedStringEnd(in chars: [Character], from start: Int) -> Int {
        let quote = chars[start]
        let triple = String(repeating: String(quote), count: 3)
        if hasPrefix(triple, in: chars, at: start) {
            var cursor = start + 3
            while cursor < chars.count {
                if hasPrefix(triple, in: chars, at: cursor) {
                    return cursor + 3
                }
                cursor += 1
            }
            return chars.count
        }

        var cursor = start + 1
        var escaped = false
        while cursor < chars.count {
            if escaped {
                escaped = false
            } else if chars[cursor] == "\\" {
                escaped = true
            } else if chars[cursor] == quote {
                return cursor + 1
            }
            cursor += 1
        }
        return chars.count
    }

    static func blockCommentEnd(in chars: [Character], from start: Int, close: String) -> Int {
        var cursor = start + 1
        while cursor < chars.count {
            if hasPrefix(close, in: chars, at: cursor) {
                return cursor + close.count
            }
            cursor += 1
        }
        return chars.count
    }

    static func lineEnd(in chars: [Character], from start: Int) -> Int {
        var cursor = start
        while cursor < chars.count, chars[cursor] != "\n" {
            cursor += 1
        }
        return cursor
    }

    static func identifierEnd(in chars: [Character], from start: Int) -> Int {
        var cursor = start
        while cursor < chars.count, isIdentifierBody(chars[cursor]) {
            cursor += 1
        }
        return cursor
    }

    static func cssNameEnd(in chars: [Character], from start: Int) -> Int {
        var cursor = start
        while cursor < chars.count, isCSSNameBody(chars[cursor]) {
            cursor += 1
        }
        return cursor
    }

    static func markupNameEnd(in chars: [Character], from start: Int) -> Int {
        var cursor = start
        while cursor < chars.count, isMarkupNameBody(chars[cursor]) {
            cursor += 1
        }
        return cursor
    }

    static func numberEnd(in chars: [Character], from start: Int) -> Int {
        var cursor = start
        if chars[cursor] == "-" {
            cursor += 1
        }
        if cursor + 1 < chars.count, chars[cursor] == "0", chars[cursor + 1].lowercased() == "x" {
            cursor += 2
            while cursor < chars.count, chars[cursor].isHexDigitOrSeparator {
                cursor += 1
            }
            return cursor
        }
        while cursor < chars.count, chars[cursor].isDecimalNumberBody {
            cursor += 1
        }
        return cursor
    }

    static func cssNumberEnd(in chars: [Character], from start: Int) -> Int {
        var cursor = numberEnd(in: chars, from: start)
        while cursor < chars.count, isCSSNameBody(chars[cursor]) || chars[cursor] == "%" {
            cursor += 1
        }
        return cursor
    }

    static func shellVariableEnd(in chars: [Character], from start: Int) -> Int {
        var cursor = start + 1
        if cursor < chars.count, chars[cursor] == "{" {
            cursor += 1
            while cursor < chars.count, chars[cursor] != "}" {
                cursor += 1
            }
            return cursor < chars.count ? cursor + 1 : chars.count
        }
        while cursor < chars.count, isIdentifierBody(chars[cursor]) {
            cursor += 1
        }
        return cursor > start + 1 ? cursor : start + 1
    }

    static func nextNonWhitespace(in chars: [Character], from start: Int) -> Character? {
        var cursor = start
        while cursor < chars.count {
            if !chars[cursor].isWhitespace {
                return chars[cursor]
            }
            cursor += 1
        }
        return nil
    }

    static func isFunctionCall(in chars: [Character], after start: Int) -> Bool {
        nextNonWhitespace(in: chars, from: start) == "("
    }

    static func isNumberStart(in chars: [Character], at cursor: Int) -> Bool {
        chars[cursor].isNumber || (chars[cursor] == "-" && cursor + 1 < chars.count && chars[cursor + 1].isNumber)
    }

    static func isIdentifierStart(_ character: Character) -> Bool {
        character == "_" || character.isLetter
    }

    static func isIdentifierBody(_ character: Character) -> Bool {
        isIdentifierStart(character) || character.isNumber
    }

    static func isCSSNameStart(_ character: Character) -> Bool {
        character == "-" || character == "_" || character.isLetter
    }

    static func isCSSNameBody(_ character: Character) -> Bool {
        isCSSNameStart(character) || character.isNumber
    }

    static func isMarkupNameStart(_ character: Character) -> Bool {
        isIdentifierStart(character)
    }

    static func isMarkupNameBody(_ character: Character) -> Bool {
        isIdentifierBody(character) || "-:.".contains(character)
    }

    static func isOperator(_ character: Character) -> Bool {
        "=+-*/%<>!&|^~?:.".contains(character)
    }

    static func hasPrefix(_ prefix: String, in chars: [Character], at index: Int) -> Bool {
        let prefixChars = Array(prefix)
        guard index + prefixChars.count <= chars.count else {
            return false
        }
        return Array(chars[index ..< (index + prefixChars.count)]) == prefixChars
    }

    static func token(_ className: String, _ raw: String, _ end: Int) -> HighlightToken {
        HighlightToken(html: span(className, raw), end: end)
    }

    static func token(_ className: String, _ chars: [Character], _ range: Range<Int>) -> HighlightToken {
        token(className, String(chars[range]), range.upperBound)
    }

    static func span(_ className: String, _ raw: String) -> String {
        "<span class=\"\(className)\">\(escape(raw))</span>"
    }

    static func escape(_ raw: String) -> String {
        TileKit.HTML.escapeText(raw)
    }
}

private extension Character {
    var isHexDigit: Bool {
        isNumber || "abcdefABCDEF".contains(self)
    }

    var isHexDigitOrSeparator: Bool {
        isHexDigit || self == "_"
    }

    var isDecimalNumberBody: Bool {
        isNumber || "._".contains(self)
    }
}

// swiftlint:enable file_length
