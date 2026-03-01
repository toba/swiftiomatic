struct DiscouragedOptionalBooleanConfiguration: RuleConfiguration {
    let id = "discouraged_optional_boolean"
    let name = "Discouraged Optional Boolean"
    let summary = "Prefer non-optional booleans over optional booleans"
    let isOptIn = true
}
