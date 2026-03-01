struct SortTypealiasesConfiguration: RuleConfiguration {
    let id = "sort_typealiases"
    let name = "Sort Typealiases"
    let summary = "Protocol composition typealiases should be sorted alphabetically"
    let scope: Scope = .suggest
}
