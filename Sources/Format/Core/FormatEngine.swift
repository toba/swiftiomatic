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
        let result = try Format.format(source, rules: rules, options: options)
        return result.output
    }

    /// Lint Swift source code, returning changes that would be made.
    public func lint(_ source: String) throws -> [Formatter.Change] {
        try Format.lint(source, rules: rules, options: options)
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
