struct PerformanceAntiPatternsConfiguration: RuleConfiguration {
    let id = "performance_anti_patterns"
    let name = "Performance Anti-Patterns"
    let summary = "Detects common performance anti-patterns like Date() for benchmarking and mutation during iteration"
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example("let now = ContinuousClock.now"),
              Example("array.removeAll(where: { $0.isEmpty })"),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                for item in ↓items {
                    items.remove(at: 0)
                }
                """,
              )
            ]
    }
}
