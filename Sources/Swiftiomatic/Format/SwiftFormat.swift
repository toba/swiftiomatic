import Foundation

/// The current SwiftFormat version
let swiftFormatVersion = "0.59.1"
let version = swiftFormatVersion

/// Supported Swift compiler versions
let swiftVersions = [
    "3.x", "4.0", "4.1", "4.2",
    "5.0", "5.1", "5.2", "5.3", "5.4", "5.5", "5.6", "5.7", "5.8", "5.9", "5.10",
    "6.0", "6.1", "6.2", "6.3", "6.4",
]

/// Supported Swift language modes
let languageModes = [
    "4", "4.2", "5", "6",
]

/// The default language mode for the given Swift compiler version
func defaultLanguageMode(for compilerVersion: Version) -> Version {
    switch compilerVersion {
        case "4.0" ..< "4.2":
            return "4"
        case "4.2":
            return "4.2"
        case "5.0" ..< "6.0":
            return "5"
        case "6.0"...:
            return "5"
        default:
            return .undefined
    }
}

/// An enumeration of the types of error that may be thrown by SwiftFormat
enum FormatError: Error, CustomStringConvertible, LocalizedError {
    case reading(String)
    case writing(String)
    case parsing(String)
    case options(String)

    static func invalidOption(
        _ option: String,
        for argumentName: String,
        with validOptions: [String],
    ) -> Self {
        let message = "Unsupported --\(argumentName) value '\(option)'"
        guard let match = option.bestMatch(in: validOptions) else {
            return .options("\(message). Valid options are \(validOptions.formattedList())")
        }
        return .options("\(message). Did you mean '\(match)'?")
    }

    var description: String {
        switch self {
            case let .reading(string),
                 let .writing(string),
                 let .parsing(string),
                 let .options(string):
                return string
        }
    }

    var localizedDescription: String {
        "Error: \(description)."
    }
}

/// Line and column offset in source
/// Note: line and column indexes start at 1
struct SourceOffset: Equatable, CustomStringConvertible {
    var line, column: Int

    init(line: Int, column: Int) {
        self.line = line
        self.column = column
    }

    var description: String {
        "\(line):\(column)"
    }
}

/// Get offset for token
func offsetForToken(at index: Int, in tokens: [Token], tabWidth: Int) -> SourceOffset {
    var column = 1
    for token in tokens[..<index].reversed() {
        switch token {
            case let .linebreak(_, line):
                return SourceOffset(line: line + 1, column: column)
            default:
                column += token.columnWidth(tabWidth: tabWidth)
        }
    }
    return SourceOffset(line: 1, column: column)
}

/// Get token index for offset
func tokenIndex(for offset: SourceOffset, in tokens: [Token], tabWidth: Int) -> Int {
    var tokenIndex = 0
    var line = 1
    for index in tokens.indices {
        guard case let .linebreak(_, originalLine) = tokens[index] else {
            continue
        }
        line = originalLine
        guard originalLine < offset.line else {
            break
        }
        tokenIndex = index + 1
    }
    if line < offset.line - 1 {
        return tokens.endIndex
    }
    var column = 1
    while tokenIndex < tokens.endIndex, column < offset.column {
        column += tokens[tokenIndex].columnWidth(tabWidth: tabWidth)
        tokenIndex += 1
    }
    return tokenIndex
}

/// Get token index range for line range
func tokenRange(forLineRange lineRange: ClosedRange<Int>, in tokens: [Token]) -> Range<Int> {
    let startOffset = SourceOffset(line: lineRange.lowerBound, column: 0)
    let endOffset = SourceOffset(line: lineRange.upperBound + 1, column: 0)
    let tokenStart = max(0, tokenIndex(for: startOffset, in: tokens, tabWidth: 1) - 1)
    let tokenEnd = max(tokenStart, tokenIndex(for: endOffset, in: tokens, tabWidth: 1) - 1)
    return tokenStart ..< tokenEnd
}

/// Get new offset for an original offset (before formatting)
func newOffset(for offset: SourceOffset, in tokens: [Token], tabWidth: Int) -> SourceOffset {
    var closestLine = 0
    for i in tokens.indices {
        guard case let .linebreak(_, originalLine) = tokens[i] else {
            continue
        }
        closestLine += 1
        guard originalLine >= offset.line else {
            continue
        }
        var lineLength = 0
        for j in (0 ..< i).reversed() {
            let token = tokens[j]
            if token.isLinebreak {
                break
            }
            lineLength += token.columnWidth(tabWidth: tabWidth)
        }
        return SourceOffset(line: closestLine, column: min(offset.column, lineLength + 1))
    }
    let lineLength = tokens.reduce(0) { $0 + $1.columnWidth(tabWidth: tabWidth) }
    return SourceOffset(line: closestLine + 1, column: min(offset.column, lineLength + 1))
}

