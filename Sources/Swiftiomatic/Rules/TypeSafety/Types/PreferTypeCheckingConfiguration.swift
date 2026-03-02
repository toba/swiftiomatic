struct PreferTypeCheckingConfiguration: RuleConfiguration {
    let id = "prefer_type_checking"
    let name = "Prefer Type Checking"
    let summary = "Prefer `a is X` to `a as? X != nil`"
    let isCorrectable = true
    var nonTriggeringExamples: [Example] {
        [
              Example("let foo = bar as? Foo"),
              Example("bar is Foo"),
              Example("2*x is X"),
              Example(
                """
                if foo is Bar {
                    doSomeThing()
                }
                """,
              ),
              Example(
                """
                if let bar = foo as? Bar {
                    foo.run()
                }
                """,
              ),
              Example("bar as Foo != nil"),
              Example("nil != bar as Foo"),
              Example("bar as Foo? != nil"),
              Example("bar as? Foo? != nil"),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("bar ↓as? Foo != nil"),
              Example("2*x as? X != nil"),
              Example(
                """
                if foo ↓as? Bar != nil {
                    doSomeThing()
                }
                """,
              ),
              Example("nil != bar ↓as? Foo"),
              Example("nil != 2*x ↓as? X"),
            ]
    }
    var corrections: [Example: Example] {
        [
              Example("bar ↓as? Foo != nil"): Example("bar is Foo"),
              Example("nil != bar ↓as? Foo"): Example("bar is Foo"),
              Example("2*x ↓as? X != nil"): Example("2*x is X"),
              Example(
                """
                if foo ↓as? Bar != nil {
                    doSomeThing()
                }
                """,
              ): Example(
                """
                if foo is Bar {
                    doSomeThing()
                }
                """,
              ),
            ]
    }
}
