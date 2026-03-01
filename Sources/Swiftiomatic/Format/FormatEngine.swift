import Foundation

/// A configured formatting engine that can format or lint Swift source code
///
/// Wraps a set of ``FormatRule`` values and ``FormatOptions`` into a
/// reusable, thread-safe entry point for formatting or linting operations.
public struct FormatEngine: Sendable {
    public let rules: [FormatRule]
    public let options: FormatOptions

    /// Creates an engine with the given rules and options
    ///
    /// - Parameters:
    ///   - rules: The format rules to apply. Defaults to ``FormatRules/default``.
    ///   - options: The formatting options to use. Defaults to ``FormatOptions/default``.
    public init(
        rules: [FormatRule] = FormatRules.default,
        options: FormatOptions = .default,
    ) {
        self.rules = rules
        self.options = options
    }

    /// Formats Swift source code and returns the formatted output
    ///
    /// - Parameters:
    ///   - source: The Swift source code string to format.
    public func format(_ source: String) throws -> String {
        let tokens = tokenize(source)
        let output = try applyRules(
            rules,
            to: tokens,
            with: options,
            trackChanges: true,
            range: nil,
        )
        return sourceCode(for: output.tokens)
    }

    /// Lints Swift source code and returns the changes that would be made
    ///
    /// - Parameters:
    ///   - source: The Swift source code string to lint.
    public func lint(_ source: String) throws -> [Formatter.Change] {
        let tokens = tokenize(source)
        return try applyRules(rules, to: tokens, with: options, trackChanges: true, range: nil)
            .changes
    }

    /// Lints Swift source code with a file path for diagnostic output
    ///
    /// - Parameters:
    ///   - source: The Swift source code string to lint.
    ///   - filePath: The file path included in each reported ``Formatter/Change``.
    public func lint(_ source: String, filePath: String) throws -> [Formatter.Change] {
        var opts = options
        opts.fileInfo = FileInfo(filePath: filePath)
        let tokens = tokenize(source)
        return try applyRules(rules, to: tokens, with: opts, trackChanges: true, range: nil).changes
    }

    /// Creates an engine by selectively enabling or disabling rules by name
    ///
    /// - Parameters:
    ///   - enable: Rule names to add to the default set.
    ///   - disable: Rule names to remove from the active set.
    ///   - options: The formatting options to use.
    public init(
        enable: [String] = [],
        disable: [String] = [],
        options: FormatOptions = .default,
    ) {
        var activeRules = FormatRules.default
        if !enable.isEmpty {
            let extraRules = FormatRules.named(enable)
            for rule in extraRules where !activeRules.contains(rule) {
                activeRules.append(rule)
            }
        }
        if !disable.isEmpty {
            let disabledRules = Set(FormatRules.named(disable))
            activeRules.removeAll { disabledRules.contains($0) }
        }
        rules = activeRules
        self.options = options
    }
}
