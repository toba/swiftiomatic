struct LiteralExpressionEndIndentationConfiguration: RuleConfiguration {
    let id = "literal_expression_end_indentation"
    let name = "Literal Expression End Indentation"
    let summary = "Array and dictionary literal end should have the same indentation as the line that started it"
    let isCorrectable = true
    let isOptIn = true
    let requiresSourceKit = true
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                [1, 2, 3]
                """,
              ),
              Example(
                """
                [1,
                 2
                ]
                """,
              ),
              Example(
                """
                [
                   1,
                   2
                ]
                """,
              ),
              Example(
                """
                [
                   1,
                   2]
                """,
              ),
              Example(
                """
                   let x = [
                       1,
                       2
                   ]
                """,
              ),
              Example(
                """
                [key: 2, key2: 3]
                """,
              ),
              Example(
                """
                [key: 1,
                 key2: 2
                ]
                """,
              ),
              Example(
                """
                [
                   key: 0,
                   key2: 20
                ]
                """,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                let x = [
                   1,
                   2
                   ↓]
                """,
              ),
              Example(
                """
                   let x = [
                       1,
                       2
                ↓]
                """,
              ),
              Example(
                """
                let x = [
                   key: value
                   ↓]
                """,
              ),
            ]
    }
    var corrections: [Example: Example] {
        [
              Example(
                """
                let x = [
                   key: value
                ↓   ]
                """,
              ): Example(
                """
                let x = [
                   key: value
                ]
                """,
              ),
              Example(
                """
                   let x = [
                       1,
                       2
                ↓]
                """,
              ): Example(
                """
                   let x = [
                       1,
                       2
                   ]
                """,
              ),
              Example(
                """
                let x = [
                   1,
                   2
                ↓   ]
                """,
              ): Example(
                """
                let x = [
                   1,
                   2
                ]
                """,
              ),
              Example(
                """
                let x = [
                   1,
                   2
                ↓   ] + [
                   3,
                   4
                ↓   ]
                """,
              ): Example(
                """
                let x = [
                   1,
                   2
                ] + [
                   3,
                   4
                ]
                """,
              ),
            ]
    }
}
