struct LegacyMultipleConfiguration: RuleConfiguration {
    let id = "legacy_multiple"
    let name = "Legacy Multiple"
    let summary = "Prefer using the `isMultiple(of:)` function instead of using the remainder operator (`%`)"
    let isOptIn = true
}
