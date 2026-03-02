struct ConditionalAssignmentConfiguration: RuleConfiguration {
    let id = "conditional_assignment"
    let name = "Conditional Assignment"
    let summary = "if/switch statements that assign to the same variable in every branch can use if/switch expressions"
    let scope: Scope = .suggest
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                let x = if condition { 1 } else { 2 }
                """,
              ),
              Example(
                """
                let x: Int
                if condition {
                  x = 1
                  print("assigned")
                } else {
                  x = 2
                }
                """,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                let x: Int
                ↓if condition {
                  x = 1
                } else {
                  x = 2
                }
                """,
              )
            ]
    }
}
