struct SinglePropertyPerLineConfiguration: RuleConfiguration {
    let id = "single_property_per_line"
    let name = "Single Property Per Line"
    let summary = "Each variable declaration should declare only one property"
    let scope: Scope = .suggest
    var nonTriggeringExamples: [Example] {
        [
              Example("let a: Int"),
              Example("var b = false"),
              Example(
                """
                let a: Int
                let b: Int
                """,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("↓let a, b, c: Int"),
              Example("↓var foo = 10, bar = false"),
            ]
    }
}
