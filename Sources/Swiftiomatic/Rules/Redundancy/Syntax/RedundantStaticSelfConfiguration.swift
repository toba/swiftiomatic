struct RedundantStaticSelfConfiguration: RuleConfiguration {
    let id = "redundant_static_self"
    let name = "Redundant Static Self"
    let summary = "Explicit `Self` qualification is redundant in static context"
    let scope: Scope = .format
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                struct Foo {
                  static let bar = "bar"
                  func baz() {
                    let _ = Self.bar
                  }
                }
                """,
              ),
              Example(
                """
                class Foo {
                  static func bar() -> Self { Self() }
                }
                """,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                struct Foo {
                  static let bar = "bar"
                  static func baz() -> String {
                    return ↓Self.bar
                  }
                }
                """,
              )
            ]
    }
}
