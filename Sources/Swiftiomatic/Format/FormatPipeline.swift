import Foundation

/// The current format engine version string
let swiftFormatVersion = "0.59.1"

/// Alias for ``swiftFormatVersion``
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

/// Returns the default Swift language mode for the given compiler version
///
/// - Parameters:
///   - compilerVersion: The Swift compiler ``Version`` to query.
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

/// A 1-based line and column position in source code
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

/// Returns the source offset (line and column) for the token at the given index
///
/// - Parameters:
///   - index: The token index to locate.
///   - tokens: The full token array.
///   - tabWidth: The number of columns per tab character.
func offsetForToken(at index: Int, in tokens: [Token], tabWidth: Int) -> SourceOffset {
    var column = 1
    for token in tokens[..<index].reversed() {
        switch token {
            case let .lineBreak(_, line):
                return SourceOffset(line: line + 1, column: column)
            default:
                column += token.columnWidth(tabWidth: tabWidth)
        }
    }
    return SourceOffset(line: 1, column: column)
}

/// Returns the token index closest to the given source offset
///
/// - Parameters:
///   - offset: The line/column position to search for.
///   - tokens: The full token array.
///   - tabWidth: The number of columns per tab character.
func tokenIndex(for offset: SourceOffset, in tokens: [Token], tabWidth: Int) -> Int {
    var tokenIndex = 0
    var line = 1
    for index in tokens.indices {
        guard case let .lineBreak(_, originalLine) = tokens[index] else {
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

/// Converts a line range into a token index range
///
/// - Parameters:
///   - lineRange: The inclusive range of source lines.
///   - tokens: The full token array.
func tokenRange(forLineRange lineRange: ClosedRange<Int>, in tokens: [Token]) -> Range<Int> {
    let startOffset = SourceOffset(line: lineRange.lowerBound, column: 0)
    let endOffset = SourceOffset(line: lineRange.upperBound + 1, column: 0)
    let tokenStart = max(0, tokenIndex(for: startOffset, in: tokens, tabWidth: 1) - 1)
    let tokenEnd = max(tokenStart, tokenIndex(for: endOffset, in: tokens, tabWidth: 1) - 1)
    return tokenStart ..< tokenEnd
}

/// Maps an original (pre-formatting) offset to its new position after formatting
///
/// - Parameters:
///   - offset: The original source offset before formatting.
///   - tokens: The formatted token array.
///   - tabWidth: The number of columns per tab character.
func newOffset(for offset: SourceOffset, in tokens: [Token], tabWidth: Int) -> SourceOffset {
    var closestLine = 0
    for i in tokens.indices {
        guard case let .lineBreak(_, originalLine) = tokens[i] else {
            continue
        }
        closestLine += 1
        guard originalLine >= offset.line else {
            continue
        }
        var lineLength = 0
        for j in (0 ..< i).reversed() {
            let token = tokens[j]
            if token.isLineBreak {
                break
            }
            lineLength += token.columnWidth(tabWidth: tabWidth)
        }
        return SourceOffset(line: closestLine, column: min(offset.column, lineLength + 1))
    }
    let lineLength = tokens.reduce(0) { $0 + $1.columnWidth(tabWidth: tabWidth) }
    return SourceOffset(line: closestLine + 1, column: min(offset.column, lineLength + 1))
}

/// Scans the token array for parsing errors and conflict markers
///
/// - Parameters:
///   - tokens: The token array to scan.
///   - options: Format options controlling fragment and conflict-marker behavior.
///   - allowErrorsInFragments: When `true`, error tokens in fragments are tolerated.
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

/// Converts a token array back into a source code string
///
/// - Parameters:
///   - tokens: The tokens to join. Returns an empty string if `nil`.
func sourceCode(for tokens: [Token]?) -> String {
    (tokens ?? []).map(\.string).joined()
}

/// Applies the specified rules to a token array, iterating until stable
///
/// Rules are applied in sorted order. Shared options are inferred from the
/// source when they are at their default values. The engine iterates up to
/// `maxIterations` times and throws if the rules fail to converge.
///
/// - Parameters:
///   - originalRules: The ``FormatRule`` instances to apply.
///   - originalTokens: The input token array.
///   - options: The ``FormatOptions`` to use.
///   - trackChanges: Whether to record a ``Formatter/Change`` for each modification.
///   - originalRange: An optional token range to restrict formatting to.
///   - maxIterations: The maximum number of formatting passes (must be > 1).
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
            if case let .lineBreak(_, line) = token {
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

/// Formats a pre-parsed token array and returns the result with changes
///
/// - Parameters:
///   - tokens: The input token array.
///   - rules: The rules to apply. Defaults to ``FormatRules/default``.
///   - options: The formatting options. Defaults to ``FormatOptions/default``.
///   - range: An optional token range to restrict formatting to.
func format(
    _ tokens: [Token], rules: [FormatRule] = FormatRules.default,
    options: FormatOptions = .default, range: Range<Int>? = nil,
) throws -> (tokens: [Token], changes: [Formatter.Change]) {
    try applyRules(rules, to: tokens, with: options, trackChanges: true, range: range)
}

/// Formats Swift source code and returns the formatted string with changes
///
/// - Parameters:
///   - source: The Swift source code to format.
///   - rules: The rules to apply. Defaults to ``FormatRules/default``.
///   - options: The formatting options. Defaults to ``FormatOptions/default``.
///   - lineRange: An optional line range to restrict formatting to.
func format(
    _ source: String, rules: [FormatRule] = FormatRules.default,
    options: FormatOptions = .default, lineRange: ClosedRange<Int>? = nil,
) throws -> (output: String, changes: [Formatter.Change]) {
    let tokens = tokenize(source)
    let range = lineRange.map { tokenRange(forLineRange: $0, in: tokens) }
    let output = try format(tokens, rules: rules, options: options, range: range)
    return (sourceCode(for: output.tokens), output.changes)
}

/// Lints a pre-parsed token array and returns the changes that would be made
///
/// - Parameters:
///   - tokens: The input token array.
///   - rules: The rules to check. Defaults to ``FormatRules/default``.
///   - options: The formatting options. Defaults to ``FormatOptions/default``.
///   - range: An optional token range to restrict linting to.
func lint(
    _ tokens: [Token], rules: [FormatRule] = FormatRules.default,
    options: FormatOptions = .default, range: Range<Int>? = nil,
) throws -> [Formatter.Change] {
    try applyRules(rules, to: tokens, with: options, trackChanges: true, range: range).changes
}

/// Lints Swift source code and returns the changes that would be made
///
/// - Parameters:
///   - source: The Swift source code to lint.
///   - rules: The rules to check. Defaults to ``FormatRules/default``.
///   - options: The formatting options. Defaults to ``FormatOptions/default``.
///   - lineRange: An optional line range to restrict linting to.
func lint(
    _ source: String, rules: [FormatRule] = FormatRules.default,
    options: FormatOptions = .default, lineRange: ClosedRange<Int>? = nil,
) throws -> [Formatter.Change] {
    let tokens = tokenize(source)
    let range = lineRange.map { tokenRange(forLineRange: $0, in: tokens) }
    return try lint(tokens, rules: rules, options: options, range: range)
}
