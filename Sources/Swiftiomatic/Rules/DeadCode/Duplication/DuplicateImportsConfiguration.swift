struct DuplicateImportsConfiguration: RuleConfiguration {
    let id = "duplicate_imports"
    let name = "Duplicate Imports"
    let summary = "Imports should be unique"
    let isCorrectable = true
}
