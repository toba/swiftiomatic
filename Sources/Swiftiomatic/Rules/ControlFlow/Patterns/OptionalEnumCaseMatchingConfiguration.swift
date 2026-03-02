struct OptionalEnumCaseMatchingConfiguration: RuleConfiguration {
    let id = "optional_enum_case_matching"
    let name = "Optional Enum Case Match"
    let summary = "Matching an enum case against an optional enum without '?' is supported on Swift 5.1 and above"
    let isCorrectable = true
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                switch foo {
                 case .bar: break
                 case .baz: break
                 default: break
                }
                """,
              ),
              Example(
                """
                switch foo {
                 case (.bar, .baz): break
                 case (.bar, _): break
                 case (_, .baz): break
                 default: break
                }
                """,
              ),
              Example(
                """
                switch (x, y) {
                case (.c, _?):
                    break
                case (.c, nil):
                    break
                case (_, _):
                    break
                }
                """,
              ),
              // https://github.com/apple/swift/issues/61817
              Example(
                """
                switch bool {
                case true?:
                  break
                case false?:
                  break
                case .none:
                  break
                }
                """, isExcludedFromDocumentation: true,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                switch foo {
                 case .bar↓?: break
                 case .baz: break
                 default: break
                }
                """,
              ),
              Example(
                """
                switch foo {
                 case Foo.bar↓?: break
                 case .baz: break
                 default: break
                }
                """,
              ),
              Example(
                """
                switch foo {
                 case .bar↓?, .baz↓?: break
                 default: break
                }
                """,
              ),
              Example(
                """
                switch foo {
                 case .bar↓? where x > 1: break
                 case .baz: break
                 default: break
                }
                """,
              ),
              Example(
                """
                switch foo {
                 case (.bar↓?, .baz↓?): break
                 case (.bar↓?, _): break
                 case (_, .bar↓?): break
                 default: break
                }
                """,
              ),
            ]
    }
    var corrections: [Example: Example] {
        [
              Example(
                """
                switch foo {
                 case .bar↓?: break
                 case .baz: break
                 default: break
                }
                """,
              ): Example(
                """
                switch foo {
                 case .bar: break
                 case .baz: break
                 default: break
                }
                """,
              ),
              Example(
                """
                switch foo {
                 case Foo.bar↓?: break
                 case .baz: break
                 default: break
                }
                """,
              ): Example(
                """
                switch foo {
                 case Foo.bar: break
                 case .baz: break
                 default: break
                }
                """,
              ),
              Example(
                """
                switch foo {
                 case .bar↓?, .baz↓?: break
                 default: break
                }
                """,
              ): Example(
                """
                switch foo {
                 case .bar, .baz: break
                 default: break
                }
                """,
              ),
              Example(
                """
                switch foo {
                 case .bar↓? where x > 1: break
                 case .baz: break
                 default: break
                }
                """,
              ): Example(
                """
                switch foo {
                 case .bar where x > 1: break
                 case .baz: break
                 default: break
                }
                """,
              ),
              Example(
                """
                switch foo {
                 case (.bar↓?, .baz↓?): break
                 case (.bar↓?, _): break
                 case (_, .bar↓?): break
                 default: break
                }
                """,
              ): Example(
                """
                switch foo {
                 case (.bar, .baz): break
                 case (.bar, _): break
                 case (_, .bar): break
                 default: break
                }
                """,
              ),
              Example(
                """
                switch foo {
                 case (true?, false?): break
                 case (true?, _): break
                 case (_, false?): break
                 default: break
                }
                """,
              ): Example(
                """
                switch foo {
                 case (true?, false?): break
                 case (true?, _): break
                 case (_, false?): break
                 default: break
                }
                """,
              ),
            ]
    }
}
