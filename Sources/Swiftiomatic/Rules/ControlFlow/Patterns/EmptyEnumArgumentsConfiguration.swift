struct EmptyEnumArgumentsConfiguration: RuleConfiguration {
    let id = "empty_enum_arguments"
    let name = "Empty Enum Arguments"
    let summary = "Arguments can be omitted when matching enums with associated values if they are not used"
    let isCorrectable = true
}
