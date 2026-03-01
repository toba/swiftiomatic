struct RedundantStringEnumValueConfiguration: RuleConfiguration {
    let id = "redundant_string_enum_value"
    let name = "Redundant String Enum Value"
    let summary = "String enum values can be omitted when they are equal to the enumcase name"
    let isCorrectable = true
}
