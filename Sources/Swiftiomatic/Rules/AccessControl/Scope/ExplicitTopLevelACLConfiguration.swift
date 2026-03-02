struct ExplicitTopLevelACLConfiguration: RuleConfiguration {
    let id = "explicit_top_level_acl"
    let name = "Explicit Top Level ACL"
    let summary = "Top-level declarations should specify Access Control Level keywords explicitly"
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example("internal enum A {}"),
              Example("public final class B {}"),
              Example(
                """
                private struct S1 {
                    struct S2 {}
                }
                """,
              ),
              Example("internal enum A { enum B {} }"),
              Example("internal final actor Foo {}"),
              Example("internal typealias Foo = Bar"),
              Example("internal func a() {}"),
              Example("extension A: Equatable {}"),
              Example("extension A {}"),
              Example("f { func f() {} }", isExcludedFromDocumentation: true),
              Example("do { func f() {} }", isExcludedFromDocumentation: true),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("↓enum A {}"),
              Example("final ↓class B {}"),
              Example("↓protocol P {}"),
              Example("↓func a() {}"),
              Example("internal let a = 0\n↓func b() {}"),
            ]
    }
}
