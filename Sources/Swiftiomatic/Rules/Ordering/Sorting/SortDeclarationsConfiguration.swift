struct SortDeclarationsConfiguration: RuleConfiguration {
    let id = "sort_declarations"
    let name = "Sort Declarations"
    let summary = "Declarations marked with `// sm:sort` should have their members sorted alphabetically"
    let scope: Scope = .suggest
}
