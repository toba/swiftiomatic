struct BlankLinesAroundMarkConfiguration: RuleConfiguration {
    let id = "blank_lines_around_mark"
    let name = "Blank Lines Around MARK"
    let summary = "MARK comments should be preceded and followed by a blank line"
    let scope: Scope = .format
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                func foo() {}

                // MARK: - Bar

                func bar() {}
                """)
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                func foo() {}
                ↓// MARK: - Bar
                func bar() {}
                """)
            ]
    }
}
