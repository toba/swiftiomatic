struct PerformanceAntiPatternsConfiguration: RuleConfiguration {
    let id = "performance_anti_patterns"
    let name = "Performance Anti-Patterns"
    let summary = "Detects common performance anti-patterns like Date() for benchmarking and mutation during iteration"
    let isOptIn = true
}
