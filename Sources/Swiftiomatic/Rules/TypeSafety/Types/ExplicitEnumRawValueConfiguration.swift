struct ExplicitEnumRawValueConfiguration: RuleConfiguration {
    let id = "explicit_enum_raw_value"
    let name = "Explicit Enum Raw Value"
    let summary = "Enums should be explicitly assigned their raw values"
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                enum Numbers {
                  case int(Int)
                  case short(Int16)
                }
                """,
              ),
              Example(
                """
                enum Numbers: Int {
                  case one = 1
                  case two = 2
                }
                """,
              ),
              Example(
                """
                enum Numbers: Double {
                  case one = 1.1
                  case two = 2.2
                }
                """,
              ),
              Example(
                """
                enum Numbers: String {
                  case one = "one"
                  case two = "two"
                }
                """,
              ),
              Example(
                """
                protocol Algebra {}
                enum Numbers: Algebra {
                  case one
                }
                """,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                enum Numbers: Int {
                  case one = 10, ↓two, three = 30
                }
                """,
              ),
              Example(
                """
                enum Numbers: NSInteger {
                  case ↓one
                }
                """,
              ),
              Example(
                """
                enum Numbers: String {
                  case ↓one
                  case ↓two
                }
                """,
              ),
              Example(
                """
                enum Numbers: String {
                   case ↓one, two = "two"
                }
                """,
              ),
              Example(
                """
                enum Numbers: Decimal {
                  case ↓one, ↓two
                }
                """,
              ),
              Example(
                """
                enum Outer {
                    enum Numbers: Decimal {
                      case ↓one, ↓two
                    }
                }
                """,
              ),
            ]
    }
}
