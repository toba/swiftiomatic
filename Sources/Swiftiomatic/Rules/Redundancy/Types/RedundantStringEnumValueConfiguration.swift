struct RedundantStringEnumValueConfiguration: RuleConfiguration {
    let id = "redundant_string_enum_value"
    let name = "Redundant String Enum Value"
    let summary = "String enum values can be omitted when they are equal to the enumcase name"
    let isCorrectable = true
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                enum Numbers: String {
                  case one
                  case two
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
                enum Numbers: String {
                  case one = "ONE"
                  case two = "TWO"
                }
                """,
              ),
              Example(
                """
                enum Numbers: String {
                  case one = "ONE"
                  case two = "two"
                }
                """,
              ),
              Example(
                """
                enum Numbers: String {
                  case one, two
                }
                """,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                enum Numbers: String {
                  case one = ↓"one"
                  case two = ↓"two"
                }
                """,
              ),
              Example(
                """
                enum Numbers: String {
                  case one = ↓"one", two = ↓"two"
                }
                """,
              ),
              Example(
                """
                enum Numbers: String {
                  case one, two = ↓"two"
                }
                """,
              ),
            ]
    }
    var corrections: [Example: Example] {
        [
              Example(
                """
                enum Numbers: String {
                  case one = ↓"one"
                  case two = ↓"two"
                }
                """,
              ): Example(
                """
                enum Numbers: String {
                  case one
                  case two
                }
                """,
              ),
              Example(
                """
                enum Numbers: String {
                  case one, two = ↓"two"
                }
                """,
              ): Example(
                """
                enum Numbers: String {
                  case one, two
                }
                """,
              ),
            ]
    }
}
