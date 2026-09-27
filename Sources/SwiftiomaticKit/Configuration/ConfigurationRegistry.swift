/// Derived rule metadata, computed once from the generated `allRuleTypes` array. Each rule type
/// carries its own `key` , `defaultValue` , and `group` via the `SyntaxRule` protocol — no
/// generated string literals needed.
package extension ConfigurationRegistry {
    /// The dense index of each rule type, which is its position in `allRuleTypes` .
    ///
    /// The generated pipelines embed the index as a literal. Hand-written code that holds only a
    /// rule type reads it here, one hash per call.
    static let ruleIndexByID: [ObjectIdentifier: Int] = Dictionary(
        uniqueKeysWithValues: allRuleTypes.enumerated().map { (ObjectIdentifier($1), $0) })

    /// The dense index of `rule` , or `nil` for a type the registry does not list.
    @inline(__always)
    internal static func ruleIndex(of rule: any SyntaxRule.Type) -> Int? {
        ruleIndexByID[ObjectIdentifier(rule)]
    }

    /// The short key of each rule, indexed by rule index.
    static let ruleKeys: [String] = allRuleTypes.map { $0.key }

    /// The dense index of each rule, keyed by its short key.
    static let ruleIndexByKey: [String: Int] = Dictionary(
        ruleKeys.enumerated().map { ($1, $0) }, uniquingKeysWith: { first, _ in first })

    /// Fast lookup from rule type identity to its short key (used by `RuleMask` ).
    static let ruleNameCache: [ObjectIdentifier: String] = Dictionary(
        uniqueKeysWithValues: allRuleTypes.map { (ObjectIdentifier($0), $0.key) })

    /// Reverse lookup from type-name-derived key (e.g. "sortImports") to the actual configuration
    /// key (e.g. "imports"). Used by `RuleMask` to resolve `// sm:ignore SortImports` directives
    /// when a rule overrides `key` to something other than the auto-derived name.
    static let typeNameToKey: [String: String] = {
        var map: [String: String] = [:]
        for type in allRuleTypes {
            let typeName = String("\(type)".split(separator: ".").last ?? "")
            let derivedKey = typeName.prefix(1).lowercased() + typeName.dropFirst()
            // Only add entries where derived key differs from actual key
            if derivedKey != type.key { map[derivedKey] = type.key }
        }
        return map
    }()

    /// Set of all known rule keys (the short JSON key form, e.g. `imports`, not `SortImports`).
    /// Used by `RuleMask` to validate space-separated rule lists in `// sm:ignore` directives.
    static let allRuleKeys: Set<String> = Set(allRuleTypes.map { $0.key })

    /// Lookup from a rule's short key to its type, the reverse of `ruleNameCache` . Used by
    /// `FlagUnusedIgnoreDirective` to resolve the names a `// sm:ignore` directive lists.
    internal static let ruleTypesByKey: [String: any SyntaxRule.Type] = Dictionary(
        uniqueKeysWithValues: allRuleTypes.map { ($0.key, $0) })

    /// Identities of the rules a pipeline dispatches per node, for `Context.dispatches(_:)` .
    static let nodeDispatchedRuleIDs: Set<ObjectIdentifier> = Set(nodeDispatchedRuleTypes.map(
        ObjectIdentifier.init))

    /// Rules organized by configuration group (values are short keys for JSON encoding).
    static let groupRules: [ConfigurationGroup: [String]] = {
        var groups: [ConfigurationGroup: [String]] = [:]
        for type in allRuleTypes {
            if let group = type.group { groups[group, default: []].append(type.key) }
        }
        return groups
    }()

    /// Set of all qualified keys managed by a group (used to avoid double-encoding).
    static let groupManagedRules: Set<String> = Set(
        allRuleTypes.compactMap { type in type.group != nil ? type.qualifiedKey : nil })
}

package extension ConfigurationRegistry {
    /// The number of `Configuration` storage slots: one per rule, then one per layout setting.
    static let storageCount = ruleCount + allSettingTypes.count

    /// The `Configuration` storage slot of each rule and layout setting, keyed by type identity.
    ///
    /// A rule's slot is its rule index. A layout setting's slot follows the rules.
    static let storageIndexByID: [ObjectIdentifier: Int] = {
        var map = ruleIndexByID
        map.reserveCapacity(storageCount)

        for (offset, type) in allSettingTypes.enumerated() {
            map[ObjectIdentifier(type)] = ruleCount + offset
        }
        return map
    }()

    /// The storage slot of `type` , or `nil` for a type the registry does not list.
    @inline(__always)
    static func storageIndex<C: Configurable>(of type: C.Type) -> Int? {
        storageIndexByID[ObjectIdentifier(type)]
    }
}
