struct ShorthandOptionalBindingConfiguration: RuleConfiguration {
    let id = "shorthand_optional_binding"
    let name = "Shorthand Optional Binding"
    let summary = "Use shorthand syntax for optional binding"
    let isCorrectable = true
    let isOptIn = true
    let deprecatedAliases: Set<String> = ["if_let_shadowing"]
}
