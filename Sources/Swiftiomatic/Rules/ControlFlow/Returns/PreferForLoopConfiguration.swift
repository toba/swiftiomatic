struct PreferForLoopConfiguration: RuleConfiguration {
    let id = "prefer_for_loop"
    let name = "Prefer For Loop"
    let summary = "`.forEach { }` calls can be replaced with `for ... in` loops for better readability"
    let scope: Scope = .suggest
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                for item in items {
                  process(item)
                }
                """,
              ),
              Example("items.map { $0.name }"),
              Example("items.filter { $0.isActive }.forEach { process($0) }"),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                items.↓forEach { item in
                  process(item)
                }
                """,
              ),
              Example(
                """
                items.↓forEach {
                  process($0)
                }
                """,
              ),
            ]
    }
}
