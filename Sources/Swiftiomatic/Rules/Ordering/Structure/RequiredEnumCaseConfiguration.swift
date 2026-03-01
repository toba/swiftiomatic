struct RequiredEnumCaseConfiguration: RuleConfiguration {
    let id = "required_enum_case"
    let name = "Required Enum Case"
    let summary = "Enums conforming to a specified protocol must implement a specific case(s)."
    let isOptIn = true
}
