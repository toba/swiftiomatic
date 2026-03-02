struct RedundantFileprivateConfiguration: RuleConfiguration {
    let id = "redundant_fileprivate"
    let name = "Redundant Fileprivate"
    let summary = "`fileprivate` can be replaced with `private` when only accessed within the same declaration scope"
    let scope: Scope = .suggest
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                class Foo {
                  private var bar: Int
                }
                """,
              ),
              Example(
                """
                fileprivate func helper() {}
                class Foo {
                  func bar() { helper() }
                }
                """,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                ↓fileprivate class Foo {}
                """,
              )
            ]
    }
}
