import Foundation

/// A configured formatting engine that can format or lint Swift source code.
package struct FormatEngine: Sendable {
    package let rules: [FormatRule]
    package let options: FormatOptions

    package init(
        rules: [FormatRule] = FormatRules.default,
        options: FormatOptions = .default,
    ) {
        self.rules = rules
        self.options = options
    }

    /// Format Swift source code, returning the formatted output.
    package func format(_ source: String) throws -> String {
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

    /// Lint Swift source code, returning changes that would be made.
    package func lint(_ source: String) throws -> [Formatter.Change] {
        let tokens = tokenize(source)
        return try applyRules(rules, to: tokens, with: options, trackChanges: true, range: nil)
            .changes
    }

    /// Lint Swift source code with a file path for diagnostic output.
    package func lint(_ source: String, filePath: String) throws -> [Formatter.Change] {
        var opts = options
        opts.fileInfo = FileInfo(filePath: filePath)
        let tokens = tokenize(source)
        return try applyRules(rules, to: tokens, with: opts, trackChanges: true, range: nil).changes
    }

    /// Build an engine with specific rule overrides.
    package init(
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
