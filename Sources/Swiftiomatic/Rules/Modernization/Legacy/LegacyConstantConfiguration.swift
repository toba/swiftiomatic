struct LegacyConstantConfiguration: RuleConfiguration {
    let id = "legacy_constant"
    let name = "Legacy Constant"
    let summary = "Struct-scoped constants are preferred over legacy global constants"
    let isCorrectable = true
}