/// Process parsing errors
func parsingError(for tokens: [Token], options: FormatOptions, allowErrorsInFragments: Bool = true)
    -> FormatError?
{
    guard
        let index = tokens.firstIndex(where: {
            guard (options.fragment && allowErrorsInFragments) || !$0.isError else { return true }
            guard !options.ignoreConflictMarkers,
                  case let .operator(string, _) = $0 else { return false }
            return string.hasPrefix("<<<<<") || string.hasPrefix("=====") || string
                .hasPrefix(">>>>>")
        })
    else {
        return nil
    }
    let message: String
    switch tokens[index] {
        case .error(""):
            message = "Unexpected end of file"
        case let .error(string):
            if string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                message = "Inconsistent whitespace in multi-line string literal"
            } else {
                message = "Unexpected token \(string)"
            }
        case let .operator(string, _):
            message = "Found conflict marker \(string)"
        default:
            preconditionFailure()
    }
    let offset = offsetForToken(at: index, in: tokens, tabWidth: options.tabWidth)
    return .parsing("\(message) at \(offset)")
}

/// Convert a token array back into a string
func sourceCode(for tokens: [Token]?) -> String {
    (tokens ?? []).map(\.string).joined()
}

/// Apply specified rules to a token array and optionally capture list of changes
func applyRules(
    _ originalRules: [FormatRule],
    to originalTokens: [Token],
    with options: FormatOptions,
    trackChanges: Bool,
    range originalRange: Range<Int>?,
    maxIterations: Int = 10,
) throws -> (tokens: [Token], changes: [Formatter.Change]) {
    precondition(maxIterations > 1)

    let originalRules = originalRules.sorted()
    var tokens = originalTokens
    var range = originalRange

    // Ensure rule names have been set
    if originalRules.first?.name == FormatRule.unnamedRule {
        _ = FormatRules.all
    }

    // Check for parsing errors
    if let error = parsingError(for: originalTokens, options: options) {
        throw error
    }

    // Infer shared options
    var options = options
    options.enabledRules = Set(originalRules.map(\.name))
    let sharedOptions =
        FormatRules
            .sharedOptionsForRules(originalRules)
            .compactMap { Descriptors.byName[$0] }
            .filter { $0.defaultArgument == $0.fromOptions(options) }
            .map(\.propertyName)

    inferFormatOptions(sharedOptions, from: originalTokens, into: &options)

    // Check if required FileInfo is available
    if originalRules.contains(.fileHeader) {
        let header = options.fileHeader
        let fileInfo = options.fileInfo

        for key in ReplacementKey.allCases {
            if case let .replace(string) = header,
               !fileInfo.hasReplacement(for: key, options: options),
               string.contains(key.placeholder)
            {
                throw FormatError.options(
                    "Failed to apply \(key.placeholder) template in file header as required info is unavailable",
                )
            }
        }
    }

    /// Split tokens into lines
    func getLines(in tokens: [Token], includingLinebreaks: Bool) -> [Int: ArraySlice<Token>] {
        var lines: [Int: ArraySlice<Token>] = [:]
        var startIndex = 0
        var nextLine = 1
        for (i, token) in tokens.enumerated() {
            if case let .linebreak(_, line) = token {
                let endIndex = i + (includingLinebreaks ? 1 : 0)
                if let existing = lines[line] {
                    lines[line] = tokens[existing.startIndex ..< endIndex]
                } else {
                    lines[line] = tokens[startIndex ..< endIndex]
                }
                nextLine = line + 1
                startIndex = i + 1
            }
        }
        lines[nextLine] = tokens[startIndex...]
        return lines
    }

    // Apply trim/indent rule once at start
    var rules = originalRules
    if rules.contains(.indent) {
        rules.insert(.indent, at: 0)
        if rules.contains(.trailingSpace) {
            rules.insert(.trailingSpace, at: 0)
        }
    }

    // Apply rules sequentially until no changes are detected
    var changes = [Formatter.Change]()
    var lastChanges = [Formatter.Change]()
    for iteration in 0 ..< maxIterations {
        let formatter = Formatter(
            tokens, options: options,
            trackChanges: trackChanges, range: range,
        )
        for rule in rules {
            rule.apply(with: formatter)
        }

        // Abort if there are fatal errors
        if let error = formatter.errors.first, !options.fragment {
            throw error
        }

        // Record changes
        lastChanges = formatter.changes
        changes += lastChanges

        // Update range and discard unwanted changes
        var newTokens = formatter.tokens
        if let oldRange = range, let newRange = formatter.range {
            newTokens = Array(
                tokens[..<oldRange.lowerBound] + newTokens[newRange] +
                    tokens[oldRange.upperBound...],
            )
            range = oldRange.lowerBound ..< (oldRange.lowerBound + newRange.count)
        }

        // Terminate early if there were no changes
        if tokens == newTokens {
            if changes.isEmpty {
                return (tokens, [])
            }

            changes.sort(by: {
                if $0.line == $1.line {
                    return $0.rule.name < $1.rule.name
                }
                return $0.line < $1.line
            })

            let oldLines = getLines(in: originalTokens, includingLinebreaks: true)
            let newLines = getLines(in: tokens, includingLinebreaks: true)

            var last: Formatter.Change?
            changes = changes.filter { change in
                if last == change {
                    return false
                }
                last = change
                if !change.isMove, newLines[change.line] == oldLines[change.line] {
                    return false
                }
                return true
            }
            return (tokens, changes)
        }

        tokens = newTokens

        if iteration == 0 {
            rules = originalRules
            rules.removeAll(where: { $0.runOnceOnly })
        }
    }

    let rulesApplied = Set(lastChanges.map(\.rule.name)).sorted()
    guard !rulesApplied.isEmpty else {
        throw FormatError.writing("Failed to terminate")
    }
    let names =
        rulesApplied.count == 1
            ? "\(rulesApplied[0]) rule" : "\(rulesApplied.formattedList(lastSeparator: "and")) rules"
    let changeLines = Set(lastChanges.map { "\($0.line)" }).sorted()
    let lines =
        changeLines.count == 1
            ? "line \(changeLines[0])" : "lines \(changeLines.formattedList(lastSeparator: "and"))"
    throw FormatError.writing("The \(names) failed to terminate at \(lines)")
}

