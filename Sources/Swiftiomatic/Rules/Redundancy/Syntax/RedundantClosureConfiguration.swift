struct RedundantClosureConfiguration: RuleConfiguration {
    let id = "redundant_closure"
    let name = "Redundant Closure"
    let summary = "Immediately-invoked closures with a single expression can be simplified"
    let scope: Scope = .format
    var nonTriggeringExamples: [Example] {
        [
              Example("let x = { 42 }()"),
              Example(
                """
                let x = {
                  let y = 10
                  return y + 1
                }()
                """,
              ),
              Example(
                """
                let x = { (a: Int) in a + 1 }(5)
                """,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                let x: Int = ↓{
                  return 42
                }()
                """,
              )
            ]
    }
}
