struct OrganizeDeclarationsConfiguration: RuleConfiguration {
    let id = "organize_declarations"
    let name = "Organize Declarations"
    let summary = "Declarations within type bodies should be organized by category (properties, lifecycle, methods)"
    let scope: Scope = .suggest
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                struct Foo {
                  let bar: Int
                  init(bar: Int) { self.bar = bar }
                  func baz() {}
                }
                """,
              )
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                struct ↓Foo {
                  func baz() {}
                  let bar: Int
                  init(bar: Int) { self.bar = bar }
                }
                """,
              )
            ]
    }
}
