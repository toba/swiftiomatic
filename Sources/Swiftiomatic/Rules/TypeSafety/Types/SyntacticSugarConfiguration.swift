struct SyntacticSugarConfiguration: RuleConfiguration {
    let id = "syntactic_sugar"
    let name = "Syntactic Sugar"
    let summary = "Shorthand syntactic sugar should be used, i.e. [Int] instead of Array<Int>."
    let isCorrectable = true
}
