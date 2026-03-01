struct LegacyConstructorConfiguration: RuleConfiguration {
    let id = "legacy_constructor"
    let name = "Legacy Constructor"
    let summary = "Swift constructors are preferred over legacy convenience functions"
    let isCorrectable = true
}
