struct AnyEliminationConfiguration: RuleConfiguration {
    let id = "any_elimination"
    let name = "Any Elimination"
    let summary = "Usage of Any/AnyObject erases type safety and should be replaced with specific types or generics"
    let scope: Scope = .suggest
    let isOptIn = true
    let canEnrichAsync = true
    var nonTriggeringExamples: [Example] {
        [
              Example("var name: String = \"\""),
              Example("func process(_ item: Codable) {}"),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("var value: ↓Any = 0"),
              Example("func process(_ dict: ↓[String: Any]) {}"),
              Example("let x = value ↓as! String"),
            ]
    }
}
