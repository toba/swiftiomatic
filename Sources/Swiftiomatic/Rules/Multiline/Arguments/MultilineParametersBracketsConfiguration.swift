struct MultilineParametersBracketsConfiguration: RuleConfiguration {
    let id = "multiline_parameters_brackets"
    let name = "Multiline Parameters Brackets"
    let summary = "Multiline parameters should have their surrounding brackets in a new line"
    let isOptIn = true
    let requiresSourceKit = true
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                func foo(param1: String, param2: String, param3: String)
                """,
              ),
              Example(
                """
                func foo(
                    param1: String, param2: String, param3: String
                )
                """,
              ),
              Example(
                """
                func foo(
                    param1: String,
                    param2: String,
                    param3: String
                )
                """,
              ),
              Example(
                """
                class SomeType {
                    func foo(param1: String, param2: String, param3: String)
                }
                """,
              ),
              Example(
                """
                class SomeType {
                    func foo(
                        param1: String, param2: String, param3: String
                    )
                }
                """,
              ),
              Example(
                """
                class SomeType {
                    func foo(
                        param1: String,
                        param2: String,
                        param3: String
                    )
                }
                """,
              ),
              Example(
                """
                func foo<T>(param1: T, param2: String, param3: String) -> T { /* some code */ }
                """,
              ),
              Example(
                """
                    func foo(a: [Int] = [
                        1
                    ])
                """,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                func foo(↓param1: String, param2: String,
                         param3: String
                )
                """,
              ),
              Example(
                """
                func foo(
                    param1: String,
                    param2: String,
                    param3: String↓)
                """,
              ),
              Example(
                """
                class SomeType {
                    func foo(↓param1: String, param2: String,
                             param3: String
                    )
                }
                """,
              ),
              Example(
                """
                class SomeType {
                    func foo(
                        param1: String,
                        param2: String,
                        param3: String↓)
                }
                """,
              ),
              Example(
                """
                func foo<T>(↓param1: T, param2: String,
                         param3: String
                ) -> T
                """,
              ),
            ]
    }
}
