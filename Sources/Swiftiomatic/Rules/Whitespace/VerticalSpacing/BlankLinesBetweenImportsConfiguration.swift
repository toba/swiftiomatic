struct BlankLinesBetweenImportsConfiguration: RuleConfiguration {
    let id = "blank_lines_between_imports"
    let name = "Blank Lines Between Imports"
    let summary = "There should be no blank lines between import statements"
    let scope: Scope = .format
    let isCorrectable = true
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                import A
                import B
                import C
                """)
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                import A

                ↓import B
                """)
            ]
    }
    var corrections: [Example: Example] {
        [
              Example("import A\n\n↓import B"): Example("import A\nimport B")
            ]
    }
}
