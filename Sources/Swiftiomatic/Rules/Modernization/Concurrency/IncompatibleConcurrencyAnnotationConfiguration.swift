struct IncompatibleConcurrencyAnnotationConfiguration: RuleConfiguration {
    let id = "incompatible_concurrency_annotation"
    let name = "Incompatible Concurrency Annotation"
    let summary = "Declaration should be @preconcurrency to maintain compatibility with Swift 5"
    let isCorrectable = true
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        IncompatibleConcurrencyAnnotationRuleExamples.nonTriggeringExamples
    }
    var triggeringExamples: [Example] {
        IncompatibleConcurrencyAnnotationRuleExamples.triggeringExamples
    }
    var corrections: [Example: Example] {
        IncompatibleConcurrencyAnnotationRuleExamples.corrections
    }
    let rationale: String? = """
      Declarations that use concurrency features such as `@Sendable` closures, `Sendable` generic type
      arguments or `@MainActor` (or other global actors) should be annotated with `@preconcurrency`
      to ensure compatibility with Swift 5.

      This rule detects public declarations that require `@preconcurrency` and can automatically add
      the annotation.
      """
}
