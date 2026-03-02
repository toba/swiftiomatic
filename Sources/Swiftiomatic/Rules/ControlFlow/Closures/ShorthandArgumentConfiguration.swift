struct ShorthandArgumentConfiguration: RuleConfiguration {
    let id = "shorthand_argument"
    let name = "Shorthand Argument"
    let summary = ""
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                f { $0 }
                """,
              ),
              Example(
                """
                f {
                    $0
                  + $1
                  + $2
                }
                """,
              ),
              Example(
                """
                f { $0.a + $0.b }
                """,
              ),
              Example(
                """
                f {
                    $0
                  +  g { $0 }
                """, configuration: ["allow_until_line_after_opening_brace": 1],
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                f {
                    $0
                  + $1
                  + $2

                  + ↓$0
                }
                """,
              ),
              Example(
                """
                f {
                    $0
                  + $1
                  + $2
                  +  5
                  + $0
                  + ↓$1
                }
                """, configuration: ["allow_until_line_after_opening_brace": 5],
              ),
              Example(
                """
                f { ↓$0 + ↓$1 }
                """, configuration: ["always_disallow_more_than_one": true],
              ),
              Example(
                """
                f {
                    ↓$0.a
                  + ↓$0.b
                  + $1
                  + ↓$2.c
                }
                """,
                configuration: [
                  "always_disallow_member_access": true,
                  "allow_until_line_after_opening_brace": 3,
                ],
              ),
            ]
    }
}
