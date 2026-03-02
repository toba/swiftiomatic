struct RedundantPublicConfiguration: RuleConfiguration {
    let id = "redundant_public"
    let name = "Redundant Public"
    let summary = "`public` on members of internal types has no effect"
    let scope: Scope = .suggest
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                public class Foo {
                  public func bar() {}
                }
                """,
              ),
              Example(
                """
                class Foo {
                  func bar() {}
                }
                """,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                class Foo {
                  ↓public func bar() {}
                }
                """,
              ),
              Example(
                """
                struct Foo {
                  ↓public let bar: String
                }
                """,
              ),
            ]
    }
}
