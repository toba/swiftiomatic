struct UnneededBreakInSwitchConfiguration: RuleConfiguration {
    let id = "unneeded_break_in_switch"
    let name = "Unneeded Break in Switch"
    let summary = "Avoid using unneeded break statements"
    let isCorrectable = true

    private static func embedInSwitch(
      _ text: String,
      case: String = "case .bar",
      file: StaticString = #filePath,
      line: UInt = #line,
    ) -> Example {
      Example(
        """
        switch foo {
        \(`case`):
            \(text)
        }
        """, file: file, line: line,
      )
    }

    var nonTriggeringExamples: [Example] {
        [
              Self.embedInSwitch("break"),
              Self.embedInSwitch("break", case: "default"),
              Self.embedInSwitch("for i in [0, 1, 2] { break }"),
              Self.embedInSwitch("if true { break }"),
              Self.embedInSwitch("something()"),
              Example(
                """
                let items = [Int]()
                for item in items {
                    if bar() {
                        do {
                            try foo()
                        } catch {
                            bar()
                            break
                        }
                    }
                }
                """,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Self.embedInSwitch("something()\n    ↓break"),
              Self.embedInSwitch("something()\n    ↓break // comment"),
              Self.embedInSwitch("something()\n    ↓break", case: "default"),
              Self.embedInSwitch("something()\n    ↓break", case: "case .foo, .foo2 where condition"),
            ]
    }
    var corrections: [Example: Example] {
        [
              Self.embedInSwitch("something()\n    ↓break"): Self.embedInSwitch("something()"),
              Self.embedInSwitch("something()\n    ↓break // line comment"): Self.embedInSwitch(
                "something()\n     // line comment",
              ),
              Self.embedInSwitch(
                """
                something()
                ↓break
                /*
                block comment
                */
                """,
              ): Self.embedInSwitch(
                """
                something()
                /*
                block comment
                */
                """,
              ),
              Self.embedInSwitch("something()\n    ↓break /// doc line comment"): Self.embedInSwitch(
                "something()\n     /// doc line comment",
              ),
              Self.embedInSwitch(
                """
                something()
                ↓break
                ///
                /// doc block comment
                ///
                """,
              ): Self.embedInSwitch(
                """
                something()
                ///
                /// doc block comment
                ///
                """,
              ),
              Self.embedInSwitch("something()\n    ↓break", case: "default"): Self.embedInSwitch(
                "something()", case: "default",
              ),
              Self.embedInSwitch("something()\n    ↓break", case: "case .foo, .foo2 where condition"):
                Self.embedInSwitch("something()", case: "case .foo, .foo2 where condition"),
            ]
    }
}
