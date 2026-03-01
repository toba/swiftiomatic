struct LegacyHashingConfiguration: RuleConfiguration {
    let id = "legacy_hashing"
    let name = "Legacy Hashing"
    let summary = "Prefer using the `hash(into:)` function instead of overriding `hashValue`"
}
