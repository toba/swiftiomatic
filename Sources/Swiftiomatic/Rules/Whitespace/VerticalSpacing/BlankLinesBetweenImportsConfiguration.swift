struct BlankLinesBetweenImportsConfiguration: RuleConfiguration {
    let id = "blank_lines_between_imports"
    let name = "Blank Lines Between Imports"
    let summary = "There should be no blank lines between import statements"
    let scope: Scope = .format
    let isCorrectable = true
}
