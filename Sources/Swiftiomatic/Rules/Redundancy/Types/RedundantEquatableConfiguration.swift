struct RedundantEquatableConfiguration: RuleConfiguration {
    let id = "redundant_equatable"
    let name = "Redundant Equatable"
    let summary = "Structs conforming to Equatable can rely on synthesized `==` instead of implementing it manually"
    let scope: Scope = .suggest
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                struct Foo: Equatable {
                  let bar: Int
                }
                """,
              ),
              Example(
                """
                struct Foo: Equatable {
                  let bar: Int
                  static func == (lhs: Foo, rhs: Foo) -> Bool {
                    lhs.bar == rhs.bar && someOtherCondition
                  }
                }
                """,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                struct Foo: Equatable {
                  let bar: Int
                  let baz: String
                  ↓static func == (lhs: Foo, rhs: Foo) -> Bool {
                    lhs.bar == rhs.bar && lhs.baz == rhs.baz
                  }
                }
                """,
              )
            ]
    }
}
