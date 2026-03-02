struct SortSwitchCasesConfiguration: RuleConfiguration {
    let id = "sort_switch_cases"
    let name = "Sort Switch Cases"
    let summary = "Switch case patterns with multiple comma-separated values should be sorted alphabetically"
    let scope: Scope = .suggest
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                switch value {
                case .a, .b, .c:
                  break
                }
                """,
              )
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                switch value {
                case ↓.c, .a, .b:
                  break
                }
                """,
              )
            ]
    }
}
