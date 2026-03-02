struct SortTypealiasesConfiguration: RuleConfiguration {
    let id = "sort_typealiases"
    let name = "Sort Typealiases"
    let summary = "Protocol composition typealiases should be sorted alphabetically"
    let scope: Scope = .suggest
    var nonTriggeringExamples: [Example] {
        [
              Example("typealias Dependencies = Bar & Foo & Quux"),
              Example("typealias Foo = Int"),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("typealias Dependencies = ↓Foo & Bar & Quux")
            ]
    }
}
