struct ContainsOverFirstNotNilConfiguration: RuleConfiguration {
    let id = "contains_over_first_not_nil"
    let name = "Contains over First not Nil"
    let summary = "Prefer `contains` over `first(where:) != nil` and `firstIndex(where:) != nil`."
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        ["first", "firstIndex"].flatMap { method in
            [
                Example("let \(method) = myList.\(method)(where: { $0 % 2 == 0 })"),
                Example("let \(method) = myList.\(method) { $0 % 2 == 0 }"),
            ]
        }
    }
    var triggeringExamples: [Example] {
        ["first", "firstIndex"].flatMap { method in
            ["!=", "=="].flatMap { comparison in
                [
                    Example("↓myList.\(method) { $0 % 2 == 0 } \(comparison) nil"),
                    Example("↓myList.\(method)(where: { $0 % 2 == 0 }) \(comparison) nil"),
                    Example(
                        "↓myList.map { $0 + 1 }.\(method)(where: { $0 % 2 == 0 }) \(comparison) nil"
                    ),
                    Example("↓myList.\(method)(where: someFunction) \(comparison) nil"),
                    Example("↓myList.map { $0 + 1 }.\(method) { $0 % 2 == 0 } \(comparison) nil"),
                    Example("(↓myList.\(method) { $0 % 2 == 0 }) \(comparison) nil"),
                ]
            }
        }
    }
}
