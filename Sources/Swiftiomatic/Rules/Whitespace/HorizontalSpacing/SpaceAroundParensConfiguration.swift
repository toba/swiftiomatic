struct SpaceAroundParensConfiguration: RuleConfiguration {
    let id = "space_around_parens"
    let name = "Space Around Parentheses"
    let summary = "No space between function name and opening paren; space required after closing paren before identifiers"
    let scope: Scope = .format
    let isCorrectable = true
    var nonTriggeringExamples: [Example] {
        [
              Example("foo(bar)"),
              Example("init(foo: Int)"),
              Example("if (condition) {}"),
              Example("switch (x) {}"),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("foo↓ (bar)"),
              Example("init↓ (foo: Int)"),
            ]
    }
    var corrections: [Example: Example] {
        [
              Example("foo↓ (bar)"): Example("foo(bar)")
            ]
    }
}
