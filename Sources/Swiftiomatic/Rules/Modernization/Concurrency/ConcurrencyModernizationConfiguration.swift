struct ConcurrencyModernizationConfiguration: RuleConfiguration {
    let id = "concurrency_modernization"
    let name = "Concurrency Modernization"
    let summary = "Flags GCD usage and legacy concurrency patterns that should use structured concurrency"
    let isOptIn = true
    let canEnrichAsync = true
    var nonTriggeringExamples: [Example] {
        [
              Example("Task { @MainActor in update() }"),
              Example("await withTaskGroup(of: Void.self) { }"),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("↓DispatchQueue.main.async { update() }"),
              Example("↓DispatchGroup()"),
              Example("func fetch(↓completion: @escaping (Result<Data, Error>) -> Void) {}"),
            ]
    }
}
