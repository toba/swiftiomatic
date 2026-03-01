struct SortImportsConfiguration: RuleConfiguration {
    let id = "sort_imports"
    let name = "Sort Imports"
    let summary = "Import statements should be sorted alphabetically"
    let scope: Scope = .format
    let isCorrectable = true
}
