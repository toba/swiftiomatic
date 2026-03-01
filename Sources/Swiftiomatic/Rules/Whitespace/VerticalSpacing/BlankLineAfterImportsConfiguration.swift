struct BlankLineAfterImportsConfiguration: RuleConfiguration {
    let id = "blank_line_after_imports"
    let name = "Blank Line After Imports"
    let summary = "There should be a blank line after import statements"
    let scope: Scope = .format
    let isCorrectable = true
}
