// FormatEngine.swift — Simplified public API for the SwiftFormat engine

import Foundation

/// A configured formatting engine that can format or lint Swift source code.
public struct FormatEngine: Sendable {
    public let rules: [FormatRule]
    public let options: FormatOptions

    public init(
        rules: [FormatRule] = FormatRules.default,
        options: FormatOptions = .default
    ) {
        self.rules = rules
        self.options = options
    }

    /// Format Swift source code, returning the formatted output.
    public func format(_ source: String) throws -> String {
        let tokens = tokenize(source)
        let output = try applyRules(rules, to: tokens, with: options, trackChanges: true, range: nil)
        return sourceCode(for: output.tokens)
    }

    /// Lint Swift source code, returning changes that would be made.
    public func lint(_ source: String) throws -> [Formatter.Change] {
        let tokens = tokenize(source)
        return try applyRules(rules, to: tokens, with: options, trackChanges: true, range: nil).changes
    }

    /// Build an engine with specific rule overrides.
    public init(
        enable: [String] = [],
        disable: [String] = [],
        options: FormatOptions = .default
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
        self.rules = activeRules
        self.options = options
    }
}
