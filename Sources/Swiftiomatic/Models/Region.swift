import SwiftSyntax

/// A contiguous region of Swift source code.
public struct Region: Equatable, Sendable {
    /// The location describing the start of the region. All locations that are less than this value
    /// (earlier in the source file) are not contained in this region.
    let start: Location
    /// The location describing the end of the region. All locations that are greater than this value
    /// (later in the source file) are not contained in this region.
    let end: Location
    /// All rule identifiers that are disabled in this region.
    let disabledRuleIdentifiers: Set<RuleIdentifier>

    /// Whether the specific location is contained in this region.
    ///
    /// - Parameters:
    ///   - location: The location to check for containment.
    ///
    /// - Returns: True if the specific location is contained in this region.
    func contains(_ location: Location) -> Bool {
        start <= location && end >= location
    }

    /// Whether the specified rule is enabled in this region.
    ///
    /// - Parameters:
    ///   - rule: The rule whose status should be determined.
    ///
    /// - Returns: True if the specified rule is enabled in this region.
    func isRuleEnabled(_ rule: some Rule) -> Bool {
        !isRuleDisabled(rule)
    }

    /// Whether the specified rule is disabled in this region.
    ///
    /// - Parameters:
    ///   - rule: The rule whose status should be determined.
    ///
    /// - Returns: True if the specified rule is disabled in this region.
    func isRuleDisabled(_ rule: some Rule) -> Bool {
        areRulesDisabled(ruleIDs: type(of: rule).allIdentifiers)
    }

    /// Whether the given rules are disabled in this region.
    ///
    /// - Parameters:
    ///   - ruleIDs: A list of rule IDs. Typically all identifiers of a single rule.
    ///
    /// - Returns: True if the specified rules are disabled in this region.
    func areRulesDisabled(ruleIDs: [String]) -> Bool {
        if disabledRuleIdentifiers.contains(.all) {
            return true
        }
        let regionIdentifiers = Set(disabledRuleIdentifiers.map(\.stringRepresentation))
        return !regionIdentifiers.isDisjoint(with: ruleIDs)
    }

    /// Returns the deprecated rule aliases that are disabling the specified rule in this region.
    /// Returns the empty set if the rule isn't disabled in this region.
    ///
    /// - Parameters:
    ///   - rule: The rule to check.
    ///
    /// - Returns: Deprecated rule aliases.
    func deprecatedAliasesDisabling(rule: some Rule) -> Set<String> {
        let identifiers = type(of: rule).ruleDeprecatedAliases
        return Set(disabledRuleIdentifiers.map(\.stringRepresentation)).intersection(identifiers)
    }

    /// Converts this `Region` to a SwiftSyntax `SourceRange`.
    ///
    /// - Parameters:
    ///   - locationConverter: The SwiftSyntax location converter to use.
    ///
    /// - Returns: The `SourceRange` if one was produced.
    func toSourceRange(locationConverter: SourceLocationConverter) -> SourceRange? {
        guard let startLine = start.line, let endLine = end.line else {
            return nil
        }

        let startPosition = locationConverter.position(
            ofLine: startLine, column: min(1000, start.column ?? 1),
        )
        let endPosition = locationConverter.position(
            ofLine: endLine, column: min(1000, end.column ?? 1),
        )
        let startLocation = locationConverter.location(for: startPosition)
        let endLocation = locationConverter.location(for: endPosition)
        return SourceRange(start: startLocation, end: endLocation)
    }
}
