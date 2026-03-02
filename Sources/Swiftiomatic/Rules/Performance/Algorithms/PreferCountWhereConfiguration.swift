struct PreferCountWhereConfiguration: RuleConfiguration {
    let id = "prefer_count_where"
    let name = "Prefer count(where:)"
    let summary = "Use `count(where:)` instead of `filter(_:).count` for better performance"
    var nonTriggeringExamples: [Example] {
        [
              Example("let count = array.count"),
              Example("let count = array.count(where: { $0 > 0 })"),
              Example("let filtered = array.filter { $0 > 0 }"),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("let count = array.↓filter { $0 > 0 }.count"),
              Example("let count = array.↓filter({ $0 > 0 }).count"),
            ]
    }
}
