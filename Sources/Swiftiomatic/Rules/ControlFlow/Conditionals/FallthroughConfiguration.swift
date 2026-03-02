struct FallthroughConfiguration: RuleConfiguration {
    let id = "fallthrough"
    let name = "Fallthrough"
    let summary = "Fallthrough should be avoided"
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                switch foo {
                case .bar, .bar2, .bar3:
                  something()
                }
                """,
              )
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                switch foo {
                case .bar:
                  ↓fallthrough
                case .bar2:
                  something()
                }
                """,
              )
            ]
    }
}
