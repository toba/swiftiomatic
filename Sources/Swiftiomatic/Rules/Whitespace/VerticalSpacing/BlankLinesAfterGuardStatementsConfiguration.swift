struct BlankLinesAfterGuardStatementsConfiguration: RuleConfiguration {
    let id = "blank_lines_after_guard_statements"
    let name = "Blank Lines After Guard Statements"
    let summary = "There should be a blank line after the last guard statement before other code"
    let scope: Scope = .format
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                guard let foo = bar else { return }

                print(foo)
                """),
              Example(
                """
                guard let a = b else { return }
                guard let c = d else { return }

                print(a, c)
                """),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                guard let foo = bar else { return }
                ↓print(foo)
                """)
            ]
    }
}
