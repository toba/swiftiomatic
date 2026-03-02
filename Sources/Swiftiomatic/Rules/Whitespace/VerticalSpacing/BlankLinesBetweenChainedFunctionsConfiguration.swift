struct BlankLinesBetweenChainedFunctionsConfiguration: RuleConfiguration {
    let id = "blank_lines_between_chained_functions"
    let name = "Blank Lines Between Chained Functions"
    let summary = "There should be no blank lines between chained function calls"
    let scope: Scope = .format
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                [0, 1, 2]
                    .map { $0 * 2 }
                    .filter { $0 > 0 }
                """)
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                [0, 1, 2]
                    .map { $0 * 2 }

                    ↓.filter { $0 > 0 }
                """)
            ]
    }
}
