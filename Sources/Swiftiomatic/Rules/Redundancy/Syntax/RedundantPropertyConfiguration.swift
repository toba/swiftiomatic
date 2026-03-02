struct RedundantPropertyConfiguration: RuleConfiguration {
    let id = "redundant_property"
    let name = "Redundant Property"
    let summary = "A local property assigned and immediately returned can be simplified to a direct return"
    let scope: Scope = .format
    let isCorrectable = true
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                func foo() -> Foo {
                  return Foo()
                }
                """,
              ),
              Example(
                """
                func foo() -> Foo {
                  let foo = Foo()
                  foo.configure()
                  return foo
                }
                """,
              ),
              Example(
                """
                func foo() -> Foo {
                  var foo = Foo()
                  foo.bar = true
                  return foo
                }
                """,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                func foo() -> Foo {
                  let ↓foo = Foo()
                  return foo
                }
                """,
              ),
              Example(
                """
                func bar() -> String {
                  let ↓result = "hello"
                  return result
                }
                """,
              ),
            ]
    }
    var corrections: [Example: Example] {
        [
              Example(
                """
                func foo() -> Foo {
                  let ↓foo = Foo()
                  return foo
                }
                """,
              ): Example(
                """
                func foo() -> Foo {
                  return Foo()
                }
                """,
              )
            ]
    }
}
