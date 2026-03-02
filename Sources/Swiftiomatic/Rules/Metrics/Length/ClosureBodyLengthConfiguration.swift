struct ClosureBodyLengthConfiguration: RuleConfiguration {
    let id = "closure_body_length"
    let name = "Closure Body Length"
    let summary = "Closure bodies should not span too many lines"
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        ClosureBodyLengthRuleExamples.nonTriggeringExamples
    }
    var triggeringExamples: [Example] {
        ClosureBodyLengthRuleExamples.triggeringExamples
    }
    let rationale: String? = """
      "Closure bodies should not span too many lines" says it all.

      Possibly you could refactor your closure code and extract some of it into a function.
      """
}
