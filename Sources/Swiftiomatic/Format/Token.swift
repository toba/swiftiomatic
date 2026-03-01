import Foundation

// https://developer.apple.com/library/ios/documentation/Swift/Conceptual/Swift_Programming_Language/LexicalStructure.html

/// Reserved Swift keywords used for fast token matching
///
/// `Any`, `Self`, `self`, `super`, `nil`, `true`, and `false` are omitted
/// because they behave like identifiers. Context-specific keywords such as
/// `async`, `lazy`, `mutating`, `some`, etc. are also excluded.
let swiftKeywords = Set([
    "let", "return", "func", "var", "if", "public", "as", "else", "in", "import",
    "class", "try", "guard", "case", "for", "init", "extension", "private", "static",
    "fileprivate", "internal", "switch", "do", "catch", "enum", "struct", "throws",
    "throw", "typealias", "where", "break", "deinit", "subscript", "is", "while",
    "associatedtype", "inout", "continue", "fallthrough", "operator", "precedencegroup",
    "repeat", "rethrows", "default", "protocol", "defer", "await", "consume", "discard",
    // Any, Self, self, super, nil, true, false
])

extension String {
    /// Is this string a reserved keyword in Swift?
    var isSwiftKeyword: Bool { swiftKeywords.contains(self) }

    /// Is a keyword when used in a type position?
    var isKeywordInTypeContext: Bool {
        ["borrowing", "consuming", "isolated", "sending", "some", "any", "of"].contains(self)
    }

    /// Is this a macro name or conditional compilation directive?
    var isMacroOrCompilerDirective: Bool { hasPrefix("#") }

    /// Is this a macro name?
    var isMacro: Bool {
        isMacroOrCompilerDirective && !["#if", "#elseif", "#else", "#endif"].contains(self)
    }

    /// Is this an attribute name?
    var isAttribute: Bool { hasPrefix("@") }

    /// Is this a macro name or conditional compilation directive?
    var isMacroOrAttribute: Bool { isMacro || isAttribute }

    /// Is this string a valid operator?
    var isOperator: Bool {
        let tokens = tokenize(self)
        return tokens.count == 1 && tokens[0].isOperator
    }

    /// Is this string a comment directive (MARK:, TODO:, sm:, etc)?
    var isCommentDirective: Bool { commentDirective != nil }

    /// Returns comment directive prefix (MARK:, TODO:, sm:, etc)?
    var commentDirective: String? {
        let parts = split(separator: ":")
        guard parts.count > 1 else { return nil }
        let exclude = ["note", "warning"]

        guard !parts[0].contains(" "), !exclude.contains(parts[0].lowercased()),
              !parts[1].hasPrefix("//")
        else {
            return nil
        }
        return String(parts[0])
    }
}

/// Categories of ``Token`` used for pattern matching in ``Formatter`` queries
enum TokenType {
    case space
    case comment
    case lineBreak
    case endOfStatement
    case startOfScope
    case endOfScope
    case keyword
    case delimiter
    case identifier
    case attribute
    case `operator`
    case unwrapOperator
    case rangeOperator
    case number
    case error

    /// OR types
    case spaceOrComment
    case spaceOrLineBreak
    case spaceOrCommentOrLineBreak
    case keywordOrAttribute
    case identifierOrKeyword

    /// NOT types
    case nonSpace
    case nonLineBreak
    case nonSpaceOrComment
    case nonSpaceOrLineBreak
    case nonSpaceOrCommentOrLineBreak
}

/// The base of a numeric literal token
enum NumberType: String {
    case integer
    case decimal
    case binary
    case octal
    case hex
}

/// The fixity of an operator token
enum OperatorType: String {
    case none
    case infix
    case prefix
    case postfix
}

/// The original 1-based line number of a token before formatting
typealias OriginalLine = Int

/// A single lexical token produced by the Swift tokenizer
enum Token: Hashable {
    case number(String, NumberType)
    case lineBreak(String, OriginalLine)
    case startOfScope(String)
    case endOfScope(String)
    case delimiter(String)
    case `operator`(String, OperatorType)
    case stringBody(String)
    case keyword(String)
    case identifier(String)
    case space(String)
    case commentBody(String)
    case error(String)
}