/// Format a pre-parsed token array
func format(
    _ tokens: [Token], rules: [FormatRule] = FormatRules.default,
    options: FormatOptions = .default, range: Range<Int>? = nil,
) throws -> (tokens: [Token], changes: [Formatter.Change]) {
    try applyRules(rules, to: tokens, with: options, trackChanges: true, range: range)
}

/// Format code with specified rules and options
func format(
    _ source: String, rules: [FormatRule] = FormatRules.default,
    options: FormatOptions = .default, lineRange: ClosedRange<Int>? = nil,
) throws -> (output: String, changes: [Formatter.Change]) {
    let tokens = tokenize(source)
    let range = lineRange.map { tokenRange(forLineRange: $0, in: tokens) }
    let output = try format(tokens, rules: rules, options: options, range: range)
    return (sourceCode(for: output.tokens), output.changes)
}

/// Lint a pre-parsed token array
func lint(
    _ tokens: [Token], rules: [FormatRule] = FormatRules.default,
    options: FormatOptions = .default, range: Range<Int>? = nil,
) throws -> [Formatter.Change] {
    try applyRules(rules, to: tokens, with: options, trackChanges: true, range: range).changes
}

/// Lint code with specified rules and options
func lint(
    _ source: String, rules: [FormatRule] = FormatRules.default,
    options: FormatOptions = .default, lineRange: ClosedRange<Int>? = nil,
) throws -> [Formatter.Change] {
    let tokens = tokenize(source)
    let range = lineRange.map { tokenRange(forLineRange: $0, in: tokens) }
    return try lint(tokens, rules: rules, options: options, range: range)
}

// MARK: Path utilities

func expandPath(_ path: String, in directory: String) -> URL {
    let nsPath: NSString = (path as NSString).expandingTildeInPath as NSString
    if nsPath.isAbsolutePath {
        return URL(fileURLWithPath: nsPath as String).standardized
    }
    return URL(fileURLWithPath: directory, isDirectory: true).appendingPathComponent(path)
        .standardized
}

// MARK: Documentation utilities

/// Strip markdown code-formatting
func stripMarkdown(_ input: String) -> String {
    var result = ""
    var startCount = 0
    var endCount = 0
    var escaped = false
    for c in input {
        if c == "`" {
            if escaped {
                endCount += 1
            } else {
                startCount += 1
            }
        } else {
            if escaped, endCount > 0 {
                if endCount != startCount {
                    result += String(repeating: "`", count: endCount)
                } else {
                    escaped = false
                    startCount = 0
                }
                endCount = 0
            }
            if startCount > 0 {
                escaped = true
            }
            result.append(c)
        }
    }
    return result
}
