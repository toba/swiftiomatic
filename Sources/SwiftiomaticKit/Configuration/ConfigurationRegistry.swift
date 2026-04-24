/// Derived rule metadata, computed once from the generated `allRuleTypes` array.
/// Each rule type carries its own `key`, `defaultValue`, and `group` via
/// the `SyntaxRule` protocol — no generated string literals needed.
extension ConfigurationRegistry {

    /// Fast lookup from rule type identity to its short key (used by `RuleMask`).
    package static let ruleNameCache: [ObjectIdentifier: String] = {
        Dictionary(uniqueKeysWithValues: allRuleTypes.map { (ObjectIdentifier($0), $0.key) })
    }()

    /// Reverse lookup from type-name-derived key (e.g. "sortImports") to the actual
    /// configuration key (e.g. "imports"). Used by `RuleMask` to resolve `// sm:ignore: SortImports`
    /// directives when a rule overrides `key` to something other than the auto-derived name.
    package static let typeNameToKey: [String: String] = {
        var map: [String: String] = [:]
        for type in allRuleTypes {
            let typeName = String("\(type)".split(separator: ".").last ?? "")
            let derivedKey = typeName.prefix(1).lowercased() + typeName.dropFirst()
            // Only add entries where derived key differs from actual key
            if derivedKey != type.key {
                map[derivedKey] = type.key
            }
        }
        return map
    }()

    /// Rules organized by configuration group (values are short keys for JSON encoding).
    package static let groupRules: [ConfigurationGroup: [String]] = {
        var groups: [ConfigurationGroup: [String]] = [:]
        for type in allRuleTypes {
            if let group = type.group { groups[group, default: []].append(type.key) }
        }
        return groups
    }()

    /// Set of all qualified keys managed by a group (used to avoid double-encoding).
    package static let groupManagedRules: Set<String> = {
        Set(allRuleTypes.compactMap { type in
            type.group != nil ? type.qualifiedKey : nil
        })
    }()
}