private extension Token {
    /// Test if token matches type of another token
    func hasType(of token: Token) -> Bool {
        switch (self, token) {
            case (.number, .number),
                 (.operator, .operator),
                 (.lineBreak, .lineBreak),
                 (.startOfScope, .startOfScope),
                 (.endOfScope, .endOfScope),
                 (.delimiter, .delimiter),
                 (.keyword, .keyword),
                 (.identifier, .identifier),
                 (.stringBody, .stringBody),
                 (.commentBody, .commentBody),
                 (.space, .space),
                 (.error, .error):
                return true
            case (.number, _),
                 (.operator, _),
                 (.lineBreak, _),
                 (.startOfScope, _),
                 (.endOfScope, _),
                 (.delimiter, _),
                 (.keyword, _),
                 (.identifier, _),
                 (.stringBody, _),
                 (.commentBody, _),
                 (.space, _),
                 (.error, _):
                return false
        }
    }
}

extension Token {
    /// Metadata about a string or regex delimiter token
    struct StringDelimiterType {
        var isRegex: Bool
        var isMultiline: Bool
        var hashCount: Int
    }

    var stringDelimiterType: StringDelimiterType? {
        switch self {
            case let .startOfScope(string), let .endOfScope(string):
                var quoteCount = 0
                var hashCount = 0
                var slashCount = 0
                for c in string {
                    switch c {
                        case "#": hashCount += 1
                        case "\"": quoteCount += 1
                        case "/": slashCount += 1
                        default: return nil
                    }
                }
                let isRegex = slashCount == 1
                guard quoteCount > 0 || isRegex else { return nil }
                return StringDelimiterType(
                    isRegex: isRegex,
                    isMultiline: quoteCount == 3 || (isRegex && hashCount > 0),
                    hashCount: hashCount,
                )
            default:
                return nil
        }
    }
}

extension Token {
    /// The original token string
    var string: String {
        switch self {
            case let .number(string, _),
                 let .lineBreak(string, _),
                 let .startOfScope(string),
                 let .endOfScope(string),
                 let .delimiter(string),
                 let .operator(string, _),
                 let .stringBody(string),
                 let .keyword(string),
                 let .identifier(string),
                 let .space(string),
                 let .commentBody(string),
                 let .error(string):
                return string
        }
    }

    /// Returns the visual column width of this token
    ///
    /// - Parameters:
    ///   - tabWidth: The number of columns a tab character occupies.
    func columnWidth(tabWidth: Int) -> Int {
        switch self {
            case let .space(string), let .stringBody(string), let .commentBody(string):
                guard tabWidth > 1 else {
                    return string.count
                }
                return string.reduce(0) { count, character in
                    count + (character == "\t" ? tabWidth : 1)
                }
            case .lineBreak:
                return 0
            default:
                return string.count
        }
    }

    /// Returns the unescaped token string
    func unescaped() -> String {
        switch self {
            case let .stringBody(string):
                var input = UnicodeScalarView(string.unicodeScalars)
                var output = String.UnicodeScalarView()
                while let c = input.popFirst() {
                    if c == "\\" {
                        _ = input.readCharacters { $0 == "#" }
                        if let c = input.popFirst() {
                            switch c {
                                case "\0": output.append("\0")
                                case "\\": output.append("\\")
                                case "t": output.append("\t")
                                case "n": output.append("\n")
                                case "r": output.append("\r")
                                case "\"": output.append("\"")
                                case "\'": output.append("\'")
                                case "u":
                                    guard input.read("{"),
                                          let hex = input.readCharacters(where: { $0.isHexDigit }),
                                          input.read("}"),
                                          let codepoint = Int(hex, radix: 16),
                                          let c = UnicodeScalar(codepoint)
                                    else {
                                        // Invalid. Recover and continue
                                        continue
                                    }
                                    output.append(c)
                                default:
                                    // Invalid, but doesn't affect parsing
                                    output.append(c)
                            }
                        } else {
                            // If a string body ends with \, it's probably part of a string
                            // interpolation expression, so the next token should be a `(`
                        }
                    } else {
                        output.append(c)
                    }
                }
                return String(output)
            case let .identifier(string):
                if string.hasPrefix("$") { return String(string.dropFirst()) }
                return string.replacingOccurrences(of: "`", with: "")
            case let .number(string, .integer), let .number(string, .decimal):
                return string.replacingOccurrences(of: "_", with: "")
            case let .number(s, .binary), let .number(s, .octal), let .number(s, .hex):
                var characters = UnicodeScalarView(s.unicodeScalars)
                guard characters.read("0"),
                      characters.readCharacter(where: {
                          "oxb".unicodeScalars.contains($0)
                      }) != nil
                else {
                    return s.replacingOccurrences(of: "_", with: "")
                }
                return String(characters.unicodeScalars).replacingOccurrences(of: "_", with: "")
            default:
                return string
        }
    }

