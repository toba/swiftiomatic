struct SortedEnumCasesConfiguration: RuleConfiguration {
    let id = "sorted_enum_cases"
    let name = "Sorted Enum Cases"
    let summary = "Enum cases should be sorted"
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                enum foo {
                    case a
                    case b
                    case c
                }
                """,
              ),
              Example(
                """
                enum foo {
                    case example
                    case exBoyfriend
                }
                """,
              ),
              Example(
                """
                enum foo {
                    case a
                    case B
                    case c
                }
                """,
              ),
              Example(
                """
                enum foo {
                    case a, b, c
                }
                """,
              ),
              Example(
                """
                enum foo {
                    case a
                    case b, c
                }
                """,
              ),
              Example(
                """
                enum foo {
                    case a(foo: Foo)
                    case b(String), c
                }
                """,
              ),
              Example(
                """
                enum foo {
                    case a
                    case b, C, d
                }
                """,
              ),
              Example(
                """
                @frozen
                enum foo {
                    case b
                    case a
                    case c, f, d
                }
                """,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                enum foo {
                    ↓case b
                    ↓case a
                    case c
                }
                """,
              ),
              Example(
                """
                enum foo {
                    ↓case B
                    ↓case a
                    case c
                }
                """,
              ),
              Example(
                """
                enum foo {
                    case ↓b, ↓a, c
                }
                """,
              ),
              Example(
                """
                enum foo {
                    case ↓B, ↓a, c
                }
                """,
              ),
              Example(
                """
                enum foo {
                    ↓case b, c
                    ↓case a
                }
                """,
              ),
              Example(
                """
                enum foo {
                    case a
                    case b, ↓d, ↓c
                }
                """,
              ),
              Example(
                """
                enum foo {
                    case a(foo: Foo)
                    case ↓c, ↓b(String)
                }
                """,
              ),
            ]
    }
}
