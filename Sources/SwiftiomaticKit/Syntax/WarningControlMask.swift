import SwiftSyntax
@_spi(ExperimentalLanguageFeatures) import SwiftWarningControl

/// Resolves Swift's first-party `@warn` (renamed `@diagnose` in newer swift-syntax) attribute into
/// Swiftiomatic's `Lint` severity scale.
///
/// `@warn(<group>, as: ignored)` over an enclosing decl silences findings for that diagnostic
/// group; `as: warning` and `as: error` set the emitted finding's severity. The matching rule's
/// configured severity acts as the fallback when no `@warn` region applies.
///
/// We try two diagnostic-group identifiers per rule: the rule's lowerCamelCase config key (e.g.
/// `dropRedundantEscaping`) and its PascalCase equivalent (e.g. `DropRedundantEscaping`).
/// PascalCase aligns with the compiler's own group identifiers (e.g. `Deprecate`); camelCase
/// matches Swiftiomatic's `// sm:ignore` vocabulary.
extension Lint {
    init(_ control: WarningGroupControl) {
        switch control {
            case .ignored: self = .no
            case .warning: self = .warn
            case .error: self = .error
        }
    }
}

extension Context {
    /// Returns a `Lint` severity overridden by an enclosing `@warn(<group>, as: …)` attribute, or
    /// `nil` if no such attribute scope applies. Rules consult this and only fall back to their
    /// configured severity when the result is `nil`.
    ///
    /// A file whose text holds no `@warn` or `@diagnose` answers `nil` and does not build the
    /// region tree.
    ///
    /// - Parameter ruleIndex: The rule's dense index, or `nil` for a rule the registry does not
    ///   list.
    func warningControlSeverity(
        of ruleType: any SyntaxRule.Type,
        ruleIndex: Int?,
        at position: AbsolutePosition
    ) -> Lint? {
        guard mayContainWarningControl else { return nil }
        let tree = warningControlRegionTree
        let identifiers = ruleIndex.map { WarningControlMask.identifiersByRuleIndex[$0] }
            ?? WarningControlMask.diagnosticGroupIdentifiers(forRuleKey: ruleType.key)

        for identifier in identifiers {
            if let control = tree.warningGroupControl(at: position, for: identifier) {
                return Lint(control)
            }
        }
        return nil
    }
}

// MARK: - Support

/// Internal namespace for warning-control resolution helpers.
enum WarningControlMask {
    /// The candidate identifiers of every rule, indexed by rule index, built once.
    static let identifiersByRuleIndex: [[DiagnosticGroupIdentifier]] = ConfigurationRegistry
        .ruleKeys.map(diagnosticGroupIdentifiers(forRuleKey:))

    /// Builds the candidate `DiagnosticGroupIdentifier` list for a rule's short key. Tries both the
    /// camelCase form (matches `sm:ignore` vocabulary) and the PascalCase form (matches Swift
    /// compiler convention for diagnostic groups).
    static func diagnosticGroupIdentifiers(forRuleKey key: String) -> [DiagnosticGroupIdentifier] {
        guard let first = key.first else { return [] }
        let pascal = first.uppercased() + key.dropFirst()
        return pascal == key
            ? [DiagnosticGroupIdentifier(key)]
            : [DiagnosticGroupIdentifier(pascal), DiagnosticGroupIdentifier(key)]
    }
}

/// Finds a `@warn` or `@diagnose` attribute in UTF-8 text without parsing it.
///
/// The search is conservative. It allows spaces and tabs between `@` and the name, and it does not
/// check that the name ends there, so it can report an attribute that is not one. It never misses
/// one.
enum WarningControlMarker {
    private static let names: [[UInt8]] = [Array("warn".utf8), Array("diagnose".utf8)]

    /// Whether `bytes` may hold a `@warn` or `@diagnose` attribute.
    static func occurs(in bytes: Span<UInt8>) -> Bool {
        var index = 0

        while index < bytes.count {
            defer { index += 1 }
            guard bytes[index] == UInt8(ascii: "@") else { continue }
            var start = index + 1
            while start < bytes.count, bytes[start] == UInt8(ascii: " ") || bytes[start] == UInt8(ascii: "\t") {
                start += 1
            }
            for name in names where start + name.count <= bytes.count {
                var matched = 0
                while matched < name.count, bytes[start + matched] == name[matched] { matched += 1 }
                if matched == name.count { return true }
            }
        }
        return false
    }
}