    /// Tests whether this token matches the given ``TokenType`` category
    ///
    /// - Parameters:
    ///   - type: The token category to test against.
    func `is`(_ type: TokenType) -> Bool {
        switch type {
            case .space: isSpace
            case .comment: isComment
            case .spaceOrComment: isSpaceOrComment
            case .spaceOrLineBreak: isSpaceOrLineBreak
            case .spaceOrCommentOrLineBreak: isSpaceOrCommentOrLineBreak
            case .lineBreak: isLineBreak
            case .endOfStatement: isEndOfStatement
            case .startOfScope: isStartOfScope
            case .endOfScope: isEndOfScope
            case .keyword: isKeyword
            case .keywordOrAttribute: isKeywordOrAttribute
            case .identifier: isIdentifier
            case .identifierOrKeyword: isIdentifierOrKeyword
            case .attribute: isAttribute
            case .delimiter: isDelimiter
            case .operator: isOperator
            case .unwrapOperator: isUnwrapOperator
            case .rangeOperator: isRangeOperator
            case .number: isNumber
            case .error: isError
            case .nonSpace: !isSpace
            case .nonLineBreak: !isLineBreak
            case .nonSpaceOrComment: !isSpaceOrComment
            case .nonSpaceOrLineBreak: !isSpaceOrLineBreak
            case .nonSpaceOrCommentOrLineBreak: !isSpaceOrCommentOrLineBreak
        }
    }

    var isAttribute: Bool { isKeywordOrAttribute && string.isAttribute }
    var isDelimiter: Bool { hasType(of: .delimiter("")) }
    var isOperator: Bool { hasType(of: .operator("", .none)) }
    var isUnwrapOperator: Bool { isOperator("?", .postfix) || isOperator("!", .postfix) }
    var isRangeOperator: Bool { isOperator("...") || isOperator("..<") }
    var isNumber: Bool { hasType(of: .number("", .integer)) }
    var isError: Bool { hasType(of: .error("")) }
    var isStartOfScope: Bool { hasType(of: .startOfScope("")) }
    var isEndOfScope: Bool { hasType(of: .endOfScope("")) }
    var isKeyword: Bool { isKeywordOrAttribute && !string.isAttribute }
    var isKeywordOrAttribute: Bool { hasType(of: .keyword("")) }
    var isIdentifier: Bool { hasType(of: .identifier("")) }
    var isIdentifierOrKeyword: Bool { isIdentifier || isKeywordOrAttribute }
    var isSpace: Bool { hasType(of: .space("")) }
    var isLineBreak: Bool { hasType(of: .lineBreak("", 0)) }
    var isEndOfStatement: Bool { self == .delimiter(";") || isLineBreak }
    var isSpaceOrLineBreak: Bool { isSpace || isLineBreak }
    var isSpaceOrComment: Bool { isSpace || isComment }
    var isSpaceOrCommentOrLineBreak: Bool { isSpaceOrComment || isLineBreak }
    var isNonSpaceOrCommentOrLineBreak: Bool { !isSpaceOrCommentOrLineBreak }
    var isCommentOrLineBreak: Bool { isComment || isLineBreak }

    var isMacro: Bool {
        if case let .keyword(string) = self { string.isMacro } else { false }
    }

    var isSwitchCaseOrDefault: Bool {
        if case let .endOfScope(string) = self {
            return ["case", "default"].contains(string)
        }
        return self == .keyword("@unknown") // support `@unknown default` as well
    }

    func isOperator(_ string: String) -> Bool {
        if case .operator(string, _) = self { true } else { false }
    }

    func isOperator(ofType type: OperatorType) -> Bool {
        if case .operator(_, type) = self { true } else { false }
    }

    func isOperator(_ string: String, _ type: OperatorType) -> Bool {
        if case .operator(string, type) = self { true } else { false }
    }

    var isComment: Bool {
        switch self {
            case .commentBody,
                 .startOfScope("//"),
                 .startOfScope("/*"),
                 .endOfScope("*/"):
                return true
            default:
                return false
        }
    }

    var isCommentBody: Bool {
        switch self {
            case .commentBody: true
            default: false
        }
    }

    var isStringBody: Bool {
        switch self {
            case .stringBody: true
            default: false
        }
    }

