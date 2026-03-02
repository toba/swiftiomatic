struct TypedThrowsConfiguration: RuleConfiguration {
    let id = "typed_throws"
    let name = "Typed Throws"
    let summary = "Functions that throw a single error type should use typed throws"
    let scope: Scope = .suggest
    let isOptIn = true
    let canEnrichAsync = true
    var nonTriggeringExamples: [Example] {
        [
              Example("func parse() throws(ParseError) { throw ParseError.invalid }"),
              Example("func work() throws { throw ErrorA.a; throw ErrorB.b }"),
              Example("func safe() { }"),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("↓func parse() throws { throw ParseError.invalid }")
            ]
    }
}
