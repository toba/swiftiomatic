struct Swift62ModernizationConfiguration: RuleConfiguration {
    let id = "swift62_modernization"
    let name = "Swift 6.2 Modernization"
    let summary = "Code that can benefit from Swift 6.2 features like @concurrent, Observations, weak let, and Span"
    let scope: Scope = .suggest
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example("func work() async { }")
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("↓Task.detached { await work() }"),
              Example("↓withObservationTracking { }"),
            ]
    }
}
