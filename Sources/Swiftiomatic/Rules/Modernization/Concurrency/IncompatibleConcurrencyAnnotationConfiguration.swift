struct IncompatibleConcurrencyAnnotationConfiguration: RuleConfiguration {
    let id = "incompatible_concurrency_annotation"
    let name = "Incompatible Concurrency Annotation"
    let summary = "Declaration should be @preconcurrency to maintain compatibility with Swift 5"
    let isCorrectable = true
    let isOptIn = true
}
