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
    func warningControlSeverity<R: SyntaxRule>(
        of ruleType: R.Type,
        at position: AbsolutePosition
    ) -> Lint? {
        let tree = warningControlRegionTree
        let key = ConfigurationRegistry.ruleNameCache[ObjectIdentifier(ruleType)] ?? R.key

        for identifier in WarningControlMask.diagnosticGroupIdentifiers(forRuleKey: key) {
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
