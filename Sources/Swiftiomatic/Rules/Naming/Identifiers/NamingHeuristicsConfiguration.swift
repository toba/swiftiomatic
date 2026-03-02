struct NamingHeuristicsConfiguration: RuleConfiguration {
    let id = "naming_heuristics"
    let name = "Naming Heuristics"
    let summary = "Checks names against Swift API Design Guidelines: Bool assertions, protocol suffixes, factory prefixes"
    let isOptIn = true
    let canEnrichAsync = true
    var nonTriggeringExamples: [Example] {
        [
              Example("var isEnabled: Bool = true"),
              Example("var hasContent: Bool = false"),
              Example("static func makeWidget() -> Widget { }"),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("var ↓enabled: Bool = true"),
              Example("static func ↓createWidget() -> Widget { }"),
            ]
    }
}
