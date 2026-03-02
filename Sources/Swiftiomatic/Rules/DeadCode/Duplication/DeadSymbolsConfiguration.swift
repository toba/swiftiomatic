struct DeadSymbolsConfiguration: RuleConfiguration {
    let id = "dead_symbols"
    let name = "Dead Symbols"
    let summary = "Private symbols with no references are likely dead code"
    let isOptIn = true
    let isCrossFile = true
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                private func helper() {}
                func main() { helper() }
                """,
              )
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                ↓private func unused() {}
                func main() { }
                """,
              )
            ]
    }
}
