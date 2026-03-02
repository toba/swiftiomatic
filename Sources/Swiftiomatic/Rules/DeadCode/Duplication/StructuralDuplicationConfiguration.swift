struct StructuralDuplicationConfiguration: RuleConfiguration {
    let id = "structural_duplication"
    let name = "Structural Duplication"
    let summary = "Functions with identical AST structure are likely duplicated code that should be consolidated"
    let isOptIn = true
    let isCrossFile = true
    var nonTriggeringExamples: [Example] {
        [
              Example("func unique1() { print(1) }\nfunc unique2() { return 2 }")
            ]
    }
    var triggeringExamples: [Example] {
        []
    }
}
