struct OptionalEnumCaseMatchingConfiguration: RuleConfiguration {
    let id = "optional_enum_case_matching"
    let name = "Optional Enum Case Match"
    let summary = "Matching an enum case against an optional enum without '?' is supported on Swift 5.1 and above"
    let isCorrectable = true
    let isOptIn = true
}
