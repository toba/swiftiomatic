struct AnonymousArgumentInMultilineClosureConfiguration: RuleConfiguration {
    let id = "anonymous_argument_in_multiline_closure"
    let name = "Anonymous Argument in Multiline Closure"
    let summary = "Use named arguments in multiline closures"
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example("closure { $0 }"),
              Example("closure { print($0) }"),
              Example(
                """
                closure { arg in
                    print(arg)
                }
                """,
              ),
              Example(
                """
                closure { arg in
                    nestedClosure { $0 + arg }
                }
                """,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                closure {
                    print(↓$0)
                }
                """,
              )
            ]
    }
    let rationale: String? = """
      In multiline closures, for clarity, prefer using named arguments

      ```
      closure { arg in
          print(arg)
      }
      ```

      to anonymous arguments

      ```
      closure {
          print(↓$0)
      }
      ```
      """
}
