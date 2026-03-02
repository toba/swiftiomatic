struct SpaceInsideGenericsConfiguration: RuleConfiguration {
    let id = "space_inside_generics"
    let name = "Space Inside Generics"
    let summary = "There should be no spaces immediately inside angle brackets"
    let scope: Scope = .format
    let isCorrectable = true
    var nonTriggeringExamples: [Example] {
        [
              Example("let a: Array<Int> = []"),
              Example("func foo<T>() {}"),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("let a: Array↓< Int > = []"),
              Example("func foo↓< T >() {}"),
            ]
    }
    var corrections: [Example: Example] {
        [
              Example("let a: Array↓< Int > = []"): Example("let a: Array<Int> = []")
            ]
    }
}