    var isStringDelimiter: Bool {
        switch self {
            case let .startOfScope(string), let .endOfScope(string):
                return string.contains("\"") || string == "/" || string.hasSuffix("#")
                    || (string.hasPrefix("#") && string.hasSuffix("/"))
            default:
                return false
        }
    }

    var isMultilineStringDelimiter: Bool {
        stringDelimiterType?.isMultiline == true
    }

    func isEndOfScope(_ token: Token) -> Bool {
        switch self {
            case let .endOfScope(closing):
                guard case let .startOfScope(opening) = token else {
                    return false
                }
                switch opening {
                    case "(": return closing == ")"
                    case "[": return closing == "]"
                    case "<": return closing == ">"
                    case "{", ":":
                        switch closing {
                            case "}", "case", "default": return true
                            default: return false
                        }
                    case "/*": return closing == "*/"
                    case "#if": return closing == "#endif"
                    default:
                        if let delimiterType = stringDelimiterType {
                            let quotes = delimiterType
                                .isRegex ? "/" : (delimiterType.isMultiline ? "\"\"\"" : "\"")
                            let hashes = String(repeating: "#", count: delimiterType.hashCount)
                            return closing == "\(quotes)\(hashes)"
                        }
                        return false
                }
            case .lineBreak:
                switch token {
                    case .startOfScope("//"), .startOfScope("#!"): return true
                    default: return false
                }
            case .delimiter(":"), .startOfScope(":"):
                switch token {
                    case .endOfScope("case"), .endOfScope("default"), .operator("?", .infix):
                        return true
                    default:
                        return false
                }
            default:
                return false
        }
    }
}

extension Token {
    var isLvalue: Bool {
        switch self {
            case .identifier, .number, .operator(_, .postfix),
                 .endOfScope(")"), .endOfScope("]"),
                 .endOfScope("}"), .endOfScope(">"),
                 .endOfScope where isStringDelimiter:
                return true
            case let .keyword(name):
                return name.isMacroOrCompilerDirective
            default:
                return false
        }
    }

    var isRvalue: Bool {
        switch self {
            case .operator(_, .infix), .operator(_, .postfix):
                return false
            case .identifier, .number, .operator,
                 .startOfScope("("), .startOfScope("["), .startOfScope("{"),
                 .startOfScope where isStringDelimiter:
                return true
            case let .keyword(name):
                return name.isMacroOrCompilerDirective
            default:
                return false
        }
    }
}

extension Collection<Token> where Index == Int {
    var string: String {
        map(\.string).joined()
    }

    /// A string representation of this array of tokens,
    /// excluding any newlines and following indentation, comments, or leading/trailing spaces.
    var stringExcludingLinebreaksAndComments: String {
        var tokens: [Token] = []

        var index = indices.startIndex
        while index < indices.endIndex {
            // Exclude any comments
            while self[index].isComment, index < indices.endIndex {
                index += 1
            }

            // Skip over any line breaks, and any indentation following the line break
            if self[index].isLineBreak {
                index += 1
                while self[index].isSpace, index < indices.endIndex {
                    index += 1
                }
            }

            if index < indices.endIndex {
                tokens.append(self[index])
                index += 1
            }
        }

        return tokens.string.trimmingCharacters(in: .whitespaces)
    }
}

extension Token: Encodable {
    private enum CodingKeys: CodingKey {
        // Properties shared by all tokens
        case type
        case string
        // Properties unique to individual tokens
        case originalLine
        case numberType
        case operatorType
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(typeName, forKey: .type)
        try container.encode(string, forKey: .string)

        switch self {
            case let .lineBreak(_, originalLine):
                try container.encode(originalLine, forKey: .originalLine)
            case let .number(_, numberType):
                try container.encode(numberType.rawValue, forKey: .numberType)
            case let .operator(_, operatorType):
                try container.encode(operatorType.rawValue, forKey: .operatorType)
            default:
                break
        }
    }

    private var typeName: String {
        switch self {
            case .number: return "number"
            case .lineBreak: return "linebreak"
            case .startOfScope: return "startOfScope"
            case .endOfScope: return "endOfScope"
            case .delimiter: return "delimiter"
            case .operator: return "operator"
            case .stringBody: return "stringBody"
            case .keyword: return "keyword"
            case .identifier: return "identifier"
            case .space: return "space"
            case .commentBody: return "commentBody"
            case .error: return "error"
        }
    }
}
