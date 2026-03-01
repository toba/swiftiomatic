struct StructuralDuplicationConfiguration: RuleConfiguration {
    let id = "structural_duplication"
    let name = "Structural Duplication"
    let summary = "Functions with identical AST structure are likely duplicated code that should be consolidated"
    let isOptIn = true
    let isCrossFile = true
}
