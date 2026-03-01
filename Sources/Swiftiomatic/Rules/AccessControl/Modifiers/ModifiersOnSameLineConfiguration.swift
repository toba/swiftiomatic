struct ModifiersOnSameLineConfiguration: RuleConfiguration {
    let id = "modifiers_on_same_line"
    let name = "Modifiers on Same Line"
    let summary = "Modifiers should be on the same line as the declaration keyword"
    let scope: Scope = .format
    let isCorrectable = true
}
