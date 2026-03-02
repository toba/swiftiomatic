struct SortDeclarationsConfiguration: RuleConfiguration {
    let id = "sort_declarations"
    let name = "Sort Declarations"
    let summary = "Declarations marked with `// sm:sort` should have their members sorted alphabetically"
    let scope: Scope = .suggest
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                // sm:sort
                enum FeatureFlags {
                  case barFeature
                  case fooFeature
                }
                """,
              )
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                // sm:sort
                enum ↓FeatureFlags {
                  case fooFeature
                  case barFeature
                }
                """,
              )
            ]
    }
}
