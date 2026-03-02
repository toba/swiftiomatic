struct LeadingDelimitersConfiguration: RuleConfiguration {
    let id = "leading_delimiters"
    let name = "Leading Delimiters"
    let summary = "Delimiters should not appear at the start of a line; move them to the end of the previous line"
    let scope: Scope = .format
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                guard let foo = maybeFoo,
                      let bar = maybeBar else { return }
                """)
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                guard let foo = maybeFoo
                      ↓, let bar = maybeBar else { return }
                """)
            ]
    }
}
