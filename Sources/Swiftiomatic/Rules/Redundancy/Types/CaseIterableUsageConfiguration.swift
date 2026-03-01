struct CaseIterableUsageConfiguration: RuleConfiguration {
    let id = "case_iterable_usage"
    let name = "CaseIterable Usage"
    let summary = "Enums conforming to CaseIterable without any .allCases references may have unnecessary conformance"
    let scope: Scope = .suggest
    let isOptIn = true
    let isCrossFile = true
}
