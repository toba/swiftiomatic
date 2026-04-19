/// Derived rule metadata, computed once from the generated `allRuleTypes` array.
/// Each rule type carries its own `key`, `defaultHandling`, and `group` via
/// the `Rule` protocol — no generated string literals needed.
extension ConfigurationRegistry {

    /// Rule name → default handling, derived from each type's static properties.
    package static let rules: [String: RuleHandling] = {
        Dictionary(uniqueKeysWithValues: allRuleTypes.map { ($0.key, $0.defaultHandling) })
    }()

    /// Fast lookup from rule type identity to its string name.
    package static let ruleNameCache: [ObjectIdentifier: String] = {
        Dictionary(uniqueKeysWithValues: allRuleTypes.map { (ObjectIdentifier($0), $0.key) })
    }()

    /// Rules organized by configuration group.
    package static let groupRules: [ConfigurationGroup: [String]] = {
        var groups: [ConfigurationGroup: [String]] = [:]
        for type in allRuleTypes {
            if let group = type.group { groups[group, default: []].append(type.key) }
        }
        return groups
    }()

    /// Set of all rule names managed by a group (used to avoid double-encoding).
    package static let groupManagedRules: Set<String> = {
        Set(groupRules.values.flatMap { $0 })
    }()
}
