struct RedundantMemberwiseInitConfiguration: RuleConfiguration {
    let id = "redundant_memberwise_init"
    let name = "Redundant Memberwise Init"
    let summary = "Structs get an automatic memberwise initializer; explicit ones that mirror it are redundant"
    let scope: Scope = .suggest
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                struct Foo {
                  let bar: Int
                  let baz: String
                }
                """,
              ),
              Example(
                """
                struct Foo {
                  let bar: Int
                  init(bar: Int, extra: String = "") {
                    self.bar = bar
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
                struct Foo {
                  let bar: Int
                  let baz: String
                  ↓init(bar: Int, baz: String) {
                    self.bar = bar
                    self.baz = baz
                  }
                }
                """,
              )
            ]
    }
}
